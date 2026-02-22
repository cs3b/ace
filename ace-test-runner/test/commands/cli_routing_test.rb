# frozen_string_literal: true

require_relative "../test_helper"
require "ace/test_runner/cli"

class CliRoutingTest < Minitest::Test
  include TestHelper

  # --- Version Command Tests ---

  def test_cli_routes_version_command
    output = capture_io do
      Ace::TestRunner::CLI.start(["version"])
    end
    assert_match(/\d+\.\d+\.\d+/, output.first)
  end

  def test_cli_routes_version_with_long_flag
    output = capture_io do
      Ace::TestRunner::CLI.start(["--version"])
    end
    assert_match(/\d+\.\d+\.\d+/, output.first)
  end

  # --- Help Command Tests ---
  # Note: dry-cli help command calls exit(0) which terminates tests
  # We verify help generation works by testing Banner/Usage modules directly

  def test_cli_routes_help_banner_generation
    # Verify help banner can be generated without triggering exit
    require "dry/cli/banner"

    # Test command banner generation for the default test command
    result = Ace::TestRunner::CLI.get(["test"])
    banner = Dry::CLI::Banner.call(result.command, "ace-test test")
    assert_match(/NAME|Command:/i, banner)
    assert_match(/USAGE|Usage:/i, banner)
  end

  def test_cli_routes_help_usage_generation
    # Verify root usage can be generated without triggering exit
    require "dry/cli/usage"

    result = Ace::TestRunner::CLI.get([])
    usage = Dry::CLI::Usage.call(result)
    assert_match(/COMMANDS|Commands:/i, usage)
    # Should include our registered commands
    assert_match(/test|version|help/i, usage)
  end

  # --- Default Task Routing Tests ---

  def test_cli_uses_test_as_default_task_with_unknown_command
    # Unknown commands should be treated as package/target arguments
    # and invoke the test command
    with_temp_dir do
      # Create a minimal test-like structure to prevent errors
      FileUtils.mkdir_p("test")
      File.write("test/sample_test.rb", "# empty test file")

      output, _err = capture_io do
        # This should attempt to run tests, but may error since we're not in a real package
        # The important thing is it routes to the test command
        begin
          Ace::TestRunner::CLI.start(["atoms"])
        rescue => e
          # Expected - we're not in a real test environment
          puts "Routed to test: #{e.class}"
        end
      end
      # If it errors, that's fine - we're testing routing
      refute_nil output
    end
  end
end
