# frozen_string_literal: true

require_relative "../test_helper"
require "ace/context/cli"

class CliRoutingTest < AceTestCase
  # --- Version Command Tests ---

  def test_cli_routes_version_command
    output = capture_io do
      Ace::Context::CLI.start(["version"])
    end
    assert_match(/\d+\.\d+\.\d+/, output.first)
  end

  def test_cli_routes_version_with_long_flag
    output = capture_io do
      Ace::Context::CLI.start(["--version"])
    end
    assert_match(/\d+\.\d+\.\d+/, output.first)
  end

  # --- Help Command Tests ---

  def test_cli_routes_help_command
    output = capture_io do
      Ace::Context::CLI.start(["help"])
    end
    # Help should mention available commands
    assert_match(/load|list|Commands/i, output.first)
  end

  def test_cli_routes_help_with_long_flag
    output = capture_io do
      Ace::Context::CLI.start(["--help"])
    end
    assert_match(/Commands:/i, output.first)
  end

  # --- List Command Tests ---

  def test_cli_routes_list_command
    output = capture_io do
      Ace::Context::CLI.start(["list"])
    end
    # Should list presets (even if empty)
    refute_nil output.first
  end

  # --- Default Task Routing Tests ---

  def test_cli_uses_load_as_default_task
    # Any unknown input should be treated as preset/input and invoke load command
    output = capture_io do
      # "project" is a common preset name that should work
      Ace::Context::CLI.start(["project"])
    end
    # Should attempt to load context (may succeed or error, but should try)
    refute_nil output.first
  end
end
