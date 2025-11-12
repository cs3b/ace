# frozen_string_literal: true

require "test_helper"

class PresetManagerTest < AceReviewTest
  def setup
    super
    # Don't create @manager here - let each test create it after setting up config
  end

  def test_loads_preset_from_config
    create_test_config(<<~YAML)
      presets:
        my_preset:
          description: "Test preset"
          model: "test-model"
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    preset = manager.load_preset("my_preset")
    assert_equal "Test preset", preset["description"]
    assert_equal "test-model", preset["model"]
  end

  def test_loads_preset_from_file
    create_test_preset("file_preset", <<~YAML)
      description: "File-based preset"
      model: "file-model"
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    preset = manager.load_preset("file_preset")
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

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    preset = manager.load_preset("override")
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

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    presets = manager.available_presets
    assert_includes presets, "config_preset"
    assert_includes presets, "file_preset"
  end

  def test_preset_exists_check
    create_test_config(<<~YAML)
      presets:
        existing:
          description: "Exists"
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    assert manager.preset_exists?("existing")
    refute manager.preset_exists?("nonexistent")
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

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    resolved = manager.resolve_preset("base", {
      model: "override-model"
    })

    # Test that basic overrides work
    assert_equal "override-model", resolved[:model]
    assert_equal "Base preset", resolved[:description]

    # Test that prompt_composition is passed through (ace-context processes it)
    assert_equal "prompt://base/system", resolved[:system_prompt]["base"]
    assert_includes resolved[:system_prompt]["focus"], "prompt://focus/quality/security"
  end

  # deep_stringify_keys tests
  def test_deep_stringify_keys_simple_hash
    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    input = { a: 1, b: 2 }
    result = manager.send(:deep_stringify_keys, input)

    assert_equal({ "a" => 1, "b" => 2 }, result)
  end

  def test_deep_stringify_keys_nested_hash
    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    input = { a: { b: { c: 1 } } }
    result = manager.send(:deep_stringify_keys, input)

    assert_equal({ "a" => { "b" => { "c" => 1 } } }, result)
  end

  def test_deep_stringify_keys_hash_in_array
    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    input = [{ a: 1 }, { b: 2 }]
    result = manager.send(:deep_stringify_keys, input)

    assert_equal([{ "a" => 1 }, { "b" => 2 }], result)
  end

  def test_deep_stringify_keys_mixed_keys
    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    input = { :symbol_key => 1, "string_key" => 2 }
    result = manager.send(:deep_stringify_keys, input)

    assert_equal({ "symbol_key" => 1, "string_key" => 2 }, result)
  end

  def test_deep_stringify_keys_complex_nested
    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    input = {
      :context => {
        :sections => [
          { :name => "code", :files => ["a.rb"] },
          { :name => "docs", :files => ["README.md"] }
        ]
      }
    }
    result = manager.send(:deep_stringify_keys, input)

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
    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    assert_equal "string", manager.send(:deep_stringify_keys, "string")
    assert_equal 123, manager.send(:deep_stringify_keys, 123)
    assert_equal nil, manager.send(:deep_stringify_keys, nil)
  end
end