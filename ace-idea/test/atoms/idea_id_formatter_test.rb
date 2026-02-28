# frozen_string_literal: true

require "test_helper"

class IdeaIdFormatterTest < AceIdeaTestCase
  def test_generates_6char_id
    id = Ace::Idea::Atoms::IdeaIdFormatter.generate
    assert_equal 6, id.length
  end

  def test_generates_lowercase_base36
    id = Ace::Idea::Atoms::IdeaIdFormatter.generate
    assert_match(/\A[0-9a-z]{6}\z/, id)
  end

  def test_no_type_marker_in_id
    id = Ace::Idea::Atoms::IdeaIdFormatter.generate
    refute_includes id, "."
    refute_includes id, ".t."
    refute_includes id, ".i."
  end

  def test_valid_returns_true_for_valid_id
    id = Ace::Idea::Atoms::IdeaIdFormatter.generate
    assert Ace::Idea::Atoms::IdeaIdFormatter.valid?(id)
  end

  def test_valid_returns_false_for_invalid
    refute Ace::Idea::Atoms::IdeaIdFormatter.valid?(nil)
    refute Ace::Idea::Atoms::IdeaIdFormatter.valid?("")
    refute Ace::Idea::Atoms::IdeaIdFormatter.valid?("abc")
    refute Ace::Idea::Atoms::IdeaIdFormatter.valid?("8pp.t.q7w")
  end

  def test_generates_different_ids_for_different_times
    t1 = Time.utc(2026, 1, 1, 0, 0, 0)
    t2 = Time.utc(2026, 1, 1, 0, 0, 10)
    id1 = Ace::Idea::Atoms::IdeaIdFormatter.generate(t1)
    id2 = Ace::Idea::Atoms::IdeaIdFormatter.generate(t2)
    refute_equal id1, id2
  end

  def test_decode_time_returns_time
    t = Time.utc(2026, 2, 28, 12, 0, 0)
    id = Ace::Idea::Atoms::IdeaIdFormatter.generate(t)
    decoded = Ace::Idea::Atoms::IdeaIdFormatter.decode_time(id)
    # Allow for 2-second resolution
    assert_in_delta t.to_i, decoded.to_i, 2
  end
end
