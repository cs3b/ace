# frozen_string_literal: true

require_relative "../test_helper"

class CliTest < Minitest::Test
  CLI = Ace::Support::Tmux::CLI

  def test_known_commands_includes_registered
    %w[start window list].each do |cmd|
      assert CLI::KNOWN_COMMANDS.include?(cmd), "Expected #{cmd} to be known"
    end
  end

  def test_known_commands_includes_builtins
    %w[version help --help -h --version].each do |cmd|
      assert CLI::KNOWN_COMMANDS.include?(cmd), "Expected #{cmd} to be known"
    end
  end

  def test_default_command_is_start
    assert_equal "start", CLI::DEFAULT_COMMAND
  end

  def test_known_command_returns_true_for_known
    assert CLI.known_command?("start")
    assert CLI.known_command?("window")
    assert CLI.known_command?("list")
    assert CLI.known_command?("version")
  end

  def test_known_command_returns_false_for_unknown
    refute CLI.known_command?("dev")
    refute CLI.known_command?("my-session")
    refute CLI.known_command?(nil)
  end

  def test_help_output
    output = capture_io { CLI.start(["--help"]) }[0]
    assert_match(/start/, output)
    assert_match(/window/, output)
    assert_match(/list/, output)
  end

  def test_version_output
    output = capture_io { CLI.start(["version"]) }[0]
    assert_match(/ace-support-tmux/, output)
    assert_match(/#{Ace::Support::Tmux::VERSION}/, output)
  end

  def test_list_command_runs
    Ace::Support::Tmux.reset_config!
    output = capture_io { CLI.start(["list"]) }[0]
    # Should list preset types
    assert_match(/sessions|windows|panes/, output)
  end
end
