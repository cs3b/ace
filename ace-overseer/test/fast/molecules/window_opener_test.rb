# frozen_string_literal: true

require_relative "../../test_helper"

class WindowOpenerTest < AceOverseerTestCase
  class FakeRuntime
    attr_reader :calls

    def initialize
      @calls = []
    end

    def ensure_window(name:, root:, preset: nil)
      @calls << {name: name, root: root, preset: preset}
      name
    end
  end

  def test_opens_sanitized_window_rooted_at_worktree
    runtime = FakeRuntime.new
    opener = Ace::Overseer::Molecules::WindowOpener.new(runtime: runtime)

    name = opener.open(worktree_path: "/wt/ace-t.k5a")

    assert_equal "ace-t-k5a", name
    assert_equal [{name: "ace-t-k5a", root: "/wt/ace-t.k5a", preset: nil}], runtime.calls
  end

  def test_passes_window_preset_through
    runtime = FakeRuntime.new
    opener = Ace::Overseer::Molecules::WindowOpener.new(runtime: runtime)

    opener.open(worktree_path: "/wt/task.230", preset: "work-on-task")

    assert_equal "work-on-task", runtime.calls.last.fetch(:preset)
  end

  def test_expands_worktree_root
    Dir.mktmpdir("wt-x") do |worktree|
      runtime = FakeRuntime.new
      opener = Ace::Overseer::Molecules::WindowOpener.new(runtime: runtime)

      opener.open(worktree_path: worktree)

      assert_equal File.expand_path(worktree), runtime.calls.last.fetch(:root)
    end
  end

  def test_configured_runtime_is_resolved_through_contract
    Ace::Runtime.reset_registry!
    runtime = FakeRuntime.new
    Ace::Runtime.register(:faketest, -> { runtime })

    opener = Ace::Overseer::Molecules::WindowOpener.new(
      config: {"runtime" => "faketest"},
      env: {}
    )
    opener.open(worktree_path: "/wt/task.230")

    assert_equal [{name: "task-230", root: "/wt/task.230", preset: nil}], runtime.calls
  ensure
    Ace::Runtime.reset_registry!
  end

  def test_shipped_auto_default_falls_through_to_env_selection
    Ace::Runtime.reset_registry!
    runtime = FakeRuntime.new
    Ace::Runtime.register(:faketest, -> { runtime })

    opener = Ace::Overseer::Molecules::WindowOpener.new(
      config: {"runtime" => "auto"},
      env: {"ACE_RUNTIME" => "faketest"}
    )
    opener.open(worktree_path: "/wt/task.230")

    assert_equal [{name: "task-230", root: "/wt/task.230", preset: nil}], runtime.calls
  ensure
    Ace::Runtime.reset_registry!
  end

  def test_shipped_auto_default_falls_through_to_detection
    Ace::Runtime.reset_registry!
    runtime = FakeRuntime.new
    Ace::Runtime.register(:herdr, -> { runtime })

    opener = Ace::Overseer::Molecules::WindowOpener.new(
      config: {"runtime" => "auto"},
      env: {"HERDR_SESSION" => "ws-live", "HERDR_PANE" => "p1"}
    )
    opener.open(worktree_path: "/wt/task.230")

    assert_equal [{name: "task-230", root: "/wt/task.230", preset: nil}], runtime.calls
  ensure
    Ace::Runtime.reset_registry!
  end

  def test_unknown_configured_runtime_fails_closed
    Ace::Runtime.reset_registry!

    opener = Ace::Overseer::Molecules::WindowOpener.new(
      config: {"runtime" => "nosuch"},
      env: {}
    )

    error = assert_raises(Ace::Overseer::Error) do
      opener.open(worktree_path: "/wt/task.230")
    end
    assert_includes error.message, "unknown runtime 'nosuch'"
  ensure
    Ace::Runtime.reset_registry!
  end

  def test_contract_failure_surfaces_as_overseer_error
    failing = Class.new do
      def ensure_window(name:, root:, preset: nil)
        raise Ace::Runtime::RuntimeUnavailableError, "tmux runtime is unavailable"
      end
    end.new
    opener = Ace::Overseer::Molecules::WindowOpener.new(runtime: failing)

    error = assert_raises(Ace::Overseer::Error) do
      opener.open(worktree_path: "/wt/task.230")
    end
    assert_includes error.message, "Failed to open terminal window"
    assert_includes error.message, "unavailable"
  end
end
