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
end
