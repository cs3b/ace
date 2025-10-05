# frozen_string_literal: true

require "test_helper"

class PresetManagerTest < AceReviewTest
  def setup
    super
    @manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
  end

  def test_loads_preset_from_config
    create_test_config(<<~YAML)
      presets:
        my_preset:
          description: "Test preset"
          model: "test-model"
    YAML

    preset = @manager.load_preset("my_preset")
    assert_equal "Test preset", preset["description"]
    assert_equal "test-model", preset["model"]
  end

  def test_loads_preset_from_file
    create_test_preset("file_preset", <<~YAML)
      description: "File-based preset"
      model: "file-model"
    YAML

    preset = @manager.load_preset("file_preset")
    assert_equal "File-based preset", preset["description"]
    assert_equal "file-model", preset["model"]
  end

  def test_file_preset_overrides_config_preset
    create_test_config(<<~YAML)
      presets:
        override:
          description: "Config version"
          model: "config-model"
    YAML

    create_test_preset("override", <<~YAML)
      description: "File version"
      model: "file-model"
    YAML

    preset = @manager.load_preset("override")
    assert_equal "File version", preset["description"]
    assert_equal "file-model", preset["model"]
  end

  def test_lists_available_presets
    create_test_config(<<~YAML)
      presets:
        config_preset:
          description: "From config"
    YAML

    create_test_preset("file_preset", <<~YAML)
      description: "From file"
    YAML

    presets = @manager.available_presets
    assert_includes presets, "config_preset"
    assert_includes presets, "file_preset"
  end

  def test_preset_exists_check
    create_test_config(<<~YAML)
      presets:
        existing:
          description: "Exists"
    YAML

    assert @manager.preset_exists?("existing")
    refute @manager.preset_exists?("nonexistent")
  end

  def test_resolves_preset_with_overrides
    create_test_config(<<~YAML)
      defaults:
        model: "default-model"
      presets:
        base:
          description: "Base preset"
          prompt_composition:
            base: "prompt://base/system"
            focus:
              - "prompt://focus/quality/security"
    YAML

    resolved = @manager.resolve_preset("base", {
      model: "override-model",
      add_focus: "quality/performance"
    })

    assert_equal "override-model", resolved[:model]
    assert_includes resolved[:prompt_composition]["focus"], "prompt://focus/quality/security"
    assert_includes resolved[:prompt_composition]["focus"], "quality/performance"
  end
end