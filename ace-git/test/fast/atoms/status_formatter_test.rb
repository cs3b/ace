# frozen_string_literal: true

require "test_helper"

class StatusFormatterTest < AceGitTestCase
  def test_to_markdown_includes_header_and_position_section
    context = Ace::Git::Models::RepoStatus.new(
      branch: "feature-123",
      tracking: "origin/feature-123",
      repository_state: :clean
    )

    markdown = Ace::Git::Atoms::StatusFormatter.to_markdown(context)

    assert_match(/# Repository Status/, markdown)
    assert_match(/## Position/, markdown)
    assert_match(/Branch: feature-123/, markdown)
  end

  def test_to_markdown_shows_detached_head
    context = Ace::Git::Models::RepoStatus.new(
      branch: "HEAD",
      repository_type: :detached,
      repository_state: :clean
    )

    markdown = Ace::Git::Atoms::StatusFormatter.to_markdown(context)

    assert_match(/\(detached HEAD\)/, markdown)
  end

  def test_to_markdown_includes_git_status_in_position
    context = Ace::Git::Models::RepoStatus.new(
      branch: "main",
      repository_state: :clean,
      git_status_sb: "## main...origin/main"
    )

    markdown = Ace::Git::Atoms::StatusFormatter.to_markdown(context)

    assert_match(/## Position/, markdown)
    assert_match(/## main\.\.\.origin\/main/, markdown)
  end

  def test_to_markdown_includes_task_pattern_in_header
    context = Ace::Git::Models::RepoStatus.new(
      branch: "140-feature",
      task_pattern: "140",
      repository_state: :clean
    )

    markdown = Ace::Git::Atoms::StatusFormatter.to_markdown(context)

    assert_match(/## Position \(task: 140\)/, markdown)
  end

  def test_to_markdown_includes_file_changes_in_position
    context = Ace::Git::Models::RepoStatus.new(
      branch: "main",
      repository_state: :clean,
      git_status_sb: "## main...origin/main\n M file.rb"
    )

    markdown = Ace::Git::Atoms::StatusFormatter.to_markdown(context)

    assert_match(/## Position/, markdown)
    # Raw git status output including branch line
    assert_match(/## main\.\.\.origin\/main/, markdown)
    assert_match(/M file\.rb/, markdown)
  end

  def test_to_markdown_includes_recent_commits_section
    context = Ace::Git::Models::RepoStatus.new(
      branch: "main",
      repository_state: :clean,
      recent_commits: [
        {hash: "a7404e9", subject: "feat: Add feature"},
        {hash: "74e8f77", subject: "chore: Update config"}
      ]
    )

    markdown = Ace::Git::Atoms::StatusFormatter.to_markdown(context)

    assert_match(/## Recent Commits/, markdown)
    assert_match(/a7404e9 feat: Add feature/, markdown)
    assert_match(/74e8f77 chore: Update config/, markdown)
  end

  def test_to_markdown_includes_current_pr_section
    context = Ace::Git::Models::RepoStatus.new(
      branch: "feature-123",
      repository_state: :clean,
      pr_metadata: {
        "number" => 82,
        "title" => "Add new feature",
        "state" => "OPEN",
        "isDraft" => false,
        "baseRefName" => "main",
        "headRefName" => "feature-123",
        "author" => {"login" => "dev1"},
        "url" => "https://github.com/owner/repo/pull/82"
      }
    )

    markdown = Ace::Git::Atoms::StatusFormatter.to_markdown(context)

    assert_match(/## Current PR/, markdown)
    assert_match(/#82 \[OPEN\] Add new feature/, markdown)
    assert_match(/Target: main/, markdown)
    assert_match(/Author: @dev1/, markdown)
  end

  def test_to_markdown_handles_missing_pr_fields
    context = Ace::Git::Models::RepoStatus.new(
      branch: "feature-123",
      repository_state: :clean,
      pr_metadata: {
        "number" => 82
      }
    )

    markdown = Ace::Git::Atoms::StatusFormatter.to_markdown(context)

    assert_match(/## Current PR/, markdown)
    assert_match(/#82/, markdown)
  end

  # PR Activity tests

  def test_to_markdown_includes_pr_activity_section
    context = Ace::Git::Models::RepoStatus.new(
      branch: "feature-123",
      repository_state: :clean,
      pr_activity: {
        merged: [
          {"number" => 84, "title" => "Update docs", "mergedAt" => Time.now.iso8601}
        ],
        open: [
          {"number" => 85, "title" => "New feature", "author" => {"login" => "user1"}}
        ]
      }
    )

    markdown = Ace::Git::Atoms::StatusFormatter.to_markdown(context)

    assert_match(/## PR Activity/, markdown)
    assert_match(/Merged:/, markdown)
    assert_match(/#84 Update docs/, markdown)
    assert_match(/Open:/, markdown)
    assert_match(/#85 New feature \(@user1\)/, markdown)
  end

  def test_to_markdown_shows_merged_relative_time
    merged_at = (Time.now - (2 * 60 * 60)).iso8601 # 2 hours ago
    context = Ace::Git::Models::RepoStatus.new(
      branch: "feature-123",
      repository_state: :clean,
      pr_activity: {
        merged: [{"number" => 84, "title" => "Fix bug", "mergedAt" => merged_at}],
        open: []
      }
    )

    markdown = Ace::Git::Atoms::StatusFormatter.to_markdown(context)

    assert_match(/#84 Fix bug \(2h ago\)/, markdown)
  end

  def test_to_markdown_omits_sections_when_no_prs
    context = Ace::Git::Models::RepoStatus.new(
      branch: "feature-123",
      repository_state: :clean,
      pr_activity: {
        merged: [],
        open: []
      }
    )

    markdown = Ace::Git::Atoms::StatusFormatter.to_markdown(context)

    refute context.has_pr_activity?
    refute_match(/## PR Activity/, markdown)
  end

  def test_format_pr_activity_section_with_only_merged
    activity = {
      merged: [{"number" => 84, "title" => "PR One"}],
      open: []
    }

    lines = Ace::Git::Atoms::StatusFormatter.format_pr_activity_section(activity)
    output = lines.join("\n")

    assert_match(/Merged:/, output)
    assert_match(/#84 PR One/, output)
    refute_match(/Open:/, output)
  end

  def test_format_pr_activity_section_with_only_open
    activity = {
      merged: [],
      open: [{"number" => 85, "title" => "PR Two", "author" => {"login" => "dev"}}]
    }

    lines = Ace::Git::Atoms::StatusFormatter.format_pr_activity_section(activity)
    output = lines.join("\n")

    refute_match(/Merged:/, output)
    assert_match(/Open:/, output)
    assert_match(/#85 PR Two \(@dev\)/, output)
  end

  def test_format_pr_activity_section_handles_missing_author
    activity = {
      merged: [],
      open: [{"number" => 85, "title" => "PR Without Author"}]
    }

    lines = Ace::Git::Atoms::StatusFormatter.format_pr_activity_section(activity)
    output = lines.join("\n")

    assert_match(/#85 PR Without Author/, output)
    refute_match(/@/, output)
  end

  def test_format_pr_activity_section_with_symbol_keys
    # RepoStatusLoader uses symbol keys for the structure (:merged, :open)
    # PR data within uses string keys from JSON parsing ("number", "title")
    activity = {
      merged: [{"number" => 84, "title" => "Symbol Keys"}],
      open: []
    }

    lines = Ace::Git::Atoms::StatusFormatter.format_pr_activity_section(activity)
    output = lines.join("\n")

    assert_match(/#84 Symbol Keys/, output)
  end

  # New section format tests

  def test_format_position_section_with_git_status
    context = Ace::Git::Models::RepoStatus.new(
      branch: "feature-123",
      task_pattern: "123",
      git_status_sb: "## feature-123...origin/feature-123 [ahead 1]\n M file.rb"
    )

    lines = Ace::Git::Atoms::StatusFormatter.format_position_section(context)
    output = lines.join("\n")

    assert_match(/## Position \(task: 123\)/, output)
    assert_match(/## feature-123\.\.\.origin\/feature-123/, output)
    assert_match(/M file\.rb/, output)
  end

  def test_format_position_section_without_task
    context = Ace::Git::Models::RepoStatus.new(
      branch: "main",
      git_status_sb: "## main...origin/main"
    )

    lines = Ace::Git::Atoms::StatusFormatter.format_position_section(context)
    output = lines.join("\n")

    assert_match(/## Position$/, output)
    refute_match(/task:/, output)
    assert_match(/## main\.\.\.origin\/main/, output)
  end

  def test_format_position_section_fallback_without_git_status
    context = Ace::Git::Models::RepoStatus.new(
      branch: "feature-123"
    )

    lines = Ace::Git::Atoms::StatusFormatter.format_position_section(context)
    output = lines.join("\n")

    assert_match(/## Position/, output)
    assert_match(/Branch: feature-123/, output)
  end

  def test_format_recent_commits_section
    commits = [
      {hash: "abc1234", subject: "First commit"},
      {hash: "def5678", subject: "Second commit"}
    ]

    lines = Ace::Git::Atoms::StatusFormatter.format_recent_commits_section(commits)
    output = lines.join("\n")

    assert_match(/## Recent Commits/, output)
    assert_match(/abc1234 First commit/, output)
    assert_match(/def5678 Second commit/, output)
  end

  def test_format_current_pr_section
    pr = {
      "number" => 85,
      "title" => "Feature PR",
      "state" => "OPEN",
      "baseRefName" => "main",
      "headRefName" => "feature",
      "author" => {"login" => "dev"},
      "isDraft" => false,
      "url" => "https://github.com/o/r/pull/85"
    }

    lines = Ace::Git::Atoms::StatusFormatter.format_current_pr_section(pr)
    output = lines.join("\n")

    assert_match(/## Current PR/, output)
    assert_match(/#85 \[OPEN\] Feature PR/, output)
    assert_match(/Target: main/, output)
    assert_match(/Author: @dev/, output)
    assert_match(/Not draft/, output)
  end

  def test_format_recent_commits_handles_string_keys
    commits = [
      {"hash" => "abc1234", "subject" => "String keys"}
    ]

    lines = Ace::Git::Atoms::StatusFormatter.format_recent_commits_section(commits)
    output = lines.join("\n")

    assert_match(/abc1234 String keys/, output)
  end
end
