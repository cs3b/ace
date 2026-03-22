# frozen_string_literal: true

require_relative "../test_helper"

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

  def test_delegates_to_tmux_window_command
    command = FakeTmuxWindowCommand.new

    opener = Ace::Overseer::Molecules::TmuxWindowOpener.new(
      tmux_window_command: command
    )

    opener.open(worktree_path: "/wt/task.230")

    assert_equal 1, command.calls.length
    assert_equal({ root: "/wt/task.230", preset: nil, quiet: true, session: nil }, command.calls.first)
  end

  def test_passes_ace_tmux_session_when_present
    command = FakeTmuxWindowCommand.new

    opener = Ace::Overseer::Molecules::TmuxWindowOpener.new(
      tmux_window_command: command
    )

    begin
      original_session = ENV["ACE_TMUX_SESSION"]
      ENV["ACE_TMUX_SESSION"] = "ace-e2e-test"

      opener.open(worktree_path: "/wt/task.230")
    ensure
      ENV["ACE_TMUX_SESSION"] = original_session
    end

    assert_equal 1, command.calls.length
    assert_equal({ root: "/wt/task.230", preset: nil, quiet: true, session: "ace-e2e-test" }, command.calls.first)
  end

  def test_passes_tmux_preset_to_tmux_command
    command = FakeTmuxWindowCommand.new

    opener = Ace::Overseer::Molecules::TmuxWindowOpener.new(
      tmux_window_command: command
    )

    opener.open(worktree_path: "/wt/task.230", preset: "work-on-tasks")

    assert_equal 1, command.calls.length
    assert_equal(
      { root: "/wt/task.230", preset: "work-on-tasks", quiet: true, session: nil },
      command.calls.first
    )
  end
end
