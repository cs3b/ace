# frozen_string_literal: true

require_relative "../../test_helper"

class BundleMergerTest < AceTestCase
  def setup
    @merger = Ace::Bundle::Molecules::BundleMerger.new
  end

  # --- merge_bundles tests ---

  def test_merge_bundles_returns_empty_result_for_nil
    result = @merger.merge_bundles(nil)
    assert_equal true, result[:success]
    assert_equal [], result[:files]
    assert_equal false, result[:merged]
    assert_equal 0, result[:total_bundles]
  end

  def test_merge_bundles_returns_empty_result_for_empty_array
    bundles = []
    result = @merger.merge_bundles(bundles)
    assert_equal true, result[:success]
    assert_equal [], result[:files]
    assert_equal false, result[:merged]
    assert_equal 0, result[:total_bundles]
  end

  def test_merge_bundles_returns_first_for_single_bundle
    bundle = {files: [{path: "a.rb"}], commands: []}
    result = @merger.merge_bundles([bundle])
    assert_equal bundle, result
  end

  def test_merge_bundles_merges_files_from_multiple_bundles
    bundle1 = {files: [{path: "a.rb"}]}
    bundle2 = {files: [{path: "b.rb"}]}

    result = @merger.merge_bundles([bundle1, bundle2])

    assert result[:files]
    paths = result[:files].map { |f| f[:path] }
    assert_includes paths, "a.rb"
    assert_includes paths, "b.rb"
  end

  def test_merge_bundles_deduplicates_files_by_path
    bundle1 = {files: [{path: "a.rb", content: "first"}]}
    bundle2 = {files: [{path: "a.rb", content: "second"}]}

    result = @merger.merge_bundles([bundle1, bundle2])

    assert_equal 1, result[:files].size
    assert_equal "a.rb", result[:files].first[:path]
    # First bundle's file should win
    assert_equal "first", result[:files].first[:content]
  end

  def test_merge_bundles_merges_commands
    bundle1 = {commands: [{command: "echo 1"}]}
    bundle2 = {commands: [{command: "echo 2"}]}

    result = @merger.merge_bundles([bundle1, bundle2])

    assert_equal 2, result[:commands].size
  end

  def test_merge_bundles_merges_errors
    bundle1 = {errors: ["Error 1"]}
    bundle2 = {errors: ["Error 2"]}

    result = @merger.merge_bundles([bundle1, bundle2])

    assert_equal 2, result[:errors].size
    assert_includes result[:errors], "Error 1"
    assert_includes result[:errors], "Error 2"
  end

  def test_merge_bundles_deduplicates_errors
    bundle1 = {errors: ["Same error"]}
    bundle2 = {errors: ["Same error"]}

    result = @merger.merge_bundles([bundle1, bundle2])

    assert_equal 1, result[:errors].size
  end

  def test_merge_bundles_sets_merged_flag
    bundle1 = {files: []}
    bundle2 = {files: []}

    result = @merger.merge_bundles([bundle1, bundle2])

    assert result[:merged]
    assert_equal 2, result[:total_bundles]
  end

  def test_merge_bundles_calculates_totals
    bundle1 = {files: [{path: "a.rb"}], commands: [{command: "echo 1"}], total_size: 100}
    bundle2 = {files: [{path: "b.rb"}], commands: [{command: "echo 2"}], total_size: 200}

    result = @merger.merge_bundles([bundle1, bundle2])

    assert_equal 2, result[:total_files]
    assert_equal 2, result[:total_commands]
    assert_equal 300, result[:total_size]
  end

  def test_merge_bundles_extracts_sources
    bundle1 = {preset_name: "preset1", files: []}
    bundle2 = {source_input: "/path/to/file", files: []}

    result = @merger.merge_bundles([bundle1, bundle2])

    assert result[:sources]
    assert_equal 2, result[:sources].size
    assert_equal({type: "preset", name: "preset1"}, result[:sources][0])
    assert_equal({type: "input", path: "/path/to/file"}, result[:sources][1])
  end

  def test_merge_bundles_merges_metadata
    bundle1 = {metadata: {key1: "value1"}, files: []}
    bundle2 = {metadata: {key2: "value2"}, files: []}

    result = @merger.merge_bundles([bundle1, bundle2])

    assert result[:metadata]
    assert_equal "value1", result[:metadata][:key1]
    assert_equal "value2", result[:metadata][:key2]
    assert result[:metadata][:merged_at]
  end

  # --- resolve_output_path tests ---

  def test_resolve_output_path_prefers_command_output
    presets = [{output: "/preset/path"}]
    result = @merger.resolve_output_path(presets, "/command/path")

    assert_equal "/command/path", result
  end

  def test_resolve_output_path_uses_preset_output_when_no_command_output
    presets = [{output: "/preset/path"}]
    result = @merger.resolve_output_path(presets, nil)

    assert_equal "/preset/path", result
  end

  def test_resolve_output_path_returns_nil_for_stdout_preset
    presets = [{name: "preset1"}]  # No :output key means stdout
    result = @merger.resolve_output_path(presets, nil)

    assert_nil result
  end

  def test_resolve_output_path_returns_nil_for_conflicting_outputs
    presets = [
      {output: "/path/one"},
      {output: "/path/two"}
    ]
    result = @merger.resolve_output_path(presets, nil)

    assert_nil result
  end

  def test_resolve_output_path_uses_same_output_from_multiple_presets
    presets = [
      {output: "/same/path"},
      {output: "/same/path"}
    ]
    result = @merger.resolve_output_path(presets, nil)

    assert_equal "/same/path", result
  end

  # --- merge_with_attribution tests ---

  def test_merge_with_attribution_adds_source_to_files
    bundles = [
      {preset_name: "test-preset", files: [{path: "a.rb"}]}
    ]

    result = @merger.merge_with_attribution(bundles)

    assert_equal "preset:test-preset", result[:files].first[:source]
  end

  def test_merge_with_attribution_adds_source_to_commands
    bundles = [
      {source_input: "/input/path", commands: [{command: "echo test"}]}
    ]

    result = @merger.merge_with_attribution(bundles)

    assert_equal "input:/input/path", result[:commands].first[:source]
  end

  def test_merge_with_attribution_uses_custom_source_key
    bundles = [
      {custom_key: "my-source", files: [{path: "a.rb"}]}
    ]

    result = @merger.merge_with_attribution(bundles, :custom_key)

    assert_equal "my-source", result[:files].first[:source]
  end

  def test_merge_with_attribution_deep_merges_metadata
    bundles = [
      {metadata: {nested: {a: 1}}, files: []},
      {metadata: {nested: {b: 2}}, files: []}
    ]

    result = @merger.merge_with_attribution(bundles)

    assert_equal 1, result[:metadata][:nested][:a]
    assert_equal 2, result[:metadata][:nested][:b]
  end
end
