# frozen_string_literal: true

require_relative "../test_helper"
require "ace/bundle/molecules/preset_manager"
require "fileutils"
require "tmpdir"

class PresetCompositionTest < AceTestCase
  def setup
    # Create a temporary directory for test presets
    @test_dir = Dir.mktmpdir
    @presets_dir = File.join(@test_dir, ".ace", "bundle", "presets")
    FileUtils.mkdir_p(@presets_dir)

    # Set up test environment to use our temp directory
    @original_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    create_test_presets
    @preset_manager = Ace::Bundle::Molecules::PresetManager.new
  end

  def teardown
    Dir.chdir(@original_pwd)
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def create_test_presets
    # Create base preset
    File.write(
      File.join(@presets_dir, "base.md"),
      <<~PRESET
        ---
        description: Base preset
        bundle:
          files:
            - file1.md
            - file2.md
          commands:
            - echo "base"
        ---
        Base content
      PRESET
    )

    # Create extending preset
    File.write(
      File.join(@presets_dir, "extended.md"),
      <<~PRESET
        ---
        description: Extended preset
        bundle:
          presets:
            - base
          files:
            - file3.md
          commands:
            - echo "extended"
        ---
        Extended content
      PRESET
    )

    # Create circular preset A
    File.write(
      File.join(@presets_dir, "circular_a.md"),
      <<~PRESET
        ---
        description: Circular A
        bundle:
          presets:
            - circular_b
        ---
        Circular A
      PRESET
    )

    # Create circular preset B
    File.write(
      File.join(@presets_dir, "circular_b.md"),
      <<~PRESET
        ---
        description: Circular B
        bundle:
          presets:
            - circular_a
        ---
        Circular B
      PRESET
    )
  end

  def test_load_preset_without_composition
    result = @preset_manager.load_preset_with_composition("base")

    assert result[:success]
    assert_equal "Base preset", result[:description]
    assert_equal ["file1.md", "file2.md"], result[:bundle]["files"]
  end

  def test_load_preset_with_composition
    result = @preset_manager.load_preset_with_composition("extended")

    assert result[:success]
    assert result[:composed]
    assert_includes result[:composed_from], "base"
    assert_includes result[:composed_from], "extended"

    # Files should be merged and deduplicated
    assert_includes result[:bundle]["files"], "file1.md"
    assert_includes result[:bundle]["files"], "file2.md"
    assert_includes result[:bundle]["files"], "file3.md"

    # Commands should be merged
    assert_includes result[:bundle]["commands"], "echo \"base\""
    assert_includes result[:bundle]["commands"], "echo \"extended\""
  end

  def test_circular_dependency_detection
    result = @preset_manager.load_preset_with_composition("circular_a")

    assert_equal false, result[:success]
    assert_match(/Circular dependency/, result[:error])
  end

  def test_nonexistent_preset
    result = @preset_manager.load_preset_with_composition("nonexistent")

    assert_equal false, result[:success]
    assert_match(/not found/, result[:error])
  end

  def test_array_deduplication
    # Create preset with duplicate files
    File.write(
      File.join(@presets_dir, "with_dupes.md"),
      <<~PRESET
        ---
        description: With duplicates
        bundle:
          presets:
            - base
          files:
            - file1.md
            - file4.md
        ---
        Content
      PRESET
    )

    @preset_manager = Ace::Bundle::Molecules::PresetManager.new
    result = @preset_manager.load_preset_with_composition("with_dupes")

    assert result[:success]

    # file1.md should appear only once (from base)
    file_count = result[:bundle]["files"].count("file1.md")
    assert_equal 1, file_count

    # All unique files should be present
    assert_includes result[:bundle]["files"], "file1.md"
    assert_includes result[:bundle]["files"], "file2.md"
    assert_includes result[:bundle]["files"], "file4.md"
  end

  def test_params_extracted_to_root_level
    # Create preset with params in context.params
    File.write(
      File.join(@presets_dir, "with_params.md"),
      <<~PRESET
        ---
        description: Preset with params
        bundle:
          params:
            output: cache
            format: yaml
            timeout: 60
            max_size: 2097152
          files:
            - file1.md
        ---
        Content
      PRESET
    )

    @preset_manager = Ace::Bundle::Molecules::PresetManager.new
    result = @preset_manager.load_preset_with_composition("with_params")

    assert result[:success]

    # Params should be extracted to root level
    assert_equal "cache", result[:output]
    assert_equal "yaml", result[:format]
    assert_equal 60, result[:timeout]
    assert_equal 2097152, result[:max_size]

    # Cache should be derived from output
    assert_equal true, result[:cache]

    # Params should also be in params hash
    assert_equal "cache", result[:params]["output"]
    assert_equal 60, result[:params]["timeout"]
  end

  def test_composed_preset_params_extracted_to_root
    # Create base with params
    File.write(
      File.join(@presets_dir, "base_params.md"),
      <<~PRESET
        ---
        description: Base with params
        bundle:
          params:
            output: stdio
            timeout: 30
          files:
            - file1.md
        ---
        Base
      PRESET
    )

    # Create extending preset that overrides params
    File.write(
      File.join(@presets_dir, "extended_params.md"),
      <<~PRESET
        ---
        description: Extended with param overrides
        bundle:
          presets:
            - base_params
          params:
            output: cache
            timeout: 120
            max_size: 5242880
        ---
        Extended
      PRESET
    )

    @preset_manager = Ace::Bundle::Molecules::PresetManager.new
    result = @preset_manager.load_preset_with_composition("extended_params")

    assert result[:success]

    # Merged params should be extracted to root (last wins)
    assert_equal "cache", result[:output]
    assert_equal 120, result[:timeout]
    assert_equal 5242880, result[:max_size]
    assert_equal true, result[:cache]
  end
end
