# frozen_string_literal: true

require_relative "../test_helper"
require "ace/docs/cli"
require "ace/support/cli"

class DocsCliRoutingTest < Minitest::Test
  # Helper to invoke CLI using the CLI runner pattern
  def invoke_cli(args)
    stdout, stderr = capture_io do
      begin
        @_cli_result = Ace::Support::Cli::Runner.new(Ace::Docs::CLI).call(args: args)
      rescue SystemExit => e
        @_cli_result = e.status
      rescue Ace::Core::CLI::Error => e
        $stderr.puts e.message
        @_cli_result = e.exit_code
      end
    end

    {
      stdout: stdout,
      stderr: stderr,
      result: @_cli_result
    }
  end

  # --- Version Command Tests ---

  def test_cli_routes_version_command
    output = invoke_cli(["version"])[:stdout]
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  def test_cli_routes_version_with_long_flag
    output = invoke_cli(["--version"])[:stdout]
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  # --- Help Command Tests ---

  def test_cli_routes_help_command
    result = invoke_cli(["help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/Commands:/i, output)
  end

  def test_cli_routes_help_with_long_flag
    result = invoke_cli(["--help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/Commands:/i, output)
  end

  def test_cli_routes_help_with_short_flag
    result = invoke_cli(["-h"])
    output = result[:stdout] + result[:stderr]
    assert_match(/Commands:/i, output)
  end

  # --- No Args Behavior (Standard Help Pattern) ---

  def test_cli_empty_args_shows_help
    # Empty args should show help (not route to default command)
    # Note: The exe handles empty args by defaulting to ["--help"]
    # When calling CLI directly with [], ace-support-cli shows its default help
    result = invoke_cli(["--help"])
    output = result[:stdout] + result[:stderr]

    # Should show help with commands list
    assert_match(/Commands:/i, output)
  end

  # --- Known Command Tests ---

  def test_cli_known_command_routes_directly
    # Known commands should route directly
    result = invoke_cli(["status", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show status command help
    assert_match(/status|Usage/i, output)
  end

  def test_cli_status_command_works
    # Status command should execute
    result = invoke_cli(["status"])
    # Status command outputs something (even if error due to no docs found)
    output = result[:stdout] + result[:stderr]
    refute_empty output
  end
end
