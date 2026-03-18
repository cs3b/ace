# frozen_string_literal: true

require_relative "../test_helper"
require "fileutils"
require "tmpdir"

# Integration test for multiple bundle merging via load_multiple_inputs
# Tests that merged bundles have valid metadata and proper structure
# Addresses the code review finding about BundleMerger return types
class MultipleBundleMergeTest < AceTestCase
  def setup
    # Create a temporary directory for test presets
    @test_dir = Dir.mktmpdir
    @presets_dir = File.join(@test_dir, ".ace", "bundle", "presets")
    FileUtils.mkdir_p(@presets_dir)

    @original_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    create_test_presets
    create_test_files
  end

  def teardown
    Dir.chdir(@original_pwd)
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def create_test_presets
      File.write(
        File.join(@presets_dir, "preset1.md"),
        <<~PRESET
        ---
        description: First test preset
        bundle:
          files:
            - file1.md
          sections:
            main:
              files:
                - file1.md
        ---
        Preset 1 content
      PRESET
    )

      File.write(
        File.join(@presets_dir, "preset2.md"),
        <<~PRESET
        ---
        description: Second test preset
        bundle:
          files:
            - file2.md
          sections:
            main:
              files:
                - file2.md
        ---
        Preset 2 content
      PRESET
    )
  end

  def create_test_files
    File.write(File.join(@test_dir, "file1.md"), "Test file 1 content")
    File.write(File.join(@test_dir, "file2.md"), "Test file 2 content")
  end

  # Test that loading multiple presets produces a valid BundleData object
  # with accessible metadata field
  def test_load_multiple_presets_returns_valid_bundle_data
    result = Ace::Bundle.load_multiple_presets(%w[preset1 preset2])

    # Should be a BundleData object
    assert_instance_of Ace::Bundle::Models::BundleData, result

    # Metadata should be accessible (this would fail if result was a Hash)
    assert_respond_to result, :metadata
    assert_instance_of Hash, result.metadata

    # Should have metadata from merge operation
    assert result.metadata.key?(:preset_content) || result.metadata.key?(:merged),
           "Should have merge metadata"
  end

  # Test that metadata can be modified after merge
  def test_merged_bundle_metadata_can_be_modified
    result = Ace::Bundle.load_multiple_presets(%w[preset1 preset2])

    # This is the critical test: metadata should be a writable Hash
    # If merge_bundles returned a non-Hash object without []= method, it would fail
    result.metadata[:test_key] = "test_value"
    result.metadata[:warnings] ||= []
    result.metadata[:warnings] << "Test warning"

    assert_equal "test_value", result.metadata[:test_key]
    assert_includes result.metadata[:warnings], "Test warning"
  end

  # Test that metadata hash is properly initialized and accessible
  def test_metadata_hash_is_accessible
    result = Ace::Bundle.load_multiple_presets(%w[preset1])

    # Metadata should be a Hash that responds to standard methods
    assert_kind_of Hash, result.metadata
    assert_respond_to result.metadata, :[]
    assert_respond_to result.metadata, :[]=
    assert_respond_to result.metadata, :key?
    assert_respond_to result.metadata, :fetch
  end

  # Test edge case: single preset should still return BundleData
  def test_single_preset_returns_valid_bundle_data
    result = Ace::Bundle.load_multiple_presets(%w[preset1])

    assert_instance_of Ace::Bundle::Models::BundleData, result
    assert_respond_to result, :metadata
  end

  # Test edge case: empty inputs should not crash
  def test_empty_inputs_returns_empty_bundle_data
    result = Ace::Bundle.load_multiple_presets([])

    assert_instance_of Ace::Bundle::Models::BundleData, result
    assert_respond_to result, :metadata
  end
end
