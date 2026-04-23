# frozen_string_literal: true

require_relative "../../test_helper"

class RecordOptionValidatorTest < AceDemoTestCase
  def test_normalize_backend_accepts_known_values
    assert_equal "vhs", Ace::Demo::Atoms::RecordOptionValidator.normalize_backend("VHS")
    assert_equal "asciinema", Ace::Demo::Atoms::RecordOptionValidator.normalize_backend("asciinema")
    assert_nil Ace::Demo::Atoms::RecordOptionValidator.normalize_backend(nil)
  end

  def test_normalize_backend_rejects_unknown_values
    error = assert_raises(ArgumentError) do
      Ace::Demo::Atoms::RecordOptionValidator.normalize_backend("foo")
    end

    assert_includes error.message, "Unknown backend"
  end

  def test_normalize_format_rejects_mp4_with_guidance
    error = assert_raises(ArgumentError) do
      Ace::Demo::Atoms::RecordOptionValidator.normalize_format(
        "mp4",
        supported_formats: %w[gif webm],
        allow_nil: false
      )
    end

    assert_includes error.message, "Unsupported format: mp4"
    assert_includes error.message, "--backend vhs --format webm"
  end

  def test_validate_yaml_backend_format_rejects_webm_without_vhs
    error = assert_raises(ArgumentError) do
      Ace::Demo::Atoms::RecordOptionValidator.validate_yaml_backend_format!(backend: "asciinema", format: "webm")
    end

    assert_includes error.message, "requires --backend vhs"
  end

  def test_validate_yaml_backend_capabilities_rejects_tmux_directives_for_vhs
    spec = {
      "scenes" => [
        {
          "commands" => [
            {"tmux" => {"action" => "wait", "for" => "window-active", "session" => "fork-demo", "window" => "work"}}
          ]
        }
      ]
    }

    error = assert_raises(ArgumentError) do
      Ace::Demo::Atoms::RecordOptionValidator.validate_yaml_backend_capabilities!(backend: "vhs", spec: spec)
    end

    assert_includes error.message, "does not support tmux directives"
    assert_includes error.message, "backend 'asciinema'"
  end

  def test_validate_yaml_backend_capabilities_allows_tmux_directives_for_asciinema
    spec = {
      "scenes" => [
        {
          "commands" => [
            {"tmux" => {"action" => "wait", "for" => "window-active", "session" => "fork-demo", "window" => "work"}}
          ]
        }
      ]
    }

    Ace::Demo::Atoms::RecordOptionValidator.validate_yaml_backend_capabilities!(backend: "asciinema", spec: spec)
  end
end
