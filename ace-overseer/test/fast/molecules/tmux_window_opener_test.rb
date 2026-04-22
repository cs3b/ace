# frozen_string_literal: true

require_relative "../../test_helper"

class TmuxWindowOpenerTest < AceOverseerTestCase
  class FakeTmuxWindowCommand
    attr_reader :calls

    def initialize
      @calls = []
    end

    def call(**kwargs)
      @calls << kwargs
    end
  end

  class FakeTmuxExecutor
    attr_reader :capture_calls, :run_calls

    def initialize(has_session: true, window_list: "", create_success: true)
      @has_session = has_session
      @window_list = window_list
      @create_success = create_success
      @capture_calls = []
      @run_calls = []
    end

    Result = Struct.new(:stdout, :success) do
      def success?
        success
      end
    end

    def capture(cmd)
      @capture_calls << cmd
      case cmd[1]
      when "has-session"
        Result.new("", @has_session)
      when "list-windows"
        Result.new(@window_list, true)
      else
        Result.new("", false)
      end
    end

    def run(cmd)
      @run_calls << cmd
      @create_success
    end
  end

  def test_delegates_to_tmux_window_command
    command = FakeTmuxWindowCommand.new

    opener = Ace::Overseer::Molecules::TmuxWindowOpener.new(
      tmux_window_command: command,
      tmux_executor: FakeTmuxExecutor.new
    )

    opener.open(worktree_path: "/wt/task.230")

    assert_equal 1, command.calls.length
    assert_equal({root: "/wt/task.230", preset: nil, quiet: true, session: nil}, command.calls.first)
  end

  def test_passes_ace_tmux_session_when_present
    command = FakeTmuxWindowCommand.new

    opener = Ace::Overseer::Molecules::TmuxWindowOpener.new(
      tmux_window_command: command,
      tmux_executor: FakeTmuxExecutor.new
    )

    begin
      original_session = ENV["ACE_TMUX_SESSION"]
      ENV["ACE_TMUX_SESSION"] = "ace-e2e-test"

      opener.open(worktree_path: "/wt/task.230")
    ensure
      ENV["ACE_TMUX_SESSION"] = original_session
    end

    assert_equal 1, command.calls.length
    assert_equal({root: "/wt/task.230", preset: nil, quiet: true, session: "ace-e2e-test"}, command.calls.first)
  end

  def test_passes_tmux_preset_to_tmux_command
    command = FakeTmuxWindowCommand.new

    opener = Ace::Overseer::Molecules::TmuxWindowOpener.new(
      tmux_window_command: command,
      tmux_executor: FakeTmuxExecutor.new
    )

    opener.open(worktree_path: "/wt/task.230", preset: "work-on-task")

    assert_equal 1, command.calls.length
    assert_equal(
      {root: "/wt/task.230", preset: "work-on-task", quiet: true, session: nil},
      command.calls.first
    )
  end

  def test_creates_missing_tmux_session_before_opening_window
    command = FakeTmuxWindowCommand.new
    executor = FakeTmuxExecutor.new(has_session: false)

    opener = Ace::Overseer::Molecules::TmuxWindowOpener.new(
      tmux_window_command: command,
      tmux_executor: executor
    )

    original_session = ENV["ACE_TMUX_SESSION"]
    ENV["ACE_TMUX_SESSION"] = "ace-e2e-test"
    opener.open(worktree_path: "/wt/task.230")

    assert_equal [["tmux", "new-session", "-d", "-s", "ace-e2e-test"]], executor.run_calls
    assert_equal 1, command.calls.length
  ensure
    ENV["ACE_TMUX_SESSION"] = original_session
  end

  def test_reuses_existing_sanitized_tmux_window_name
    command = FakeTmuxWindowCommand.new
    executor = FakeTmuxExecutor.new(window_list: "ace-t-k5a\nother\n")

    opener = Ace::Overseer::Molecules::TmuxWindowOpener.new(
      tmux_window_command: command,
      tmux_executor: executor
    )

    original_session = ENV["ACE_TMUX_SESSION"]
    ENV["ACE_TMUX_SESSION"] = "ace-e2e-test"
    opener.open(worktree_path: "/wt/ace-t.k5a")

    assert_empty command.calls
  ensure
    ENV["ACE_TMUX_SESSION"] = original_session
  end
end
