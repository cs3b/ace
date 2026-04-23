# frozen_string_literal: true

require_relative "../../test_helper"

class SendCommandTest < Minitest::Test
  class FakeControlSurface
    attr_reader :send_calls, :capture_calls, :wait_calls

    def initialize(capture_output: "captured output")
      @capture_outputs = Array(capture_output)
      @send_calls = []
      @capture_calls = []
      @wait_calls = []
    end

    def send_sequence(**options)
      @send_calls << options
    end

    def wait_for_condition(**options)
      @wait_calls << options
      true
    end

    def capture_recent_output(**options)
      @capture_calls << options
      @capture_outputs.length > 1 ? @capture_outputs.shift : @capture_outputs.first
    end
  end

  def test_requires_at_least_one_payload_flag
    command = Ace::Tmux::CLI::Commands::Send.new

    error = assert_raises(Ace::Support::Cli::Error) { command.call(pane: "%1") }

    assert_includes error.message, "Provide at least one"
  end

  def test_rejects_cmd_and_msg_together
    command = Ace::Tmux::CLI::Commands::Send.new

    error = assert_raises(Ace::Support::Cli::Error) do
      command.call(pane: "%1", cmd: "echo hi", msg: ["echo"])
    end

    assert_includes error.message, "Use either --cmd or --msg"
  end

  def test_cmd_sends_sequence_and_prints_success_message
    fake = FakeControlSurface.new
    command = Ace::Tmux::CLI::Commands::Send.new

    output = Ace::Tmux::Organisms::ControlSurface.stub(:new, fake) do
      capture_io { command.call(pane: "%1", cmd: "echo hi") }[0]
    end

    assert_equal [{ pane: "%1", command: "echo hi", messages: [], keys: [] }], fake.send_calls
    assert_equal "Sent command\n", output
  end

  def test_msg_and_keys_send_in_one_call
    fake = FakeControlSurface.new
    command = Ace::Tmux::CLI::Commands::Send.new

    output = Ace::Tmux::Organisms::ControlSurface.stub(:new, fake) do
      capture_io { command.call(pane: "%1", msg: ["echo", " hi"], key: ["Enter", "C-c"]) }[0]
    end

    assert_equal [{ pane: "%1", command: nil, messages: ["echo", " hi"], keys: ["Enter", "C-c"] }], fake.send_calls
    assert_equal "Sent 2 messages and 2 keys\n", output
  end

  def test_capture_without_value_uses_defaults_and_prints_capture_output
    fake = FakeControlSurface.new(capture_output: "pane tail")
    command = Ace::Tmux::CLI::Commands::Send.new

    output = Ace::Tmux::Organisms::ControlSurface.stub(:new, fake) do
      command.stub(:sleep, nil) do
        capture_io { command.call(pane: "%1", cmd: "echo hi", capture: nil) }[0]
      end
    end

    assert_equal [{ pane: "%1", command: "echo hi", messages: [], keys: [] }], fake.send_calls
    assert_equal [{ pane: "%1", lines: 40 }], fake.capture_calls
    assert_equal "pane tail\n", output
  end

  def test_capture_with_custom_value_uses_requested_lines
    fake = FakeControlSurface.new(capture_output: "pane tail")
    command = Ace::Tmux::CLI::Commands::Send.new

    Ace::Tmux::Organisms::ControlSurface.stub(:new, fake) do
      command.stub(:sleep, nil) do
        capture_io { command.call(pane: "%1", key: ["Enter"], capture: "80:5") }
      end
    end

    assert_equal [{ pane: "%1", lines: 80 }], fake.capture_calls
  end

  def test_wait_without_value_defaults_to_agent_and_uses_pre_send_baseline
    fake = FakeControlSurface.new(capture_output: ["before", "after"])
    command = Ace::Tmux::CLI::Commands::Send.new

    output = Ace::Tmux::Organisms::ControlSurface.stub(:new, fake) do
      command.stub(:sleep, proc { raise "unexpected sleep" }) do
        capture_io { command.call(pane: "%1", cmd: "ping", wait: nil, capture: "20") }[0]
      end
    end

    assert_equal [{ pane: "%1", command: "ping", messages: [], keys: [] }], fake.send_calls
    assert_equal [
      {
        pane: "%1",
        condition: "agent",
        pattern: nil,
        timeout: 10.0,
        interval: 0.2,
        lines: 20,
        baseline_output: "before",
        require_change: true
      }
    ], fake.wait_calls
    assert_equal [{ pane: "%1", lines: 20 }, { pane: "%1", lines: 20 }], fake.capture_calls
    assert_equal "after\n", output
  end

  def test_wait_output_requires_pattern
    command = Ace::Tmux::CLI::Commands::Send.new

    error = assert_raises(Ace::Support::Cli::Error) do
      command.call(pane: "%1", cmd: "echo hi", wait: "output")
    end

    assert_includes error.message, "--pattern is required"
  end

  def test_wait_output_uses_pre_send_baseline
    fake = FakeControlSurface.new(capture_output: ["before done", "before done\nafter done"])
    command = Ace::Tmux::CLI::Commands::Send.new

    Ace::Tmux::Organisms::ControlSurface.stub(:new, fake) do
      capture_io { command.call(pane: "%1", cmd: "echo done", wait: "output", pattern: "done", capture: "20") }
    end

    assert_equal [
      {
        pane: "%1",
        condition: "output",
        pattern: "done",
        timeout: 10.0,
        interval: 0.2,
        lines: 20,
        baseline_output: "before done",
        require_change: false
      }
    ], fake.wait_calls
  end

  def test_rejects_invalid_capture_value
    command = Ace::Tmux::CLI::Commands::Send.new

    error = assert_raises(Ace::Support::Cli::Error) do
      command.call(pane: "%1", key: ["Enter"], capture: "bad")
    end

    assert_includes error.message, "Invalid --capture value"
  end

  def test_reports_invalid_pane_target_with_correct_format_hint
    executor = MockExecutor.new
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: Ace::Tmux::Molecules::RuntimeTargetResolver.new(executor: executor, env: {})
    )
    command = Ace::Tmux::CLI::Commands::Send.new

    error = Ace::Tmux::Organisms::ControlSurface.stub(:new, control) do
      assert_raises(Ace::Support::Cli::Error) { command.call(pane: "default:3:1", key: ["Enter"]) }
    end

    assert_equal "Invalid pane target 'default:3:1'. Use '%8', 'default:3.1', '.1', or '--window 3 --pane 1'.", error.message
  end
end
