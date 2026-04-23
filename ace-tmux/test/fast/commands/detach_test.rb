# frozen_string_literal: true

require_relative "../../test_helper"

class DetachCommandTest < Minitest::Test
  class FakeControlSurface
    attr_reader :session

    def initialize(session)
      @session = session
    end

    def detach_session(session: nil)
      session || @session
    end
  end

  def test_command_class_exists
    assert_instance_of Ace::Tmux::CLI::Commands::Detach, Ace::Tmux::CLI::Commands::Detach.new
  end

  def test_prints_resolved_session_name
    fake = FakeControlSurface.new("dev")
    command = Ace::Tmux::CLI::Commands::Detach.new

    output = Ace::Tmux::Organisms::ControlSurface.stub(:new, fake) do
      capture_io { command.call }[0]
    end

    assert_equal "Detached session dev\n", output
  end
end
