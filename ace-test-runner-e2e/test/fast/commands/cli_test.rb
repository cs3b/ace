# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/support/cli"
require "stringio"

class CLITest < Minitest::Test
  RunTest = Ace::Test::EndToEndRunner::CLI::Commands::RunTest

  def call_cli(args)
    out = StringIO.new
    err = StringIO.new
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = out
    $stderr = err
    begin
      Ace::Support::Cli::Runner.new(RunTest).call(args: args)
    rescue SystemExit
      # ace-support-cli single-command --help calls exit(0)
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end
    [out.string, err.string]
  end

  def test_help_flag
    out, = call_cli(["--help"])
    assert out.include?("Run E2E tests via LLM execution"), "Help should show RunTest description"
    assert out.include?("PACKAGE"), "Help should show package argument"
  end

  def test_help_shows_examples
    out, = call_cli(["--help"])
    assert out.include?("ace-lint TS-LINT-001"), "Help should include run example"
  end

  def test_no_subcommand_list
    out, = call_cli(["--help"])
    refute out.include?("Commands:"), "Single-command CLI should not show subcommand list"
    refute out.include?("suite"), "Single-command CLI should not mention suite"
    refute out.include?("setup"), "Single-command CLI should not mention setup"
  end
end
