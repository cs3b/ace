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

  def test_lists_gem_default_presets_without_local_config
    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    presets = manager.available_presets

    assert_includes presets, "code-valid"
    assert_includes presets, "code-fit"
  end

  def test_loads_gem_default_preset_without_local_config
    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    preset = manager.load_preset("code-valid")

    refute_nil preset
    assert_equal "Correctness review - does the code work correctly?", preset["description"]
    assert_equal "project", preset["bundle"]
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

    # Test that prompt_composition is passed through (ace-bundle processes it)
    assert_equal "prompt://base/system", resolved[:system_prompt]["base"]
    assert_includes resolved[:system_prompt]["focus"], "prompt://focus/quality/security"
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

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    preset = manager.load_preset("composed")
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
      bundle: "project"
    YAML

    create_test_preset("composed", <<~YAML)
      presets:
        - base1
        - base2
      description: "Composed preset"
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    preset = manager.load_preset("composed")
    assert_equal "Composed preset", preset["description"]
    assert_equal "model-1", preset["model"]
    assert_equal "project", preset["bundle"]
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
      bundle: "project"
    YAML

    create_test_preset("top", <<~YAML)
      presets:
        - middle
      description: "Top"
      output_format: "json"
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    preset = manager.load_preset("top")
    assert_equal "Top", preset["description"]
    assert_equal "base-model", preset["model"]
    assert_equal "project", preset["bundle"]
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

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    preset = manager.load_preset("composed")
    # Arrays should be concatenated and deduplicated
    expected_files = ["file1.rb", "file2.rb", "file3.rb"]
    assert_equal expected_files, preset["subject"]["files"]
  end

  def test_load_preset_with_composition_hash_deep_merge
    create_test_preset("base", <<~YAML)
      description: "Base"
      instructions:
        base: "prompt://base/system"
        bundle:
          sections:
            format:
              title: "Format"
    YAML

    create_test_preset("composed", <<~YAML)
      presets:
        - base
      description: "Composed"
      instructions:
        bundle:
          sections:
            code:
              title: "Code"
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    preset = manager.load_preset("composed")
    assert_equal "prompt://base/system", preset["instructions"]["base"]
    assert preset["instructions"]["bundle"]["sections"]["format"]
    assert preset["instructions"]["bundle"]["sections"]["code"]
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

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    preset = manager.load_preset("composed")
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

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    preset = manager.load_preset("preset_a")
    assert_nil preset
  end

  def test_load_preset_with_composition_missing_reference_error
    create_test_preset("composed", <<~YAML)
      presets:
        - nonexistent
      description: "Composed"
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    preset = manager.load_preset("composed")
    assert_nil preset
  end

  def test_load_preset_without_composition_backward_compatible
    create_test_preset("simple", <<~YAML)
      description: "Simple preset"
      model: "simple-model"
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    preset = manager.load_preset("simple")
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

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    preset1 = manager.load_preset("composed")
    preset2 = manager.load_preset("composed")

    # Should return same cached object
    assert_equal preset1.object_id, preset2.object_id
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
      :bundle => {
        :sections => [
          { :name => "code", :files => ["a.rb"] },
          { :name => "docs", :files => ["README.md"] }
        ]
      }
    }
    result = manager.send(:deep_stringify_keys, input)

    expected = {
      "bundle" => {
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

  # Security tests for path traversal prevention
  def test_load_preset_validates_path_traversal_with_dotdot
    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)

    error = assert_raises(ArgumentError) do
      manager.send(:load_preset_from_file, "../../../etc/passwd")
    end

    assert_match(/invalid preset name/i, error.message)
    assert_match(/\.\./i, error.message)
  end

  def test_load_preset_validates_absolute_path
    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)

    error = assert_raises(ArgumentError) do
      manager.send(:load_preset_from_file, "/etc/passwd")
    end

    assert_match(/invalid preset name/i, error.message)
    assert_match(/absolute path/i, error.message)
  end

  def test_load_preset_validates_backslash_traversal
    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)

    error = assert_raises(ArgumentError) do
      manager.send(:load_preset_from_file, "..\\..\\windows\\system32")
    end

    assert_match(/invalid preset name/i, error.message)
  end

  def test_load_preset_allows_valid_names
    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)

    # Create a valid preset file
    preset_dir = File.join(@test_dir, ".ace/review/presets")
    FileUtils.mkdir_p(preset_dir)
    File.write(File.join(preset_dir, "valid-preset.yml"), "description: test\n")

    # Should not raise error for valid preset name
    result = manager.send(:load_preset_from_file, "valid-preset")
    assert_instance_of Hash, result
    assert_equal "test", result["description"]
  end
end
