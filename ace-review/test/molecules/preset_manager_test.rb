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

  # deep_stringify_keys tests
  def test_deep_stringify_keys_simple_hash
    input = { a: 1, b: 2 }
    result = @manager.send(:deep_stringify_keys, input)

    assert_equal({ "a" => 1, "b" => 2 }, result)
  end

  def test_deep_stringify_keys_nested_hash
    input = { a: { b: { c: 1 } } }
    result = @manager.send(:deep_stringify_keys, input)

    assert_equal({ "a" => { "b" => { "c" => 1 } } }, result)
  end

  def test_deep_stringify_keys_hash_in_array
    input = [{ a: 1 }, { b: 2 }]
    result = @manager.send(:deep_stringify_keys, input)

    assert_equal([{ "a" => 1 }, { "b" => 2 }], result)
  end

  def test_deep_stringify_keys_mixed_keys
    input = { :symbol_key => 1, "string_key" => 2 }
    result = @manager.send(:deep_stringify_keys, input)

    assert_equal({ "symbol_key" => 1, "string_key" => 2 }, result)
  end

  def test_deep_stringify_keys_complex_nested
    input = {
      :context => {
        :sections => [
          { :name => "code", :files => ["a.rb"] },
          { :name => "docs", :files => ["README.md"] }
        ]
      }
    }
    result = @manager.send(:deep_stringify_keys, input)

    expected = {
      "context" => {
        "sections" => [
          { "name" => "code", "files" => ["a.rb"] },
          { "name" => "docs", "files" => ["README.md"] }
        ]
      }
    }
    assert_equal expected, result
  end

  def test_deep_stringify_keys_non_hash_passthrough
    assert_equal "string", @manager.send(:deep_stringify_keys, "string")
    assert_equal 123, @manager.send(:deep_stringify_keys, 123)
    assert_equal nil, @manager.send(:deep_stringify_keys, nil)
  end
end