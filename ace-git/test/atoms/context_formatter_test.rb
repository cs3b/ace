# frozen_string_literal: true

require_relative "../test_helper"

class ContextFormatterTest < AceGitTestCase
  def test_to_markdown_includes_branch_name
    context = Ace::Git::Models::RepoContext.new(
      branch: "feature-123",
      tracking: "origin/feature-123",
      repository_state: :clean
    )

    markdown = Ace::Git::Atoms::ContextFormatter.to_markdown(context)

    assert_match(/# Repository Context/, markdown)
    assert_match(/Branch: feature-123/, markdown)
  end

  def test_to_markdown_shows_detached_head
    context = Ace::Git::Models::RepoContext.new(
      branch: "HEAD",
      repository_type: :detached,
      repository_state: :clean
    )

    markdown = Ace::Git::Atoms::ContextFormatter.to_markdown(context)

    assert_match(/\(detached HEAD\)/, markdown)
  end

  def test_to_markdown_includes_tracking_info
    context = Ace::Git::Models::RepoContext.new(
      branch: "main",
      tracking: "origin/main",
      ahead: 2,
      behind: 0,
      repository_state: :clean
    )

    markdown = Ace::Git::Atoms::ContextFormatter.to_markdown(context)

    # Combined branch and remote format
    assert_match(/Branch: main => origin\/main \(2 ahead\)/, markdown)
    # No separate Remote line
    refute_match(/Remote:/, markdown)
  end

  def test_to_markdown_includes_task_pattern
    context = Ace::Git::Models::RepoContext.new(
      branch: "140-feature",
      task_pattern: "140",
      repository_state: :clean
    )

    markdown = Ace::Git::Atoms::ContextFormatter.to_markdown(context)

    assert_match(/Task Pattern: 140/, markdown)
  end

  def test_to_markdown_includes_pr_metadata
    context = Ace::Git::Models::RepoContext.new(
      branch: "feature-123",
      repository_state: :clean,
      pr_metadata: {
        "number" => 82,
        "title" => "Add new feature",
        "state" => "OPEN",
        "isDraft" => false,
        "baseRefName" => "main",
        "url" => "https://github.com/owner/repo/pull/82"
      }
    )

    markdown = Ace::Git::Atoms::ContextFormatter.to_markdown(context)

    # Compact header format: ## PR #82: Title [STATUS]
    assert_match(/## PR #82: Add new feature \[OPEN\]/, markdown)
    assert_match(/Target: main \| Draft: No/, markdown)
    assert_match(%r{URL: https://github\.com/owner/repo/pull/82}, markdown)
  end

  def test_to_markdown_handles_missing_pr_fields
    context = Ace::Git::Models::RepoContext.new(
      branch: "feature-123",
      repository_state: :clean,
      pr_metadata: {
        "number" => 82
        # Other fields are missing
      }
    )

    markdown = Ace::Git::Atoms::ContextFormatter.to_markdown(context)

    # Compact header with just PR number (no title/status)
    assert_match(/## PR #82/, markdown)
    refute_match(/Target:/, markdown)
  end
end
