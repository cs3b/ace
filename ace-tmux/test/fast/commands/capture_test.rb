# frozen_string_literal: true

require_relative "../../test_helper"

class CaptureCommandTest < Minitest::Test
  def test_command_class_exists
    assert_instance_of Ace::Tmux::CLI::Commands::Capture, Ace::Tmux::CLI::Commands::Capture.new
  end

  def test_reports_invalid_pane_target_with_correct_format_hint
    executor = MockExecutor.new
    control = Ace::Tmux::Organisms::ControlSurface.new(
      executor: executor,
      resolver: Ace::Tmux::Molecules::RuntimeTargetResolver.new(executor: executor, env: {})
    )
    command = Ace::Tmux::CLI::Commands::Capture.new

    error = Ace::Tmux::Organisms::ControlSurface.stub(:new, control) do
      assert_raises(Ace::Support::Cli::Error) { command.call(pane: "default:3:1", lines: 10) }
    end

    assert_equal "Invalid pane target 'default:3:1'. Use '%8', 'default:3.1', '.1', or '--window 3 --pane 1'.", error.message
  end
end
