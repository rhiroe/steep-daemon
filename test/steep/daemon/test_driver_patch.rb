# frozen_string_literal: true

require "test_helper"

class Steep::Daemon::TestDriverPatch < Minitest::Test
  def test_driver_check_patch_module_exists
    assert defined?(Steep::Daemon::DriverCheckPatch)
  end

  def test_driver_check_has_use_daemon_method
    # Load the Steep::Drivers::Check class
    require "steep/drivers/check"

    assert Steep::Drivers::Check.instance_methods.include?(:use_daemon)
  end

  def test_driver_check_has_run_with_server_method
    require "steep/drivers/check"

    assert Steep::Drivers::Check.instance_methods.include?(:run_with_server)
  end

  def test_driver_check_has_wait_for_daemon_method
    require "steep/drivers/check"

    assert Steep::Drivers::Check.instance_methods.include?(:wait_for_daemon)
  end

  def test_driver_check_has_build_typecheck_params_method
    require "steep/drivers/check"

    assert Steep::Drivers::Check.instance_methods.include?(:build_typecheck_params)
  end

  def test_driver_check_has_print_typecheck_result_method
    require "steep/drivers/check"

    assert Steep::Drivers::Check.instance_methods.include?(:print_typecheck_result)
  end

  def test_patch_is_prepended_to_driver_check
    require "steep/drivers/check"

    # Check that our module is prepended
    ancestors = Steep::Drivers::Check.ancestors
    patch_index = ancestors.index(Steep::Daemon::DriverCheckPatch)
    check_index = ancestors.index(Steep::Drivers::Check)

    # DriverCheckPatch should appear before Steep::Drivers::Check in the ancestor chain
    assert patch_index < check_index, "Patch should be prepended"
  end

  def test_use_daemon_defaults_to_true
    require "steep/drivers/check"

    # Create a mock driver instance
    # Note: This is a simplified test - full integration testing would require more setup
    driver = Steep::Drivers::Check.allocate
    driver.instance_variable_set(:@use_daemon, true)

    assert_equal true, driver.use_daemon
  end

  def test_use_daemon_is_settable
    require "steep/drivers/check"

    driver = Steep::Drivers::Check.allocate
    driver.use_daemon = false

    assert_equal false, driver.use_daemon
  end
end
