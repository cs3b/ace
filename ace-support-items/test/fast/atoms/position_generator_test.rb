# frozen_string_literal: true

require "test_helper"
require "ace/b36ts"

class PositionGeneratorTest < AceSupportItemsTestCase
  PG = Ace::Support::Items::Atoms::PositionGenerator

  def test_first_returns_6_char_string
    pos = PG.first
    assert_equal 6, pos.length
    assert_match(/\A[0-9a-z]{6}\z/, pos)
  end

  def test_last_returns_6_char_string
    pos = PG.last
    assert_equal 6, pos.length
    assert_match(/\A[0-9a-z]{6}\z/, pos)
  end

  def test_first_sorts_before_last
    assert_operator PG.first, :<, PG.last
  end

  def test_first_sorts_before_any_recent_timestamp
    recent = Ace::B36ts.encode(Time.utc(2025, 1, 1))
    assert_operator PG.first, :<, recent
  end

  def test_after_sorts_after_given_position
    base = Ace::B36ts.encode(Time.utc(2025, 6, 15))
    result = PG.after(base)
    assert_operator result, :>, base
  end

  def test_before_sorts_before_given_position
    base = Ace::B36ts.encode(Time.utc(2025, 6, 15))
    result = PG.before(base)
    assert_operator result, :<, base
  end

  def test_between_sorts_between_two_positions
    a = Ace::B36ts.encode(Time.utc(2025, 1, 1))
    b = Ace::B36ts.encode(Time.utc(2025, 12, 31))
    mid = PG.between(a, b)

    assert_operator mid, :>, a
    assert_operator mid, :<, b
  end

  def test_after_returns_distinct_value
    base = Ace::B36ts.encode(Time.utc(2025, 6, 15))
    refute_equal base, PG.after(base)
  end

  def test_before_returns_distinct_value
    base = Ace::B36ts.encode(Time.utc(2025, 6, 15))
    refute_equal base, PG.before(base)
  end

  def test_between_with_close_positions
    # Even with positions only a few seconds apart, between should produce a value
    a = Ace::B36ts.encode(Time.utc(2025, 6, 15, 12, 0, 0))
    b = Ace::B36ts.encode(Time.utc(2025, 6, 15, 12, 0, 10))
    mid = PG.between(a, b)

    assert_operator mid, :>=, a
    assert_operator mid, :<=, b
  end
end
