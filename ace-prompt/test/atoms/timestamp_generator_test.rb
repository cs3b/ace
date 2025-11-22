# frozen_string_literal: true

require "test_helper"
require "ace/prompt/atoms/timestamp_generator"

class TimestampGeneratorTest < Ace::Prompt::TestCase
  def test_generate_returns_correct_format
    time = Time.new(2025, 11, 22, 14, 30, 45)
    result = Ace::Prompt::Atoms::TimestampGenerator.generate(time)

    assert_equal "20251122-143045", result
  end

  def test_generate_with_enhancement_adds_suffix
    time = Time.new(2025, 11, 22, 14, 30, 45)
    result = Ace::Prompt::Atoms::TimestampGenerator.generate_with_enhancement(1, time)

    assert_equal "20251122-143045_e001", result
  end

  def test_generate_with_enhancement_pads_iteration
    time = Time.new(2025, 11, 22, 14, 30, 45)
    result = Ace::Prompt::Atoms::TimestampGenerator.generate_with_enhancement(42, time)

    assert_equal "20251122-143045_e042", result
  end
end
