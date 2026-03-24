# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/test_runner/suite"
require "stringio"

class SimpleDisplayManagerTest < Minitest::Test
  def setup
    @packages = [
      {"name" => "ace-support-core", "path" => "/path/to/ace-support-core"},
      {"name" => "ace-bundle", "path" => "/path/to/ace-bundle"}
    ]
    @config = {
      "test_suite" => {
        "display" => {"color" => false}
      }
    }
  end

  def test_initialize_display_prints_package_count
    manager = Ace::TestRunner::Suite::SimpleDisplayManager.new(@packages, @config)

    output = capture_output { manager.initialize_display }

    assert_includes output, "Running tests for 2 packages..."
  end

  def test_update_package_does_not_print_when_not_completed
    manager = Ace::TestRunner::Suite::SimpleDisplayManager.new(@packages, @config)

    status = {status: :running, elapsed: 1.5}
    output = capture_output { manager.update_package(@packages[0], status) }

    assert_empty output
  end

  def test_update_package_prints_when_completed_success
    manager = Ace::TestRunner::Suite::SimpleDisplayManager.new(@packages, @config)

    status = {
      completed: true,
      success: true,
      elapsed: 2.34,
      results: {
        tests: 100,
        assertions: 200,
        failures: 0,
        skipped: 0
      }
    }
    output = capture_output { manager.update_package(@packages[0], status) }

    # New columnar format: STATUS TIME PACKAGE TESTS ASSERTS FAIL
    assert_includes output, "ace-support-core"
    assert_includes output, "✓"  # Green checkmark for success
    assert_includes output, "100 tests"
    assert_includes output, "200 asserts"
    assert_includes output, "0 fail"
    assert_includes output, "2.34s"
  end

  def test_update_package_prints_when_completed_failure
    manager = Ace::TestRunner::Suite::SimpleDisplayManager.new(@packages, @config)

    status = {
      completed: true,
      success: false,
      elapsed: 3.45,
      results: {
        tests: 50,
        assertions: 120,
        failures: 2,
        errors: 1,
        skipped: 0
      }
    }
    output = capture_output { manager.update_package(@packages[0], status) }

    # New columnar format: STATUS TIME PACKAGE TESTS ASSERTS FAIL
    assert_includes output, "ace-support-core"
    assert_includes output, "✗"  # Red X for failure
    assert_includes output, "50 tests"
    assert_includes output, "3 fail"  # failures + errors
    assert_includes output, "3.45s"
  end

  def test_update_package_shows_skipped_when_present
    manager = Ace::TestRunner::Suite::SimpleDisplayManager.new(@packages, @config)

    status = {
      completed: true,
      success: true,
      elapsed: 1.23,
      results: {
        tests: 30,
        assertions: 60,
        failures: 0,
        skipped: 5
      }
    }
    output = capture_output { manager.update_package(@packages[0], status) }

    assert_includes output, "5 skip"
    assert_includes output, "?"  # Warning icon for skipped
  end

  def test_refresh_does_nothing
    manager = Ace::TestRunner::Suite::SimpleDisplayManager.new(@packages, @config)

    output = capture_output { manager.refresh }

    assert_empty output
  end

  def test_show_final_results_does_nothing
    manager = Ace::TestRunner::Suite::SimpleDisplayManager.new(@packages, @config)

    output = capture_output { manager.show_final_results }

    assert_empty output
  end

  def test_show_summary_displays_success
    manager = Ace::TestRunner::Suite::SimpleDisplayManager.new(@packages, @config)

    summary = {
      packages_passed: 2,
      packages_failed: 0,
      total_tests: 150,
      total_passed: 150,
      total_failed: 0,
      total_skipped: 0,
      total_assertions: 300,
      assertions_failed: 0,
      results: []
    }
    output = capture_output { manager.show_summary(summary) }

    assert_includes output, "ALL TESTS PASSED"
    assert_includes output, "Packages:    2 passed, 0 failed"
    assert_includes output, "Tests:       150 passed, 0 failed"
  end

  def test_show_summary_displays_failures
    manager = Ace::TestRunner::Suite::SimpleDisplayManager.new(@packages, @config)

    summary = {
      packages_passed: 1,
      packages_failed: 1,
      total_tests: 150,
      total_passed: 148,
      total_failed: 2,
      total_skipped: 0,
      total_assertions: 300,
      assertions_failed: 2,
      failed_packages: [
        {name: "ace-bundle", path: "/path/to/ace-bundle", failures: 2, errors: 0, failed_tests: []}
      ],
      results: []
    }
    output = capture_output { manager.show_summary(summary) }

    assert_includes output, "SOME TESTS FAILED"
    assert_includes output, "Packages:    1 passed, 1 failed"
    assert_includes output, "Failed packages:"
    assert_includes output, "ace-bundle"
  end

  def test_show_summary_displays_skipped
    manager = Ace::TestRunner::Suite::SimpleDisplayManager.new(@packages, @config)

    summary = {
      packages_passed: 2,
      packages_failed: 0,
      total_tests: 150,
      total_passed: 147,
      total_failed: 0,
      total_skipped: 3,
      total_assertions: 290,
      assertions_failed: 0,
      results: [
        {package: "ace-bundle", skipped: 3}
      ]
    }
    output = capture_output { manager.show_summary(summary) }

    assert_includes output, "ALL TESTS PASSED"
    assert_includes output, "Skipped:"
    assert_includes output, "ace-bundle (3)"
  end

  def test_responds_to_all_display_manager_interface_methods
    manager = Ace::TestRunner::Suite::SimpleDisplayManager.new(@packages, @config)

    assert_respond_to manager, :initialize_display
    assert_respond_to manager, :update_package
    assert_respond_to manager, :refresh
    assert_respond_to manager, :show_final_results
    assert_respond_to manager, :show_summary
    assert_respond_to manager, :packages
    assert_respond_to manager, :config
    assert_respond_to manager, :start_time
  end

  private

  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
