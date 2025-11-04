# frozen_string_literal: true

require_relative "../test_helper"

class WorktreeManagerTest < Minitest::Test
  def setup
    setup_temp_dir
    @manager = Ace::Git::Worktree::Organisms::WorktreeManager.new
  end

  def teardown
    teardown_temp_dir
  end

  def test_create_task_worktree_success
    # Mock successful task metadata fetch
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix authentication bug",
      status: "🟡 In Progress",
      estimate: "2-4 hours"
    )

    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, task_metadata, ["081"])

    # Mock successful worktree creation
    mock_worktree_creator = Minitest::Mock.new
    mock_worktree_creator.expect(:create_worktree, true) do |options|
      assert_equal "feature/task-081-fix-authentication", options[:branch]
      assert options[:path].include?("task-081")
      assert_equal task_metadata, options[:task_metadata]
    end

    # Mock successful mise trust
    mock_mise_trustor = Minitest::Mock.new
    mock_mise_trustor.expect(:trust_worktree, { success: true }, [String])

    @manager.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @manager.instance_variable_set(:@worktree_creator, mock_worktree_creator)
    @manager.instance_variable_set(:@mise_trustor, mock_mise_trustor)

    result = @manager.create_task_worktree(task_id: "081")

    assert result[:success]
    assert_match(/created successfully/i, result[:message])
    assert task_metadata, result[:task_metadata]

    mock_task_fetcher.verify
    mock_worktree_creator.verify
    mock_mise_trustor.verify
  end

  def test_create_task_worktree_task_not_found
    # Mock task not found
    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, nil, ["999"])

    @manager.instance_variable_set(:@task_fetcher, mock_task_fetcher)

    result = @manager.create_task_worktree(task_id: "999")

    refute result[:success]
    assert_match(/not found/i, result[:message])
    assert_nil result[:task_metadata]

    mock_task_fetcher.verify
  end

  def test_create_task_worktree_with_dry_run
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix authentication bug"
    )

    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, task_metadata, ["081"])

    mock_worktree_creator = Minitest::Mock.new
    mock_worktree_creator.expect(:create_worktree, true) do |options|
      assert options[:dry_run]
    end

    @manager.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @manager.instance_variable_set(:@worktree_creator, mock_worktree_creator)

    result = @manager.create_task_worktree(task_id: "081", dry_run: true)

    assert result[:success]
    assert_match(/dry run/i, result[:message])

    mock_task_fetcher.verify
    mock_worktree_creator.verify
  end

  def test_create_task_worktree_with_custom_path
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix authentication bug"
    )

    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, task_metadata, ["081"])

    mock_worktree_creator = Minitest::Mock.new
    mock_worktree_creator.expect(:create_worktree, true) do |options|
      assert_equal "/custom/path", options[:path]
    end

    @manager.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @manager.instance_variable_set(:@worktree_creator, mock_worktree_creator)

    result = @manager.create_task_worktree(
      task_id: "081",
      path: "/custom/path"
    )

    assert result[:success]

    mock_task_fetcher.verify
    mock_worktree_creator.verify
  end

  def test_create_traditional_worktree_success
    mock_worktree_creator = Minitest::Mock.new
    mock_worktree_creator.expect(:create_worktree, true) do |options|
      assert_equal "feature-branch", options[:branch]
      assert_equal "/custom/path", options[:path]
    end

    @manager.instance_variable_set(:@worktree_creator, mock_worktree_creator)

    result = @manager.create_traditional_worktree(
      branch: "feature-branch",
      path: "/custom/path"
    )

    assert result[:success]

    mock_worktree_creator.verify
  end

  def test_list_worktrees_success
    mock_worktrees = [
      {
        path: "/path/to/main",
        branch: "main",
        commit: "abc123",
        bare: false,
        detached: false
      },
      {
        path: "/path/to/feature",
        branch: "feature-branch",
        commit: "def456",
        bare: false,
        detached: false
      }
    ]

    mock_worktree_lister = Minitest::Mock.new
    mock_worktree_lister.expect(:list_worktrees, mock_worktrees, [Hash])

    @manager.instance_variable_set(:@worktree_lister, mock_worktree_lister)

    result = @manager.list_worktrees

    assert result[:success]
    assert_equal 2, result[:worktrees].length

    mock_worktree_lister.verify
  end

  def test_remove_worktree_success
    mock_worktree_remover = Minitest::Mock.new
    mock_worktree_remover.expect(:remove_worktree, true, [Hash])

    @manager.instance_variable_set(:@worktree_remover, mock_worktree_remover)

    result = @manager.remove_worktree(path: "/path/to/worktree")

    assert result[:success]

    mock_worktree_remover.verify
  end

  def test_switch_to_worktree_success
    mock_worktree_remover = Minitest::Mock.new
    mock_worktree_remover.expect(:switch_to_worktree, true, [Hash])

    @manager.instance_variable_set(:@worktree_remover, mock_worktree_remover)

    result = @manager.switch_to_worktree(path: "/path/to/worktree")

    assert result[:success]

    mock_worktree_remover.verify
  end

  def test_switch_to_branch_success
    mock_worktree_remover = Minitest::Mock.new
    mock_worktree_remover.expect(:switch_to_branch, true, [Hash])

    @manager.instance_variable_set(:@worktree_remover, mock_worktree_remover)

    result = @manager.switch_to_branch(branch: "feature-branch")

    assert result[:success]

    mock_worktree_remover.verify
  end

  def test_switch_to_task_worktree_success
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix authentication bug"
    )

    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, task_metadata, ["081"])

    mock_worktree_lister = Minitest::Mock.new
    task_worktree = {
      path: "/path/to/task-081",
      branch: "feature/task-081",
      task_metadata: task_metadata
    }
    mock_worktree_lister.expect(:list_worktrees, [task_worktree], [Hash])

    mock_worktree_remover = Minitest::Mock.new
    mock_worktree_remover.expect(:switch_to_worktree, true, [Hash])

    @manager.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @manager.instance_variable_set(:@worktree_lister, mock_worktree_lister)
    @manager.instance_variable_set(:@worktree_remover, mock_worktree_remover)

    result = @manager.switch_to_task_worktree(task_id: "081")

    assert result[:success]

    mock_task_fetcher.verify
    mock_worktree_lister.verify
    mock_worktree_remover.verify
  end

  def test_prune_worktrees_success
    mock_worktree_remover = Minitest::Mock.new
    mock_worktree_remover.expect(:prune_worktrees, true, [Hash])

    @manager.instance_variable_set(:@worktree_remover, mock_worktree_remover)

    result = @manager.prune_worktrees

    assert result[:success]

    mock_worktree_remover.verify
  end

  def test_handles_task_fetcher_unavailable
    # Mock task fetcher as unavailable
    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:ace_taskflow_available?, false)

    @manager.instance_variable_set(:@task_fetcher, mock_task_fetcher)

    result = @manager.create_task_worktree(task_id: "081")

    refute result[:success]
    assert_match(/ace-taskflow not available/i, result[:message])

    mock_task_fetcher.verify
  end

  def test_handles_dangerous_task_id
    dangerous_task_id = "081; rm -rf /"

    result = @manager.create_task_worktree(task_id: dangerous_task_id)

    refute result[:success]
    assert_match(/invalid.*task.*id/i, result[:message])
  end

  def test_handles_dangerous_path
    dangerous_paths = [
      "/etc/passwd",
      "../../../root",
      "/path; rm -rf /"
    ]

    dangerous_paths.each do |dangerous_path|
      result = @manager.create_traditional_worktree(
        branch: "safe-branch",
        path: dangerous_path
      )

      refute result[:success], "Should reject dangerous path: #{dangerous_path}"
    end
  end

  def test_validation_blocks_malformed_options
    # Test with nil or empty required options
    result = @manager.create_task_worktree(task_id: nil)
    refute result[:success]

    result = @manager.create_task_worktree(task_id: "")
    refute result[:success]

    result = @manager.create_traditional_worktree(branch: nil)
    refute result[:success]

    result = @manager.remove_worktree(path: nil)
    refute result[:success]
  end

  def test_error_propagation_from_dependencies
    # Test that errors from dependencies are properly handled
    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, nil) do
      raise StandardError, "Network error"
    end

    @manager.instance_variable_set(:@task_fetcher, mock_task_fetcher)

    result = @manager.create_task_worktree(task_id: "081")

    refute result[:success]
    assert_match(/Network error/i, result[:message])

    mock_task_fetcher.verify
  end

  def test_integration_workflow
    # Test a complete workflow: create -> list -> switch -> remove
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix authentication bug"
    )

    # Mock successful operations
    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, task_metadata, ["081"])

    mock_worktree_creator = Minitest::Mock.new
    mock_worktree_creator.expect(:create_worktree, true, [Hash])

    mock_worktree_lister = Minitest::Mock.new
    created_worktree = {
      path: "/path/to/task-081",
      branch: "feature/task-081",
      task_metadata: task_metadata
    }
    mock_worktree_lister.expect(:list_worktrees, [created_worktree], [Hash])

    mock_worktree_remover = Minitest::Mock.new
    mock_worktree_remover.expect(:switch_to_worktree, true, [Hash])
    mock_worktree_remover.expect(:remove_worktree, true, [Hash])

    @manager.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @manager.instance_variable_set(:@worktree_creator, mock_worktree_creator)
    @manager.instance_variable_set(:@worktree_lister, mock_worktree_lister)
    @manager.instance_variable_set(:@worktree_remover, mock_worktree_remover)

    # Create task worktree
    result = @manager.create_task_worktree(task_id: "081")
    assert result[:success]

    # List worktrees
    result = @manager.list_worktrees
    assert result[:success]
    assert_equal 1, result[:worktrees].length

    # Switch to worktree
    result = @manager.switch_to_worktree(path: "/path/to/task-081")
    assert result[:success]

    # Remove worktree
    result = @manager.remove_worktree(path: "/path/to/task-081")
    assert result[:success]

    mock_task_fetcher.verify
    mock_worktree_creator.verify
    mock_worktree_lister.verify
    mock_worktree_remover.verify
  end
end