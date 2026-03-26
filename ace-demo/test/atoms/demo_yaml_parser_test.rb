# frozen_string_literal: true

require_relative "../test_helper"

class DemoYamlParserTest < AceDemoTestCase
  def parse_hash(settings)
    Ace::Demo::Atoms::DemoYamlParser.parse_hash(
      {
        "description" => "demo",
        "settings" => settings,
        "scenes" => [
          {"name" => "main", "commands" => [{"type" => "echo hi", "sleep" => "1s"}]}
        ]
      },
      source_path: "demo.tape.yml"
    )
  end

  def test_accepts_playback_speed_and_output_settings
    parsed = parse_hash(
      "playback_speed" => "4x",
      "output" => "docs/demo/example.gif",
      "format" => "gif"
    )

    settings = parsed["settings"]
    assert_equal "4x", settings["playback_speed"]
    assert_equal "docs/demo/example.gif", settings["output"]
    assert_equal "gif", settings["format"]
  end

  def test_coerces_output_setting_to_string
    parsed = parse_hash(
      "output" => 123,
      "format" => "gif"
    )

    assert_equal "123", parsed["settings"]["output"]
  end

  def test_rejects_blank_output_setting
    error = assert_raises(Ace::Demo::DemoYamlParseError) do
      parse_hash(
        "output" => "   ",
        "format" => "gif"
      )
    end

    assert_includes error.message, "settings.output must be a non-empty path"
  end

  def test_rejects_invalid_playback_speed
    error = assert_raises(Ace::Demo::DemoYamlParseError) do
      parse_hash("playback_speed" => "3x")
    end

    assert_includes error.message, "Invalid playback speed"
    assert_includes error.message, "Use one of: 1x, 2x, 4x, 8x"
  end
end
