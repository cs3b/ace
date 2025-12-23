# frozen_string_literal: true

require_relative "../test_helper"

class RepoContextTest < AceGitTestCase
  def setup
    super
    @context = Ace::Git::Models::RepoContext.new(
      branch: "140-feature",
      tracking: "origin/140-feature",
      ahead: 2,
      behind: 1,
      task_pattern: "140",
      pr_metadata: { "number" => 75, "title" => "Add feature", "state" => "open" },
      repository_type: :normal,
      repository_state: :clean
    )
  end

  def test_stores_branch_name
    assert_equal "140-feature", @context.branch
  end

  def test_stores_tracking_branch
    assert_equal "origin/140-feature", @context.tracking
  end

  def test_stores_ahead_behind_counts
    assert_equal 2, @context.ahead
    assert_equal 1, @context.behind
  end

  def test_stores_task_pattern
    assert_equal "140", @context.task_pattern
  end

  def test_stores_pr_metadata
    assert_equal 75, @context.pr_metadata["number"]
    assert_equal "Add feature", @context.pr_metadata["title"]
  end

  def test_detached_returns_true_for_head
    context = Ace::Git::Models::RepoContext.new(branch: "HEAD")
    assert context.detached?
  end

  def test_detached_returns_false_for_branch
    refute @context.detached?
  end

  def test_tracking_returns_true_when_tracking
    assert @context.tracking?
  end

  def test_tracking_returns_false_when_not_tracking
    context = Ace::Git::Models::RepoContext.new(branch: "main")
    refute context.tracking?
  end

  def test_up_to_date_returns_true_when_no_ahead_behind
    context = Ace::Git::Models::RepoContext.new(
      branch: "main",
      ahead: 0,
      behind: 0
    )
    assert context.up_to_date?
  end

  def test_up_to_date_returns_false_when_ahead
    refute @context.up_to_date?
  end

  def test_has_pr_returns_true_with_metadata
    assert @context.has_pr?
  end

  def test_has_pr_returns_false_without_metadata
    context = Ace::Git::Models::RepoContext.new(branch: "main")
    refute context.has_pr?
  end

  def test_has_task_pattern_returns_true_with_pattern
    assert @context.has_task_pattern?
  end

  def test_has_task_pattern_returns_false_without_pattern
    context = Ace::Git::Models::RepoContext.new(branch: "main")
    refute context.has_task_pattern?
  end

  def test_clean_returns_true_when_clean
    assert @context.clean?
  end

  def test_clean_returns_false_when_dirty
    context = Ace::Git::Models::RepoContext.new(
      branch: "main",
      repository_state: :dirty
    )
    refute context.clean?
  end

  def test_tracking_status_up_to_date
    context = Ace::Git::Models::RepoContext.new(
      branch: "main",
      tracking: "origin/main",
      ahead: 0,
      behind: 0
    )
    assert_equal "up to date", context.tracking_status
  end

  def test_tracking_status_ahead
    context = Ace::Git::Models::RepoContext.new(
      branch: "main",
      tracking: "origin/main",
      ahead: 3,
      behind: 0
    )
    assert_equal "3 ahead", context.tracking_status
  end

  def test_tracking_status_behind
    context = Ace::Git::Models::RepoContext.new(
      branch: "main",
      tracking: "origin/main",
      ahead: 0,
      behind: 2
    )
    assert_equal "2 behind", context.tracking_status
  end

  def test_tracking_status_ahead_and_behind
    assert_equal "2 ahead, 1 behind", @context.tracking_status
  end

  def test_to_h_returns_hash
    result = @context.to_h

    assert_instance_of Hash, result
    assert_equal "140-feature", result[:branch]
    assert_equal "140", result[:task_pattern]
    assert result[:has_pr]
  end

  def test_to_markdown_returns_string
    result = @context.to_markdown

    assert_instance_of String, result
    assert_includes result, "# Repository Context"
    assert_includes result, "Branch: 140-feature"
    assert_includes result, "Task Pattern: 140"
    # Compact PR format: ## PR #75: Add feature [open]
    assert_includes result, "## PR #75"
  end

  def test_from_data_creates_instance
    context = Ace::Git::Models::RepoContext.from_data(
      branch_info: { name: "main", tracking: nil, ahead: 0, behind: 0 },
      task_pattern: nil,
      pr_metadata: nil,
      repo_type: :normal,
      repo_state: :clean
    )

    assert_equal "main", context.branch
    assert_nil context.task_pattern
    refute context.has_pr?
  end
end
