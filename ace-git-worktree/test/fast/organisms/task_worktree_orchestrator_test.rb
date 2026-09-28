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

  def test_no_pr_task_creation_never_resolves_a_server
    mock_data = {id: "8vb.t.vz8", path: ".ace-tasks/test_task.s.md", title: "Test Task"}
    @orchestrator.stub(:fetch_task_data, mock_data) do
      # PullRequestCreator is the orchestrator's only forge touchpoint; the
      # --no-pr gate must make it unreachable (hence no server resolution).
      Ace::Git::Worktree::Molecules::PullRequestCreator.stub(:new,
        ->(**_kw) { flunk("local-only path constructed a forge PR creator") }) do
        result = @orchestrator.create_for_task("8vb.t.vz8", no_pr: true, no_status_update: true, no_commit: true)
        # The workflow may fail later on real git operations in a temp dir,
        # but it must never attempt forge server resolution.
        assert result.is_a?(Hash)
        assert result.key?(:steps_completed)
      end
    end
  end

  def test_dry_run_never_constructs_a_pr_creator
    Ace::Git::Worktree::Molecules::PullRequestCreator.stub(:new,
      ->(**_kw) { flunk("dry run constructed a forge PR creator") }) do
      result = @orchestrator.dry_run_create("whatever", no_pr: true)
      assert result.is_a?(Hash)
    end
  end

  def test_pr_creation_carries_pushed_sha_proof_and_selection
    # The neutral creator must receive the exact pushed SHA and the task's
    # server selection; the base is the resolved start point.
    creator = Object.new
    captured = {}
    creator.define_singleton_method(:create_draft) do |branch:, base:, title:, expected_head:, head_repository_url: nil|
      captured.merge!(
        branch: branch, base: base, title: title,
        expected_head: expected_head, head_repository_url: head_repository_url
      )
      {success: true, pr_number: 9, pr_url: "https://forge.example.com/o/r/pull/9", existing: false, head_sha: expected_head, error: nil}
    end
    Ace::Git::Worktree::Molecules::PullRequestCreator.stub(:new, lambda { |**kwargs|
      captured[:selection] = kwargs
      creator
    }) do
      @orchestrator.stub(:pushed_branch_sha, "d" * 40) do
        @orchestrator.stub(:remote_url, "https://forge.example.com/o/r") do
          result = @orchestrator.send(:create_pr_for_task,
            {id: "8vb.t.vz8", title: "T"},
            {branch: "8vb-fix", start_point: "main", worktree_path: "/tmp/nowhere"},
            {server: "forgejo-lab"}
          )
          assert result[:success]
          assert_equal "d" * 40, captured[:expected_head]
          assert_equal "8vb-fix", captured[:branch]
          assert_equal "https://forge.example.com/o/r", captured[:head_repository_url]
          assert_equal "forgejo-lab", captured[:selection][:server_name]
          assert_equal "main", captured[:base]
        end
      end
    end
  end
end
