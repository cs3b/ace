# frozen_string_literal: true

require_relative "../test_helper"

class TmuxWindowOpenerTest < AceOverseerTestCase
  class FakeWindowManager
    attr_reader :calls

    def initialize(result_name)
      @result_name = result_name
      @calls = []
    end

    def add_window(preset, session:, root:, name:)
      @calls << { preset: preset, session: session, root: root, name: name }
      @result_name
    end
  end

  def test_delegates_to_window_manager
    window_manager = FakeWindowManager.new("t230")

    opener = Ace::Overseer::Molecules::TmuxWindowOpener.new(
      window_manager: window_manager
    )

    result = opener.open(
      worktree_path: "/wt/task.230",
      window_name: "t230",
      session_name: "ace",
      preset: "cc"
    )

    assert_equal "t230", result[:window_name]
    assert_equal 1, window_manager.calls.length
    assert_equal({ preset: "cc", session: "ace", root: "/wt/task.230", name: "t230" }, window_manager.calls.first)
  end

  def test_passes_nil_session_when_not_specified
    window_manager = FakeWindowManager.new("t230")

    opener = Ace::Overseer::Molecules::TmuxWindowOpener.new(
      window_manager: window_manager
    )

    result = opener.open(
      worktree_path: "/wt/task.230",
      window_name: "t230",
      preset: "cc"
    )

    assert_equal "t230", result[:window_name]
    assert_nil window_manager.calls.first[:session]
  end
end
