# frozen_string_literal: true

require_relative "../../test_helper"

class WaitCommandTest < Minitest::Test
  class FakeControlSurface
    attr_reader :wait_calls

    def initialize
      @wait_calls = []
    end

    def wait_for_condition(**options)
      @wait_calls << options
      true
    end
  end

  def test_command_class_exists
    assert_instance_of Ace::Tmux::CLI::Commands::Wait, Ace::Tmux::CLI::Commands::Wait.new
  end

  def test_reports_invalid_pane_target_with_correct_format_hint
    executor = MockExecutor.new
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: Ace::Tmux::Molecules::RuntimeTargetResolver.new(executor: executor, env: {})
    )
    command = Ace::Tmux::CLI::Commands::Wait.new

    error = Ace::Tmux::Organisms::ControlSurface.stub(:new, control) do
      assert_raises(Ace::Support::Cli::Error) do
        command.call(for: "pane-exists", pane: "default:3:1", timeout: "1", interval: "0.1")
      end
    end

    assert_equal "Invalid pane target 'default:3:1'. Use '%8', 'default:3.1', '.1', or '--window 3 --pane 1'.", error.message
  end

  def test_passes_lines_to_control_surface
    fake = FakeControlSurface.new
    command = Ace::Tmux::CLI::Commands::Wait.new

    output = Ace::Tmux::Organisms::ControlSurface.stub(:new, fake) do
      capture_io { command.call(for: "output", pane: "%1", pattern: "ready", lines: 80, timeout: "1", interval: "0.1") }[0]
    end

    assert_equal [
      {
        condition: "output",
        session: nil,
        window: nil,
        pane: "%1",
        pattern: "ready",
        lines: 80,
        timeout: 1.0,
        interval: 0.1
      }
    ], fake.wait_calls
    assert_equal "Condition met: output\n", output
  end
end
