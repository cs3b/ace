# frozen_string_literal: true

require_relative "../../test_helper"

class RuntimeDirectiveExecutorTest < AceDemoTestCase
  # Fake contract adapters — one per runtime — recording the ops demo's
  # directives must map onto identically.
  class FakeAdapter
    attr_reader :calls

    def initialize
      @calls = []
    end

    def wait_lifecycle(condition:, target:, timeout:)
      @calls << [:wait_lifecycle, {condition: condition, target: target, timeout: timeout}]
      true
    end

    def send_command(pane:, command:)
      @calls << [:send_command, {pane: pane, command: command}]
      true
    end

    def send_keys(pane:, keys:)
      @calls << [:send_keys, {pane: pane, keys: keys}]
      true
    end
  end

  class FakeTmuxExecutor
    attr_reader :run_calls

    def initialize
      @run_calls = []
    end

    def run(cmd)
      @run_calls << cmd
      true
    end
  end

  RUNTIMES = %w[tmux herdr].freeze

  def teardown
    Ace::Runtime.reset_registry!
    super
  end

  def test_lifecycle_and_send_directives_map_identically_on_both_adapters
    directives = [
      {"action" => "wait", "for" => "window-exists", "window" => "work"},
      {"action" => "wait", "for" => "window-active", "window" => "work", "timeout" => 5},
      {"action" => "wait", "for" => "pane-exists", "pane" => "%3"},
      {"action" => "wait", "for" => "pane-exited", "pane" => "p7"},
      {"action" => "send", "pane" => "%3", "command" => "echo hi"},
      {"action" => "send", "pane" => "w1:p1", "key" => "Enter"}
    ]

    observed = RUNTIMES.map do |runtime|
      adapter = FakeAdapter.new
      executor = build_executor(runtime: runtime, adapter: adapter)

      directives.each { |directive| executor.execute({"tmux" => directive}, {}) }

      adapter.calls
    end

    assert_equal observed[0], observed[1], "both runtimes must receive identical contract ops"
    assert_equal 6, observed[0].length
    assert_equal [:wait_lifecycle, {condition: "window-exists", target: "work", timeout: 10.0}], observed[0][0]
    assert_equal [:wait_lifecycle, {condition: "window-active", target: "work", timeout: 5}], observed[0][1]
    assert_equal [:wait_lifecycle, {condition: "pane-exists", target: "%3", timeout: 10.0}], observed[0][2]
    assert_equal [:wait_lifecycle, {condition: "pane-exited", target: "p7", timeout: 10.0}], observed[0][3]
    assert_equal [:send_command, {pane: "%3", command: "echo hi"}], observed[0][4]
    assert_equal [:send_keys, {pane: "w1:p1", keys: ["Enter"]}], observed[0][5]
  end

  def test_directive_runtime_wins_over_inherited_environment
    adapter = FakeAdapter.new
    executor = build_executor(runtime: "tmux", adapter: adapter)

    executor.execute(
      {"tmux" => {"action" => "send", "runtime" => "tmux", "pane" => "%3", "command" => "echo hi"}},
      {"ACE_RUNTIME" => "herdr"}
    )

    assert_equal [:send_command, {pane: "%3", command: "echo hi"}], adapter.calls.first
  end

  def test_each_directive_resolves_its_own_runtime
    Ace::Runtime.reset_registry!
    tmux_adapter = FakeAdapter.new
    herdr_adapter = FakeAdapter.new
    Ace::Runtime.register(:tmux, -> { tmux_adapter })
    Ace::Runtime.register(:herdr, -> { herdr_adapter })

    executor = Ace::Demo::Molecules::RuntimeDirectiveExecutor.new(env: {})

    executor.execute({"tmux" => {"action" => "send", "runtime" => "tmux", "pane" => "%3", "command" => "one"}}, {})
    executor.execute({"tmux" => {"action" => "send", "runtime" => "herdr", "pane" => "p1", "command" => "two"}}, {})

    assert_equal [[:send_command, {pane: "%3", command: "one"}]], tmux_adapter.calls
    assert_equal [[:send_command, {pane: "p1", command: "two"}]], herdr_adapter.calls
  ensure
    Ace::Runtime.reset_registry!
  end

  def test_wait_rejects_unknown_condition
    executor = build_executor(runtime: "tmux", adapter: FakeAdapter.new)

    error = assert_raises(ArgumentError) do
      executor.execute({"tmux" => {"action" => "wait", "for" => "output-contains", "window" => "work"}}, {})
    end

    assert_includes error.message, "wait condition must be one of"
  end

  def test_wait_requires_condition_target
    executor = build_executor(runtime: "tmux", adapter: FakeAdapter.new)

    error = assert_raises(ArgumentError) do
      executor.execute({"tmux" => {"action" => "wait", "for" => "window-active"}}, {})
    end

    assert_includes error.message, "missing window"
  end

  def test_attach_returns_shell_command_without_detected_runtime
    executor = build_executor(runtime: "tmux", adapter: FakeAdapter.new)

    result = executor.execute({"tmux" => {"action" => "attach", "session" => "fork-demo"}}, {})

    assert_equal({shell_command: "tmux attach-session -t fork-demo"}, result)
  end

  def test_attach_under_herdr_is_rejected
    executor = build_executor(runtime: "tmux", adapter: FakeAdapter.new)

    error = assert_raises(Ace::Demo::Error) do
      executor.execute(
        {"tmux" => {"action" => "attach", "runtime" => "herdr", "session" => "fork-demo"}},
        {}
      )
    end

    assert_includes error.message, "attach is tmux-local and unsupported under the 'herdr' runtime"
  end

  def test_attach_rejects_inherited_herdr_environment
    executor = build_executor(runtime: "herdr", adapter: FakeAdapter.new, override: nil)

    error = assert_raises(Ace::Demo::Error) do
      executor.execute(
        {"tmux" => {"action" => "attach", "session" => "fork-demo"}},
        {"ACE_RUNTIME" => "herdr"}
      )
    end

    assert_includes error.message, "attach is tmux-local and unsupported under the 'herdr' runtime"
  end

  def test_detach_runs_tmux_client_detach
    tmux_executor = FakeTmuxExecutor.new
    executor = build_executor(runtime: "tmux", adapter: FakeAdapter.new, tmux_executor: tmux_executor)

    executor.execute({"tmux" => {"action" => "detach", "session" => "fork-demo"}}, {})

    assert_equal [["tmux", "detach-client", "-s", "fork-demo"]], tmux_executor.run_calls
  end

  def test_detach_under_herdr_is_rejected
    executor = build_executor(runtime: "herdr", adapter: FakeAdapter.new)

    error = assert_raises(Ace::Demo::Error) do
      executor.execute({"tmux" => {"action" => "detach", "session" => "fork-demo"}}, {})
    end

    assert_includes error.message, "detach is tmux-local and unsupported under the 'herdr' runtime"
  end

  def test_unsupported_action_is_rejected
    executor = build_executor(runtime: "tmux", adapter: FakeAdapter.new)

    error = assert_raises(ArgumentError) do
      executor.execute({"tmux" => {"action" => "capture", "pane" => "%3", "lines" => 10}}, {})
    end

    assert_includes error.message, "Unsupported tmux action"
  end

  def test_contract_errors_surface_as_demo_errors
    failing = Class.new do
      def wait_lifecycle(condition:, target:, timeout:)
        raise Ace::Runtime::TargetNotFoundError, "target is unavailable"
      end
    end.new
    executor = build_executor(runtime: "tmux", adapter: failing)

    error = assert_raises(Ace::Demo::Error) do
      executor.execute({"tmux" => {"action" => "wait", "for" => "window-active", "window" => "work"}}, {})
    end

    assert_includes error.message, "unavailable"
  end

  private

  def build_executor(runtime:, adapter:, tmux_executor: nil, override: :default)
    Ace::Runtime.reset_registry!
    Ace::Runtime.register(runtime.to_sym, -> { adapter })
    Ace::Demo::Molecules::RuntimeDirectiveExecutor.new(
      runtime: override == :default ? runtime : override,
      env: {},
      tmux_executor: tmux_executor
    )
  end
end
