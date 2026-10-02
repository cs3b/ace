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
    def validate_key!(_key) = true
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
    attr_accessor :available, :fail_pane_queries
    attr_accessor :pane_query_error

    def initialize
      @commands = []
      @window = nil
      @pane = nil
      @options = {}
      @available = true
      @fail_pane_queries = false
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
        if @fail_pane_queries
          success = false
          stderr = pane_query_error || "server error"
          ""
        else
          @options[[command[-2], command[-1]]].to_s
        end
      when "set-window-option", "set-option"
        @options[[command[command.index("-t") + 1], command[-2]]] = command[-1]
        ""
      when "display-message"
        case command[-1]
        when "\#{pane_current_path}" then "/tmp/work"
        when "\#{pane_dead}", "\#{pane_id}"
          if command[command.index("-t") + 1] == @pane && !@fail_pane_queries
            command[-1] == "\#{pane_dead}" ? "0" : command[command.index("-t") + 1]
          else
            success = false
            stderr = @fail_pane_queries ? (pane_query_error || "server error") : "can't find pane"
            ""
          end
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
    surface.define_singleton_method(:fetch_pane_profile) { |_pane| {interactive_cli: true} }
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

  def test_native_wait_agent_polls_shell_panes_for_completion_states
    surface = Object.new
    wait_calls = []
    surface.define_singleton_method(:fetch_pane_profile) { |_pane| {interactive_cli: false} }
    surface.define_singleton_method(:wait_for_condition) do |**options|
      wait_calls << options
      raise "shell panes must not use the interactive completion wait"
    end
    outputs = ["building...\n", "done\n$ "]
    surface.define_singleton_method(:capture_recent_output) { |**_options| outputs.shift || "done\n$ " }
    backend = Ace::Tmux::NativeRuntimeBackend.new(
      executor: @executor, env: {"ACE_TMUX_SESSION" => "main"}, surface: surface
    )

    assert backend.wait_agent(pane: "%2", states: %w[idle], timeout: 5)
    assert_empty wait_calls
  end

  def test_native_wait_agent_mixed_states_match_any_requested_state
    surface = Object.new
    wait_calls = []
    surface.define_singleton_method(:fetch_pane_profile) { |_pane| {interactive_cli: true} }
    surface.define_singleton_method(:wait_for_condition) do |**options|
      wait_calls << options
      true
    end
    surface.define_singleton_method(:capture_recent_output) { |**_options| "esc to interrupt\n" }
    backend = Ace::Tmux::NativeRuntimeBackend.new(
      executor: @executor, env: {"ACE_TMUX_SESSION" => "main"}, surface: surface
    )

    assert backend.wait_agent(pane: "%2", states: %w[idle working], timeout: 5)
    assert_empty wait_calls
  end

  def test_native_shell_wait_matches_completion_alias_via_idle
    surface = Object.new
    surface.define_singleton_method(:fetch_pane_profile) { |_pane| {interactive_cli: false} }
    surface.define_singleton_method(:capture_recent_output) { |**_options| "ready\n$ " }
    backend = Ace::Tmux::NativeRuntimeBackend.new(
      executor: @executor, env: {"ACE_TMUX_SESSION" => "main"}, surface: surface
    )

    assert backend.wait_agent(pane: "%2", states: %w[done], timeout: 5)
  end

  def test_native_window_option_reads_use_window_scope
    @adapter.ensure_window(name: "work", root: "/tmp/work")
    @adapter.ensure_window(name: "work", root: "/tmp/work")

    reads = @executor.commands.select { |command| command[1] == "show-options" && command.last == "@ace_runtime_root" }
    refute_empty reads
    assert_includes reads.first, "-w"
  end

  def test_native_window_option_reads_tolerate_trailing_newline
    executor = NewlineShowOptionsExecutor.new
    adapter = Ace::Tmux::RuntimeAdapter.new(
      backend: Ace::Tmux::NativeRuntimeBackend.new(executor: executor, env: {"ACE_TMUX_SESSION" => "main"})
    )

    first = adapter.ensure_window(name: "work", root: "/tmp/work")
    assert_equal first, adapter.ensure_window(name: "work", root: "/tmp/work")
    assert_equal 1, executor.commands.count { |command| command[1] == "new-window" }
  end

  def test_native_context_preserves_session_and_window_when_pane_is_unresolved
    executor = FakeTmuxExecutor.new
    backend = Ace::Tmux::NativeRuntimeBackend.new(
      executor: executor,
      env: {"TMUX" => "1", "ACE_TMUX_SESSION" => "main", "ACE_TMUX_WINDOW" => "work"}
    )

    context = backend.context

    assert_equal true, context[:in_runtime]
    assert_equal "main", context[:session]
    assert_equal "work", context[:window]
    assert_nil context[:pane]
  end

  def test_native_shell_wait_times_out_while_output_keeps_changing
    surface = Object.new
    ticks = 0
    surface.define_singleton_method(:fetch_pane_profile) { |_pane| {interactive_cli: false} }
    surface.define_singleton_method(:capture_recent_output) do |**_options|
      ticks += 1
      "tick #{ticks}\n"
    end
    backend = Ace::Tmux::NativeRuntimeBackend.new(
      executor: @executor, env: {"ACE_TMUX_SESSION" => "main"}, surface: surface
    )

    assert_raises(Ace::Tmux::WaitTimeoutError) do
      backend.wait_agent(pane: "%2", states: %w[idle], timeout: 0.3)
    end
  end

  def test_native_wait_agent_returns_immediately_when_working_observed
    surface = Object.new
    ticks = 0
    surface.define_singleton_method(:fetch_pane_profile) { |_pane| {interactive_cli: false} }
    surface.define_singleton_method(:capture_recent_output) do |**_options|
      ticks += 1
      "esc to interrupt (#{ticks})\n"
    end
    backend = Ace::Tmux::NativeRuntimeBackend.new(
      executor: @executor, env: {"ACE_TMUX_SESSION" => "main"}, surface: surface
    )

    assert backend.wait_agent(pane: "%2", states: %w[working], timeout: 0.3)
  end

  def test_native_pane_exists_query_failure_is_runtime_unavailable
    @adapter.ensure_window(name: "work", root: "/tmp/work")
    @executor.fail_pane_queries = true

    assert_raises(Ace::Runtime::RuntimeUnavailableError) do
      @adapter.wait_lifecycle(condition: "pane-exists", target: "%2", timeout: 1)
    end
  end

  def test_native_preset_window_failure_maps_to_runtime_unavailable
    assert_raises(Ace::Runtime::RuntimeUnavailableError) do
      @adapter.ensure_window(name: "lab", root: "/tmp/lab", preset: "no-such-preset")
    end
  end

  def test_native_prepared_pane_splits_in_window_root
    @adapter.ensure_window(name: "work", root: "/tmp/work")
    @adapter.prepare_pane(window: "work")

    split = @executor.commands.find { |command| command[1] == "split-window" }
    refute_nil split
    assert_includes split, "-c"
    assert_equal "/tmp/work", split[split.index("-c") + 1]
  end

  def test_native_query_classifies_missing_target_and_server_failure
    missing = Object.new
    missing.define_singleton_method(:capture) do |_command|
      Ace::Tmux::Molecules::ExecutionResult.new(stdout: "", stderr: "can't find session: main", success: false, exit_code: 1)
    end
    adapter = Ace::Tmux::RuntimeAdapter.new(
      backend: Ace::Tmux::NativeRuntimeBackend.new(executor: missing, env: {"ACE_TMUX_SESSION" => "main"})
    )
    assert_raises(Ace::Runtime::TargetNotFoundError) { adapter.list_windows }

    broken = Object.new
    broken.define_singleton_method(:capture) do |_command|
      Ace::Tmux::Molecules::ExecutionResult.new(stdout: "", stderr: "server exited unexpectedly", success: false, exit_code: 1)
    end
    adapter = Ace::Tmux::RuntimeAdapter.new(
      backend: Ace::Tmux::NativeRuntimeBackend.new(executor: broken, env: {"ACE_TMUX_SESSION" => "main"})
    )
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { adapter.list_windows }
  end

  def test_native_pane_listing_preserves_empty_trailing_field
    executor = EmptyPathPaneExecutor.new
    adapter = Ace::Tmux::RuntimeAdapter.new(
      backend: Ace::Tmux::NativeRuntimeBackend.new(executor: executor, env: {"ACE_TMUX_SESSION" => "main"})
    )
    adapter.ensure_window(name: "work", root: "/tmp/work")

    entries = adapter.list_panes(window: "work")

    assert_equal 1, entries.length
    assert_equal "%2", entries.first[:pane]
  end

  class EmptyPathPaneExecutor < FakeTmuxExecutor
    def initialize
      super
      @pane = "%2"
    end

    def capture(command)
      result = super
      if command[1] == "list-panes" && result.success?
        return Ace::Tmux::Molecules::ExecutionResult.new(
          stdout: "1\t%2\tmain\t@1\t1\twork\t0\tzsh\t\n", stderr: result.stderr, success: true, exit_code: 0
        )
      end
      result
    end
  end

  def test_native_pane_exited_distinguishes_absence_from_query_failure
    @adapter.ensure_window(name: "work", root: "/tmp/work")
    pane = @adapter.prepare_pane(window: "work")

    error = assert_raises(Ace::Runtime::WaitTimeoutError) do
      @adapter.wait_lifecycle(condition: "pane-exited", target: pane, timeout: 0.1)
    end
    assert_equal 0.1, error.timeout

    assert @adapter.wait_lifecycle(condition: "pane-exited", target: "%999", timeout: 1)

    @executor.fail_pane_queries = true
    assert_raises(Ace::Runtime::RuntimeUnavailableError) do
      @adapter.wait_lifecycle(condition: "pane-exited", target: pane, timeout: 1)
    end
  end

  def test_native_send_rejects_unknown_key_before_transport
    @adapter.ensure_window(name: "work", root: "/tmp/work")
    @adapter.prepare_pane(window: "work")
    sends_before = @executor.commands.count { |command| command[1] == "send-keys" }

    assert_raises(Ace::Runtime::SendRejectedError) do
      @adapter.send_keys(pane: "%2", keys: %w[C-z Z-z])
    end

    sends_after = @executor.commands.count { |command| command[1] == "send-keys" }
    assert_equal sends_before, sends_after
  end

  def test_native_wait_output_rejects_blank_pattern
    assert_raises(ArgumentError) { @adapter.wait_output(pane: "%2", pattern: "", timeout: 1) }
    assert_raises(ArgumentError) { @adapter.wait_output(pane: "%2", pattern: nil, timeout: 1) }
  end

  def test_native_option_query_failure_is_runtime_unavailable
    executor = FakeTmuxExecutor.new
    executor.fail_pane_queries = true
    backend = Ace::Tmux::NativeRuntimeBackend.new(executor: executor, env: {"ACE_TMUX_SESSION" => "main"})

    assert_raises(Ace::Tmux::Error) { backend.send(:option, "@1", "@ace_runtime_root") }
  end

  def test_native_socket_failure_is_never_a_missing_target
    @adapter.ensure_window(name: "work", root: "/tmp/work")
    @adapter.prepare_pane(window: "work")
    @executor.fail_pane_queries = true
    @executor.pane_query_error = "error connecting to /tmp/tmux-501/default: No such file or directory"

    assert_raises(Ace::Runtime::RuntimeUnavailableError) do
      @adapter.wait_lifecycle(condition: "pane-exited", target: "%2", timeout: 1)
    end
    assert_raises(Ace::Runtime::RuntimeUnavailableError) do
      @adapter.list_panes(window: "work")
    end
  end

  class NewlineShowOptionsExecutor < FakeTmuxExecutor
    def capture(command)
      result = super
      if command[1] == "show-options" && !result.stdout.to_s.empty?
        return Ace::Tmux::Molecules::ExecutionResult.new(
          stdout: "#{result.stdout}\n", stderr: result.stderr, success: result.success?, exit_code: 0
        )
      end
      result
    end
  end
end
