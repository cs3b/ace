# frozen_string_literal: true

require_relative "../test_helper"

# Integration tests for multi-subject merging functionality
# Tests the flow: CLI subjects → SubjectExtractor.merge_typed_subject_configs → DeepMerger
class MultiSubjectIntegrationTest < Minitest::Test
  def setup
    @extractor = Ace::Review::Molecules::SubjectExtractor.new
  end

  # Test that multiple PR subjects are merged into a single config with array of PRs
  def test_merge_multiple_pr_subjects
    subjects = ["pr:77", "pr:78"]

    config = @extractor.merge_typed_subject_configs(subjects)

    assert config, "Should return merged config"
    assert config["context"], "Should have context key"
    assert config["context"]["pr"], "Should have pr key in context"
    assert_equal %w[77 78], config["context"]["pr"], "Should merge PR numbers into array"
  end

  # Test that mixed subject types (diff + files) are merged correctly
  def test_merge_mixed_subject_types
    subjects = ["diff:HEAD~3", "files:*.md"]

    config = @extractor.merge_typed_subject_configs(subjects)

    assert config, "Should return merged config"
    assert config["context"], "Should have context key"
    assert_equal ["HEAD~3"], config["context"]["diffs"], "Should have diffs array"
    assert_equal ["*.md"], config["context"]["files"], "Should have files array"
  end

  # Test that duplicate values in merged arrays are deduplicated
  def test_merge_deduplicates_arrays
    subjects = ["diff:HEAD~3", "diff:HEAD~3", "diff:HEAD~5"]

    config = @extractor.merge_typed_subject_configs(subjects)

    assert config, "Should return merged config"
    diffs = config["context"]["diffs"]
    assert_equal 2, diffs.size, "Should deduplicate identical diffs"
    assert_includes diffs, "HEAD~3"
    assert_includes diffs, "HEAD~5"
  end

  # Test that single subject returns valid config (backward compatibility)
  def test_single_subject_returns_valid_config
    subjects = ["pr:123"]

    config = @extractor.merge_typed_subject_configs(subjects)

    assert config, "Should return config for single subject"
    assert_equal ["123"], config["context"]["pr"]
  end

  # Test empty array returns nil
  def test_empty_subjects_returns_nil
    config = @extractor.merge_typed_subject_configs([])

    assert_nil config, "Should return nil for empty subjects"
  end

  # Test nil input returns nil
  def test_nil_subjects_returns_nil
    config = @extractor.merge_typed_subject_configs(nil)

    assert_nil config, "Should return nil for nil input"
  end

  # Test that DeepMerger is correctly required and used
  # This validates the critical fix: require "ace/core/atoms/deep_merger"
  def test_deep_merger_is_available
    assert defined?(Ace::Core::Atoms::DeepMerger),
           "DeepMerger should be available after requiring subject_extractor"
  end

  # Test that :coerce_union strategy works correctly
  def test_coerce_union_strategy_merges_arrays
    subjects = ["files:src/*.rb", "files:lib/*.rb"]

    config = @extractor.merge_typed_subject_configs(subjects)

    assert config, "Should return merged config"
    files = config["context"]["files"]
    assert_equal 2, files.size, "Should have both file patterns"
    assert_includes files, "src/*.rb"
    assert_includes files, "lib/*.rb"
  end

  # Test three or more subjects merge correctly
  def test_merge_three_or_more_subjects
    subjects = ["pr:77", "files:README.md", "diff:HEAD~1"]

    config = @extractor.merge_typed_subject_configs(subjects)

    assert config, "Should return merged config"
    context = config["context"]
    assert_equal ["77"], context["pr"], "Should have PR"
    assert_equal ["README.md"], context["files"], "Should have files"
    assert_equal ["HEAD~1"], context["diffs"], "Should have diffs"
  end

  # Test that hash subjects pass through unchanged
  def test_hash_subject_passes_through
    hash_subject = { "context" => { "files" => ["custom.rb"] } }
    subjects = [hash_subject]

    config = @extractor.merge_typed_subject_configs(subjects)

    assert config, "Should return config"
    assert_equal ["custom.rb"], config["context"]["files"]
  end

  # Test mixing hash and string subjects
  def test_mix_hash_and_string_subjects
    hash_subject = { "context" => { "files" => ["custom.rb"] } }
    subjects = [hash_subject, "files:other.rb"]

    config = @extractor.merge_typed_subject_configs(subjects)

    assert config, "Should return merged config"
    files = config["context"]["files"]
    assert_includes files, "custom.rb"
    assert_includes files, "other.rb"
  end
end
