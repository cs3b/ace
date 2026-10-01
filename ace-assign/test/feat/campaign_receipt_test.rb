# frozen_string_literal: true
require_relative "../test_helper"
require "ace/review"
require_relative "../../../ace-review/test/campaign_fixtures"
require_relative "../../../ace-review/test/campaign_assignment_fixtures"

# Actual coordinator, managed assignment and evidence-ref publication.
class CampaignReceiptTest < AceAssignTestCase
  include CampaignFixtures
  include CampaignAssignmentFixtures

  def setup
    super
    @cache = self.class.class_temp_dir
    @test_dir = File.join(@cache, "candidate")
    FileUtils.mkdir_p(@test_dir)
    git_in(@test_dir, "init", "-b", "main")
    git_in(@test_dir, "config", "user.name", "test")
    git_in(@test_dir, "config", "user.email", "test@example.com")
    File.write(File.join(@test_dir, ".gitignore"), ".ace-local/\n")
    File.write(File.join(@test_dir, "candidate.rb"), "puts :candidate\n")
    git_in(@test_dir, "add", ".gitignore", "candidate.rb")
    git_in(@test_dir, "commit", "-m", "candidate")
    @head = @base = git_in(@test_dir, "rev-parse", "HEAD")
    @campaign = start_campaign
    3.times do |n|
      input = round_input(n)
      make_campaign_session(@campaign, input)
      add_campaign_approval(@campaign, input) if n == 2
      campaign_manager.record_round(@campaign["campaign_id"], input)
    end
    result = campaign_manager.finish(@campaign["campaign_id"])
    assert result["accepted"], result["reasons"].inspect
    @result_path = ".ace-local/campaign-result.json"
    File.write(File.join(@test_dir, @result_path), JSON.generate(result))
    @identity = Ace::Assign::Molecules::ExecutionIdentityResolver::Identity.new(
      actor: "operator", role: "coordinator", runtime: "local:test", adapter: "local")
    resolver = Ace::Assign::Molecules::ExecutionIdentityResolver.new(adapter: "local")
    identity = @identity
    resolver.define_singleton_method(:resolve) { identity }
    @coordinator = Ace::Assign::Organisms::AttemptCoordinator.new(cache_base: @cache, repo_root: @test_dir,
      identity_resolver: resolver, journal: Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @test_dir,
        checkout_root: File.join(@cache, "audit")),
      lifecycle_exclusion: Ace::Assign::Molecules::LifecycleExclusion.new(root: File.join(@cache, "exclusion")))
    @assignment = Ace::Assign::Molecules::AssignmentManager.new(cache_base: @cache).create(
      name: "campaign-consumer", source_config: "job.yaml", task_id: "8x0.t.ig2", project_id: "ace")
  end

  def campaign_manager
    Ace::Review::Organisms::CampaignManager.new(repo_root: @test_dir)
  end

  def receipt(attempt, overrides = {})
    ref = artifact_ref(@result_path)
    data = {"attempt_id" => attempt.attempt_id, "assignment_id" => @assignment.id,
      "project_id" => "ace", "scope" => "010", "operation" => "review",
      "producer" => {"actor" => "worker", "role" => "worker", "runtime" => "fixture:worker"},
      "head" => @head, "verdict" => "succeeded", "artifacts" => [ref],
      "checks" => [{"name" => "tests", "verdict" => "passed"}],
      "review" => {"reviewer" => {"actor" => "reviewer", "runtime" => "fixture:reviewer"},
        "verdict" => "approved", "head" => @head},
      "campaign" => {"id" => @campaign["campaign_id"], "result" => ref}}.merge(overrides)
    path = File.join(@cache, "receipt.json")
    File.write(path, JSON.generate(data))
    path
  end

  def start_attempt
    @coordinator.start(assignment_id: @assignment.id, step: "010", project_id: "ace")
  end

  def test_campaign_consumption_uses_existing_authority_and_does_not_advance_candidate
    attempt = start_attempt
    before = git_in(@test_dir, "rev-parse", "HEAD")
    finished = @coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: receipt(attempt))
    assert_equal "succeeded", finished.state
    assert_equal before, git_in(@test_dir, "rev-parse", "HEAD")
    assert_equal before, finished.candidate_head
    refute_nil finished.journal_commit
    assert_equal @campaign["campaign_id"], finished.accepted_receipts.last["campaign"]["id"]
  end

  def test_read_only_check_evidence_recovers_from_journal_and_rejects_unknown_digest
    result = JSON.parse(File.read(File.join(@test_dir, @result_path)))
    ref = result["rounds"].last["approval"]["checks"].first["receipt"]
    missing_cache = File.join(@test_dir, ".ace-local/missing-cache")
    missing_checkout = File.join(@test_dir, ".ace-local/missing-audit-checkout")
    coordinator = Ace::Assign::Organisms::AttemptCoordinator.new(repo_root: @test_dir, cache_base: missing_cache,
      journal: Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @test_dir, checkout_root: missing_checkout))
    before = git_in(@test_dir, "rev-parse", "HEAD")
    proof = coordinator.evidence(attempt_id: ref["attempt_id"], receipt_digest: ref["digest"])
    assert_equal @head, proof["head"]
    assert_equal ref["digest"], proof["receipt_digest"]
    assert_equal before, git_in(@test_dir, "rev-parse", "HEAD")
    refute File.exist?(missing_cache)
    refute File.exist?(missing_checkout)
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      coordinator.evidence(attempt_id: ref["attempt_id"], receipt_digest: "0" * 64)
    end
  end

  def test_stale_snapshot_and_attribution_cannot_bypass_receipt_checks
    attempt = start_attempt
    bad = {"reviewer" => {"actor" => "worker"}, "verdict" => "approved", "head" => @head}
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: receipt(attempt, "review" => bad))
    end
    result = JSON.parse(File.read(File.join(@test_dir, @result_path)))
    result["result_identity"] = "fabricated"
    File.write(File.join(@test_dir, @result_path), JSON.generate(result))
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: receipt(attempt))
    end
    File.write(File.join(@test_dir, "candidate.rb"), "puts :changed\n")
    git_in(@test_dir, "add", "candidate.rb")
    git_in(@test_dir, "commit", "-m", "new head")
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: receipt(attempt))
    end
    assert_equal "running", @coordinator.store.find(attempt.attempt_id).state
  end
  def test_superseded_campaign_result_is_rejected_by_the_receipt_owner
    attempt = start_attempt
    successor = campaign_manager.start(subject: campaign_subject, contract: "Changed requirement",
      policy: campaign_policy, reason: "Requirements changed")
    refute successor["accepted"]
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: receipt(attempt))
    end
    assert_equal "running", @coordinator.store.find(attempt.attempt_id).state
    assert_equal @head, git_in(@test_dir, "rev-parse", "HEAD")
  end

  def test_non_test_receipt_cannot_supply_tests_evidence
    path = ".ace-local/unrelated-operation.json"
    File.write(File.join(@test_dir, path), JSON.generate("operation" => "work", "head" => @head))
    ref = accepted_execution_reference(operation: "work", artifacts: [artifact_ref(path)],
      checks: [{"name" => "tests", "verdict" => "passed"}])
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @check_coordinator.evidence(attempt_id: ref["attempt_id"], receipt_digest: ref["digest"], kind: "check")
    end
    review_ref = campaign_manager.status(@campaign["campaign_id"])["rounds"].first["sessions"].first["receipt"]
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @check_coordinator.evidence(attempt_id: review_ref["attempt_id"], receipt_digest: review_ref["digest"], kind: "check")
    end
    unmanaged = Ace::Assign::Molecules::AssignmentManager.new(cache_base: @cache).create(
      name: "unmanaged-check", source_config: "fixture", project_id: "ace")
    local_attempt = @coordinator.start(assignment_id: unmanaged.id, step: "010", project_id: "ace")
    refute local_attempt.managed?
    finished = @coordinator.finish(attempt_id: local_attempt.attempt_id,
      receipt_path: receipt(local_attempt, "assignment_id" => unmanaged.id, "operation" => "test",
        "review" => nil, "campaign" => nil))
    assert_equal "succeeded", finished.state
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @coordinator.evidence(attempt_id: local_attempt.attempt_id, receipt_digest: finished.accepted_receipts.last["digest"])
    end
  end

  def test_historical_review_proof_retains_authority_without_certifying_live_checks
    result = campaign_manager.status(@campaign["campaign_id"])
    ref = result["rounds"].first["sessions"].first["receipt"]
    old_head = @head
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @check_coordinator.evidence(attempt_id: ref["attempt_id"], receipt_digest: ref["digest"],
        kind: "review-collection", historical_head: false)
    end
    File.write(File.join(@test_dir, "candidate.rb"), "puts :changed\n")
    git_in(@test_dir, "add", "candidate.rb")
    git_in(@test_dir, "commit", "-m", "new head")
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @check_coordinator.evidence(attempt_id: ref["attempt_id"], receipt_digest: ref["digest"], kind: "review-collection")
    end
    proof = @check_coordinator.evidence(attempt_id: ref["attempt_id"], receipt_digest: ref["digest"],
      kind: "review-collection", historical_head: old_head)
    assert proof["historical"]
    assert_equal old_head, proof["head"]
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @check_coordinator.evidence(attempt_id: ref["attempt_id"], receipt_digest: ref["digest"], historical_head: old_head)
    end
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @check_coordinator.evidence(attempt_id: ref["attempt_id"], receipt_digest: ref["digest"],
        kind: "review-collection", historical_head: "f" * 40)
    end
    journal_head = git_in(@test_dir, "rev-parse", "refs/ace/execution")
    git_in(@test_dir, "update-ref", "-d", "refs/ace/execution")
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @check_coordinator.evidence(attempt_id: ref["attempt_id"], receipt_digest: ref["digest"],
        kind: "review-collection", historical_head: old_head)
    end
    git_in(@test_dir, "update-ref", "refs/ace/execution", journal_head)
    assert @check_coordinator.evidence(attempt_id: ref["attempt_id"], receipt_digest: ref["digest"],
      kind: "review-collection", historical_head: old_head)["historical"]
    refute_equal git_in(@test_dir, "rev-parse", "HEAD"), proof["head"]
  end

  def test_worker_authored_passed_check_cannot_become_accepted_execution_authority
    attempt = start_attempt
    path = receipt(attempt, "operation" => "test", "review" => nil, "campaign" => nil)
    data = JSON.parse(File.read(path))
    digest = Ace::Assign::Models::ExecutionReceipt.from_h(data).digest
    worker = Ace::Assign::Molecules::ExecutionIdentityResolver::Identity.new(
      actor: "worker", role: "worker", runtime: "fixture:worker", adapter: "service")
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: path, identity: worker)
    end
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @coordinator.evidence(attempt_id: attempt.attempt_id, receipt_digest: digest)
    end
    assert_equal "running", @coordinator.store.find(attempt.attempt_id).state
    assert_empty @coordinator.store.find(attempt.attempt_id).accepted_receipts
  end

  def test_independent_approval_proof_binds_report_actors_and_verdict
    result = campaign_manager.status(@campaign["campaign_id"])
    approval = result["rounds"].last["approval"]
    ref = approval["receipt"]
    proof = @check_coordinator.evidence(attempt_id: ref["attempt_id"], receipt_digest: ref["digest"], kind: "review-approval")
    assert_equal "approved", proof.dig("review", "verdict")
    assert_equal approval["reviewer"], proof.dig("review", "reviewer", "actor")
    boundary = Ace::Review::Molecules::CampaignExecutionEvidence.new(repo_root: @test_dir)
    args = {head: @head, artifacts: approval["reports"], producer: approval["producer"], reviewer: approval["reviewer"]}
    assert_equal ref["digest"], boundary.approval(ref, **args)["receipt_digest"]
    [{producer: "other"}, {reviewer: "other"}, {artifacts: [artifact_ref(@result_path)]}].each do |wrong_binding|
      assert_raises(ArgumentError) { boundary.approval(ref, **args.merge(wrong_binding)) }
    end
    collection_ref = result["rounds"].last["sessions"].first["receipt"]
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @check_coordinator.evidence(attempt_id: collection_ref["attempt_id"], receipt_digest: collection_ref["digest"], kind: "review-approval")
    end
    File.write(File.join(@test_dir, "candidate.rb"), "puts :changed\n")
    git_in(@test_dir, "add", "candidate.rb")
    git_in(@test_dir, "commit", "-m", "new head")
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @check_coordinator.evidence(attempt_id: ref["attempt_id"], receipt_digest: ref["digest"], kind: "review-approval")
    end
    assert @check_coordinator.evidence(attempt_id: ref["attempt_id"], receipt_digest: ref["digest"],
      kind: "review-approval", historical_head: @head)["historical"]
  end

  def test_consumer_rejects_saved_acceptance_when_independent_approval_authority_is_lost
    attempt = start_attempt
    before = git_in(@test_dir, "rev-parse", "HEAD")
    result = JSON.parse(File.read(File.join(@test_dir, @result_path)))
    # Retain collection history while losing the later approval/check acceptances.
    collection = result["rounds"].last["sessions"].first["receipt"]
    git_in(@test_dir, "update-ref", "refs/ace/execution", @accepted_receipt_journal_commits.fetch(collection["digest"]))
    approval_ref = result["rounds"].last["approval"]["receipt"]
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @check_coordinator.evidence(attempt_id: approval_ref["attempt_id"], receipt_digest: approval_ref["digest"], kind: "review-approval")
    end
    refute campaign_manager.finish(@campaign["campaign_id"])["accepted"]
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: receipt(attempt))
    end
    assert_equal "running", @coordinator.store.find(attempt.attempt_id).state
    assert_equal before, git_in(@test_dir, "rev-parse", "HEAD")
  end

end
