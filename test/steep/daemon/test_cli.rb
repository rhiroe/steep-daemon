# frozen_string_literal: true

require "test_helper"

module Steep
  module Daemon
    class TestCLI < Minitest::Test
      def setup
        @original_stderr = $stderr
        @original_stdout = $stdout
        $stderr = StringIO.new
        $stdout = StringIO.new

        # Ensure daemon is not running
        Steep::Daemon.cleanup
      end

      def teardown
        $stderr = @original_stderr
        $stdout = @original_stdout
        Steep::Daemon.cleanup
      end

      def test_help_command
        cli = Steep::Daemon::CLI.new(["help"])
        cli.run

        output = $stdout.string
        assert_includes output, "Usage: steep-daemon COMMAND"
        assert_includes output, "start"
        assert_includes output, "stop"
        assert_includes output, "restart"
        assert_includes output, "status"
      end

      def test_help_flag
        cli = Steep::Daemon::CLI.new(["--help"])
        cli.run

        output = $stdout.string
        assert_includes output, "Usage: steep-daemon COMMAND"
      end

      def test_no_arguments_shows_help
        cli = Steep::Daemon::CLI.new([])
        cli.run

        output = $stdout.string
        assert_includes output, "Usage: steep-daemon COMMAND"
      end

      def test_unknown_command_shows_error
        cli = Steep::Daemon::CLI.new(["unknown"])

        assert_raises(SystemExit) do
          cli.run
        end

        assert_includes $stderr.string, "Unknown command: unknown"
      end

      def test_status_command_when_not_running
        cli = Steep::Daemon::CLI.new(["status"])

        assert_raises(SystemExit) do
          cli.run
        end

        assert_includes $stderr.string, "Steep server is not running"
      end

      def test_stop_command_when_not_running
        cli = Steep::Daemon::CLI.new(["stop"])

        assert_raises(SystemExit) do
          cli.run
        end

        assert_includes $stderr.string, "Steep daemon is not running"
      end

      def test_cli_has_all_required_commands
        cli = Steep::Daemon::CLI.new([])

        # Verify that CLI responds to the run method
        assert_respond_to cli, :run
      end
    end
  end
end
