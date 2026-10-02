# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/runtime/testing"

class TmuxRuntimeAdapterContractTest < Minitest::Test
  include Ace::Runtime::Testing::AdapterContract
  include Ace::Runtime::Testing::AdapterContract::PlainPaneSendMatrix

  # Bridges the shared scripted terminal to the same primitive operations
  # the production backend exposes. Adapter orchestration remains identical.
  class ScriptedBackend
    def initialize(fixture)
      @fixture = fixture
    end

    def context = fixture.context

    def available!
      raise Ace::Runtime::Testing::FixtureUnavailable if fixture.unavailable?

      true
    end

    def window_info(name)
      available!
      info = fixture.window_info(name)
      info && {id: info[:id], root: info[:root], preset: info[:preset]}
    end

    def create_window(**options) = fixture.create_window(**options)
    def split_window(window) = fixture.split_window(window)
    def set_keep_alive(pane, value) = fixture.set_keep_alive(pane, value)
    def focus_window(window) = fixture.focus_window(window)
    def write_text(pane, text) = fixture.write_text(pane, text)
    def press_key(pane, key) = fixture.press_key(pane, key)
    def capture_output(pane, lines:) = fixture.capture_output(pane, lines: lines)
    def agent_state(pane) = fixture.agent_state(pane)
    def kill_window(window) = fixture.kill_window(window)

    def windows
      available!
      fixture.windows.map do |name, info|
        {name: name, id: info[:id], active: info[:focused]}
      end
    end

    def panes_for(window)
      available!
      info = fixture.window_info(window)
      return [] unless info

      info[:panes].map do |id|
        pane = fixture.panes.fetch(id)
        {pane: id, keep_alive: pane[:keep_alive], alive: pane[:alive]}
      end
    end

    def lifecycle?(condition, target)
      case condition
      when "window-exists" then fixture.window_exists?(target)
      when "window-active" then fixture.window_info(target)&.fetch(:focused)
      when "pane-exists" then fixture.pane_exists?(target)
      when "pane-exited" then !fixture.pane_exists?(target) || !fixture.alive?(target)
      end
    end

    def translate_error(error)
      case error
      when Ace::Runtime::Testing::FixtureUnavailable
        Ace::Runtime::RuntimeUnavailableError.new("tmux runtime is unavailable")
      when Ace::Runtime::Testing::FixtureTargetMissing
        Ace::Runtime::TargetNotFoundError.new("tmux target is unavailable")
      when Ace::Runtime::Testing::FixtureStall
        Ace::Runtime::SendStalledError.new("submission did not begin processing")
      else
        error
      end
    end

    private

    attr_reader :fixture
  end

  def build_fixture = Ace::Runtime::Testing::ScriptedRuntime.new
  def build_adapter(fixture) = Ace::Tmux::RuntimeAdapter.new(backend: ScriptedBackend.new(fixture))
end

class TmuxRuntimeAdapterEntrypointTest < Minitest::Test
  def test_resolves_registered_adapter
    require "ace/runtime/adapters/tmux"

    assert_instance_of Ace::Tmux::RuntimeAdapter, Ace::Runtime.resolve("tmux")
  end
end

