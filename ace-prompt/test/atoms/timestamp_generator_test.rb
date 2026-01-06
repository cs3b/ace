# frozen_string_literal: true

require "test_helper"

class TimestampGeneratorTest < Minitest::Test
  # --- Base36 ID generation tests ---

  def test_generates_base36_id
    result = Ace::Prompt::Atoms::TimestampGenerator.call

    assert result[:timestamp]
    # Base36 IDs are 6 characters
    assert_equal 6, result[:timestamp].length
  end

  def test_generates_base36_id_for_specific_time
    time = Time.utc(2025, 11, 27, 14, 30, 0)
    result = Ace::Prompt::Atoms::TimestampGenerator.call(time: time)

    assert_equal 6, result[:timestamp].length
    # Verify it's valid base36
    assert Ace::Timestamp.valid?(result[:timestamp])
  end

  def test_generates_consistent_id_for_same_time
    time = Time.utc(2025, 11, 27, 14, 30, 0)
    result1 = Ace::Prompt::Atoms::TimestampGenerator.call(time: time)
    result2 = Ace::Prompt::Atoms::TimestampGenerator.call(time: time)

    assert_equal result1[:timestamp], result2[:timestamp]
  end

  # --- Validation tests ---

  def test_valid_returns_true_for_base36
    assert Ace::Prompt::Atoms::TimestampGenerator.valid?("i50jj3")
  end

  def test_valid_returns_false_for_invalid
    refute Ace::Prompt::Atoms::TimestampGenerator.valid?("invalid")
  end

  def test_valid_returns_false_for_non_string
    refute Ace::Prompt::Atoms::TimestampGenerator.valid?(123)
  end

  def test_valid_returns_false_for_nil
    refute Ace::Prompt::Atoms::TimestampGenerator.valid?(nil)
  end

  def test_valid_returns_false_for_empty_string
    refute Ace::Prompt::Atoms::TimestampGenerator.valid?("")
  end

  def test_valid_returns_false_for_invalid_base36_characters
    # 6 characters but contains invalid Base36 character (!)
    refute Ace::Prompt::Atoms::TimestampGenerator.valid?("i50jj!")
  end

  # --- Return hash tests ---

  def test_returns_hash_with_timestamp_key
    result = Ace::Prompt::Atoms::TimestampGenerator.call

    assert_kind_of Hash, result
    assert result.key?(:timestamp)
  end
end
