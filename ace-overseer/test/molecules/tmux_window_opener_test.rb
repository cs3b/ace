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
    assert_equal({ root: "/wt/task.230", quiet: true }, command.calls.first)
  end
end