class TmuxRuntimeAdapterNativeTest < Minitest::Test
  class FakeTmuxExecutor
    attr_reader :commands
    attr_accessor :available

    def initialize
      @commands = []
      @window = nil
      @pane = nil
      @options = {}
      @available = true
    end

    def tmux_available?(tmux: "tmux") = available

    def capture(command)
      @commands << command
      action = command[1]
      success = true
      stderr = ""
      output = case action
      when "list-windows"
        @window ? "0\t@1\tmain\t1\twork\t1" : ""
      when "new-window"
        @window = "@1"
      when "split-window"
        @pane = "%2"
      when "list-panes"
        @pane ? "1\t%2\tmain\t@1\t1\twork\t0\tzsh\t/tmp/work" : ""
      when "show-options"
        @options[[command[-2], command[-1]]].to_s
      when "set-window-option", "set-option"
        @options[[command[command.index("-t") + 1], command[-2]]] = command[-1]
        ""
      when "display-message"
        case command[-1]
        when "\#{pane_current_path}" then "/tmp/work"
        when "\#{pane_dead}" then "0"
        else ""
        end
      when "send-keys"
        if command[command.index("-t") + 1] != @pane
          success = false
          stderr = "can't find pane"
        end
        ""
      when "capture-pane"
        if command[command.index("-t") + 1] != @pane
          success = false
          stderr = "can't find pane"
        end
        ""
      else
        ""
      end
      Ace::Tmux::Molecules::ExecutionResult.new(
        stdout: output, stderr: stderr, success: success, exit_code: success ? 0 : 1
      )
    end

    def run(command)
      capture(command).success?
    end
  end

  def setup
    @executor = FakeTmuxExecutor.new
    @backend = Ace::Tmux::NativeRuntimeBackend.new(executor: @executor, env: {"ACE_TMUX_SESSION" => "main"})
    @adapter = Ace::Tmux::RuntimeAdapter.new(backend: @backend)
  end

  def test_native_window_creation_is_idempotent_and_uses_root
    first = @adapter.ensure_window(name: "work", root: "/tmp/work")
    second = @adapter.ensure_window(name: "work", root: "/tmp/work")

    assert_equal "@1", first
    assert_equal first, second
    assert_equal 1, @executor.commands.count { |command| command[1] == "new-window" }
    assert_includes @executor.commands,
      ["tmux", "new-window", "-t", "main:", "-n", "work", "-c", "/tmp/work", "-P", "-F", "\#{window_id}"]
  end

  def test_native_preparation_reuses_live_marked_pane
    @adapter.ensure_window(name: "work", root: "/tmp/work")
    first = @adapter.prepare_pane(window: "work")
    second = @adapter.prepare_pane(window: "work")

    assert_equal "%2", first
    assert_equal first, second
    assert_equal 1, @executor.commands.count { |command| command[1] == "split-window" }
    assert @executor.commands.any? { |command| command.include?("remain-on-exit") }
  end

  def test_native_send_uses_control_surface_and_preserves_order
    @adapter.ensure_window(name: "work", root: "/tmp/work")
    @adapter.prepare_pane(window: "work")
    @adapter.send(pane: "%2", items: [{message: "one"}, {key: "Enter"}, {message: "two"}])

    sends = @executor.commands.select { |command| command[1] == "send-keys" }
    assert_equal ["one", "Enter", "two"], sends.map(&:last)
  end

  def test_native_message_uses_literal_mode_but_key_does_not
    @adapter.ensure_window(name: "work", root: "/tmp/work")
    @adapter.prepare_pane(window: "work")
    @adapter.send(pane: "%2", items: [{message: "Enter"}, {key: "Enter"}])

    sends = @executor.commands.select { |command| command[1] == "send-keys" }
    assert_includes sends.first, "-l"
    refute_includes sends.last, "-l"
  end

  def test_native_missing_pane_send_is_target_not_found
    @adapter.ensure_window(name: "work", root: "/tmp/work")
    @adapter.prepare_pane(window: "work")

    assert_raises(Ace::Runtime::TargetNotFoundError) do
      @adapter.send_command(pane: "%999", command: "run")
    end
  end

  def test_native_missing_pane_capture_is_target_not_found
    @adapter.ensure_window(name: "work", root: "/tmp/work")
    @adapter.prepare_pane(window: "work")

    assert_raises(Ace::Runtime::TargetNotFoundError) do
      @adapter.capture(pane: "%999")
    end
  end

  def test_native_missing_binary_is_runtime_unavailable
    @executor.available = false

    assert_raises(Ace::Runtime::RuntimeUnavailableError) do
      @adapter.ensure_window(name: "work", root: "/tmp/work")
    end
  end

  def test_native_multi_state_completion_wait_uses_stability_and_capped_polling
    surface = Object.new
    calls = []
    surface.define_singleton_method(:wait_for_condition) do |**options|
      calls << options
      true
    end
    backend = Ace::Tmux::NativeRuntimeBackend.new(
      executor: @executor, env: {"ACE_TMUX_SESSION" => "main"}, surface: surface
    )

    assert backend.wait_agent(pane: "%2", states: %w[idle working-done], timeout: 600)
    assert_equal "agent", calls.first[:condition]
    assert_operator calls.first[:interval], :<=, 0.2
    assert_equal 1.0, calls.first[:settle]
  end
end
