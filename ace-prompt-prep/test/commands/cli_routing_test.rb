# frozen_string_literal: true

require_relative "../test_helper"
require "ace/prompt_prep/cli"
require "ace/support/cli"

class PromptCliRoutingTest < Minitest::Test
  # Helper to invoke CLI using the CLI runner pattern
  def invoke_cli(args)
    stdout, stderr = capture_io do
      begin
        @_cli_result = Ace::Support::Cli::Runner.new(Ace::PromptPrep::CLI).call(args: args)
      rescue SystemExit => e
        @_cli_result = e.status
      rescue Ace::Core::CLI::Error => e
        @_cli_result = e.exit_code
        $stderr.puts e.message
      end
    end

    {
      stdout: stdout,
      stderr: stderr,
      result: @_cli_result
    }
  end

  # Helper for stdout output only
  def invoke_cli_stdout(args)
    invoke_cli(args)[:stdout]
  end

  # Mock result for PromptProcessor - avoids filesystem/git dependencies
  def mock_processor_result
    { success: true, content: "mocked content", archive_path: "/tmp/archive.md" }
  end

  # Helper to invoke CLI with stubbed PromptProcessor
  def invoke_cli_with_stub(args)
    Ace::PromptPrep::Organisms::PromptProcessor.stub(:call, ->(*) { mock_processor_result }) do
      invoke_cli(args)
    end
  end

  # --- Version Command Tests ---

  def test_cli_routes_version_command
    output = invoke_cli_stdout(["version"])
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  def test_cli_routes_version_with_long_flag
    output = invoke_cli_stdout(["--version"])
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  # --- Help Command Tests ---

  def test_cli_routes_help_command
    result = invoke_cli(["help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:/i, output)
  end

  def test_cli_routes_help_with_long_flag
    result = invoke_cli(["--help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:/i, output)
  end

  def test_cli_routes_help_with_short_flag
    result = invoke_cli(["-h"])
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:/i, output)
  end

  # --- Process Command Tests ---

  def test_cli_process_command_with_flags
    # Flags must be passed with explicit process command
    result = invoke_cli_with_stub(["process", "--enhance"])
    output = result[:stdout] + result[:stderr]

    # Should process the flag without error
    refute_match(/unknown command/i, output)
  end

  def test_cli_process_command_with_task_flag
    # Task flag requires explicit process command
    result = invoke_cli_with_stub(["process", "--task", "123"])
    output = result[:stdout] + result[:stderr]

    # Should process the task flag
    refute_match(/unknown command/i, output)
  end

  def test_cli_help_shows_custom_format
    # --help shows our custom formatted help
    result = invoke_cli(["--help"])
    output = result[:stdout] + result[:stderr]

    # Should show our custom help format with Commands: header
    assert_match(/COMMANDS|Commands:/i, output)
  end

  def test_cli_known_command_routes_directly
    # Known commands should route directly
    result = invoke_cli(["process", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show process command help
    assert_match(/process|Usage/i, output)
  end

  def test_cli_setup_command_routes_directly
    # Setup command should route directly
    result = invoke_cli(["setup", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show setup command help
    assert_match(/setup|Usage/i, output)
  end

  def test_cli_builtin_flags_show_help
    # Built-in flags like --help should show root help
    result = invoke_cli(["--help"])
    output = result[:stdout] + result[:stderr]

    # Should show root help with Commands list
    assert_match(/COMMANDS|Commands:/i, output)
  end
end
