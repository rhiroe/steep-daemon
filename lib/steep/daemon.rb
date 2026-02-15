# frozen_string_literal: true

require "tmpdir"
require "digest"
require "fileutils"

# Require steep first
require "steep"

require_relative "daemon/version"
require_relative "daemon/configuration"
require_relative "daemon/server"
require_relative "daemon/driver_patch"

module Steep
  module Daemon
    class Error < StandardError; end

    SOCKET_DIR = File.join(Dir.tmpdir, "steep-server")

    LARGE_LOG_FILE_THRESHOLD = 10 * 1024 * 1024

    class << self
      def config
        @config ||= Configuration.new
      end

      def project_id
        config.project_id
      end

      def socket_path
        config.socket_path
      end

      def pid_path
        config.pid_path
      end

      def log_path
        config.log_path
      end

      def starting?
        return false unless File.exist?(pid_path)
        return false if File.exist?(socket_path)

        pid = File.read(pid_path).to_i
        Process.kill(0, pid)
        true
      rescue Errno::ESRCH, Errno::ENOENT
        false
      end

      def running?
        return false unless File.exist?(pid_path) && File.exist?(socket_path)

        pid = File.read(pid_path).to_i
        Process.kill(0, pid)
        socket = UNIXSocket.new(socket_path)
        socket.close
        true
      rescue Errno::ESRCH, Errno::ENOENT, Errno::ECONNREFUSED, Errno::ENOTSOCK
        false
      end

      def cleanup
        [socket_path, pid_path].each do |path|
          FileUtils.rm_f(path)
        rescue StandardError
          nil
        end
      end

      def start
        if running?
          warn "Steep server already running (PID: #{File.read(pid_path).strip})"
          return true
        end

        cleanup

        unless Process.respond_to?(:fork)
          warn "fork() not available, cannot start steep server daemon"
          return false
        end

        child_pid = fork do
          Process.setsid
          daemon_pid = fork do
            File.write(pid_path, Process.pid.to_s)
            log_file = File.open(log_path, "a")
            log_file.sync = true
            $stdout.reopen(log_file)
            $stderr.reopen(log_file)
            $stdin.reopen(File::NULL)
            run_server
          end
          exit!(0) if daemon_pid
        end

        Process.waitpid(child_pid) if child_pid

        40.times do
          sleep 0.5
          next unless running?

          warn "Steep server started (PID: #{File.read(pid_path).strip})"
          return true
        end

        warn "Failed to start steep server. Check log: #{log_path}"
        false
      end

      def stop
        unless File.exist?(pid_path)
          warn "Steep server is not running"
          return
        end

        pid = File.read(pid_path).to_i
        Process.kill("TERM", pid)
        process_alive = true
        20.times do
          sleep 0.5
          Process.kill(0, pid)
        rescue Errno::ESRCH
          process_alive = false
          break
        end

        if process_alive
          Process.kill("KILL", pid)
          warn "Steep server did not stop gracefully, forcefully killed (PID: #{pid})"
        else
          warn "Steep server stopped (PID: #{pid})"
        end
        cleanup
      rescue Errno::ESRCH
        cleanup
        warn "Steep server was not running (cleaned up stale files)"
      end

      def status
        if running?
          pid = File.read(pid_path).to_i
          warn "Steep server running (PID: #{pid})"
          warn "  Socket: #{socket_path}"
          warn "  Log:    #{log_path}"

          if File.exist?(log_path)
            log_content = if File.size(log_path) > LARGE_LOG_FILE_THRESHOLD
                            # SAFE: log_path is controlled internally, no user input
                            `tail -n 20 #{log_path.shellescape}`
                          else
                            File.readlines(log_path).last(20).join
                          end

            if log_content.include?("Warm-up complete")
              warn "  Status: Ready"
            elsif log_content.include?("Warming up type checker")
              warn "  Status: Warming up (loading RBS environment)"
            else
              warn "  Status: Starting"
            end
          end
        else
          warn "Steep server is not running"

          if File.exist?(pid_path) || File.exist?(socket_path)
            warn "  (Found stale files - run 'steep server stop' to clean up)"
          end
        end
      end

      private

      def run_server
        project = load_project
        server = Server.new(config: config, project: project)
        server.run
      end

      def load_project
        steep_file = Pathname("Steepfile")
        steep_file_path = steep_file.realpath

        project = ::Steep::Project.new(steepfile_path: steep_file_path)
        ::Steep::Project::DSL.parse(project, steep_file.read, filename: steep_file.to_s)

        project.targets.each do |target|
          case target.options.load_collection_lock
          when nil, RBS::Collection::Config::Lockfile
            # OK
          when RBS::Collection::Config::CollectionNotAvailable
            config_path = target.options.collection_config_path || raise
            lockfile_path = RBS::Collection::Config.to_lockfile_path(config_path)
            RBS::Collection::Installer.new(
              lockfile_path: lockfile_path, stdout: $stderr
            ).install_from_lockfile
            target.options.load_collection_lock(force: true)
          end
        end

        project
      end
    end
  end
end
