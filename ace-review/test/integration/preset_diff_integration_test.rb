# frozen_string_literal: true

require_relative "../test_helper"
require "yaml"
require "tmpdir"

class PresetDiffIntegrationTest < AceReviewTest
  def setup
    super  # IMPORTANT: Calls parent to stub ace-bundle and BranchReader for fast tests
    @extractor = Ace::Review::Molecules::SubjectExtractor.new
    # Git operations are mocked via stub_branch_reader in AceReviewTest
    # No need for real git repo since extraction is fully mocked
  end

  def test_loads_preset_with_new_subject_format
    preset_content = <<~YAML
      description: "Test PR preset"
      subject:
        bundle:
          sections:
            changes:
              title: "Changes to Review"
              diffs:
                - "HEAD~1..HEAD"
    YAML

    create_test_preset("test_pr", preset_content)
    preset = YAML.load_file(".ace/review/presets/test_pr.yml")

    assert_kind_of Hash, preset["subject"]["context"]
    assert_includes preset["subject"]["context"], "sections"
    assert_kind_of Hash, preset["subject"]["context"]["sections"]["changes"]
    assert_equal "Changes to Review", preset["subject"]["context"]["sections"]["changes"]["title"]
  end

  def test_extracts_subject_from_new_ace_context_format
    # Git operations are mocked - no need to create real commits
    config = {
      "bundle" => {
        "sections" => {
          "changes" => {
            "title" => "Recent Changes",
            "diffs" => ["HEAD~1..HEAD"]
          }
        }
      }
    }

    result = @extractor.extract(config)

    assert_kind_of String, result
    # Result should contain diff output (processed by ace-bundle)
    assert !result.nil?
  end

  def test_extracts_subject_from_hash_config_with_paths
    # Git operations are mocked - no need to create real files/commits
    config = {
      "diff" => {
        "ranges" => ["HEAD~1..HEAD"]
      },
      "files" => ["lib/**/*.rb"]
    }

    result = @extractor.extract(config)

    assert_kind_of String, result
  end

  def test_supports_legacy_string_diff_format
    # Git operations are mocked - no need to create real commits
    # Old format: diff as a string
    config = {
      "diff" => "HEAD~1..HEAD"
    }

    result = @extractor.extract(config)

    assert_kind_of String, result
    assert !result.nil?
  end

  def test_handles_new_ace_context_format_directly
    # Test that SubjectExtractor passes new ace-bundle format directly
    config = {
      "bundle" => {
        "sections" => {
          "changes" => {
            "title" => "Multiple Changes",
            "diffs" => ["origin/main...HEAD", "HEAD~5..HEAD"]
          }
        }
      }
    }

    result = @extractor.extract(config)
    assert_kind_of String, result
    # Result should contain diff output (processed by ace-bundle)
    assert !result.nil?
  end

  def test_extracts_from_preset_with_since_key
    config = {
      "diff" => {
        "since" => "1 day ago"
      }
    }

    # Should not raise an error (since is valid alternative to ranges)
    result = @extractor.extract(config)
    assert_kind_of String, result
  end

  def test_supports_commands_as_fallback
    # Git operations are mocked - no need to create real commits
    config = {
      "commands" => ["git diff HEAD~1..HEAD"]
    }

    result = @extractor.extract(config)

    assert_kind_of String, result
  end

  def test_extracts_from_string_special_keywords
    # Git operations are mocked - ace-bundle handles git diffs via ace-git
    result = @extractor.extract("staged")

    assert_kind_of String, result
  end

  def test_extracts_from_string_git_range
    # Git operations are mocked - Ace::Bundle.load_auto returns mock diff
    result = @extractor.extract("HEAD~1..HEAD")

    assert_kind_of String, result
  end
end
