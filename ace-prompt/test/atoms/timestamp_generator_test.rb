# frozen_string_literal: true

require "test_helper"

class TimestampGeneratorTest < Minitest::Test
  def test_generates_timestamp_in_correct_format
    result = Ace::Prompt::Atoms::TimestampGenerator.call

    assert result[:timestamp]
    assert_match(/^\d{8}-\d{6}$/, result[:timestamp])
  end

  def test_generates_timestamp_for_specific_time
    time = Time.new(2025, 11, 27, 14, 30, 0)
    result = Ace::Prompt::Atoms::TimestampGenerator.call(time: time)

    assert_equal "20251127-143000", result[:timestamp]
  end

  def test_returns_hash
    result = Ace::Prompt::Atoms::TimestampGenerator.call

    assert_kind_of Hash, result
    assert result.key?(:timestamp)
  end
end
