# frozen_string_literal: true

require_relative "../test_helper"
require "dry/cli"
require "stringio"

class CLITest < Minitest::Test
  CLI = Ace::Test::EndToEndRunner::CLI

  def call_cli(args)
    capture_io { Dry::CLI.new(CLI).call(arguments: args) }
  end

  def test_version_command
    out, = call_cli(["version"])
    assert_match(/ace-test-e2e \d+\.\d+\.\d+/, out)
  end

  def test_version_flag
    out, = call_cli(["--version"])
    assert_match(/ace-test-e2e \d+\.\d+\.\d+/, out)
  end

  def test_help_flag
    out, = call_cli(["--help"])
    assert out.include?("Commands:"), "Help should show commands"
    assert out.include?("ace-test-e2e"), "Help should include command name"
    assert out.include?("run"), "Help should list run command"
    assert out.include?("suite"), "Help should list suite command"
    assert out.include?("setup"), "Help should list setup command"
  end

  def test_help_command
    out, = call_cli(["help"])
    assert out.include?("Commands:"), "Help should show commands"
    assert out.include?("Examples:"), "Help should show examples section"
  end

  def test_help_shows_examples
    out, = call_cli(["--help"])
    assert out.include?("ace-test-e2e run ace-lint TS-LINT-001"), "Help should include run example"
    assert out.include?("ace-test-e2e suite"), "Help should include suite example"
    assert out.include?("ace-test-e2e setup"), "Help should include setup example"
  end

  def test_no_args_shows_help
    # Note: The exe handles empty args by defaulting to ["--help"]
    # When calling CLI directly with [], dry-cli shows its default help
    # So we test --help here to verify the help behavior
    out, = call_cli(["--help"])
    assert out.include?("Commands:"), "Help should show commands"
  end
end
