# frozen_string_literal: true

require_relative "../test_helper"

class PlaybackSpeedParserTest < AceDemoTestCase
  def test_parses_supported_speed
    parsed = Ace::Demo::Atoms::PlaybackSpeedParser.parse("4x")
    assert_equal "4x", parsed[:label]
    assert_equal 4.0, parsed[:factor]
  end

  def test_returns_nil_for_nil_or_empty
    assert_nil Ace::Demo::Atoms::PlaybackSpeedParser.parse(nil)
    assert_nil Ace::Demo::Atoms::PlaybackSpeedParser.parse("  ")
  end

  def test_rejects_invalid_speed
    error = assert_raises(ArgumentError) do
      Ace::Demo::Atoms::PlaybackSpeedParser.parse("3x")
    end
    assert_includes error.message, "Invalid playback speed"
  end
end
