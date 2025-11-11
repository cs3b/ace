# frozen_string_literal: true

require "test_helper"

class PresetCompositionIntegrationTest < AceReviewTest
  def setup
    super
    @manager = Ace::Review::Molecules::PresetManager.new(project_root: @test_dir)
  end

  def test_code_pr_preset_composition
    # Create the base code preset
    create_test_preset("code", <<~YAML)
      description: "Base code review configuration"
      instructions:
        description: "Code review instructions"
        context:
          base: "prompt://base/system"
          sections:
            review_focus:
              title: "Files Under Review"
              files:
                - "prompt://focus/scope/tests"
                - "prompt://focus/languages/ruby"
            format_guidelines:
              title: "Format Guidelines"
              files:
                - "prompt://format/detailed"
      model: gpro
    YAML

    # Create the composed code-pr preset
    create_test_preset("code-pr", <<~YAML)
      presets:
        - code
      description: "Pull request review - comprehensive code changes review"
      subject:
        context:
          sections:
            code_changes:
              title: "Code Changes"
              description: "Code changes to review from pull request"
              diffs:
                - "origin...HEAD"
    YAML

    # Load the composed preset
    preset = @manager.load_preset("code-pr")

    # Verify composition worked correctly
    refute_nil preset, "Composed preset should load successfully"

    # Check description was overridden (last wins)
    assert_equal "Pull request review - comprehensive code changes review", preset["description"]

    # Check model was inherited from base
    assert_equal "gpro", preset["model"]

    # Check instructions were inherited
    assert preset["instructions"]
    assert_equal "Code review instructions", preset["instructions"]["description"]
    assert_equal "prompt://base/system", preset["instructions"]["context"]["base"]

    # Check sections were merged
    assert preset["instructions"]["context"]["sections"]["review_focus"]
    assert preset["instructions"]["context"]["sections"]["format_guidelines"]

    # Check subject was added by composed preset
    assert preset["subject"]
    assert preset["subject"]["context"]["sections"]["code_changes"]
    assert_equal "Code Changes", preset["subject"]["context"]["sections"]["code_changes"]["title"]
    assert_equal ["origin...HEAD"], preset["subject"]["context"]["sections"]["code_changes"]["diffs"]
  end

  def test_multi_level_composition_with_array_merging
    # Create base preset
    create_test_preset("base", <<~YAML)
      description: "Base"
      instructions:
        context:
          sections:
            base_section:
              files:
                - "base_file_1.md"
                - "base_file_2.md"
    YAML

    # Create middle preset that extends base
    create_test_preset("middle", <<~YAML)
      presets:
        - base
      description: "Middle"
      instructions:
        context:
          sections:
            base_section:
              files:
                - "base_file_2.md"
                - "middle_file.md"
            middle_section:
              files:
                - "middle_only.md"
    YAML

    # Create top preset that extends middle
    create_test_preset("top", <<~YAML)
      presets:
        - middle
      description: "Top"
      instructions:
        context:
          sections:
            base_section:
              files:
                - "top_file.md"
    YAML

    preset = @manager.load_preset("top")

    # Verify multi-level composition
    refute_nil preset
    assert_equal "Top", preset["description"]

    # Verify array deduplication across all levels
    base_section_files = preset["instructions"]["context"]["sections"]["base_section"]["files"]
    assert_equal ["base_file_1.md", "base_file_2.md", "middle_file.md", "top_file.md"], base_section_files

    # Verify middle-level section was preserved
    assert preset["instructions"]["context"]["sections"]["middle_section"]
    assert_equal ["middle_only.md"], preset["instructions"]["context"]["sections"]["middle_section"]["files"]
  end

  def test_circular_dependency_detection_with_real_presets
    # Create circular dependency: A -> B -> A
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

    # Attempt to load should return nil (error handled gracefully)
    preset = @manager.load_preset("preset_a")
    assert_nil preset, "Circular dependency should prevent preset loading"
  end

  def test_missing_reference_error_handling
    create_test_preset("broken", <<~YAML)
      presets:
        - nonexistent_base
      description: "Broken composition"
    YAML

    preset = @manager.load_preset("broken")
    assert_nil preset, "Missing reference should prevent preset loading"
  end

  def test_deep_nesting_within_limit
    # Create a chain of 5 presets (well within MAX_DEPTH=10)
    create_test_preset("level_1", <<~YAML)
      description: "Level 1"
      model: "base-model"
    YAML

    (2..5).each do |i|
      create_test_preset("level_#{i}", <<~YAML)
        presets:
          - level_#{i-1}
        description: "Level #{i}"
        context_#{i}: "data_#{i}"
      YAML
    end

    preset = @manager.load_preset("level_5")

    refute_nil preset, "Deep nesting within limit should work"
    assert_equal "Level 5", preset["description"]
    assert_equal "base-model", preset["model"]

    # Verify all context fields were merged
    (2..5).each do |i|
      assert_equal "data_#{i}", preset["context_#{i}"]
    end
  end

  def test_caching_prevents_redundant_composition
    create_test_preset("base", <<~YAML)
      description: "Base"
      model: "test-model"
    YAML

    create_test_preset("composed", <<~YAML)
      presets:
        - base
      description: "Composed"
    YAML

    # Load twice
    preset1 = @manager.load_preset("composed")
    preset2 = @manager.load_preset("composed")

    # Should return same cached object
    assert_equal preset1.object_id, preset2.object_id, "Cache should return same object"
  end

  def test_composition_with_empty_presets_array
    create_test_preset("empty_refs", <<~YAML)
      presets: []
      description: "No references"
      model: "test-model"
    YAML

    preset = @manager.load_preset("empty_refs")

    refute_nil preset
    assert_equal "No references", preset["description"]
    assert_equal "test-model", preset["model"]
  end
end
