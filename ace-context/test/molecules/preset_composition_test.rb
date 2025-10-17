# frozen_string_literal: true

require_relative "../test_helper"
require "ace/context/molecules/preset_manager"
require "fileutils"
require "tmpdir"

class PresetCompositionTest < AceTestCase
  def setup
    # Create a temporary directory for test presets
    @test_dir = Dir.mktmpdir
    @presets_dir = File.join(@test_dir, ".ace", "context", "presets")
    FileUtils.mkdir_p(@presets_dir)

    # Set up test environment to use our temp directory
    @original_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    create_test_presets
    @preset_manager = Ace::Context::Molecules::PresetManager.new
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
        context:
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
        context:
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
        context:
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
        context:
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
    assert_equal ["file1.md", "file2.md"], result[:context]["files"]
  end

  def test_load_preset_with_composition
    result = @preset_manager.load_preset_with_composition("extended")

    assert result[:success]
    assert result[:composed]
    assert_includes result[:composed_from], "base"
    assert_includes result[:composed_from], "extended"

    # Files should be merged and deduplicated
    assert_includes result[:context]["files"], "file1.md"
    assert_includes result[:context]["files"], "file2.md"
    assert_includes result[:context]["files"], "file3.md"

    # Commands should be merged
    assert_includes result[:context]["commands"], "echo \"base\""
    assert_includes result[:context]["commands"], "echo \"extended\""
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
        context:
          presets:
            - base
          files:
            - file1.md
            - file4.md
        ---
        Content
      PRESET
    )

    @preset_manager = Ace::Context::Molecules::PresetManager.new
    result = @preset_manager.load_preset_with_composition("with_dupes")

    assert result[:success]

    # file1.md should appear only once (from base)
    file_count = result[:context]["files"].count("file1.md")
    assert_equal 1, file_count

    # All unique files should be present
    assert_includes result[:context]["files"], "file1.md"
    assert_includes result[:context]["files"], "file2.md"
    assert_includes result[:context]["files"], "file4.md"
  end
end
