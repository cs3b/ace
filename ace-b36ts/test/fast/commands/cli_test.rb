# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/support/cli"

class CliTest < AceB36tsTestCase
  # Helper to invoke CLI using the CLI runner pattern
  def invoke_cli(args)
    stdout, stderr = capture_io do
      @_cli_result = Ace::Support::Cli::Runner.new(Ace::B36ts::CLI).call(args: args)
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

    assert_includes output, "encode"
    assert_includes output, "decode"
    assert_includes output, "config"
  end

  def test_help_with_short_flag
    result = invoke_cli(["-h"])
    output = result[:stdout] + result[:stderr]

    assert_includes output, "encode"
    assert_includes output, "decode"
    assert_includes output, "config"
  end

  def test_version_command_prints_version
    result = invoke_cli(["version"])
    output = result[:stdout] + result[:stderr]

    assert_includes output, "ace-b36ts"
    assert_includes output, Ace::B36ts::VERSION
  end

  def test_version_with_long_flag
    result = invoke_cli(["--version"])
    output = result[:stdout] + result[:stderr]

    assert_includes output, "ace-b36ts"
    assert_includes output, Ace::B36ts::VERSION
  end

  def test_help_shows_examples
    result = invoke_cli(["--help"])
    output = result[:stdout] + result[:stderr]

    assert_includes output, "ace-b36ts encode"
    assert_includes output, "ace-b36ts decode"
  end

  def test_empty_args_shows_help
    result = invoke_cli(["--help"])
    output = result[:stdout] + result[:stderr]

    assert_includes output, "encode"
    assert_includes output, "decode"
  end
end
