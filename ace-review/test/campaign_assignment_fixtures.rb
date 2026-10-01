# frozen_string_literal: true
require "ace/assign"

# Real qjl authority for public-process and receipt integration scenarios.
module CampaignAssignmentFixtures
  def accepted_check_reference(check_path)
    accepted_execution_reference(operation: "test", artifacts: [artifact_ref(check_path)],
      checks: [{"name" => "tests", "verdict" => "passed"}])
  end

  def accepted_review_reference(dir)
    accepted_execution_reference(operation: "review-collect", artifacts: review_artifacts(dir),
      checks: [{"name" => "review-execution", "verdict" => "passed"}])
  end

  def accepted_approval_reference(reports:, producer:, reviewer:)
    accepted_execution_reference(operation: "review", artifacts: reports,
      checks: [{"name" => "review-execution", "verdict" => "passed"}],
      producer: {"actor" => producer, "role" => "worker", "runtime" => "fixture:worker"},
      review: {"reviewer" => {"actor" => reviewer, "runtime" => "fixture:reviewer"},
        "head" => @head, "verdict" => "approved"})
  end

  def accepted_execution_reference(operation:, artifacts:, checks: [], producer: nil, review: nil)
    cache = File.join(@test_dir, ".ace-local/assign")
    identity = Ace::Assign::Molecules::ExecutionIdentityResolver::Identity.new(
      actor: "test-coordinator", role: "coordinator", runtime: "local:test", adapter: "local")
    @check_coordinator ||= Ace::Assign::Organisms::AttemptCoordinator.new(cache_base: cache, repo_root: @test_dir,
      lifecycle_exclusion: Ace::Assign::Molecules::LifecycleExclusion.new(root: File.join(@test_dir, ".ace-local/exclusion")))
    @check_assignment ||= Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache).create(
      name: "executed-check", source_config: "fixture-check", task_id: "8x0.t.ig2", project_id: "ace")
    attempt = @check_coordinator.start(assignment_id: @check_assignment.id, step: "010", project_id: "ace", identity: identity)
    data = {"attempt_id" => attempt.attempt_id, "assignment_id" => @check_assignment.id,
      "project_id" => "ace", "scope" => "010", "operation" => operation,
      "producer" => producer || {"actor" => "check-worker", "role" => "worker", "runtime" => "fixture:check"},
      "review" => review,
      "head" => @head, "verdict" => "succeeded", "artifacts" => artifacts, "checks" => checks}
    path = File.join(@test_dir, ".ace-local/check-receipt.json")
    File.write(path, JSON.generate(data))
    accepted = @check_coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: path, identity: identity)
    digest = accepted.accepted_receipts.last["digest"]
    (@accepted_receipt_journal_commits ||= {})[digest] = accepted.journal_commit
    {"attempt_id" => accepted.attempt_id, "digest" => digest}
  end
end
