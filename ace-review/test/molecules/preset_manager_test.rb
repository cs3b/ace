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

  # Composition tests
  def test_load_preset_with_composition_single_reference
    create_test_preset("base", <<~YAML)
      description: "Base preset"
      model: "base-model"
      instructions:
        base: "prompt://base/system"
    YAML

    create_test_preset("composed", <<~YAML)
      presets:
        - base
      description: "Composed preset"
      subject:
        files:
          - "test.rb"
    YAML

    preset = @manager.load_preset("composed")
    assert_equal "Composed preset", preset["description"]
    assert_equal "base-model", preset["model"]
    assert_equal "prompt://base/system", preset["instructions"]["base"]
    assert_equal ["test.rb"], preset["subject"]["files"]
  end

  def test_load_preset_with_composition_multiple_references
    create_test_preset("base1", <<~YAML)
      description: "Base 1"
      model: "model-1"
    YAML

    create_test_preset("base2", <<~YAML)
      description: "Base 2"
      context: "project"
    YAML

    create_test_preset("composed", <<~YAML)
      presets:
        - base1
        - base2
      description: "Composed preset"
    YAML

    preset = @manager.load_preset("composed")
    assert_equal "Composed preset", preset["description"]
    assert_equal "model-1", preset["model"]
    assert_equal "project", preset["context"]
  end

  def test_load_preset_with_composition_multi_level
    create_test_preset("base", <<~YAML)
      description: "Base"
      model: "base-model"
    YAML

    create_test_preset("middle", <<~YAML)
      presets:
        - base
      description: "Middle"
      context: "project"
    YAML

    create_test_preset("top", <<~YAML)
      presets:
        - middle
      description: "Top"
      output_format: "json"
    YAML

    preset = @manager.load_preset("top")
    assert_equal "Top", preset["description"]
    assert_equal "base-model", preset["model"]
    assert_equal "project", preset["context"]
    assert_equal "json", preset["output_format"]
  end

  def test_load_preset_with_composition_array_merging
    create_test_preset("base", <<~YAML)
      description: "Base"
      subject:
        files:
          - "file1.rb"
          - "file2.rb"
    YAML

    create_test_preset("composed", <<~YAML)
      presets:
        - base
      description: "Composed"
      subject:
        files:
          - "file2.rb"
          - "file3.rb"
    YAML

    preset = @manager.load_preset("composed")
    # Arrays should be concatenated and deduplicated
    expected_files = ["file1.rb", "file2.rb", "file3.rb"]
    assert_equal expected_files, preset["subject"]["files"]
  end

  def test_load_preset_with_composition_hash_deep_merge
    create_test_preset("base", <<~YAML)
      description: "Base"
      instructions:
        base: "prompt://base/system"
        context:
          sections:
            format:
              title: "Format"
    YAML

    create_test_preset("composed", <<~YAML)
      presets:
        - base
      description: "Composed"
      instructions:
        context:
          sections:
            code:
              title: "Code"
    YAML

    preset = @manager.load_preset("composed")
    assert_equal "prompt://base/system", preset["instructions"]["base"]
    assert preset["instructions"]["context"]["sections"]["format"]
    assert preset["instructions"]["context"]["sections"]["code"]
  end

  def test_load_preset_with_composition_scalar_last_wins
    create_test_preset("base", <<~YAML)
      description: "Base description"
      model: "base-model"
    YAML

    create_test_preset("composed", <<~YAML)
      presets:
        - base
      description: "Composed description"
      output_format: "json"
    YAML

    preset = @manager.load_preset("composed")
    assert_equal "Composed description", preset["description"]
    assert_equal "base-model", preset["model"]
    assert_equal "json", preset["output_format"]
  end

  def test_load_preset_with_composition_circular_dependency_error
    create_test_preset("preset_a", <<~YAML)
      presets:
        - preset_b
      description: "Preset A"
    YAML

    create_test_preset("preset_b", <<~YAML)
      presets:
        - preset_a
      description: "Preset B"
    YAML

    preset = @manager.load_preset("preset_a")
    assert_nil preset
  end

  def test_load_preset_with_composition_missing_reference_error
    create_test_preset("composed", <<~YAML)
      presets:
        - nonexistent
      description: "Composed"
    YAML

    preset = @manager.load_preset("composed")
    assert_nil preset
  end

  def test_load_preset_without_composition_backward_compatible
    create_test_preset("simple", <<~YAML)
      description: "Simple preset"
      model: "simple-model"
    YAML

    preset = @manager.load_preset("simple")
    assert_equal "Simple preset", preset["description"]
    assert_equal "simple-model", preset["model"]
  end

  def test_load_preset_with_composition_caches_result
    create_test_preset("base", <<~YAML)
      description: "Base"
      model: "base-model"
    YAML

    create_test_preset("composed", <<~YAML)
      presets:
        - base
      description: "Composed"
    YAML

    preset1 = @manager.load_preset("composed")
    preset2 = @manager.load_preset("composed")

    # Should return same cached object
    assert_equal preset1.object_id, preset2.object_id
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