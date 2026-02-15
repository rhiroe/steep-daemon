# frozen_string_literal: true

module Steep
  module Daemon
    class CLI
      def initialize(argv)
        @argv = argv
      end

      def run
        command = @argv[0]

        case command
        when "start"
          start_command
        when "stop"
          stop_command
        when "restart"
          restart_command
        when "status"
          status_command
        when "help", "--help", "-h", nil
          print_help
        else
          warn "Unknown command: #{command}"
          print_help
          exit 1
        end
      end

      private

      def start_command
        if Daemon.running?
          warn "Steep daemon is already running"
          exit 1
        end

        warn "Starting Steep daemon..."
        success = Daemon.start

        exit(success ? 0 : 1)
      end

      def stop_command
        unless Daemon.running?
          warn "Steep daemon is not running"
          exit 1
        end

        warn "Stopping Steep daemon..."
        Daemon.stop
        exit 0
      end

      def restart_command
        if Daemon.running?
          warn "Stopping Steep daemon..."
          Daemon.stop
          sleep 1
        end

        warn "Starting Steep daemon..."
        success = Daemon.start
        exit(success ? 0 : 1)
      end

      def status_command
        Daemon.status
        exit(Daemon.running? ? 0 : 1)
      end

      def print_help
        puts <<~HELP
          Usage: steep-daemon COMMAND

          Manage Steep daemon server for persistent RBS environment

          Commands:
            start      Start the daemon server
            stop       Stop the daemon server
            restart    Restart the daemon server
            status     Show daemon status
            help       Show this help message

          Examples:
            $ steep-daemon start
            $ steep-daemon status
            $ steep-daemon stop

          Once the daemon is running, 'steep check' will automatically use it
          for dramatically faster type checking (10-100x speedup).

          The daemon keeps Steep's LSP Server (Master + Workers) running
          persistently, avoiding expensive RBS environment reloading on each check.

          Socket and log paths:
            Socket: #{Daemon.socket_path}
            PID:    #{Daemon.pid_path}
            Log:    #{Daemon.log_path}
        HELP
      end
    end
  end
end
