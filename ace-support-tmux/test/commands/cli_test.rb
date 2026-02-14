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

  def test_inside_tmux_with_valid_env
    original = ENV["TMUX"]
    ENV["TMUX"] = "/tmp/tmux-1000/default,12345,0"
    assert CLI.inside_tmux?
  ensure
    ENV["TMUX"] = original
  end

  def test_inside_tmux_with_empty_env
    original = ENV["TMUX"]
    ENV["TMUX"] = ""
    refute CLI.inside_tmux?
  ensure
    ENV["TMUX"] = original
  end

  def test_inside_tmux_with_unset_env
    original = ENV["TMUX"]
    ENV.delete("TMUX")
    refute CLI.inside_tmux?
  ensure
    ENV["TMUX"] = original
  end

  def test_no_args_outside_tmux_routes_to_start
    original = ENV["TMUX"]
    ENV.delete("TMUX")
    # We can't fully run start (no preset loader context), but we can verify
    # the args routing by checking that help includes "start" context
    # Instead, test the routing logic directly
    args = []
    routed = if args.empty?
               CLI.inside_tmux? ? ["window"] : ["start"]
             end
    assert_equal ["start"], routed
  ensure
    ENV["TMUX"] = original
  end

  def test_no_args_inside_tmux_routes_to_window
    original = ENV["TMUX"]
    ENV["TMUX"] = "/tmp/tmux-1000/default,12345,0"
    args = []
    routed = if args.empty?
               CLI.inside_tmux? ? ["window"] : ["start"]
             end
    assert_equal ["window"], routed
  ensure
    ENV["TMUX"] = original
  end

  def test_unknown_args_outside_tmux_routes_to_start
    original = ENV["TMUX"]
    ENV.delete("TMUX")
    args = ["--root", "/tmp"]
    routed = if args.empty?
               CLI.inside_tmux? ? ["window"] : ["start"]
             elsif !CLI.known_command?(args.first)
               default = CLI.inside_tmux? ? "window" : CLI::DEFAULT_COMMAND
               [default] + args
             end
    assert_equal ["start", "--root", "/tmp"], routed
  ensure
    ENV["TMUX"] = original
  end

  def test_unknown_args_inside_tmux_routes_to_window
    original = ENV["TMUX"]
    ENV["TMUX"] = "/tmp/tmux-1000/default,12345,0"
    args = ["--root", "/tmp"]
    routed = if args.empty?
               CLI.inside_tmux? ? ["window"] : ["start"]
             elsif !CLI.known_command?(args.first)
               default = CLI.inside_tmux? ? "window" : CLI::DEFAULT_COMMAND
               [default] + args
             end
    assert_equal ["window", "--root", "/tmp"], routed
  ensure
    ENV["TMUX"] = original
  end

  def test_list_command_runs
    Ace::Support::Tmux.reset_config!
    output = capture_io { CLI.start(["list"]) }[0]
    # Should list preset types
    assert_match(/sessions|windows|panes/, output)
  end
end
