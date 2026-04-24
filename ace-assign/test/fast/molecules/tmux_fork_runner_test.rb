# frozen_string_literal: true

require_relative "../../test_helper"

class TmuxForkRunnerTest < AceAssignTestCase
  class FakeResult
    def initialize(stdout)
      @stdout = stdout
    end

    def stdout
      @stdout.to_s.strip
    end

    def stdout_lines
      stdout.split("\n").map(&:strip).reject(&:empty?)
    end

    def success?
      true
    end
  end

  class FakeTmuxForkRunner < Ace::Assign::Molecules::TmuxForkRunner
    attr_reader :commands

    def initialize(results: {})
      super(tmux_binary: "tmux")
      @results = results
      @commands = []
    end

    private

    def capture(cmd)
      @commands << cmd
      stdout = @results.fetch(cmd, "")
      FakeResult.new(stdout)
    end
  end

  def with_env(vars)
    original = {}
    vars.each_key do |key|
      original[key] = ENV[key]
    end
    vars.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def test_current_window_prefers_explicit_fork_window
    runner = FakeTmuxForkRunner.new

    with_env("ACE_ASSIGN_FORK_WINDOW" => "work-fs", "ACE_TMUX_SESSION" => "demo", "TMUX" => nil) do
      assert_equal "work-fs", runner.current_window
    end

    assert_equal [], runner.commands
  end

  def test_current_window_prefers_origin_pane_window
    runner = FakeTmuxForkRunner.new(
      results: {
        ["tmux", "display-message", "-t", "%42", "-p", "#S"] => "demo",
        ["tmux", "display-message", "-t", "%42", "-p", "#W"] => "ace-t-ks9"
      }
    )

    with_env("ACE_ASSIGN_FORK_WINDOW" => nil, "ACE_TMUX_SESSION" => "demo", "TMUX_PANE" => "%42", "TMUX" => nil) do
      assert_equal "ace-t-ks9", runner.current_window
    end

    assert_equal [
      ["tmux", "display-message", "-t", "%42", "-p", "#S"],
      ["tmux", "display-message", "-t", "%42", "-p", "#W"]
    ], runner.commands
  end

  def test_current_window_falls_back_when_origin_pane_session_mismatches_target_session
    runner = FakeTmuxForkRunner.new(
      results: {
        ["tmux", "display-message", "-t", "%42", "-p", "#S"] => "other",
        ["tmux", "display-message", "-t", "%42", "-p", "#W"] => "ace-t-n1d",
        ["tmux", "display-message", "-t", "demo:", "-p", "#W"] => "work"
      }
    )

    with_env("ACE_ASSIGN_FORK_WINDOW" => nil, "ACE_TMUX_SESSION" => "demo", "TMUX_PANE" => "%42", "TMUX" => nil) do
      assert_equal "work", runner.current_window
    end

    assert_equal [
      ["tmux", "display-message", "-t", "%42", "-p", "#S"],
      ["tmux", "display-message", "-t", "%42", "-p", "#W"],
      ["tmux", "display-message", "-t", "demo:", "-p", "#W"]
    ], runner.commands
  end

  def test_current_window_uses_explicit_tmux_session_without_tmux_env
    runner = FakeTmuxForkRunner.new(
      results: {["tmux", "display-message", "-t", "demo:", "-p", "#W"] => "work"}
    )

    with_env("ACE_ASSIGN_FORK_WINDOW" => nil, "ACE_TMUX_SESSION" => "demo", "TMUX_PANE" => nil, "TMUX" => nil) do
      assert_equal "work", runner.current_window
    end

    assert_equal [["tmux", "display-message", "-t", "demo:", "-p", "#W"]], runner.commands
  end

  def test_current_window_falls_back_to_active_list_windows_for_explicit_session
    runner = FakeTmuxForkRunner.new(
      results: {
        ["tmux", "display-message", "-t", "demo:", "-p", "#W"] => "",
        ["tmux", "list-windows", "-t", "demo", "-F", '#{window_active} #{window_name}'] => "1 work\n0 logs"
      }
    )

    with_env("ACE_ASSIGN_FORK_WINDOW" => nil, "ACE_TMUX_SESSION" => "demo", "TMUX_PANE" => nil, "TMUX" => nil) do
      assert_equal "work", runner.current_window
    end

    assert_equal [
      ["tmux", "display-message", "-t", "demo:", "-p", "#W"],
      ["tmux", "list-windows", "-t", "demo", "-F", '#{window_active} #{window_name}']
    ], runner.commands
  end

  def test_current_window_uses_live_tmux_when_available
    runner = FakeTmuxForkRunner.new(
      results: {["tmux", "display-message", "-p", "#W"] => "work"}
    )

    with_env("ACE_ASSIGN_FORK_WINDOW" => nil, "ACE_TMUX_SESSION" => nil, "TMUX_PANE" => nil,
      "TMUX" => "/tmp/tmux-1000/default,1,0") do
      assert_equal "work", runner.current_window
    end

    assert_equal [["tmux", "display-message", "-p", "#W"]], runner.commands
  end

  def test_result_normalizes_stdout_and_stderr_without_raising
    status = Struct.new(:success?).new(true)
    result = Ace::Assign::Molecules::TmuxForkRunner::Result.new(
      stdout: " work \n",
      stderr: " err \n",
      status: status
    )

    assert_equal "work", result.stdout
    assert_equal "err", result.stderr
    assert_equal ["work"], result.stdout_lines
    assert result.success?
  end

  def test_fork_window_name_uses_shared_tmux_safe_name
    runner = FakeTmuxForkRunner.new

    assert_equal "ace-t-k5a-fs", runner.fork_window_name("ace-t.k5a")
    assert_equal "ace-t-k5a-fs", runner.fork_window_name("ace-t.k5a-fs")
  end

  def test_ensure_window_reuses_existing_window_id
    runner = FakeTmuxForkRunner.new(
      results: {
        ["tmux", "list-windows", "-t", "demo", "-F", "#{'#{window_id}'}\t#{'#{window_name}'}"] =>
          "@7\tace-t-k5a-fs\n@8\tother"
      }
    )

    info = runner.ensure_window(session: "demo", name: "ace-t-k5a-fs", root: Dir.pwd)

    assert_equal({created: false, target: "@7", window_id: "@7", name: "ace-t-k5a-fs"}, info)
    assert_equal 1, runner.commands.length
  end

  def test_ensure_window_creates_window_and_returns_window_id
    runner = FakeTmuxForkRunner.new(
      results: {
        ["tmux", "list-windows", "-t", "demo", "-F", "#{'#{window_id}'}\t#{'#{window_name}'}"] => "",
        ["tmux", "new-window", "-d", "-t", "demo:", "-n", "ace-t-k5a-fs", "-c", File.expand_path(Dir.pwd),
          "-P", "-F", '#{window_id}'] => "@9"
      }
    )

    info = runner.ensure_window(session: "demo", name: "ace-t-k5a-fs", root: Dir.pwd)

    assert_equal({created: true, target: "@9", window_id: "@9", name: "ace-t-k5a-fs"}, info)
  end

  def test_prepare_pane_targets_window_id
    runner = FakeTmuxForkRunner.new(
      results: {
        ["tmux", "list-panes", "-t", "@9", "-F", '#{pane_id}'] => "%1"
      }
    )

    pane = runner.prepare_pane(
      session: "demo",
      window: "ace-t-k5a-fs",
      window_target: "@9",
      root: Dir.pwd,
      keep_existing: true
    )

    assert_equal "%1", pane
    assert_includes runner.commands, ["tmux", "list-panes", "-t", "@9", "-F", '#{pane_id}']
    assert_includes runner.commands, ["tmux", "select-layout", "-t", "@9", "tiled"]
  end

  def test_prepare_pane_creates_detached_split_when_adding_new_pane
    runner = FakeTmuxForkRunner.new(
      results: {
        ["tmux", "split-window", "-d", "-t", "@9", "-c", File.expand_path(Dir.pwd), "-P", "-F", '#{pane_id}'] => "%3"
      }
    )

    pane = runner.prepare_pane(
      session: "demo",
      window: "ace-t-k5a-fs",
      window_target: "@9",
      root: Dir.pwd,
      keep_existing: false
    )

    assert_equal "%3", pane
    assert_includes runner.commands,
      ["tmux", "split-window", "-d", "-t", "@9", "-c", File.expand_path(Dir.pwd), "-P", "-F", '#{pane_id}']
    assert_includes runner.commands, ["tmux", "select-layout", "-t", "@9", "tiled"]
  end

  def test_run_invocation_in_pane_builds_direct_shell_command
    runner = FakeTmuxForkRunner.new

    runner.run_invocation_in_pane(
      pane_target: "%1",
      command: ["ace-llm", "claude:sonnet", "/as-assign-drive abc123@010", "--interactive"],
      env: {
        "PROJECT_ROOT_PATH" => "/tmp/project",
        "ACE_ASSIGN_DEFAULT_TARGET" => "abc123@010",
        "ACE_ASSIGN_CURRENT_ASSIGNMENT_ID" => "abc123",
        "ACE_ASSIGN_CURRENT_FORK_ROOT" => "010",
        "CLAUDECODE" => nil
      },
      working_dir: "/tmp/project",
      visible_handoff: "$as-assign-drive abc123@010"
    )

    sent = runner.commands.last
    assert_equal ["tmux", "send-keys", "-t", "%1", sent[4], "Enter"], sent
    assert_includes sent[4], "cd /tmp/project"
    assert_includes sent[4], "printf '%s\\n' \\$as-assign-drive\\ abc123@010"
    assert_includes sent[4], "env -u CLAUDECODE PROJECT_ROOT_PATH=/tmp/project ACE_ASSIGN_DEFAULT_TARGET=abc123@010 ACE_ASSIGN_CURRENT_ASSIGNMENT_ID=abc123 ACE_ASSIGN_CURRENT_FORK_ROOT=010"
    assert_includes sent[4], "ace-llm claude:sonnet /as-assign-drive\\ abc123@010 --interactive"
  end

  def test_run_invocation_in_pane_puts_multiple_unsets_before_assignments
    runner = FakeTmuxForkRunner.new

    runner.run_invocation_in_pane(
      pane_target: "%1",
      command: ["ace-assign", "status"],
      env: {
        "KEEP" => "1",
        "DROP_ONE" => nil,
        "SET_TWO" => "2",
        "DROP_TWO" => nil
      },
      working_dir: "/tmp/project",
      visible_handoff: ""
    )

    sent = runner.commands.last
    assert_includes sent[4], "env -u DROP_ONE -u DROP_TWO KEEP=1 SET_TWO=2 ace-assign status"
  end
end
