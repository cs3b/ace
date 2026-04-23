# frozen_string_literal: true

require_relative "../../test_helper"

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
      "backend" => "asciinema",
      "playback_speed" => "4x",
      "output" => "docs/demo/example.gif",
      "format" => "gif",
      "agg_font_family" => "Hack Nerd Font Mono"
    )

    settings = parsed["settings"]
    assert_equal "asciinema", settings["backend"]
    assert_equal "4x", settings["playback_speed"]
    assert_equal "docs/demo/example.gif", settings["output"]
    assert_equal "gif", settings["format"]
    assert_equal "Hack Nerd Font Mono", settings["agg_font_family"]
  end

  def test_accepts_verify_block
    parsed = Ace::Demo::Atoms::DemoYamlParser.parse_hash(
      {
        "description" => "demo",
        "verify" => {
          "allow_nonzero_exit" => true,
          "require_vars" => ["DEMO_ISSUE_NUMBER"],
          "require_output" => ["work-fs"],
          "require_output_sequence" => ["work", "work-fs"],
          "forbid_output" => ["GitHub sync warning"],
          "assert_commands" => ['test "$DEMO_ISSUE_NUMBER" = "123"']
        },
        "scenes" => [
          {"name" => "main", "commands" => [{"type" => "echo hi", "sleep" => "1s"}]}
        ]
      },
      source_path: "demo.tape.yml"
    )

    assert_equal true, parsed["verify"]["allow_nonzero_exit"]
    assert_equal ["DEMO_ISSUE_NUMBER"], parsed["verify"]["require_vars"]
    assert_equal ["work-fs"], parsed["verify"]["require_output"]
    assert_equal ["work", "work-fs"], parsed["verify"]["require_output_sequence"]
    assert_equal ["GitHub sync warning"], parsed["verify"]["forbid_output"]
    assert_equal ['test "$DEMO_ISSUE_NUMBER" = "123"'], parsed["verify"]["assert_commands"]
  end

  def test_rejects_non_boolean_verify_allow_nonzero_exit
    error = assert_raises(Ace::Demo::DemoYamlParseError) do
      Ace::Demo::Atoms::DemoYamlParser.parse_hash(
        {
          "description" => "demo",
          "verify" => {"allow_nonzero_exit" => "yes"},
          "scenes" => [
            {"name" => "main", "commands" => [{"type" => "echo hi", "sleep" => "1s"}]}
          ]
        },
        source_path: "demo.tape.yml"
      )
    end

    assert_includes error.message, "verify.allow_nonzero_exit must be a boolean"
  end

  def test_rejects_non_array_verify_require_vars
    error = assert_raises(Ace::Demo::DemoYamlParseError) do
      Ace::Demo::Atoms::DemoYamlParser.parse_hash(
        {
          "description" => "demo",
          "verify" => {"require_vars" => "DEMO_ISSUE_NUMBER"},
          "scenes" => [
            {"name" => "main", "commands" => [{"type" => "echo hi", "sleep" => "1s"}]}
          ]
        },
        source_path: "demo.tape.yml"
      )
    end

    assert_includes error.message, "verify.require_vars must be an array"
  end

  def test_rejects_unknown_backend
    error = assert_raises(Ace::Demo::DemoYamlParseError) do
      parse_hash("backend" => "foo")
    end

    assert_includes error.message, "Unknown backend 'foo'"
    assert_includes error.message, "Valid: asciinema, vhs"
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

  def test_accepts_tmux_commands_alongside_type_commands
    parsed = Ace::Demo::Atoms::DemoYamlParser.parse_hash(
      {
        "description" => "demo",
        "scenes" => [
          {
            "name" => "main",
            "commands" => [
              {"type" => "echo hi", "sleep" => "1s"},
              {"tmux" => {"action" => "wait", "for" => "window-active", "session" => "fork-demo", "window" => "work"}},
              {"tmux" => {"action" => "send", "pane" => "fork-demo:work.0", "key" => "Enter"}}
            ]
          }
        ]
      },
      source_path: "demo.tape.yml"
    )

    assert_equal "echo hi", parsed["scenes"][0]["commands"][0]["type"]
    assert_equal "wait", parsed["scenes"][0]["commands"][1]["tmux"]["action"]
    assert_equal "Enter", parsed["scenes"][0]["commands"][2]["tmux"]["key"]
  end

  def test_rejects_tmux_send_without_exactly_one_command_or_key
    error = assert_raises(Ace::Demo::DemoYamlParseError) do
      Ace::Demo::Atoms::DemoYamlParser.parse_hash(
        {
          "description" => "demo",
          "scenes" => [
            {
              "commands" => [
                {"tmux" => {"action" => "send", "pane" => "fork-demo:work.0"}}
              ]
            }
          ]
        },
        source_path: "demo.tape.yml"
      )
    end

    assert_includes error.message, "tmux send must define exactly one of command or key"
  end

  def test_rejects_tmux_capture_action
    error = assert_raises(Ace::Demo::DemoYamlParseError) do
      Ace::Demo::Atoms::DemoYamlParser.parse_hash(
        {
          "description" => "demo",
          "scenes" => [
            {
              "commands" => [
                {"tmux" => {"action" => "capture", "pane" => "fork-demo:work.0"}}
              ]
            }
          ]
        },
        source_path: "demo.tape.yml"
      )
    end

    assert_includes error.message, "Unknown tmux action 'capture'"
  end
end
