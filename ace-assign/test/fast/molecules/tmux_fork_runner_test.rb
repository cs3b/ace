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

  def test_current_window_uses_explicit_tmux_session_without_tmux_env
    runner = FakeTmuxForkRunner.new(
      results: {["tmux", "display-message", "-t", "demo:", "-p", "#W"] => "work"}
    )

    with_env("ACE_ASSIGN_FORK_WINDOW" => nil, "ACE_TMUX_SESSION" => "demo", "TMUX" => nil) do
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

    with_env("ACE_ASSIGN_FORK_WINDOW" => nil, "ACE_TMUX_SESSION" => "demo", "TMUX" => nil) do
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

    with_env("ACE_ASSIGN_FORK_WINDOW" => nil, "ACE_TMUX_SESSION" => nil, "TMUX" => "/tmp/tmux-1000/default,1,0") do
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
end
