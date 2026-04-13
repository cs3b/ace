# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/support/cli"

class CliTest < AceOverseerTestCase
  # Helper to invoke CLI using the CLI runner pattern
  def invoke_cli(args)
    stdout, stderr = capture_io do
      @_cli_result = Ace::Support::Cli::Runner.new(Ace::Overseer::CLI).call(args: args)
    rescue SystemExit => e
      @_cli_result = e.status
    rescue Ace::Support::Cli::Error => e
      warn e.message
      @_cli_result = e.exit_code
    end

    {
      stdout: stdout,
      stderr: stderr,
      result: @_cli_result
    }
  end

  def test_help_lists_registered_commands
    result = invoke_cli(["--help"])
    output = result[:stdout] + result[:stderr]

    assert_includes output, "work-on"
    assert_includes output, "status"
    assert_includes output, "prune"
  end

  def test_help_with_short_flag
    result = invoke_cli(["-h"])
    output = result[:stdout] + result[:stderr]

    assert_includes output, "work-on"
    assert_includes output, "status"
    assert_includes output, "prune"
  end

  def test_version_command_prints_version
    result = invoke_cli(["version"])
    output = result[:stdout] + result[:stderr]

    assert_includes output, "ace-overseer"
    assert_includes output, Ace::Overseer::VERSION
  end

  def test_version_with_long_flag
    result = invoke_cli(["--version"])
    output = result[:stdout] + result[:stderr]

    assert_includes output, "ace-overseer"
    assert_includes output, Ace::Overseer::VERSION
  end

  def test_help_shows_examples
    result = invoke_cli(["--help"])
    output = result[:stdout] + result[:stderr]

    assert_includes output, "ace-overseer work-on"
    assert_includes output, "ace-overseer status"
    assert_includes output, "ace-overseer prune"
  end
end
