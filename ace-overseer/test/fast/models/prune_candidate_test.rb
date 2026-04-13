# frozen_string_literal: true

require_relative "../../test_helper"

class PruneCandidateTest < AceOverseerTestCase
  def test_safe_to_prune_when_all_checks_pass
    candidate = Ace::Overseer::Models::PruneCandidate.new(
      task_id: "230",
      worktree_path: "/tmp/task.230",
      assignment_complete: true,
      task_done: true,
      git_clean: true
    )

    assert candidate.safe_to_prune?
  end

  def test_safe_to_prune_is_false_when_any_check_fails
    candidate = Ace::Overseer::Models::PruneCandidate.new(
      task_id: "230",
      worktree_path: "/tmp/task.230",
      assignment_complete: true,
      task_done: false,
      git_clean: true,
      reasons: ["task not done"]
    )

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons, "task not done"
  end
end
