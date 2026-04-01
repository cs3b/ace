# frozen_string_literal: true

require "test_helper"

class SubjectExtractorTest < AceReviewTest
  def setup
    super
    @extractor = Ace::Review::Molecules::SubjectExtractor.new
  end

  def test_extracts_from_simple_string
    # Mock response for simple string
    result = @extractor.extract("test-string")
    assert_kind_of String, result
  end

  def test_extracts_from_hash_with_new_ace_context_format
    config = {
      "bundle" => {
        "sections" => {
          "changes" => {
            "title" => "Changes to Review",
            "diffs" => ["origin/main...HEAD"]
          }
        }
      }
    }

    result = @extractor.extract(config)
    assert_kind_of String, result
  end

  def test_passes_through_any_hash_format_directly
    config = {
      "bundle" => {
        "sections" => {
          "review" => {
            "title" => "Review Section",
            "files" => ["**/*.rb"],
            "diffs" => ["HEAD~5..HEAD", "origin/main...HEAD"]
          }
        }
      }
    }

    # Should not raise an error and pass through directly
    result = @extractor.extract(config)
    assert_kind_of String, result
  end

  def test_extracts_from_hash_with_files
    config = {
      "files" => ["lib/**/*.rb"]
    }

    result = @extractor.extract(config)
    assert_kind_of String, result
  end

  def test_extracts_from_hash_with_commands
    config = {
      "commands" => ["git diff HEAD~1..HEAD"]
    }

    result = @extractor.extract(config)
    assert_kind_of String, result
  end

  def test_passes_complete_ace_context_format_directly
    # Test that SubjectExtractor passes complete ace-bundle format directly
    config = {
      "bundle" => {
        "sections" => {
          "code_changes" => {
            "title" => "Code Changes",
            "description" => "Code changes for review",
            "diffs" => ["origin/main...HEAD", "HEAD~5..HEAD"],
            "since" => "7d"
          },
          "additional_files" => {
            "title" => "Related Files",
            "description" => "Additional files for context",
            "files" => ["**/*.rb"]
          }
        }
      },
      "commands" => ["git log --oneline -5"]
    }

    result = @extractor.extract(config)
    assert_kind_of String, result
  end

  def test_handles_hash_formats
    # Test that SubjectExtractor can handle multiple supported hash formats
    new_config = {
      "bundle" => {
        "sections" => {
          "changes" => {
            "title" => "Changes to Review",
            "diffs" => ["HEAD~3..HEAD"]
          }
        }
      }
    }

    nested_config = {
      "bundle" => {
        "files" => ["README.md"]
      }
    }

    # Both should work - passed through directly to ace-bundle
    new_result = @extractor.extract(new_config)
    nested_result = @extractor.extract(nested_config)

    assert_kind_of String, new_result
    assert_kind_of String, nested_result
  end

  def test_returns_empty_string_for_nil
    result = @extractor.extract(nil)
    assert_equal "", result
  end

  def test_returns_empty_string_for_invalid_type
    result = @extractor.extract(123)
    assert_equal "", result
  end

  # Typed subject tests
  def test_diff_typed_subject
    result = @extractor.extract("diff:origin/main..HEAD")
    assert_kind_of String, result
  end

  def test_pr_typed_subject
    result = @extractor.extract("pr:123")
    assert_kind_of String, result
  end

  def test_pr_typed_subject_multiple_prs
    # Verify the config parsing produces correct PR array
    config = @extractor.parse_typed_subject_config("pr:123,456")
    assert_equal({"bundle" => {"pr" => ["123", "456"]}}, config)

    # Also verify extraction returns a string
    result = @extractor.extract("pr:123,456")
    assert_kind_of String, result
  end

  def test_pr_typed_subject_multiple_prs_with_whitespace
    # Verify whitespace is properly trimmed from PR refs
    config = @extractor.parse_typed_subject_config("pr: 123 , 456 ")
    assert_equal({"bundle" => {"pr" => ["123", "456"]}}, config)

    # Also verify extraction returns a string
    result = @extractor.extract("pr: 123 , 456")
    assert_kind_of String, result
  end

  def test_files_typed_subject_single
    result = @extractor.extract("files:lib/**/*.rb")
    assert_kind_of String, result
  end

  def test_files_typed_subject_multiple
    result = @extractor.extract("files:lib/**/*.rb,test/**/*")
    assert_kind_of String, result
  end

  def test_task_typed_subject
    # Mock ace-task command
    mock_output = "/path/to/task/145.md\n"
    mock_status = Minitest::Mock.new
    mock_status.expect :success?, true

    @extractor.stub :run_taskflow_command, [mock_output, "", mock_status, nil] do
      result = @extractor.extract("task:145")
      assert_kind_of String, result
    end

    mock_status.verify
  end

  def test_task_typed_subject_subtask
    # Mock ace-task command
    mock_output = "/path/to/task/145.02-subtask.s.md\n"
    mock_status = Minitest::Mock.new
    mock_status.expect :success?, true

    @extractor.stub :run_taskflow_command, [mock_output, "", mock_status, nil] do
      result = @extractor.extract("task:145.02")
      assert_kind_of String, result
    end

    mock_status.verify
  end

  def test_task_not_found_error
    # Mock ace-task command failure
    mock_status = Minitest::Mock.new
    mock_status.expect :success?, false

    @extractor.stub :run_taskflow_command, ["", "Task not found", mock_status, nil] do
      error = assert_raises Ace::Review::Errors::TaskNotFoundError do
        @extractor.extract("task:999")
      end
      assert_includes error.message, "Task '999' not found"
      assert_includes error.message, "ace-task show 999"
    end

    mock_status.verify
  end

  def test_task_no_path_error
    # Mock ace-task command success but empty path
    mock_status = Minitest::Mock.new
    mock_status.expect :success?, true

    @extractor.stub :run_taskflow_command, ["", "", mock_status, nil] do
      error = assert_raises Ace::Review::Errors::TaskPathNotFoundError do
        @extractor.extract("task:145")
      end
      assert_includes error.message, "Task '145' exists but has no path"
      assert_includes error.message, "ace-task show 145"
    end

    mock_status.verify
  end

  def test_task_invalid_ref_format
    error = assert_raises ArgumentError do
      @extractor.extract("task:../../../etc/passwd")
    end
    assert_includes error.message, "Invalid task reference format"
  end

  def test_task_qualified_ref_with_plus
    # Test that qualified task refs like v.0.9.0+task.145 work
    mock_output = "/path/to/v.0.9.0/tasks/145-feature/145-feature.s.md\n"
    mock_status = Minitest::Mock.new
    mock_status.expect :success?, true

    @extractor.stub :run_taskflow_command, [mock_output, "", mock_status, nil] do
      result = @extractor.extract("task:v.0.9.0+task.145")
      assert_kind_of String, result
    end

    mock_status.verify
  end

  def test_task_missing_ace_taskflow
    # Test that missing ace-task raises helpful error
    @extractor.stub :run_taskflow_command, ->(_ref) { raise Errno::ENOENT, "ace-task" } do
      error = assert_raises Ace::Review::Errors::MissingDependencyError do
        @extractor.extract("task:145")
      end
      assert_includes error.message, "ace-task"
    end
  end

  def test_task_timeout_raises_command_timeout_error
    # Test that a hanging ace-task subprocess raises timeout error
    Timeout.stub :timeout, ->(_seconds) { raise Timeout::Error } do
      error = assert_raises Ace::Review::Errors::CommandTimeoutError do
        @extractor.extract("task:145")
      end
      assert_includes error.message, "ace-task"
      assert_includes error.message, "timed out"
      assert_equal "ace-task show 145 --path", error.command
      assert_equal Ace::Review::Molecules::SubjectExtractor::TASKFLOW_TIMEOUT, error.timeout_seconds
    end
  end

  def test_keywords_use_ace_bundle
    # Test that keywords still work (now through ace-bundle)
    result = @extractor.extract("staged")
    assert_kind_of String, result

    result = @extractor.extract("working")
    assert_kind_of String, result
  end

  def test_backward_compatible_yaml
    # YAML syntax still works
    yaml_input = '{"diffs": ["origin/main..HEAD"]}'
    result = @extractor.extract(yaml_input)
    assert_kind_of String, result
  end

  def test_backward_compatible_auto_detect
    # Auto-detect still works for git ranges
    result = @extractor.extract("HEAD~5..HEAD")
    assert_kind_of String, result

    # Auto-detect for file patterns
    result = @extractor.extract("lib/**/*.rb")
    assert_kind_of String, result
  end

  def test_unknown_typed_subject_falls_through
    # Unknown type prefix should fall through to auto-detect
    result = @extractor.extract("unknown:abc123")
    assert_kind_of String, result
  end

  def test_empty_diff_value_raises_helpful_error
    error = assert_raises ArgumentError do
      @extractor.extract("diff:")
    end
    assert_includes error.message, "Empty value for diff: subject"
    assert_includes error.message, "diff:RANGE"
  end

  def test_empty_pr_value_raises_helpful_error
    error = assert_raises ArgumentError do
      @extractor.extract("pr:")
    end
    assert_includes error.message, "Empty value for pr: subject"
    assert_includes error.message, "pr:NUMBER"
  end

  def test_pr_trailing_comma_rejects_empty_refs
    # Trailing comma should not produce empty string in PR array
    config = @extractor.parse_typed_subject_config("pr:123,")
    assert_equal({"bundle" => {"pr" => ["123"]}}, config)
  end

  def test_pr_multiple_commas_rejects_empty_refs
    # Multiple commas should not produce empty strings
    config = @extractor.parse_typed_subject_config("pr:123,,456")
    assert_equal({"bundle" => {"pr" => ["123", "456"]}}, config)
  end

  def test_pr_duplicate_refs_deduped
    # Duplicate PR refs should be deduplicated
    config = @extractor.parse_typed_subject_config("pr:123,456,123")
    assert_equal({"bundle" => {"pr" => ["123", "456"]}}, config)
  end

  def test_pr_only_commas_raises_error
    # Only commas (no valid refs) should raise error
    error = assert_raises ArgumentError do
      @extractor.extract("pr:,,,")
    end
    assert_includes error.message, "No valid PR references"
  end

  def test_pr_qualified_ref_accepted
    # Qualified PR refs (owner/repo#number) should be accepted
    # Validation is delegated to ace-bundle's PrIdentifierParser
    config = @extractor.parse_typed_subject_config("pr:owner/repo#456")
    assert_equal({"bundle" => {"pr" => ["owner/repo#456"]}}, config)
  end

  def test_pr_github_url_accepted
    # GitHub URL refs should be accepted
    config = @extractor.parse_typed_subject_config("pr:https://github.com/owner/repo/pull/789")
    assert_equal({"bundle" => {"pr" => ["https://github.com/owner/repo/pull/789"]}}, config)
  end

  def test_pr_mixed_formats_accepted
    # Mixed numeric and qualified refs should all be accepted
    config = @extractor.parse_typed_subject_config("pr:123,owner/repo#456,789")
    assert_equal({"bundle" => {"pr" => ["123", "owner/repo#456", "789"]}}, config)
  end

  def test_empty_files_value_raises_helpful_error
    error = assert_raises ArgumentError do
      @extractor.extract("files:")
    end
    assert_includes error.message, "Empty value for files: subject"
    assert_includes error.message, "files:PATTERN"
  end

  def test_empty_task_value_raises_helpful_error
    error = assert_raises ArgumentError do
      @extractor.extract("task:")
    end
    assert_includes error.message, "Empty value for task: subject"
    assert_includes error.message, "task:REF"
  end

  # commit: subject type tests
  def test_commit_typed_subject_short_hash
    result = @extractor.extract("commit:abc123")
    assert_kind_of String, result
  end

  def test_commit_typed_subject_short_hash_config
    config = @extractor.parse_typed_subject_config("commit:abc123")
    assert_equal({"bundle" => {"diffs" => ["abc123~1..abc123"]}}, config)
  end

  def test_commit_typed_subject_full_hash
    result = @extractor.extract("commit:3cd9afbf1234567890abcd1234567890abcd1234")
    assert_kind_of String, result
  end

  def test_commit_typed_subject_full_hash_config
    config = @extractor.parse_typed_subject_config("commit:3cd9afbf1234567890abcd1234567890abcd1234")
    assert_equal({"bundle" => {"diffs" => ["3cd9afbf1234567890abcd1234567890abcd1234~1..3cd9afbf1234567890abcd1234567890abcd1234"]}}, config)
  end

  def test_commit_typed_subject_with_whitespace
    # Whitespace should be trimmed
    config = @extractor.parse_typed_subject_config("commit:  abc123  ")
    assert_equal({"bundle" => {"diffs" => ["abc123~1..abc123"]}}, config)
  end

  def test_commit_typed_subject_invalid_format_non_hex
    error = assert_raises ArgumentError do
      @extractor.extract("commit:xyz")
    end
    assert_includes error.message, "Invalid commit hash format"
    assert_includes error.message, "xyz"
    assert_includes error.message, "6-40 hexadecimal characters"
  end

  def test_commit_typed_subject_invalid_format_too_short
    error = assert_raises ArgumentError do
      @extractor.extract("commit:abc12")
    end
    assert_includes error.message, "Invalid commit hash format"
    assert_includes error.message, "abc12"
    assert_includes error.message, "6-40 hexadecimal characters"
  end

  def test_commit_typed_subject_invalid_format_too_long
    error = assert_raises ArgumentError do
      @extractor.extract("commit:abc123abc123abc123abc123abc123abc123abc123abc123")
    end
    assert_includes error.message, "Invalid commit hash format"
    assert_includes error.message, "6-40 hexadecimal characters"
  end

  def test_commit_typed_subject_uppercase_normalized
    # Uppercase should be normalized to lowercase (improves UX)
    config = @extractor.parse_typed_subject_config("commit:ABC123")
    assert_equal({"bundle" => {"diffs" => ["abc123~1..abc123"]}}, config)
  end

  def test_commit_typed_subject_invalid_format_special_chars
    error = assert_raises ArgumentError do
      @extractor.extract("commit:abc-123")
    end
    assert_includes error.message, "Invalid commit hash format"
  end

  def test_empty_commit_value_raises_helpful_error
    error = assert_raises ArgumentError do
      @extractor.extract("commit:")
    end
    assert_includes error.message, "Empty value for commit: subject"
    assert_includes error.message, "commit:HASH"
  end

  def test_commit_typed_subject_exact_boundaries
    # Test exactly 6 characters (lower boundary)
    config = @extractor.parse_typed_subject_config("commit:abcdef")
    assert_equal({"bundle" => {"diffs" => ["abcdef~1..abcdef"]}}, config)

    # Test exactly 40 characters (upper boundary)
    full_hash = "a" * 40
    config = @extractor.parse_typed_subject_config("commit:#{full_hash}")
    assert_equal({"bundle" => {"diffs" => ["#{full_hash}~1..#{full_hash}"]}}, config)
  end

  def test_typed_subject_parsing_precedence
    # Typed subjects take precedence over auto-detect
    # Even if input looks like a git range, typed prefix wins
    result = @extractor.extract("diff:HEAD~1..HEAD")
    assert_kind_of String, result

    # Files type takes precedence over auto-detect
    result = @extractor.extract("files:*.rb")
    assert_kind_of String, result
  end

  # parse_typed_subject_config tests - returns config hash without extraction
  def test_parse_typed_subject_config_for_pr
    config = @extractor.parse_typed_subject_config("pr:77")
    assert_equal({"bundle" => {"pr" => ["77"]}}, config)
  end

  def test_parse_typed_subject_config_for_diff
    config = @extractor.parse_typed_subject_config("diff:HEAD~3...HEAD")
    assert_equal({"bundle" => {"diffs" => ["HEAD~3...HEAD"]}}, config)
  end

  def test_parse_typed_subject_config_for_diff_with_paths
    config = @extractor.parse_typed_subject_config("diff:origin/main...HEAD -- ace-test-runner-e2e docs/configuration.md")
    assert_equal(
      {"bundle" => {"diffs" => ["origin/main...HEAD"], "paths" => ["ace-test-runner-e2e", "docs/configuration.md"]}},
      config
    )
  end

  def test_parse_typed_subject_config_for_diff_with_comma_separated_paths
    config = @extractor.parse_typed_subject_config("diff:origin/main...HEAD -- ace-test-runner-e2e,docs/configuration.md")
    assert_equal(
      {"bundle" => {"diffs" => ["origin/main...HEAD"], "paths" => ["ace-test-runner-e2e", "docs/configuration.md"]}},
      config
    )
  end

  def test_parse_typed_subject_config_for_diff_with_empty_paths_raises
    error = assert_raises ArgumentError do
      @extractor.parse_typed_subject_config("diff:origin/main...HEAD --   ")
    end

    assert_includes error.message, "No valid paths specified after --"
  end

  def test_parse_typed_subject_config_for_files
    config = @extractor.parse_typed_subject_config("files:lib/**/*.rb")
    assert_equal({"bundle" => {"files" => ["lib/**/*.rb"]}}, config)
  end

  def test_parse_typed_subject_config_for_multiple_files
    config = @extractor.parse_typed_subject_config("files:lib/**/*.rb,test/**/*")
    assert_equal({"bundle" => {"files" => ["lib/**/*.rb", "test/**/*"]}}, config)
  end

  def test_parse_typed_subject_config_for_task
    mock_output = "/path/to/task/145-feature.s.md\n"
    mock_status = Minitest::Mock.new
    mock_status.expect :success?, true

    @extractor.stub :run_taskflow_command, [mock_output, "", mock_status, nil] do
      config = @extractor.parse_typed_subject_config("task:145")
      assert_equal({"bundle" => {"files" => ["/path/to/task/**/*.s.md"]}}, config)
    end

    mock_status.verify
  end

  def test_parse_typed_subject_config_returns_nil_for_non_typed
    # Non-typed subjects should return nil
    assert_nil @extractor.parse_typed_subject_config("staged")
    assert_nil @extractor.parse_typed_subject_config("HEAD~3..HEAD")
    assert_nil @extractor.parse_typed_subject_config("some-branch")
  end

  def test_parse_typed_subject_config_returns_nil_for_non_string
    assert_nil @extractor.parse_typed_subject_config(nil)
    assert_nil @extractor.parse_typed_subject_config(123)
    assert_nil @extractor.parse_typed_subject_config({"pr" => "77"})
  end

  # Content verification tests - ensure extract actually produces content
  # NOTE: ace-bundle is stubbed in test_helper.rb, so these tests verify
  # that the extract method correctly delegates to ace-bundle and returns
  # the mock data (which simulates real content behavior)

  def test_extract_diff_produces_content
    # Test with a known git range that should produce content
    result = @extractor.extract("diff:HEAD~1...HEAD")
    # With mocked ace-bundle, should return non-empty mock content
    assert_kind_of String, result
    # Mock returns diff output
    assert result.length > 0, "Expected non-empty result from mock"
  end

  def test_extract_files_produces_file_content
    # Test file extraction - ace-bundle is mocked so we get mock content
    result = @extractor.extract("files:lib/**/*.rb")
    assert_kind_of String, result
    # Mock returns file content
    assert result.length > 0, "Expected non-empty result from mock"
  end

  def test_extract_with_valid_config_hash_produces_content
    # Test the hash-based extraction
    config = {"files" => ["lib/**/*.rb"]}
    result = @extractor.extract(config)

    assert_kind_of String, result
    # With mocked ace-bundle, should return mock content
    assert result.length > 0, "Expected non-empty result from mock"
  end

  def test_deep_merge_arrays_both_arrays
    # Both base and overlay have arrays: concatenate
    base = {"files" => ["a.rb"]}
    overlay = {"files" => ["b.rb"]}
    result = @extractor.send(:deep_merge_arrays, base, overlay)
    assert_equal({"files" => ["a.rb", "b.rb"]}, result)
  end

  def test_deep_merge_arrays_base_array_overlay_scalar
    # Base is array, overlay is scalar: append
    base = {"files" => ["a.rb"]}
    overlay = {"files" => "b.rb"}
    result = @extractor.send(:deep_merge_arrays, base, overlay)
    assert_equal({"files" => ["a.rb", "b.rb"]}, result)
  end

  def test_deep_merge_arrays_base_scalar_overlay_array
    # Base is scalar, overlay is array: prepend base to array
    base = {"files" => "a.rb"}
    overlay = {"files" => ["b.rb", "c.rb"]}
    result = @extractor.send(:deep_merge_arrays, base, overlay)
    assert_equal({"files" => ["a.rb", "b.rb", "c.rb"]}, result)
  end

  def test_deep_merge_arrays_both_scalars
    # Both scalars: convert to array
    base = {"pr" => "123"}
    overlay = {"pr" => "456"}
    result = @extractor.send(:deep_merge_arrays, base, overlay)
    assert_equal({"pr" => ["123", "456"]}, result)
  end

  def test_deep_merge_arrays_new_key
    # Overlay has new key: add directly
    base = {"files" => ["a.rb"]}
    overlay = {"diffs" => ["HEAD~3"]}
    result = @extractor.send(:deep_merge_arrays, base, overlay)
    assert_equal({"files" => ["a.rb"], "diffs" => ["HEAD~3"]}, result)
  end

  def test_deep_merge_arrays_preserves_both_keys
    # Multiple different keys should all be preserved
    base = {"files" => ["a.rb"]}
    overlay = {"diffs" => ["HEAD~3"], "pr" => ["123"]}
    result = @extractor.send(:deep_merge_arrays, base, overlay)
    assert_equal({"files" => ["a.rb"], "diffs" => ["HEAD~3"], "pr" => ["123"]}, result)
  end

  def test_deep_merge_arrays_nested_hashes
    # Two typed subjects produce nested { "bundle" => { ... } } structures
    # Must recurse into nested hashes to merge correctly
    base = {"bundle" => {"diffs" => ["HEAD~3"]}}
    overlay = {"bundle" => {"diffs" => ["HEAD"]}}
    result = @extractor.send(:deep_merge_arrays, base, overlay)
    assert_equal({"bundle" => {"diffs" => ["HEAD~3", "HEAD"]}}, result)
  end

  def test_deep_merge_arrays_nested_hashes_different_keys
    # Nested hashes with different keys should merge
    base = {"bundle" => {"diffs" => ["HEAD~3"]}}
    overlay = {"bundle" => {"files" => ["*.rb"]}}
    result = @extractor.send(:deep_merge_arrays, base, overlay)
    assert_equal({"bundle" => {"diffs" => ["HEAD~3"], "files" => ["*.rb"]}}, result)
  end

  def test_deep_merge_arrays_deeply_nested
    # Test 3+ levels of nesting
    base = {"a" => {"b" => {"c" => ["1"]}}}
    overlay = {"a" => {"b" => {"c" => ["2"]}}}
    result = @extractor.send(:deep_merge_arrays, base, overlay)
    assert_equal({"a" => {"b" => {"c" => ["1", "2"]}}}, result)
  end

  def test_deep_merge_arrays_does_not_mutate_input
    # Verify immutability - input hashes should not be modified
    base = {"bundle" => {"diffs" => ["HEAD~3"]}}
    overlay = {"bundle" => {"diffs" => ["HEAD"]}}
    base_original = Marshal.load(Marshal.dump(base))
    overlay_original = Marshal.load(Marshal.dump(overlay))

    @extractor.send(:deep_merge_arrays, base, overlay)

    assert_equal base_original, base, "base hash was mutated"
    assert_equal overlay_original, overlay, "overlay hash was mutated"
  end

  def test_resolve_single_subject_string_typed
    # Typed subject string should parse to config
    result = @extractor.send(:resolve_single_subject, "diff:HEAD~3")
    assert_equal({"bundle" => {"diffs" => ["HEAD~3"]}}, result)
  end

  def test_resolve_single_subject_string_keyword
    # Keyword should parse to config
    result = @extractor.send(:resolve_single_subject, "staged")
    assert_equal({"diffs" => ["--staged"]}, result)
  end

  def test_resolve_single_subject_hash
    # Hash should pass through directly
    config = {"files" => ["*.rb"]}
    result = @extractor.send(:resolve_single_subject, config)
    assert_equal config, result
  end

  def test_resolve_single_subject_invalid_type
    # Invalid type should return empty hash
    result = @extractor.send(:resolve_single_subject, 123)
    assert_equal({}, result)
  end

  # merge_typed_subject_configs tests - returns merged config without extraction
  def test_merge_typed_subject_configs_returns_merged_config
    # Should merge multiple typed subjects into single config
    subjects = ["diff:HEAD~3", "files:*.rb"]
    config = @extractor.merge_typed_subject_configs(subjects)

    assert_kind_of Hash, config
    assert config.key?("bundle"), "Should have bundle key"
    assert config["bundle"].key?("diffs"), "Should have diffs"
    assert config["bundle"].key?("files"), "Should have files"
    assert_equal ["HEAD~3"], config["bundle"]["diffs"]
    assert_equal ["*.rb"], config["bundle"]["files"]
  end

  def test_merge_typed_subject_configs_merges_same_type
    # Multiple PRs should merge into array
    subjects = ["pr:77", "pr:79"]
    config = @extractor.merge_typed_subject_configs(subjects)

    assert_equal({"bundle" => {"pr" => ["77", "79"]}}, config)
  end

  def test_merge_typed_subject_configs_merges_diffs
    # Multiple diffs should merge into array
    subjects = ["diff:HEAD~3", "diff:origin/main..HEAD"]
    config = @extractor.merge_typed_subject_configs(subjects)

    assert_equal({"bundle" => {"diffs" => ["HEAD~3", "origin/main..HEAD"]}}, config)
  end

  def test_merge_typed_subject_configs_merges_files
    # Multiple file patterns should merge
    subjects = ["files:lib/**/*.rb", "files:test/**/*.rb"]
    config = @extractor.merge_typed_subject_configs(subjects)

    assert_equal({"bundle" => {"files" => ["lib/**/*.rb", "test/**/*.rb"]}}, config)
  end

  def test_merge_typed_subject_configs_handles_mixed_types
    # Mix of typed and keyword subjects
    subjects = ["pr:77", "files:README.md", "staged"]
    config = @extractor.merge_typed_subject_configs(subjects)

    assert_kind_of Hash, config
    # pr:77 produces { "bundle" => { "pr" => "77" } }
    # files:README.md produces { "bundle" => { "files" => ["README.md"] } }
    # staged produces { "diffs" => ["--staged"] }
    assert config["bundle"]["pr"]
    assert config["bundle"]["files"]
    assert config["diffs"], "Keyword subject should add top-level diffs"
  end

  def test_merge_typed_subject_configs_returns_nil_for_empty_array
    assert_nil @extractor.merge_typed_subject_configs([])
  end

  def test_merge_typed_subject_configs_returns_nil_for_non_array
    assert_nil @extractor.merge_typed_subject_configs("single_subject")
    assert_nil @extractor.merge_typed_subject_configs(nil)
    assert_nil @extractor.merge_typed_subject_configs({"files" => ["*.rb"]})
  end

  def test_merge_typed_subject_configs_handles_hash_subjects
    # Hash subjects should pass through directly
    subjects = [
      "diff:HEAD~3",
      {"files" => ["lib/**/*.rb"]}
    ]
    config = @extractor.merge_typed_subject_configs(subjects)

    assert_kind_of Hash, config
    assert config["bundle"]["diffs"]
    assert config["files"], "Hash subject should add top-level files"
  end

  # Additional nested hash merge test (PR #79 feedback)
  def test_deep_merge_arrays_nested_mixed_keys_and_arrays
    # Test deeply nested hash merge where inner keys differ
    base = {"bundle" => {"diffs" => ["a"], "pr" => "1"}}
    overlay = {"bundle" => {"diffs" => ["b"], "files" => ["*.rb"]}}
    result = @extractor.send(:deep_merge_arrays, base, overlay)

    # Should merge nested hashes: preserve pr, concatenate diffs, add files
    expected = {"bundle" => {"diffs" => ["a", "b"], "pr" => "1", "files" => ["*.rb"]}}
    assert_equal expected, result
  end

  def test_deep_merge_arrays_three_level_nesting_with_arrays
    # Test 3+ levels with arrays at leaf
    base = {"bundle" => {"sections" => {"code" => {"files" => ["a.rb"]}}}}
    overlay = {"bundle" => {"sections" => {"code" => {"files" => ["b.rb"]}}}}
    result = @extractor.send(:deep_merge_arrays, base, overlay)

    expected = {"bundle" => {"sections" => {"code" => {"files" => ["a.rb", "b.rb"]}}}}
    assert_equal expected, result
  end

  def test_deep_merge_arrays_preserves_sibling_keys
    # Ensure sibling keys at same level are preserved during merge
    base = {"bundle" => {"diffs" => ["a"], "title" => "Base Title"}}
    overlay = {"bundle" => {"diffs" => ["b"], "description" => "Overlay Desc"}}
    result = @extractor.send(:deep_merge_arrays, base, overlay)

    expected = {
      "bundle" => {
        "diffs" => ["a", "b"],
        "title" => "Base Title",
        "description" => "Overlay Desc"
      }
    }
    assert_equal expected, result
  end
end
