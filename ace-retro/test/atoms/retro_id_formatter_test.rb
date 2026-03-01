# frozen_string_literal: true

require "test_helper"

class RetroIdFormatterTest < AceRetroTestCase
  def test_generates_6char_id
    id = Ace::Retro::Atoms::RetroIdFormatter.generate
    assert_equal 6, id.length
  end

  def test_generates_lowercase_base36
    id = Ace::Retro::Atoms::RetroIdFormatter.generate
    assert_match(/\A[0-9a-z]{6}\z/, id)
  end

  def test_no_type_marker_in_id
    id = Ace::Retro::Atoms::RetroIdFormatter.generate
    refute_includes id, "."
  end

  def test_valid_returns_true_for_valid_id
    id = Ace::Retro::Atoms::RetroIdFormatter.generate
    assert Ace::Retro::Atoms::RetroIdFormatter.valid?(id)
  end

  def test_valid_returns_false_for_invalid
    refute Ace::Retro::Atoms::RetroIdFormatter.valid?(nil)
    refute Ace::Retro::Atoms::RetroIdFormatter.valid?("")
  end

  def test_generates_different_ids_for_different_times
    t1 = Time.utc(2026, 1, 1, 0, 0, 0)
    t2 = Time.utc(2026, 1, 1, 0, 0, 10)
    id1 = Ace::Retro::Atoms::RetroIdFormatter.generate(t1)
    id2 = Ace::Retro::Atoms::RetroIdFormatter.generate(t2)
    refute_equal id1, id2
  end

  def test_decode_time_returns_time
    t = Time.utc(2026, 2, 28, 12, 0, 0)
    id = Ace::Retro::Atoms::RetroIdFormatter.generate(t)
    decoded = Ace::Retro::Atoms::RetroIdFormatter.decode_time(id)
    assert_in_delta t.to_i, decoded.to_i, 2
  end
end
