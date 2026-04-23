# frozen_string_literal: true

require_relative "../../test_helper"

class TmuxDirectiveExecutorTest < AceDemoTestCase
  class FakeControlSurface
    attr_reader :calls

    def initialize
      @calls = []
    end

    def detach_session(session:)
      @calls << [:detach, session]
      true
    end

    def wait_for_condition(**kwargs)
      @calls << [:wait, kwargs]
      true
    end

    def send_command(**kwargs)
      @calls << [:send_command, kwargs]
      true
    end

    def send_key(**kwargs)
      @calls << [:send_key, kwargs]
      true
    end

    def capture_recent_output(**kwargs)
      @calls << [:capture, kwargs]
      "tail"
    end
  end

  def test_attach_returns_shell_command
    executor = build_executor

    result = executor.execute("tmux" => {"action" => "attach", "session" => "fork-demo"})

    assert_equal({shell_command: "tmux attach-session -t fork-demo"}, result)
  end

  def test_send_command_uses_control_surface
    control = FakeControlSurface.new
    executor = build_executor(control_surface: control)

    executor.execute("tmux" => {"action" => "send", "pane" => "fork-demo:work.0", "command" => "echo hi"})

    assert_equal [:send_command, {session: nil, window: nil, pane: "fork-demo:work.0", command: "echo hi"}], control.calls.first
  end

  def test_send_key_uses_control_surface
    control = FakeControlSurface.new
    executor = build_executor(control_surface: control)

    executor.execute("tmux" => {"action" => "send", "pane" => "fork-demo:work.0", "key" => "Enter"})

    assert_equal [:send_key, {session: nil, window: nil, pane: "fork-demo:work.0", key: "Enter"}], control.calls.first
  end

  def test_wait_uses_control_surface
    control = FakeControlSurface.new
    executor = build_executor(control_surface: control)

    executor.execute("tmux" => {"action" => "wait", "for" => "window-active", "session" => "fork-demo", "window" => "work"})

    assert_equal :wait, control.calls.first[0]
  end

  def test_capture_is_not_supported_without_an_observable_sink
    executor = build_executor

    error = assert_raises(ArgumentError) do
      executor.execute("tmux" => {"action" => "capture", "pane" => "fork-demo:work-fs.0", "lines" => 10})
    end

    assert_includes error.message, "Unsupported tmux action"
  end

  private

  def build_executor(control_surface: FakeControlSurface.new)
    Ace::Demo::Molecules::TmuxDirectiveExecutor.new(control_surface: control_surface)
  end
end
