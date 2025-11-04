# frozen_string_literal: true

require "test_helper"

class TaskMetadataTest < AceGitWorktreeTestCase
  def test_initialization_with_minimal_data
    metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix authentication bug"
    )

    assert_equal "081", metadata.id
    assert_equal "081", metadata.full_id
    assert_equal "Fix authentication bug", metadata.title
    assert_equal "pending", metadata.status
    assert_equal "081", metadata.number
    assert_nil metadata.release
    assert_nil metadata.priority
    assert_nil metadata.estimate
    assert_empty metadata.dependencies
    assert_nil metadata.path
  end

  def test_initialization_with_full_data
    metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "v.0.9.0+task.081",
      full_id: "v.0.9.0+task.081",
      release: "v.0.9.0",
      number: "081",
      title: "Fix authentication bug",
      status: "in-progress",
      priority: "high",
      estimate: "2h",
      dependencies: ["task.080", "task.079"],
      path: ".ace-taskflow/v.0.9.0/tasks/081-fix-auth/task.081.md"
    )

    assert_equal "v.0.9.0+task.081", metadata.id
    assert_equal "v.0.9.0+task.081", metadata.full_id
    assert_equal "v.0.9.0", metadata.release
    assert_equal "081", metadata.number
    assert_equal "Fix authentication bug", metadata.title
    assert_equal "in-progress", metadata.status
    assert_equal "high", metadata.priority
    assert_equal "2h", metadata.estimate
    assert_equal ["task.080", "task.079"], metadata.dependencies
    assert_equal ".ace-taskflow/v.0.9.0/tasks/081-fix-auth/task.081.md", metadata.path
  end

  def test_slug_generation
    metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix Authentication Bug #123"
    )

    assert_equal "fix-authentication-bug-123", metadata.slug
    assert_equal "fix-auth", metadata.slug(max_length: 10)
    assert_equal "fix_authentication_bug_123", metadata.slug(separator: "_")
  end

  def test_slug_with_empty_title
    metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: ""
    )

    assert_equal "", metadata.slug
  end

  def test_status_check_methods
    pending = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Task",
      status: "pending"
    )

    assert pending.pending?
    refute pending.in_progress?
    refute pending.done?
    refute pending.blocked?

    in_progress = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "082",
      title: "Task",
      status: "in-progress"
    )

    refute in_progress.pending?
    assert in_progress.in_progress?
    refute in_progress.done?
    refute in_progress.blocked?

    done = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "083",
      title: "Task",
      status: "done"
    )

    refute done.pending?
    refute done.in_progress?
    assert done.done?
    refute done.blocked?

    blocked = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "084",
      title: "Task",
      status: "blocked"
    )

    refute blocked.pending?
    refute blocked.in_progress?
    refute blocked.done?
    assert blocked.blocked?
  end

  def test_template_variables
    metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "v.0.9.0+task.081",
      full_id: "v.0.9.0+task.081",
      release: "v.0.9.0",
      number: "081",
      title: "Fix authentication bug"
    )

    variables = metadata.template_variables

    assert_equal "081", variables[:id]
    assert_equal "v.0.9.0+task.081", variables[:task_id]
    assert_equal "v.0.9.0", variables[:release]
    assert_equal "fix-authentication-bug", variables[:slug]
  end

  def test_to_h_returns_hash_representation
    metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "v.0.9.0+task.081",
      full_id: "v.0.9.0+task.081",
      release: "v.0.9.0",
      number: "081",
      title: "Fix authentication bug",
      status: "in-progress",
      priority: "high"
    )

    hash = metadata.to_h

    assert_equal "v.0.9.0+task.081", hash[:id]
    assert_equal "v.0.9.0+task.081", hash[:full_id]
    assert_equal "v.0.9.0", hash[:release]
    assert_equal "081", hash[:number]
    assert_equal "Fix authentication bug", hash[:title]
    assert_equal "in-progress", hash[:status]
    assert_equal "high", hash[:priority]
    refute hash.key?(:estimate) # nil values should be compacted
    refute hash.key?(:path)
  end

  def test_from_taskflow_output_parsing
    output = <<~YAML
      ---
      id: v.0.9.0+task.081
      status: pending
      priority: high
      estimate: 2h
      dependencies:
        - task.080
      ---
      # Fix authentication bug

      Task description here...
    YAML

    metadata = Ace::Git::Worktree::Models::TaskMetadata.from_taskflow_output(output)

    assert_equal "v.0.9.0+task.081", metadata.id
    assert_equal "v.0.9.0+task.081", metadata.full_id
    assert_equal "v.0.9.0", metadata.release
    assert_equal "081", metadata.number
    assert_equal "Fix authentication bug", metadata.title
    assert_equal "pending", metadata.status
    assert_equal "high", metadata.priority
    assert_equal "2h", metadata.estimate
    assert_equal ["task.080"], metadata.dependencies
  end

  def test_from_taskflow_output_with_invalid_input
    assert_nil Ace::Git::Worktree::Models::TaskMetadata.from_taskflow_output(nil)
    assert_nil Ace::Git::Worktree::Models::TaskMetadata.from_taskflow_output("")
    assert_nil Ace::Git::Worktree::Models::TaskMetadata.from_taskflow_output("not yaml")
  end

  def test_from_list_output_parsing
    line = "v.0.9.0+task.081 🟡 Fix authentication bug"

    metadata = Ace::Git::Worktree::Models::TaskMetadata.from_list_output(line)

    assert_equal "v.0.9.0+task.081", metadata.id
    assert_equal "v.0.9.0+task.081", metadata.full_id
    assert_equal "v.0.9.0", metadata.release
    assert_equal "081", metadata.number
    assert_equal "Fix authentication bug", metadata.title
  end

  def test_from_list_output_with_invalid_input
    assert_nil Ace::Git::Worktree::Models::TaskMetadata.from_list_output(nil)
    assert_nil Ace::Git::Worktree::Models::TaskMetadata.from_list_output("")
    assert_nil Ace::Git::Worktree::Models::TaskMetadata.from_list_output("not a task line")
  end

  def test_extract_number_from_various_formats
    # Test with just number
    metadata1 = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Test"
    )
    assert_equal "081", metadata1.number

    # Test with task prefix
    metadata2 = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "task.081",
      title: "Test"
    )
    assert_equal "081", metadata2.number

    # Test with full ID
    metadata3 = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "v.0.9.0+task.081",
      title: "Test"
    )
    assert_equal "081", metadata3.number

    # Test with non-matching format
    metadata4 = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "feature-branch",
      title: "Test"
    )
    assert_equal "feature-branch", metadata4.number
  end
end