# frozen_string_literal: true

require "test_helper"
require "yaml"

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
      presets:
        base:
          description: "Base preset"
          reviewers:
            - name: base
              providers:
                - llm:base:default-model
              prompt:
                base: "prompt://base/system"
                focus:
                  - "prompt://focus/quality/security"
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    resolved = manager.resolve_preset("base", {
      model: "override-model"
    })

    # CLI model overrides are ignored during preset resolution.
    assert_equal "default-model", resolved[:model]
    assert_equal ["default-model"], resolved[:models]
    assert_equal "Base preset", resolved[:description]

    # Test that reviewer prompt is preserved for model migration.
    reviewer = resolved[:reviewers].find { |item| item.respond_to?(:name) && item.name == "base" }
    assert reviewer, "Expected base reviewer to be resolved"
    assert_equal "prompt://base/system", reviewer.prompt["base"]
    assert_includes reviewer.prompt["focus"], "prompt://focus/quality/security"
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

  def test_resolve_preset_pipeline_loads_reviewer_providers_and_evidence_lanes
    create_test_preset("narrow", <<~YAML)
      description: "Narrow preset"
      pipeline: narrow-risk-based
    YAML

    create_test_pipeline("narrow-risk-based", <<~YAML)
      always:
        - correctness
        - contracts
      evidence:
        - lint
    YAML

    create_test_reviewer("correctness", <<~YAML)
      providers:
        - llm:fast:google:gemini-2.5-flash@ro
      focus: correctness
      weight: 1.0
    YAML
    create_test_reviewer("contracts", <<~YAML)
      providers:
        - llm:deep:codex:codex@rw
      focus: contracts
      weight: 1.0
    YAML
    create_test_reviewer("lint", <<~YAML)
      providers:
        - tool:lint
      focus: lint
      weight: 0.6
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    resolved = manager.resolve_preset("narrow")

    assert_equal "narrow-risk-based", resolved[:pipeline]
    assert_equal ["google:gemini-2.5-flash@ro", "codex:codex@rw"], resolved[:models]
    assert_equal %w[correctness contracts lint], resolved[:reviewers].map(&:name)

    lint_reviewer = resolved[:reviewers].find { |reviewer| reviewer.name == "lint" }
    assert lint_reviewer
    assert_equal "tool", lint_reviewer.provider_kind
    assert_equal "tool:lint", lint_reviewer.model
  end

  def test_resolve_preset_pipeline_raises_for_missing_reviewer_reference
    create_test_preset("narrow", <<~YAML)
      description: "Narrow preset"
      pipeline: narrow-risk-based
    YAML

    create_test_pipeline("narrow-risk-based", <<~YAML)
      always:
        - missing-reviewer
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    error = assert_raises(ArgumentError) { manager.resolve_preset("narrow") }
    assert_match(/Missing reviewer reference: missing-reviewer/, error.message)
  end

  def test_resolve_preset_pipeline_raises_for_missing_providers_list
    create_test_preset("narrow", <<~YAML)
      description: "Narrow preset"
      pipeline: narrow-risk-based
    YAML

    create_test_pipeline("narrow-risk-based", <<~YAML)
      always:
        - correctness
    YAML

    create_test_reviewer("correctness", <<~YAML)
      focus: correctness
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    error = assert_raises(ArgumentError) { manager.resolve_preset("narrow") }
    assert_match(/provider_class.*model.*providers/i, error.message)
  end

  def test_resolve_preset_pipeline_uses_safe_minimal_when_optional_lanes_do_not_match
    create_test_preset("narrow", <<~YAML)
      description: "Narrow preset"
      pipeline: optional-only
    YAML

    create_test_pipeline("optional-only", <<~YAML)
      optional:
        - reviewer: tests
          when_any_changed:
            - test/**/*.rb
      safe_minimal:
        - correctness
    YAML

    create_test_reviewer("correctness", <<~YAML)
      providers:
        - llm:fast:google:gemini-2.5-flash@ro
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    resolved = manager.resolve_preset("narrow")
    assert_equal ["correctness"], resolved[:reviewers].map(&:name)
  end

  def test_resolve_preset_pipeline_supports_phased_preset_cutover_shape
    create_test_preset("code-valid", <<~YAML)
      description: "Correctness review - does the code work correctly?"
      pipeline: phased-valid
    YAML
    create_test_preset("code-fit", <<~YAML)
      description: "Quality review - is the code well-structured and maintainable?"
      pipeline: phased-fit
    YAML
    create_test_preset("code-shine", <<~YAML)
      description: "Polish review - can we simplify and improve clarity?"
      pipeline: phased-shine
    YAML

    create_test_pipeline("phased-valid", <<~YAML)
      always:
        - correctness
        - contracts
      evidence:
        - lint
    YAML
    create_test_pipeline("phased-fit", <<~YAML)
      always:
        - architecture-fit
        - performance
        - tests
      evidence:
        - lint
    YAML
    create_test_pipeline("phased-shine", <<~YAML)
      always:
        - simplicity
        - docs-dx
      evidence:
        - lint
    YAML

    create_test_reviewer("correctness", "providers:\n  - llm:fast:google:gemini-2.5-flash@ro\n")
    create_test_reviewer("contracts", "providers:\n  - llm:deep:codex:codex@rw\n")
    create_test_reviewer("architecture-fit", "providers:\n  - llm:deep:codex:codex@rw\n")
    create_test_reviewer("performance", "providers:\n  - llm:fast:google:gemini-2.5-flash@ro\n")
    create_test_reviewer("tests", "providers:\n  - llm:fast:google:gemini-2.5-flash@ro\n")
    create_test_reviewer("simplicity", "providers:\n  - llm:fast:google:gemini-2.5-flash@ro\n")
    create_test_reviewer("docs-dx", "providers:\n  - llm:fast:google:gemini-2.5-flash@ro\n")
    create_test_reviewer("lint", "providers:\n  - tool:lint\n")

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)

    valid = manager.resolve_preset("code-valid")
    fit = manager.resolve_preset("code-fit")
    shine = manager.resolve_preset("code-shine")

    assert_equal "phased-valid", valid[:pipeline]
    assert_equal %w[correctness contracts lint], valid[:reviewers].map(&:name)

    assert_equal "phased-fit", fit[:pipeline]
    assert_equal %w[architecture-fit performance tests lint], fit[:reviewers].map(&:name)

    assert_equal "phased-shine", shine[:pipeline]
    assert_equal %w[simplicity docs-dx lint], shine[:reviewers].map(&:name)
  end

  def test_resolve_preset_rejects_legacy_top_level_model
    create_test_preset("legacy", <<~YAML)
      description: "Legacy preset"
      model: "google:gemini-2.5-flash"
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    error = assert_raises(ArgumentError) { manager.resolve_preset("legacy") }
    assert_match(/legacy top-level model\/models/i, error.message)
  end

  # Provider catalog resolution tests

  def test_resolve_preset_pipeline_expands_provider_class_via_catalog
    create_llm_catalog(<<~YAML)
      fast:
        - "codex:spark@ro"
    YAML
    create_tools_lint_catalog(<<~YAML)
      lint:
        - lint
    YAML

    create_test_preset("valid", <<~YAML)
      description: "Correctness review"
      pipeline: phased-valid
      providers:
        llm: [fast]
        tools_lint: [lint]
    YAML
    create_test_pipeline("phased-valid", <<~YAML)
      always:
        - correctness
        - contracts
      evidence:
        - lint
    YAML
    create_test_reviewer("correctness", <<~YAML)
      provider_class: llm
      focus: correctness
      weight: 1.0
    YAML
    create_test_reviewer("contracts", <<~YAML)
      provider_class: llm
      focus: contracts
      weight: 1.0
    YAML
    create_test_reviewer("lint", <<~YAML)
      provider_class: tools-lint
      focus: lint
      weight: 0.6
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    resolved = manager.resolve_preset("valid")

    assert_equal "phased-valid", resolved[:pipeline]
    reviewers = resolved[:reviewers]
    assert_equal %w[correctness contracts lint], reviewers.map(&:name)

    # LLM reviewers should be resolved with model from catalog
    llm_reviewers = reviewers.reject { |r| r.provider_kind.to_s == "tool" }
    assert llm_reviewers.all? { |r| r.model == "codex:spark@ro" }

    # Tool reviewer should be resolved
    lint_reviewer = reviewers.find { |r| r.name == "lint" }
    assert_equal "tool", lint_reviewer.provider_kind
    assert_equal "tool:lint", lint_reviewer.model
  end

  def test_resolve_preset_providers_llm_override_replaces_default
    create_llm_catalog(<<~YAML)
      fast:
        - "codex:spark@ro"
      deep:
        - "codex:codex@rw"
    YAML

    create_test_preset("valid", <<~YAML)
      description: "Correctness review"
      pipeline: simple-pipeline
      providers:
        llm: [fast]
    YAML
    create_test_pipeline("simple-pipeline", <<~YAML)
      always:
        - correctness
    YAML
    create_test_reviewer("correctness", <<~YAML)
      provider_class: llm
      focus: correctness
      weight: 1.0
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    resolved = manager.resolve_preset("valid", { providers_llm: ["deep"] })

    llm_reviewers = resolved[:reviewers].reject { |r| r.provider_kind.to_s == "tool" }
    assert llm_reviewers.all? { |r| r.model == "codex:codex@rw" }
  end

  def test_resolve_preset_providers_llm_inline_model_id_override
    create_llm_catalog("fast:\n  - \"codex:spark@ro\"\n")

    create_test_preset("valid", <<~YAML)
      description: "Review"
      pipeline: simple-pipeline
      providers:
        llm: [fast]
    YAML
    create_test_pipeline("simple-pipeline", <<~YAML)
      always:
        - correctness
    YAML
    create_test_reviewer("correctness", <<~YAML)
      provider_class: llm
      focus: correctness
      weight: 1.0
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    resolved = manager.resolve_preset("valid", { providers_llm: ["google:gemini-2.5-flash@custom"] })

    llm_reviewers = resolved[:reviewers].reject { |r| r.provider_kind.to_s == "tool" }
    assert llm_reviewers.all? { |r| r.model == "google:gemini-2.5-flash@custom" }
  end

  # Task 3: Deduplication rule

  def test_resolve_preset_deduplicates_reviewers_when_optional_matches_always
    create_llm_catalog("fast:\n  - \"codex:spark@ro\"\n")

    create_test_preset("valid", <<~YAML)
      description: "Review"
      pipeline: dedup-pipeline
      providers:
        llm: [fast]
    YAML
    # Pipeline has correctness in always AND in optional — should run only once
    create_test_pipeline("dedup-pipeline", <<~YAML)
      always:
        - correctness
      optional:
        - correctness
    YAML
    create_test_reviewer("correctness", <<~YAML)
      provider_class: llm
      focus: correctness
      weight: 1.0
    YAML

    manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
    resolved = manager.resolve_preset("valid")

    # Correctness should appear exactly once, not twice
    correctness_count = resolved[:reviewers].count { |r| r.name == "correctness" }
    assert_equal 1, correctness_count, "Expected correctness reviewer to run only once, not #{correctness_count} times"
  end

  private

  def create_test_reviewer(name, content)
    FileUtils.mkdir_p(".ace/review/reviewers")
    file_path = File.join(".ace/review/reviewers", "#{name}.yml")
    parsed_content = begin
      YAML.safe_load(content) || {}
    rescue StandardError
      {}
    end

    if parsed_content.is_a?(Hash) && !parsed_content.key?("prompt")
      parsed_content["prompt"] ||= {
        "base" => "prompt://base/system"
      }
      File.write(file_path, YAML.dump(parsed_content))
    else
      File.write(file_path, content)
    end
  end

  def create_test_pipeline(name, content)
    FileUtils.mkdir_p(".ace/review/pipelines")
    File.write(".ace/review/pipelines/#{name}.yml", content)
  end

  def create_llm_catalog(content)
    FileUtils.mkdir_p(".ace/review/providers")
    File.write(".ace/review/providers/llm.yml", content)
  end

  def create_tools_lint_catalog(content)
    FileUtils.mkdir_p(".ace/review/providers")
    File.write(".ace/review/providers/tools-lint.yml", content)
  end
end
