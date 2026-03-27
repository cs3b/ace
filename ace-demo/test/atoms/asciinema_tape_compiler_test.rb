# frozen_string_literal: true

require_relative "../test_helper"

class AsciinemaTapeCompilerTest < AceDemoTestCase
  def test_compiles_multi_scene_script_with_defaults
    spec = {
      "settings" => {"env" => {"PROJECT_ROOT_PATH" => "/tmp/sandbox", "DEMO_FLAG" => "with spaces"}},
      "scenes" => [
        {
          "name" => "Setup",
          "commands" => [
            {"type" => "echo setup", "sleep" => "1s"}
          ]
        },
        {
          "name" => "Run",
          "commands" => [
            {"type" => "echo \"$HOME\" && printf 'hi\\\\n'"}
          ]
        }
      ]
    }

    script = Ace::Demo::Atoms::AsciinemaTapeCompiler.compile(spec: spec, default_timeout: "3s")

    assert_includes script, "#!/usr/bin/env bash"
    assert_includes script, "set -euo pipefail"
    assert_includes script, "export PROJECT_ROOT_PATH=/tmp/sandbox"
    assert_includes script, "export DEMO_FLAG=with\\ spaces"
    assert_includes script, "# Scene: Setup"
    assert_includes script, "echo setup"
    assert_includes script, "sleep 1s"
    assert_includes script, "# Scene: Run"
    assert_includes script, "echo \"$HOME\" && printf 'hi\\\\n'"
    assert_includes script, "sleep 3s"
    assert script.end_with?("\n"), "compiled script should end with newline"
  end

  def test_rejects_invalid_sleep_value
    spec = {
      "scenes" => [
        {
          "commands" => [
            {"type" => "echo setup", "sleep" => "1; rm -rf /"}
          ]
        }
      ]
    }

    error = assert_raises(ArgumentError) do
      Ace::Demo::Atoms::AsciinemaTapeCompiler.compile(spec: spec)
    end

    assert_includes error.message, "sleep must be a numeric duration"
  end
end
