# frozen_string_literal: true

require "test_helper"

module Steep
  module Daemon
    class TestConfiguration < Minitest::Test
      def setup
        @config = Steep::Daemon::Configuration.new(base_dir: "/test/project")
      end

      def test_generates_consistent_project_id
        project_id = @config.project_id
        assert_equal 8, project_id.length
        assert_match(/\A[0-9a-f]{8}\z/, project_id)
      end

      def test_project_id_is_deterministic
        config1 = Steep::Daemon::Configuration.new(base_dir: "/test/project")
        config2 = Steep::Daemon::Configuration.new(base_dir: "/test/project")
        assert_equal config1.project_id, config2.project_id
      end

      def test_different_projects_have_different_ids
        config1 = Steep::Daemon::Configuration.new(base_dir: "/test/project1")
        config2 = Steep::Daemon::Configuration.new(base_dir: "/test/project2")
        refute_equal config1.project_id, config2.project_id
      end

      def test_socket_dir_is_set
        assert_equal File.join(Dir.tmpdir, "steep-server"), @config.socket_dir
      end

      def test_socket_path_includes_project_id
        assert_includes @config.socket_path, @config.project_id
        assert_match(/steep-[0-9a-f]{8}\.sock\z/, @config.socket_path)
      end

      def test_pid_path_derives_from_socket_path
        assert_equal @config.socket_path.sub(".sock", ".pid"), @config.pid_path
      end

      def test_log_path_derives_from_socket_path
        assert_equal @config.socket_path.sub(".sock", ".log"), @config.log_path
      end

      def test_socket_dir_is_created
        # The directory should be created during initialization
        assert File.directory?(@config.socket_dir)
      end

      def test_uses_current_directory_by_default
        config = Steep::Daemon::Configuration.new
        expected_id = Digest::MD5.hexdigest(Dir.pwd)[0, 8]
        assert_equal expected_id, config.project_id
      end
    end
  end
end
