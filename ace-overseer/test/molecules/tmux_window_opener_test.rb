# frozen_string_literal: true

require_relative "../test_helper"

class TmuxWindowOpenerTest < AceOverseerTestCase
  Result = Struct.new(:ok, :stdout) do
    def success?
      ok
    end
  end

  class FakeExecutor
    attr_reader :capture_calls, :run_calls

    def initialize(capture_results:, run_success: true)
      @capture_results = capture_results.dup
      @run_success = run_success
      @capture_calls = []
      @run_calls = []
    end

    def capture(cmd)
      @capture_calls << cmd
      @capture_results.shift || Result.new(false, "")
    end

    def run(cmd)
      @run_calls << cmd
      @run_success
    end
  end

  class FakeSessionManager
    attr_reader :start_calls

    def initialize
      @start_calls = []
    end

    def start(*args, **kwargs)
      @start_calls << [args, kwargs]
    end
  end

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

  def test_creates_non_default_session_with_tmux_command
    executor = FakeExecutor.new(
      capture_results: [
        Result.new(false, ""), # has-session
        Result.new(false, "")  # list-windows
      ],
      run_success: true
    )
    session_manager = FakeSessionManager.new
    window_manager = FakeWindowManager.new("t230")

    opener = Ace::Overseer::Molecules::TmuxWindowOpener.new(
      executor: executor,
      session_manager: session_manager,
      window_manager: window_manager
    )

    result = opener.open(
      worktree_path: "/wt/task.230",
      window_name: "t230",
      session_name: "ace",
      preset: "cc"
    )

    assert_equal "t230", result[:window_name]
    assert_equal false, result[:reused]
    assert_equal 1, executor.run_calls.length
    assert_equal [], session_manager.start_calls
    assert_equal "ace", window_manager.calls.first[:session]
  end

  def test_bootstraps_default_session_via_session_manager
    executor = FakeExecutor.new(
      capture_results: [
        Result.new(false, ""), # has-session
        Result.new(false, "")  # list-windows
      ],
      run_success: true
    )
    session_manager = FakeSessionManager.new
    window_manager = FakeWindowManager.new("task230")

    opener = Ace::Overseer::Molecules::TmuxWindowOpener.new(
      executor: executor,
      session_manager: session_manager,
      window_manager: window_manager
    )

    opener.open(
      worktree_path: "/wt/task.230",
      window_name: "task230",
      session_name: "default",
      preset: "cc"
    )

    assert_equal 1, session_manager.start_calls.length
    assert_equal [], executor.run_calls
  end

  def test_reuses_existing_window_without_creating_duplicate
    executor = FakeExecutor.new(
      capture_results: [
        Result.new(true, ""),                    # has-session
        Result.new(true, "t230\nanother-window") # list-windows
      ],
      run_success: true
    )
    session_manager = FakeSessionManager.new
    window_manager = FakeWindowManager.new("t230")

    opener = Ace::Overseer::Molecules::TmuxWindowOpener.new(
      executor: executor,
      session_manager: session_manager,
      window_manager: window_manager
    )

    result = opener.open(
      worktree_path: "/wt/task.230",
      window_name: "t230",
      session_name: "ace",
      preset: "cc"
    )

    assert_equal "t230", result[:window_name]
    assert_equal true, result[:reused]
    assert_empty window_manager.calls
    assert_empty executor.run_calls
  end
end
