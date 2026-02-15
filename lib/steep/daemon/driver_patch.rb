# frozen_string_literal: true

require "json"
require "socket"

module Steep
  module Daemon
    module DriverCheckPatch
      attr_accessor :use_daemon

      def initialize(**args)
        super
        @use_daemon = true
      end

      def run
        if use_daemon
          if Daemon.running?
            Steep.logger.info { "Daemon detected, using server mode" }
            return run_with_server
          elsif Daemon.starting?
            Steep.logger.info { "Daemon is starting, waiting for it to be ready" }
            if wait_for_daemon
              return run_with_server
            else
              stderr.puts Rainbow("Daemon failed to start, falling back to standard mode").yellow
            end
          end
        end

        super
      end

      def run_with_server
        project = load_config()

        stdout.puts Rainbow("# Type checking files (server mode):").bold
        stdout.puts

        params = build_typecheck_params(project)

        Steep.logger.info {
          "Server mode: #{params[:code_paths].size} code files, #{params[:signature_paths].size} signatures"
        }

        socket = UNIXSocket.new(Daemon.socket_path)
        socket.puts(JSON.generate({ params: params }))

        diagnostic_notifications = []
        error_messages = []

        while (line = socket.gets)
          msg = JSON.parse(line, symbolize_names: true)

          case msg[:type]
          when "diagnostic"
            ds = msg[:params][:diagnostics]
            ds.select! { |d| keep_diagnostic?(d, severity_level: severity_level) }
            stdout.print(ds.empty? ? "." : "F")
            diagnostic_notifications << msg[:params]
            stdout.flush
          when "message"
            lsp_error = LanguageServer::Protocol::Constant::MessageType::ERROR
            if msg[:params][:type] == lsp_error
              error_messages << msg[:params][:message]
            end
          when "complete"
            break
          end
        end

        socket.close

        stdout.puts
        stdout.puts

        print_typecheck_result(project: project, diagnostic_notifications: diagnostic_notifications, error_messages: error_messages)
      rescue Errno::ECONNREFUSED, Errno::ENOENT => e
        stderr.puts "Steep server connection failed (#{e.message}), falling back to normal check"
        super
      rescue Errno::EPIPE => error
        stdout.puts Rainbow("Steep server connection lost: #{error.inspect}").red.bold
        1
      end

      def print_typecheck_result(project:, diagnostic_notifications:, error_messages:)
        if error_messages.empty?
          loader = Services::FileLoader.new(base_dir: project.base_dir)
          all_files = project.targets.each.with_object(Set[]) do |target, set|
            set.merge(loader.load_changes(target.source_pattern, command_line_patterns, changes: {}).each_key)
            set.merge(loader.load_changes(target.signature_pattern, changes: {}).each_key)
          end.to_a

          case
          when with_expectations_path
            print_expectations(project: project,
                               all_files: all_files,
                               expectations_path: with_expectations_path,
                               notifications: diagnostic_notifications)
          when save_expectations_path
            save_expectations(project: project,
                              all_files: all_files,
                              expectations_path: save_expectations_path,
                              notifications: diagnostic_notifications)
          else
            print_result(project: project, notifications: diagnostic_notifications)
          end
        else
          stdout.puts Rainbow("Unexpected error reported. 🚨").red.bold
          1
        end
      end

      def build_typecheck_params(project)
        params = { library_paths: [], inline_paths: [], signature_paths: [], code_paths: [] }

        if command_line_patterns.empty?
          files = Server::TargetGroupFiles.new(project)
          loader = Services::FileLoader.new(base_dir: project.base_dir)

          project.targets.each do |target|
            target.new_env_loader.each_dir do |_, dir|
              RBS::FileFinder.each_file(dir, skip_hidden: true) do |path|
                files.add_library_path(target, path)
              end
            end

            loader.each_path_in_target(target) do |path|
              files.add_path(path)
            end
          end

          project.targets.each do |target|
            target.groups.each do |group|
              if active_group?(group)
                load_files(files, target, group, params: params)
              end
            end
            if active_group?(target)
              load_files(files, target, target, params: params)
            end
          end
        else
          command_line_patterns.each do |pattern|
            path = Pathname(pattern)
            path = project.absolute_path(path)
            next unless path.file?
            if target = project.target_for_source_path(path)
              params[:code_paths] << [target.name.to_s, path.to_s]
            end
            if target = project.target_for_signature_path(path)
              params[:signature_paths] << [target.name.to_s, path.to_s]
            end
          end
        end

        params
      end

      def wait_for_daemon(timeout: 300)
        stdout.puts "Daemon is warming up, waiting for it to be ready..."
        start_time = Time.now
        dots_printed = 0

        loop do
          if Daemon.running?
            stdout.puts unless dots_printed == 0
            return true
          end

          elapsed = Time.now - start_time
          if elapsed > timeout
            stdout.puts unless dots_printed == 0
            Steep.logger.warn { "Daemon warm-up timed out after #{timeout}s" }
            return false
          end

          unless Daemon.starting?
            stdout.puts unless dots_printed == 0
            Steep.logger.warn { "Daemon process died during warm-up" }
            return false
          end

          sleep 1
          stdout.print "."
          stdout.flush
          dots_printed += 1
        end
      end
    end
  end
end

# Apply the monkey patch when Steep::Drivers::Check is loaded
# Use TracePoint to detect when the class is defined
trace = TracePoint.new(:end) do |tp|
  if tp.self.name == "Steep::Drivers::Check"
    tp.self.prepend(Steep::Daemon::DriverCheckPatch)
    trace.disable
  end
end
trace.enable

# If already loaded, apply immediately
if defined?(Steep::Drivers::Check)
  Steep::Drivers::Check.prepend(Steep::Daemon::DriverCheckPatch)
  trace.disable
end
