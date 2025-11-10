# frozen_string_literal: true

require_relative "../test_helper"
require "yaml"
require "tmpdir"

class PresetDiffIntegrationTest < AceReviewTest
  def setup
    super
    @extractor = Ace::Review::Molecules::SubjectExtractor.new

    # Initialize a git repo for testing
    system("git init -q")
    system("git config user.name 'Test'")
    system("git config user.email 'test@test.com'")

    # Create initial commit
    File.write("test.txt", "initial content")
    system("git add test.txt")
    system("git commit -q -m 'Initial commit'")
  end

  def test_loads_preset_with_new_subject_format
    preset_content = <<~YAML
      description: "Test PR preset"
      subject:
        context:
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
    # Create a change to diff
    File.write("test.txt", "modified content")
    system("git add test.txt")
    system("git commit -q -m 'Modify test'")

    config = {
      "context" => {
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
    # Result should contain diff output (processed by ace-context)
    assert !result.nil?
  end

  def test_extracts_subject_from_hash_config_with_paths
    # Create multiple files
    FileUtils.mkdir_p("lib")
    FileUtils.mkdir_p("test")
    File.write("lib/test.rb", "ruby code")
    File.write("test/test.rb", "test code")
    system("git add .")
    system("git commit -q -m 'Add files'")

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
    # Create a change
    File.write("legacy.txt", "legacy change")
    system("git add legacy.txt")
    system("git commit -q -m 'Legacy change'")

    # Old format: diff as a string
    config = {
      "diff" => "HEAD~1..HEAD"
    }

    result = @extractor.extract(config)

    assert_kind_of String, result
    assert !result.nil?
  end

  def test_handles_new_ace_context_format_directly
    # Test that SubjectExtractor passes new ace-context format directly
    config = {
      "context" => {
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
    # Result should contain diff output (processed by ace-context)
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
    # Create a change
    File.write("cmd.txt", "command change")
    system("git add cmd.txt")
    system("git commit -q -m 'Command change'")

    config = {
      "commands" => ["git diff HEAD~1..HEAD"]
    }

    result = @extractor.extract(config)

    assert_kind_of String, result
  end

  def test_extracts_from_string_special_keywords
    # Create staged change
    File.write("staged.txt", "staged change")
    system("git add staged.txt")

    result = @extractor.extract("staged")

    assert_kind_of String, result
  end

  def test_extracts_from_string_git_range
    # Create commits
    File.write("range1.txt", "first")
    system("git add range1.txt")
    system("git commit -q -m 'First'")

    File.write("range2.txt", "second")
    system("git add range2.txt")
    system("git commit -q -m 'Second'")

    result = @extractor.extract("HEAD~1..HEAD")

    assert_kind_of String, result
  end
end
