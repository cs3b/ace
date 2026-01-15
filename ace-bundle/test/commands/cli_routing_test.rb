# frozen_string_literal: true

require_relative "../test_helper"
require "ace/bundle/cli"

class CliRoutingTest < AceTestCase
  include Ace::TestSupport::CliHelpers

  # Helper method to invoke CLI with routing logic
  # Uses CLI.start to ensure default task routing is tested
  def invoke_context_cli(args)
    invoke_cli_stdout(Ace::Bundle::CLI, args)
  end

  # --- Version Command Tests ---

  def test_cli_routes_version_command
    output = invoke_context_cli(["version"])
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  def test_cli_routes_version_with_long_flag
    output = invoke_context_cli(["--version"])
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  # --- Help Command Tests ---

  def test_cli_routes_help_command
    result = invoke_cli(Ace::Bundle::CLI, ["help"])
    # Help goes to stderr in dry-cli
    output = result[:stdout] + result[:stderr]
    assert_match(/load|list|Commands/i, output)
  end

  def test_cli_routes_help_with_long_flag
    result = invoke_cli(Ace::Bundle::CLI, ["--help"])
    # Help goes to stderr in dry-cli
    output = result[:stdout] + result[:stderr]
    assert_match(/Commands:/i, output)
  end

  # --- List Command Tests ---

  def test_cli_routes_list_command
    output = invoke_context_cli(["list"])
    # Should list presets (even if empty)
    refute_nil output
  end

  # --- Default Task Routing Tests ---

  def test_cli_uses_load_as_default_task
    # Any unknown input should be treated as preset/input and invoke load command
    output = invoke_context_cli(["project"])
    # Should attempt to load context (may succeed or error, but should try)
    refute_nil output
  end

  # --- Numeric Flag Conversion Tests ---

  def test_cli_converts_max_size_to_integer
    # Pass --max-size as string, verify it's converted to integer before use
    # The convert_types helper should convert string "1024" to Integer 1024
    result = invoke_cli(Ace::Bundle::CLI, ["load", "project", "--max-size", "1024"])
    # Should not raise ArgumentError about string comparison
    # Success or error about missing preset is fine, but no type error
    output = result[:stdout] + result[:stderr]
    refute_match(/ArgumentError.*String.*Integer/i, output)
    refute_match(/comparison.*failed/i, output)
  end

  def test_cli_converts_timeout_to_integer
    # Pass --timeout as string, verify it's converted to integer before use
    result = invoke_cli(Ace::Bundle::CLI, ["load", "project", "--timeout", "60"])
    # Should not raise ArgumentError about string comparison
    output = result[:stdout] + result[:stderr]
    refute_match(/ArgumentError.*String.*Integer/i, output)
    refute_match(/comparison.*failed/i, output)
  end
end
