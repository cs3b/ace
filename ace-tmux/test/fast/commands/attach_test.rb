# frozen_string_literal: true

require_relative "../../test_helper"

class AttachCommandTest < Minitest::Test
  def test_command_class_exists
    assert_instance_of Ace::Tmux::CLI::Commands::Attach, Ace::Tmux::CLI::Commands::Attach.new
  end
end
