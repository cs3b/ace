# frozen_string_literal: true

require_relative "../../test_helper"

class PresetLoaderTest < AceAssignTestCase
  def test_load_returns_hash_for_existing_preset
    preset = Ace::Assign::Atoms::PresetLoader.load("work-on-task")

    assert_kind_of Hash, preset
    assert_kind_of Array, preset["steps"]
    assert_kind_of Hash, preset["expansion"]
  end

  def test_load_raises_for_missing_preset
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Assign::Atoms::PresetLoader.load("missing-preset-name")
    end

    assert_includes error.message, "not found"
  end

  def test_load_rejects_invalid_preset_name_characters
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Assign::Atoms::PresetLoader.load("../../../etc/passwd")
    end

    assert_includes error.message, "Invalid preset name"
  end
end
