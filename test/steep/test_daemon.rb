# frozen_string_literal: true

require "test_helper"

class Steep::TestDaemon < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Steep::Daemon::VERSION
  end

  def test_socket_dir_constant
    assert_equal File.join(Dir.tmpdir, "steep-server"), Steep::Daemon::SOCKET_DIR
  end

  def test_config_returns_configuration_instance
    config = Steep::Daemon.config
    assert_instance_of Steep::Daemon::Configuration, config
  end

  def test_config_is_memoized
    config1 = Steep::Daemon.config
    config2 = Steep::Daemon.config
    assert_same config1, config2
  end

  def test_project_id_delegates_to_config
    assert_equal Steep::Daemon.config.project_id, Steep::Daemon.project_id
  end

  def test_socket_path_delegates_to_config
    assert_equal Steep::Daemon.config.socket_path, Steep::Daemon.socket_path
  end

  def test_pid_path_delegates_to_config
    assert_equal Steep::Daemon.config.pid_path, Steep::Daemon.pid_path
  end

  def test_log_path_delegates_to_config
    assert_equal Steep::Daemon.config.log_path, Steep::Daemon.log_path
  end

  def test_running_returns_false_when_no_files_exist
    # Cleanup any existing files
    Steep::Daemon.cleanup
    refute Steep::Daemon.running?
  end

  def test_starting_returns_false_when_no_files_exist
    # Cleanup any existing files
    Steep::Daemon.cleanup
    refute Steep::Daemon.starting?
  end

  def test_cleanup_removes_socket_and_pid_files
    # Create dummy files
    FileUtils.mkdir_p(File.dirname(Steep::Daemon.socket_path))
    File.write(Steep::Daemon.socket_path, "dummy")
    File.write(Steep::Daemon.pid_path, "12345")

    # Cleanup
    Steep::Daemon.cleanup

    # Verify files are removed
    refute File.exist?(Steep::Daemon.socket_path)
    refute File.exist?(Steep::Daemon.pid_path)
  end

  def teardown
    # Cleanup after each test
    Steep::Daemon.cleanup
  end
end
