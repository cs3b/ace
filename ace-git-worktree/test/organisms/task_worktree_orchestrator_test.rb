# frozen_string_literal: true

require_relative "../test_helper"

class TaskWorktreeOrchestratorTest < Minitest::Test
  def setup
    setup_temp_dir
    @orchestrator = Ace::Git::Worktree::Organisms::TaskWorktreeOrchestrator.new
  end

  def teardown
    teardown_temp_dir
  end

  def test_orchestrate_task_worktree_creation_success
    # Mock successful task metadata fetch
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix authentication bug",
      status: "🟡 In Progress",
      estimate: "2-4 hours"
    )

    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, task_metadata, ["081"])

    # Mock successful worktree manager operations
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task_worktree,
      { success: true, path: "/path/to/task-081" }, [Hash])
    mock_worktree_manager.expect(:switch_to_worktree,
      { success: true }, [Hash])

    # Mock successful task status update
    mock_task_status_updater = Minitest::Mock.new
    mock_task_status_updater.expect(:update_task_status, true, [Hash])

    # Mock successful mise trust
    mock_mise_trustor = Minitest::Mock.new
    mock_mise_trustor.expect(:trust_worktree, { success: true }, [String])

    @orchestrator.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @orchestrator.instance_variable_set(:@worktree_manager, mock_worktree_manager)
    @orchestrator.instance_variable_set(:@task_status_updater, mock_task_status_updater)
    @orchestrator.instance_variable_set(:@mise_trustor, mock_mise_trustor)

    result = @orchestrator.orchestrate_task_worktree_creation(
      task_id: "081",
      switch_to_worktree: true
    )

    assert result[:success]
    assert_match(/orchestrated successfully/i, result[:message])
    assert_equal task_metadata, result[:task_metadata]
    assert_match(/task-081/, result[:worktree_path])

    mock_task_fetcher.verify
    mock_worktree_manager.verify
    mock_task_status_updater.verify
    mock_mise_trustor.verify
  end

  def test_orchestrate_task_worktree_creation_without_switching
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix authentication bug"
    )

    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, task_metadata, ["081"])

    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task_worktree,
      { success: true, path: "/path/to/task-081" }, [Hash])

    # Should not call switch_to_worktree when switch_to_worktree is false
    mock_task_status_updater = Minitest::Mock.new
    mock_task_status_updater.expect(:update_task_status, true, [Hash])

    mock_mise_trustor = Minitest::Mock.new
    mock_mise_trustor.expect(:trust_worktree, { success: true }, [String])

    @orchestrator.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @orchestrator.instance_variable_set(:@worktree_manager, mock_worktree_manager)
    @orchestrator.instance_variable_set(:@task_status_updater, mock_task_status_updater)
    @orchestrator.instance_variable_set(:@mise_trustor, mock_mise_trustor)

    result = @orchestrator.orchestrate_task_worktree_creation(
      task_id: "081",
      switch_to_worktree: false
    )

    assert result[:success]
    assert_match(/created successfully/i, result[:message])

    mock_task_fetcher.verify
    mock_worktree_manager.verify
    mock_task_status_updater.verify
    mock_mise_trustor.verify
  end

  def test_orchestrate_task_worktree_creation_task_not_found
    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, nil, ["999"])

    @orchestrator.instance_variable_set(:@task_fetcher, mock_task_fetcher)

    result = @orchestrator.orchestrate_task_worktree_creation(task_id: "999")

    refute result[:success]
    assert_match(/task.*not found/i, result[:message])
    assert_nil result[:task_metadata]

    mock_task_fetcher.verify
  end

  def test_orchestrate_task_worktree_creation_worktree_creation_fails
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix authentication bug"
    )

    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, task_metadata, ["081"])

    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task_worktree,
      { success: false, error: "Git command failed" }, [Hash])

    @orchestrator.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @orchestrator.instance_variable_set(:@worktree_manager, mock_worktree_manager)

    result = @orchestrator.orchestrate_task_worktree_creation(task_id: "081")

    refute result[:success]
    assert_match(/Git command failed/i, result[:message])

    mock_task_fetcher.verify
    mock_worktree_manager.verify
  end

  def test_orchestrate_task_worktree_creation_with_dry_run
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix authentication bug"
    )

    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, task_metadata, ["081"])

    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task_worktree,
      { success: true, path: "/path/to/task-081" }, [Hash])

    # Should not update task status or switch worktree in dry run
    mock_mise_trustor = Minitest::Mock.new
    mock_mise_trustor.expect(:trust_worktree, { success: true }, [String])

    @orchestrator.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @orchestrator.instance_variable_set(:@worktree_manager, mock_worktree_manager)
    @orchestrator.instance_variable_set(:@mise_trustor, mock_mise_trustor)

    result = @orchestrator.orchestrate_task_worktree_creation(
      task_id: "081",
      dry_run: true
    )

    assert result[:success]
    assert_match(/dry run/i, result[:message])

    mock_task_fetcher.verify
    mock_worktree_manager.verify
    mock_mise_trustor.verify
  end

  def test_orchestrate_task_worktree_creation_handles_mise_unavailable
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix authentication bug"
    )

    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, task_metadata, ["081"])

    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task_worktree,
      { success: true, path: "/path/to/task-081" }, [Hash])

    mock_task_status_updater = Minitest::Mock.new
    mock_task_status_updater.expect(:update_task_status, true, [Hash])

    # Mock mise as unavailable
    mock_mise_trustor = Minitest::Mock.new
    mock_mise_trustor.expect(:trust_worktree,
      { success: true, message: "mise not available, skipping trust" }, [String])

    @orchestrator.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @orchestrator.instance_variable_set(:@worktree_manager, mock_worktree_manager)
    @orchestrator.instance_variable_set(:@task_status_updater, mock_task_status_updater)
    @orchestrator.instance_variable_set(:@mise_trustor, mock_mise_trustor)

    result = @orchestrator.orchestrate_task_worktree_creation(task_id: "081")

    assert result[:success]
    # Should succeed even without mise

    mock_task_fetcher.verify
    mock_worktree_manager.verify
    mock_task_status_updater.verify
    mock_mise_trustor.verify
  end

  def test_orchestrate_task_worktree_cleanup_success
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

    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:remove_worktree, { success: true }, [Hash])

    mock_task_status_updater = Minitest::Mock.new
    mock_task_status_updater.expect(:update_task_status, true, [Hash])

    @orchestrator.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @orchestrator.instance_variable_set(:@worktree_lister, mock_worktree_lister)
    @orchestrator.instance_variable_set(:@worktree_manager, mock_worktree_manager)
    @orchestrator.instance_variable_set(:@task_status_updater, mock_task_status_updater)

    result = @orchestrator.orchestrate_task_worktree_cleanup(task_id: "081")

    assert result[:success]
    assert_match(/cleanup.*successful/i, result[:message])

    mock_task_fetcher.verify
    mock_worktree_lister.verify
    mock_worktree_manager.verify
    mock_task_status_updater.verify
  end

  def test_orchestrate_task_worktree_cleanup_worktree_not_found
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix authentication bug"
    )

    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, task_metadata, ["081"])

    mock_worktree_lister = Minitest::Mock.new
    mock_worktree_lister.expect(:list_worktrees, [], [Hash])  # No worktrees found

    @orchestrator.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @orchestrator.instance_variable_set(:@worktree_lister, mock_worktree_lister)

    result = @orchestrator.orchestrate_task_worktree_cleanup(task_id: "081")

    refute result[:success]
    assert_match(/worktree.*not found/i, result[:message])

    mock_task_fetcher.verify
    mock_worktree_lister.verify
  end

  def test_orchestrate_task_worktree_completion_success
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

    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:remove_worktree, { success: true }, [Hash])

    mock_task_status_updater = Minitest::Mock.new
    mock_task_status_updater.expect(:update_task_status, true, [Hash])

    mock_task_committer = Minitest::Mock.new
    mock_task_committer.expect(:commit_task_work, true, [Hash])

    @orchestrator.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @orchestrator.instance_variable_set(:@worktree_lister, mock_worktree_lister)
    @orchestrator.instance_variable_set(:@worktree_manager, mock_worktree_manager)
    @orchestrator.instance_variable_set(:@task_status_updater, mock_task_status_updater)
    @orchestrator.instance_variable_set(:@task_committer, mock_task_committer)

    result = @orchestrator.orchestrate_task_worktree_completion(
      task_id: "081",
      commit_message: "Complete authentication bug fix"
    )

    assert result[:success]
    assert_match(/completion.*successful/i, result[:message])

    mock_task_fetcher.verify
    mock_worktree_lister.verify
    mock_worktree_manager.verify
    mock_task_status_updater.verify
    mock_task_committer.verify
  end

  def test_handles_dangerous_task_id
    dangerous_task_id = "081; rm -rf /"

    result = @orchestrator.orchestrate_task_worktree_creation(task_id: dangerous_task_id)

    refute result[:success]
    assert_match(/invalid.*task.*id/i, result[:message])
  end

  def test_handles_missing_dependencies_gracefully
    # Test when ace-taskflow is not available
    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:ace_taskflow_available?, false)

    @orchestrator.instance_variable_set(:@task_fetcher, mock_task_fetcher)

    result = @orchestrator.orchestrate_task_worktree_creation(task_id: "081")

    refute result[:success]
    assert_match(/ace-taskflow.*not available/i, result[:message])

    mock_task_fetcher.verify
  end

  def test_error_handling_in_orchestration
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix authentication bug"
    )

    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, task_metadata, ["081"])

    # Mock worktree manager throwing an unexpected error
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task_worktree, nil) do
      raise StandardError, "Unexpected error during git operation"
    end

    @orchestrator.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @orchestrator.instance_variable_set(:@worktree_manager, mock_worktree_manager)

    result = @orchestrator.orchestrate_task_worktree_creation(task_id: "081")

    refute result[:success]
    assert_match(/Unexpected error/i, result[:message])

    mock_task_fetcher.verify
    mock_worktree_manager.verify
  end

  def test_full_orchestration_workflow
    # Test complete workflow: create -> complete
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      title: "Fix authentication bug"
    )

    # Setup mocks for creation
    mock_task_fetcher = Minitest::Mock.new
    mock_task_fetcher.expect(:fetch, task_metadata, ["081"])

    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task_worktree,
      { success: true, path: "/path/to/task-081" }, [Hash])

    mock_task_status_updater = Minitest::Mock.new
    mock_task_status_updater.expect(:update_task_status, true, [Hash])

    mock_mise_trustor = Minitest::Mock.new
    mock_mise_trustor.expect(:trust_worktree, { success: true }, [String])

    @orchestrator.instance_variable_set(:@task_fetcher, mock_task_fetcher)
    @orchestrator.instance_variable_set(:@worktree_manager, mock_worktree_manager)
    @orchestrator.instance_variable_set(:@task_status_updater, mock_task_status_updater)
    @orchestrator.instance_variable_set(:@mise_trustor, mock_mise_trustor)

    # Create task worktree
    create_result = @orchestrator.orchestrate_task_worktree_creation(task_id: "081")
    assert create_result[:success]

    # Setup mocks for completion
    mock_worktree_lister = Minitest::Mock.new
    task_worktree = {
      path: "/path/to/task-081",
      branch: "feature/task-081",
      task_metadata: task_metadata
    }
    mock_worktree_lister.expect(:list_worktrees, [task_worktree], [Hash])

    mock_worktree_manager.expect(:remove_worktree, { success: true }, [Hash])

    mock_task_committer = Minitest::Mock.new
    mock_task_committer.expect(:commit_task_work, true, [Hash])

    @orchestrator.instance_variable_set(:@worktree_lister, mock_worktree_lister)
    @orchestrator.instance_variable_set(:@task_committer, mock_task_committer)

    # Complete task worktree
    complete_result = @orchestrator.orchestrate_task_worktree_completion(
      task_id: "081",
      commit_message: "Complete authentication bug fix"
    )

    assert complete_result[:success]

    mock_task_fetcher.verify
    mock_worktree_manager.verify
    mock_task_status_updater.verify
    mock_mise_trustor.verify
    mock_worktree_lister.verify
    mock_task_committer.verify
  end
end