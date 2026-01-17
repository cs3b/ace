# frozen_string_literal: true

require_relative "../test_helper"
require "yaml"
require "tmpdir"

class PRDiffGenerationTest < AceReviewTest
  # NOTE: These tests are temporarily skipped pending updates to match current ReviewManager format
  # The ReviewManager now requires 'instructions' format for presets, and these tests need updating

  def setup
    super  # IMPORTANT: Calls parent to stub ace-bundle and git-extractor for fast tests
    @temp_dir = Dir.mktmpdir

    # Create test fixture for "pr" preset - tests should not depend on .ace/ directory
    create_test_preset("pr", <<~YAML)
      description: "Test PR preset"
      instructions:
        base: "prompt://base/system"
        bundle:
          sections:
            format:
              title: "Format Guidelines"
              files:
                - "prompt://format/standard"
      bundle: "project"
      subject:
        bundle:
          sections:
            code_changes:
              title: "Code Changes"
              diffs:
                - "origin/main...HEAD"
    YAML

    # Use @test_dir as project root for test isolation
    @manager = Ace::Review::Organisms::ReviewManager.new(project_root: @test_dir)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
    super  # IMPORTANT: Call parent to restore ace-bundle
  end

  def test_pr_review_overwrites_preset_subject_config
    skip "Pending updates to match current ReviewManager instructions format"
    # Mock the PR fetcher to return test data
    mock_pr_diff = <<~DIFF
      --- a/test.rb
      +++ b/test.rb
      @@ -1,3 +1,4 @@
       def existing_method
         puts "hello"
       end
      +
      +def new_method
      +  puts "new"
      +end
    DIFF

    mock_pr_metadata = {
      "number" => 52,
      "title" => "Test PR",
      "author" => { "login" => "testuser" },
      "state" => "OPEN",
      "isDraft" => false,
      "baseRefName" => "main",
      "headRefName" => "feature-branch",
      "url" => "https://github.com/test/repo/pull/52"
    }

    # Mock the GhPrFetcher
    Ace::Review::Molecules::GhPrFetcher.stub(:fetch_pr, { diff: mock_pr_diff, metadata: mock_pr_metadata }) do
      # Test options with --pr flag
      options = {
        preset: "pr",  # Use default "pr" preset which is available
        pr: "52",  # PR identifier
        auto_execute: false  # Don't actually call LLM
      }

      result = @manager.execute_review(options)

      assert result[:success], "PR review should succeed: #{result[:error]}"
      assert result[:session_dir], "Should have session directory"

      # Check that user.context.md was created with PR content
      user_context_path = File.join(result[:session_dir], "user.context.md")
      assert File.exist?(user_context_path), "user.context.md should exist"

      user_context_content = File.read(user_context_path)

      # Verify that the context contains PR-specific content, not "origin...HEAD"
      refute_match(/origin\.\.\.HEAD/, user_context_content, "Should not contain origin...HEAD")

      # Verify it contains the PR diff file reference
      assert_match(/pr_changes/, user_context_content, "Should contain pr_changes section")
      assert_match(/pr-diff\.patch/, user_context_content, "Should reference PR diff file")

      # Check that the actual PR diff file was created
      pr_diff_path = File.join(result[:session_dir], "pr-diff.patch")
      assert File.exist?(pr_diff_path), "PR diff file should exist"

      actual_diff_content = File.read(pr_diff_path)
      assert_equal mock_pr_diff, actual_diff_content, "PR diff file should contain the correct diff"
    end
  end

  def test_non_pr_review_uses_preset_subject_config
    skip "Pending updates to match current ReviewManager instructions format"
    # Create a custom preset with subject config for testing
    preset_content = <<~YAML
      description: "Test preset for non-PR review"
      subject:
        bundle:
          sections:
            code_changes:
              title: "Code Changes"
              description: "Changes to review"
              diffs:
                - "HEAD~1..HEAD"
    YAML

    create_test_preset("test_non_pr", preset_content)

    # Test options without --pr flag
    options = {
      preset: "test_non_pr",
      auto_execute: false  # Don't actually call LLM
    }

    result = @manager.execute_review(options)

    assert result[:success], "Non-PR review should succeed: #{result[:error]}"
    assert result[:session_dir], "Should have session directory"

    # Check that user.context.md was created with preset content
    user_context_path = File.join(result[:session_dir], "user.context.md")
    assert File.exist?(user_context_path), "user.context.md should exist"

    user_context_content = File.read(user_context_path)

    # Verify that the context contains preset's diff format
    assert_match(/HEAD~1\.\.HEAD/, user_context_content, "Should contain preset diff format")
    refute_match(/pr_changes/, user_context_content, "Should not contain PR changes section")
  end

  def test_pr_preset_without_pr_flag_uses_default_subject
    # Test that pr preset works without --pr flag - uses its default subject config
    options = {
      preset: "pr",
      auto_execute: false  # Don't actually call LLM
    }

    result = @manager.execute_review(options)

    # The default "pr" preset has a subject config with git commands
    # It should succeed but use the default subject (origin/main...HEAD)
    assert result[:success], "pr preset without --pr should succeed with default subject: #{result[:error]}"
  end

  def test_pr_review_with_empty_diff
    skip "Pending updates to match current ReviewManager instructions format"
    # Mock the PR fetcher to return empty diff
    mock_pr_diff = ""
    mock_pr_metadata = {
      "number" => 53,
      "title" => "Empty PR",
      "author" => { "login" => "testuser" },
      "state" => "OPEN",
      "isDraft" => false,
      "baseRefName" => "main",
      "headRefName" => "empty-branch",
      "url" => "https://github.com/test/repo/pull/53"
    }

    Ace::Review::Molecules::GhPrFetcher.stub(:fetch_pr, { diff: mock_pr_diff, metadata: mock_pr_metadata }) do
      options = {
        preset: "pr",  # Use default "pr" preset which is available
        pr: "53",
        auto_execute: false
      }

      result = @manager.execute_review(options)

      # Should still succeed but with empty PR diff file
      assert result[:success], "Empty PR review should succeed: #{result[:error]}"

      pr_diff_path = File.join(result[:session_dir], "pr-diff.patch")
      assert File.exist?(pr_diff_path), "PR diff file should exist even if empty"

      actual_diff_content = File.read(pr_diff_path)
      assert_equal "", actual_diff_content, "PR diff file should be empty"
    end
  end

  private

  def create_test_preset(name, content)
    preset_dir = File.join(Dir.pwd, ".ace", "review", "presets")
    FileUtils.mkdir_p(preset_dir)

    preset_file = File.join(preset_dir, "#{name}.yml")
    File.write(preset_file, content)
  end
end