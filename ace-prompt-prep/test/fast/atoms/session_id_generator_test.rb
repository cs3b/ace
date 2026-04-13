# frozen_string_literal: true

require "test_helper"

class SessionIdGeneratorTest < Minitest::Test
  # --- Base36 ID generation tests ---

  def test_generates_base36_id
    result = Ace::PromptPrep::Atoms::SessionIdGenerator.call

    assert result[:timestamp]
    # Base36 IDs are 6 characters
    assert_equal 6, result[:timestamp].length
  end

  def test_generates_base36_id_for_specific_time
    time = Time.utc(2025, 11, 27, 14, 30, 0)
    result = Ace::PromptPrep::Atoms::SessionIdGenerator.call(time: time)

    assert_equal 6, result[:timestamp].length
    # Verify it's valid base36
    assert Ace::B36ts.valid?(result[:timestamp])
  end

  def test_generates_consistent_id_for_same_time
    time = Time.utc(2025, 11, 27, 14, 30, 0)
    result1 = Ace::PromptPrep::Atoms::SessionIdGenerator.call(time: time)
    result2 = Ace::PromptPrep::Atoms::SessionIdGenerator.call(time: time)

    assert_equal result1[:timestamp], result2[:timestamp]
  end

  def test_default_time_evaluates_at_call_time_not_load_time
    # Use time stubbing to simulate time passing
    t1 = Time.utc(2025, 1, 6, 10, 0, 0)
    t2 = Time.utc(2025, 1, 6, 10, 0, 3)  # 3 seconds later (> 1.85s precision)

    result1 = nil
    result2 = nil

    Time.stub(:now, t1) { result1 = Ace::PromptPrep::Atoms::SessionIdGenerator.call }
    Time.stub(:now, t2) { result2 = Ace::PromptPrep::Atoms::SessionIdGenerator.call }

    # IDs should be different because time is evaluated at call time, not load time
    refute_equal result1[:timestamp], result2[:timestamp]
  end

  # --- Validation tests ---

  def test_valid_returns_true_for_base36
    assert Ace::PromptPrep::Atoms::SessionIdGenerator.valid?("i50jj3")
  end

  def test_valid_returns_false_for_invalid
    refute Ace::PromptPrep::Atoms::SessionIdGenerator.valid?("invalid")
  end

  def test_valid_returns_false_for_non_string
    refute Ace::PromptPrep::Atoms::SessionIdGenerator.valid?(123)
  end

  def test_valid_returns_false_for_nil
    refute Ace::PromptPrep::Atoms::SessionIdGenerator.valid?(nil)
  end

  def test_valid_returns_false_for_empty_string
    refute Ace::PromptPrep::Atoms::SessionIdGenerator.valid?("")
  end

  def test_valid_returns_false_for_invalid_base36_characters
    # 6 characters but contains invalid Base36 character (!)
    refute Ace::PromptPrep::Atoms::SessionIdGenerator.valid?("i50jj!")
  end

  # --- Return hash tests ---

  def test_returns_hash_with_timestamp_key
    result = Ace::PromptPrep::Atoms::SessionIdGenerator.call

    assert_kind_of Hash, result
    assert result.key?(:timestamp)
  end
end
