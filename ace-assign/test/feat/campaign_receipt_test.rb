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

end
