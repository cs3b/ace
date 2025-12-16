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
      "context" => {
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

  def test_extracts_from_hash_with_legacy_diff_format
    config = {
      "diff" => "origin/main...HEAD"
    }

    result = @extractor.extract(config)
    assert_kind_of String, result
  end

  def test_passes_through_any_hash_format_directly
    config = {
      "context" => {
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
    # Test that SubjectExtractor passes complete ace-context format directly
    config = {
      "context" => {
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

  def test_handles_both_legacy_and_new_formats
    # Test that SubjectExtractor can handle both legacy and new ace-context formats
    new_config = {
      "context" => {
        "sections" => {
          "changes" => {
            "title" => "Changes to Review",
            "diffs" => ["HEAD~3..HEAD"]
          }
        }
      }
    }

    legacy_config = {
      "diff" => "origin/main...HEAD",
      "files" => ["README.md"]
    }

    # Both should work - passed through directly to ace-context
    new_result = @extractor.extract(new_config)
    legacy_result = @extractor.extract(legacy_config)

    assert_kind_of String, new_result
    assert_kind_of String, legacy_result
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

  def test_files_typed_subject_single
    result = @extractor.extract("files:lib/**/*.rb")
    assert_kind_of String, result
  end

  def test_files_typed_subject_multiple
    result = @extractor.extract("files:lib/**/*.rb,test/**/*")
    assert_kind_of String, result
  end

  def test_task_typed_subject
    # Mock ace-taskflow command
    mock_output = "/path/to/task/145.md\n"
    mock_status = Minitest::Mock.new
    mock_status.expect :success?, true

    Open3.stub :capture3, [mock_output, "", mock_status] do
      result = @extractor.extract("task:145")
      assert_kind_of String, result
    end

    mock_status.verify
  end

  def test_task_typed_subject_subtask
    # Mock ace-taskflow command
    mock_output = "/path/to/task/145.02-subtask.s.md\n"
    mock_status = Minitest::Mock.new
    mock_status.expect :success?, true

    Open3.stub :capture3, [mock_output, "", mock_status] do
      result = @extractor.extract("task:145.02")
      assert_kind_of String, result
    end

    mock_status.verify
  end

  def test_task_not_found_error
    # Mock ace-taskflow command failure
    mock_status = Minitest::Mock.new
    mock_status.expect :success?, false

    Open3.stub :capture3, ["", "Task not found", mock_status] do
      error = assert_raises Ace::Review::Errors::TaskNotFoundError do
        @extractor.extract("task:999")
      end
      assert_includes error.message, "Task '999' not found"
      assert_includes error.message, "ace-taskflow task 999"
    end

    mock_status.verify
  end

  def test_task_no_path_error
    # Mock ace-taskflow command success but empty path
    mock_status = Minitest::Mock.new
    mock_status.expect :success?, true

    Open3.stub :capture3, ["", "", mock_status] do
      error = assert_raises Ace::Review::Errors::TaskPathNotFoundError do
        @extractor.extract("task:145")
      end
      assert_includes error.message, "Task '145' exists but has no path"
      assert_includes error.message, "ace-taskflow task 145"
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

    Open3.stub :capture3, [mock_output, "", mock_status] do
      result = @extractor.extract("task:v.0.9.0+task.145")
      assert_kind_of String, result
    end

    mock_status.verify
  end

  def test_task_missing_ace_taskflow
    # Test that missing ace-taskflow raises helpful error
    Open3.stub :capture3, ->(*_args) { raise Errno::ENOENT, "ace-taskflow" } do
      error = assert_raises Ace::Review::Errors::MissingDependencyError do
        @extractor.extract("task:145")
      end
      assert_includes error.message, "ace-taskflow"
    end
  end

  def test_task_timeout_raises_command_timeout_error
    # Test that a hanging ace-taskflow subprocess raises timeout error
    Timeout.stub :timeout, ->(_seconds) { raise Timeout::Error } do
      error = assert_raises Ace::Review::Errors::CommandTimeoutError do
        @extractor.extract("task:145")
      end
      assert_includes error.message, "ace-taskflow"
      assert_includes error.message, "timed out"
      assert_equal "ace-taskflow task 145 --path", error.command
      assert_equal Ace::Review::Molecules::SubjectExtractor::TASKFLOW_TIMEOUT, error.timeout_seconds
    end
  end

  def test_keywords_use_ace_context
    # Test that keywords still work (now through ace-context)
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
    result = @extractor.extract("commit:abc123")
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
    assert_equal({ "context" => { "pr" => "77" } }, config)
  end

  def test_parse_typed_subject_config_for_diff
    config = @extractor.parse_typed_subject_config("diff:HEAD~3...HEAD")
    assert_equal({ "context" => { "diffs" => ["HEAD~3...HEAD"] } }, config)
  end

  def test_parse_typed_subject_config_for_files
    config = @extractor.parse_typed_subject_config("files:lib/**/*.rb")
    assert_equal({ "context" => { "files" => ["lib/**/*.rb"] } }, config)
  end

  def test_parse_typed_subject_config_for_multiple_files
    config = @extractor.parse_typed_subject_config("files:lib/**/*.rb,test/**/*")
    assert_equal({ "context" => { "files" => ["lib/**/*.rb", "test/**/*"] } }, config)
  end

  def test_parse_typed_subject_config_for_task
    mock_output = "/path/to/task/145-feature.s.md\n"
    mock_status = Minitest::Mock.new
    mock_status.expect :success?, true

    Open3.stub :capture3, [mock_output, "", mock_status] do
      config = @extractor.parse_typed_subject_config("task:145")
      assert_equal({ "context" => { "files" => ["/path/to/task/**/*.s.md"] } }, config)
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
    assert_nil @extractor.parse_typed_subject_config({ "pr" => "77" })
  end

  # Content verification tests - ensure extract actually produces content
  # NOTE: ace-context is stubbed in test_helper.rb, so these tests verify
  # that the extract method correctly delegates to ace-context and returns
  # the mock data (which simulates real content behavior)

  def test_extract_diff_produces_content
    # Test with a known git range that should produce content
    result = @extractor.extract("diff:HEAD~1...HEAD")
    # With mocked ace-context, should return non-empty mock content
    assert_kind_of String, result
    # Mock returns diff output
    assert result.length > 0, "Expected non-empty result from mock"
  end

  def test_extract_files_produces_file_content
    # Test file extraction - ace-context is mocked so we get mock content
    result = @extractor.extract("files:lib/**/*.rb")
    assert_kind_of String, result
    # Mock returns file content
    assert result.length > 0, "Expected non-empty result from mock"
  end

  def test_extract_with_valid_config_hash_produces_content
    # Test the hash-based extraction
    config = { "files" => ["lib/**/*.rb"] }
    result = @extractor.extract(config)

    assert_kind_of String, result
    # With mocked ace-context, should return mock content
    assert result.length > 0, "Expected non-empty result from mock"
  end
end
