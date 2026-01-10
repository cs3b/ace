# frozen_string_literal: true

require_relative "../test_helper"
require "ace/prompt/cli"
require "ace/test_support/cli_helpers"

class PromptCliRoutingTest < Minitest::Test
  include Ace::TestSupport::CliHelpers

  # Mock result for PromptProcessor - avoids filesystem/git dependencies
  def mock_processor_result
    { success: true, content: "mocked content", archive_path: "/tmp/archive.md" }
  end

  # Helper to invoke CLI with stubbed PromptProcessor
  def invoke_cli_with_stub(args)
    Ace::Prompt::Organisms::PromptProcessor.stub(:call, ->(*) { mock_processor_result }) do
      invoke_cli(Ace::Prompt::CLI, args)
    end
  end

  # --- Version Command Tests ---

  def test_cli_routes_version_command
    output = invoke_cli_stdout(Ace::Prompt::CLI, ["version"])
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  def test_cli_routes_version_with_long_flag
    output = invoke_cli_stdout(Ace::Prompt::CLI, ["--version"])
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  # --- Help Command Tests ---

  def test_cli_routes_help_command
    result = invoke_cli(Ace::Prompt::CLI, ["help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/Commands:/i, output)
  end

  def test_cli_routes_help_with_long_flag
    result = invoke_cli(Ace::Prompt::CLI, ["--help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/Commands:/i, output)
  end

  def test_cli_routes_help_with_short_flag
    result = invoke_cli(Ace::Prompt::CLI, ["-h"])
    output = result[:stdout] + result[:stderr]
    assert_match(/Commands:/i, output)
  end

  # --- Default Task Routing Tests ---
  # Critical regression tests for Task 200 fix
  # Uses stubbed PromptProcessor to avoid filesystem/git dependencies

  def test_cli_routes_unknown_flag_to_default_command
    # Flags like --enhance should route to the default 'process' command
    # Previously, the hyphen check would reject flags as unknown commands
    result = invoke_cli_with_stub(["--enhance"])
    output = result[:stdout] + result[:stderr]

    # Should either process the flag or show process command help
    # Not reject as "unknown command"
    refute_match(/unknown command/i, output)
  end

  def test_cli_routes_context_flag_to_default_command
    # The --context flag should route to default command
    result = invoke_cli_with_stub(["--context"])
    output = result[:stdout] + result[:stderr]

    # Should process flags, not reject them
    refute_match(/unknown command/i, output)
  end

  def test_cli_routes_task_flag_to_default_command
    # The --task flag should route to default command
    result = invoke_cli_with_stub(["--task", "123"])
    output = result[:stdout] + result[:stderr]

    # Should process the task flag
    refute_match(/unknown command/i, output)
  end

  def test_cli_routes_multiple_flags_to_default_command
    # Multiple flags should all route to the default command
    result = invoke_cli_with_stub(["--enhance", "--context", "--output", "stdio"])
    output = result[:stdout] + result[:stderr]

    # Should process flags, not reject them
    refute_match(/unknown command/i, output)
  end

  def test_cli_empty_args_routes_to_default_command
    # Empty args should invoke the default command
    result = invoke_cli_with_stub([])
    output = result[:stdout] + result[:stderr]

    # Should attempt to run process, not show "unknown command"
    refute_match(/unknown command/i, output)
  end

  def test_cli_known_command_routes_directly
    # Known commands should route directly
    result = invoke_cli(Ace::Prompt::CLI, ["process", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show process command help
    assert_match(/process|Usage/i, output)
  end

  def test_cli_setup_command_routes_directly
    # Setup command should route directly, not get default prepended
    result = invoke_cli(Ace::Prompt::CLI, ["setup", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show setup command help
    assert_match(/setup|Usage/i, output)
  end

  def test_cli_builtin_flags_not_routed_to_default
    # Built-in flags like --help should NOT route to default command
    result = invoke_cli(Ace::Prompt::CLI, ["--help"])
    output = result[:stdout] + result[:stderr]

    # Should show root help with Commands list
    assert_match(/Commands:/i, output)
  end
end
