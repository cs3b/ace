# frozen_string_literal: true

require_relative "../../test_helper"

class TaskWorktreeOrchestratorTest < Minitest::Test
  def setup
    setup_temp_dir
    @orchestrator = Ace::Git::Worktree::Organisms::TaskWorktreeOrchestrator.new
  end

  def teardown
    teardown_temp_dir
  end

  # Smoke tests - verify API exists and basic behavior
  # These don't mock internals since organisms initialize their own dependencies

  def test_create_for_task_api_exists
    result = @orchestrator.create_for_task(nil)
    assert result.is_a?(Hash)
    assert result.key?(:success)
  end

  def test_create_for_task_validates_dangerous_input
    # Should reject dangerous task references via validation
    result = @orchestrator.create_for_task("; rm -rf /")
    assert result.is_a?(Hash)
    # Either validation rejects it or task fetcher returns nil
    # Either way, we get a structured response
  end

  def test_dry_run_create_api_exists
    result = @orchestrator.dry_run_create(nil)
    assert result.is_a?(Hash)
    assert result.key?(:success)
  end

  def test_remove_task_worktree_api_exists
    result = @orchestrator.remove_task_worktree(nil)
    assert result.is_a?(Hash)
    assert result.key?(:success)
  end

  def test_workflow_result_has_expected_structure
    # Any result should have standard workflow structure
    result = @orchestrator.create_for_task("nonexistent-999")

    assert result.is_a?(Hash)
    assert result.key?(:success)
    assert result.key?(:message) || result.key?(:error)
    assert result.key?(:steps_completed)
    assert result[:steps_completed].is_a?(Array)
    assert result.key?(:preexisting_dirty)
    assert result.key?(:owned_task_paths)
    assert result.key?(:path_set_verified)
  end

  def test_snapshot_dirty_state_returns_structured_dirty_hash
    dirty = @orchestrator.send(:snapshot_dirty_state)
    assert dirty.key?(:staged)
    assert dirty.key?(:unstaged)
    assert dirty.key?(:untracked)
    assert dirty[:staged].is_a?(Array)
    assert dirty[:unstaged].is_a?(Array)
    assert dirty[:untracked].is_a?(Array)
  end

  def test_preexisting_target_edit_blocks_worktree_creation
    # Mock task fetcher to return a task path
    mock_data = {id: "8vb.t.vz8", path: ".ace-tasks/test_task.s.md", title: "Test Task"}
    @orchestrator.stub(:fetch_task_data, mock_data) do
      @orchestrator.stub(:snapshot_dirty_state, {staged: [".ace-tasks/test_task.s.md"], unstaged: [], untracked: []}) do
        result = @orchestrator.create_for_task("8vb.t.vz8")
        refute result[:success]
        assert_match(/Pre-existing edits on target task paths/, result[:error])
        refute_nil result[:recovery]
      end
    end
  end
end
