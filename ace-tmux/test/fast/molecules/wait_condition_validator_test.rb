# frozen_string_literal: true

require_relative "../../test_helper"

class WaitConditionValidatorTest < Minitest::Test
  def test_accepts_supported_condition
    assert_equal "window-active", Ace::Tmux::Molecules::WaitConditionValidator.validate!(
      condition: "window-active",
      pattern: nil
    )
  end

  def test_accepts_agent_condition
    assert_equal "agent", Ace::Tmux::Molecules::WaitConditionValidator.validate!(
      condition: "agent",
      pattern: nil
    )
  end

  def test_requires_pattern_for_output_wait
    error = assert_raises(Ace::Tmux::ValidationError) do
      Ace::Tmux::Molecules::WaitConditionValidator.validate!(condition: "output", pattern: nil)
    end

    assert_includes error.message, "--pattern is required"
  end
end
