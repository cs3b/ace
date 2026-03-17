# frozen_string_literal: true

require_relative "../test_helper"

class CliTest < Minitest::Test
  CLI = Ace::Tmux::CLI

  def test_program_name
    assert_equal "ace-tmux", CLI::PROGRAM_NAME
  end

  def test_registered_commands_has_descriptions
    commands = CLI::REGISTERED_COMMANDS
    assert commands.is_a?(Array)
    assert commands.any? { |cmd, _| cmd == "start" }
    assert commands.any? { |cmd, _| cmd == "window" }
    assert commands.any? { |cmd, _| cmd == "list" }
  end

  def test_help_examples_defined
    examples = CLI::HELP_EXAMPLES
    assert examples.is_a?(Array)
    assert examples.any? { |ex| ex.include?("start") }
    assert examples.any? { |ex| ex.include?("window") }
    assert examples.any? { |ex| ex.include?("list") }
  end

  def test_help_output
    output = capture_io { CLI.start(["--help"]) }[0]
    assert_match(/start/, output)
    assert_match(/window/, output)
    assert_match(/list/, output)
    assert_match(/EXAMPLES|Examples:/, output)
  end

  def test_h_flag_shows_help
    output = capture_io { CLI.start(["-h"]) }[0]
    assert_match(/start/, output)
    assert_match(/window/, output)
    assert_match(/list/, output)
  end

  def test_help_command_shows_help
    output = capture_io { CLI.start(["help"]) }[0]
    assert_match(/start/, output)
    assert_match(/window/, output)
    assert_match(/list/, output)
  end

  def test_version_output
    output = capture_io { CLI.start(["version"]) }[0]
    assert_match(/ace-tmux/, output)
    assert_match(/#{Ace::Tmux::VERSION}/, output)
  end

  def test_version_flag_output
    output = capture_io { CLI.start(["--version"]) }[0]
    assert_match(/ace-tmux/, output)
    assert_match(/#{Ace::Tmux::VERSION}/, output)
  end

  def test_list_command_runs
    Ace::Tmux.reset_config!
    output = capture_io { CLI.start(["list"]) }[0]
    # Should list preset types
    assert_match(/sessions|windows|panes/, output)
  end

  def test_start_command_registered
    # Verify start command is registered (without executing it)
    assert CLI::REGISTERED_COMMANDS.any? { |cmd, _| cmd == "start" }
  end
end
