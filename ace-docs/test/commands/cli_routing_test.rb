# frozen_string_literal: true

require_relative "../test_helper"
require "ace/docs/cli"
require "ace/test_support/cli_helpers"

class DocsCliRoutingTest < Minitest::Test
  include Ace::TestSupport::CliHelpers

  # --- Version Command Tests ---

  def test_cli_routes_version_command
    output = invoke_cli_stdout(Ace::Docs::CLI, ["version"])
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  def test_cli_routes_version_with_long_flag
    output = invoke_cli_stdout(Ace::Docs::CLI, ["--version"])
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  # --- Help Command Tests ---

  def test_cli_routes_help_command
    result = invoke_cli(Ace::Docs::CLI, ["help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:/i, output)
  end

  def test_cli_routes_help_with_long_flag
    result = invoke_cli(Ace::Docs::CLI, ["--help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:/i, output)
  end

  def test_cli_routes_help_with_short_flag
    result = invoke_cli(Ace::Docs::CLI, ["-h"])
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:/i, output)
  end

  # --- Default Task Routing Tests ---
  # Critical regression tests for Task 200 fix

  def test_cli_routes_unknown_flag_to_default_command
    # Flags like --format should route to the default 'status' command
    # Previously, the hyphen check would reject flags as unknown commands
    result = invoke_cli(Ace::Docs::CLI, ["--format", "json"])
    output = result[:stdout] + result[:stderr]

    # Should either process the flag or show status command help
    # Not reject as "unknown command"
    refute_match(/unknown command/i, output)
  end

  def test_cli_routes_multiple_flags_to_default_command
    # Multiple flags should all route to the default command
    result = invoke_cli(Ace::Docs::CLI, ["--needs-update", "--quiet"])
    output = result[:stdout] + result[:stderr]

    # Should process flags, not reject them
    refute_match(/unknown command/i, output)
  end

  def test_cli_empty_args_routes_to_default_command
    # Empty args should invoke the default command
    result = invoke_cli(Ace::Docs::CLI, [])
    output = result[:stdout] + result[:stderr]

    # Should show status output or status help
    refute_nil output
    refute_match(/unknown command/i, output)
  end

  def test_cli_known_command_routes_directly
    # Known commands should route directly, not get default prepended
    result = invoke_cli(Ace::Docs::CLI, ["status", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show status command help
    assert_match(/status|Usage/i, output)
  end

  def test_cli_builtin_flags_not_routed_to_default
    # Built-in flags like --help should NOT route to default command
    # They should be handled directly by dry-cli
    result = invoke_cli(Ace::Docs::CLI, ["--help"])
    output = result[:stdout] + result[:stderr]

    # Should show root help, not default command help
    assert_match(/COMMANDS|Commands:/i, output)
  end
end
