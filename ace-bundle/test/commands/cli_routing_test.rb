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
end
