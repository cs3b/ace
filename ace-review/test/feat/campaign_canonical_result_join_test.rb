# frozen_string_literal: true
require "test_helper"
require "open3"
require_relative "../campaign_fixtures"
require_relative "../campaign_assignment_fixtures"

# Existing local execution/canonical artifact owners, no native launch simulation.
class CampaignCanonicalResultJoinTest < AceReviewTest
  include CampaignFixtures
  include CampaignAssignmentFixtures

  def git(*args)
    out, err, status = Open3.capture3("git", *args, chdir: @test_dir)
    assert status.success?, err
    out.strip
  end

  def campaign_manager
    authority = Ace::Review::Molecules::CampaignExecutionEvidence.new(repo_root: @test_dir)
    coordinator = -> { @check_coordinator }
    authority.define_singleton_method(:read) do |reference, head:, kind:, check_name: "tests", historical: false|
      coordinator.call.evidence(attempt_id: reference.fetch("attempt_id"), receipt_digest: reference.fetch("digest"),
        kind: kind, check_name: check_name, historical_head: historical ? head : nil)
    end
    Ace::Review::Organisms::CampaignManager.new(repo_root: @test_dir,
      check_evidence: authority.method(:check), review_evidence: authority.method(:review),
      approval_evidence: authority.method(:approval))
  end

  def test_exported_three_round_result_uses_canonical_bytes_and_same_held_current_gate
    git("init", "-b", "main")
    git("config", "user.name", "test")
    git("config", "user.email", "test@example.com")
    File.write(".gitignore", ".ace-local/\n")
    File.write("candidate.rb", "puts :base\n")
    git("add", ".gitignore", "candidate.rb")
    git("commit", "-m", "base")
    @base = git("rev-parse", "HEAD")
    File.write("candidate.rb", "puts :candidate\n")
    git("commit", "-am", "candidate")
    @head = git("rev-parse", "HEAD")
    campaign = start_campaign
    id = campaign.fetch("campaign_id")
    3.times do |n|
      input = round_input(n)
      make_campaign_session(campaign, input)
      add_campaign_approval(campaign, input) if n == 2
      result = campaign_manager.record_round(id, input)
      assert_equal n + 1, result.fetch("completed_rounds")
      assert_equal n == 2, result.fetch("accepted")
    end
    manager = campaign_manager
    result = manager.accepted_result_snapshot(id)
    binding = {subject: result.fetch("subject"), contract_identity: result.fetch("contract_identity"),
      policy: result.fetch("effective_policy"), head: @head, base: @base, producer: "worker", reviewer: "reviewer"}
    projections = 0
    original = manager.method(:projection)
    manager.define_singleton_method(:projection) { |*args, **kwargs| projections += 1; original.call(*args, **kwargs) }
    manager.with_verified_result!(result: result, **binding) do |verified, snapshot|
      assert verified.fetch("accepted")
      assert_equal result, snapshot
      assert snapshot.frozen?
      assert_equal 1, projections
    end
    assert_equal 1, projections

    journal = Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @test_dir, ref: "refs/ace/campaign-result-join",
      checkout_root: ".ace-local/result-join-checkout")
    canonical = Ace::Assign::Molecules::CanonicalEvidence.new(journal: journal)
    journal.mutate(assignment_id: "export", attempt_id: "result", mutation_id: "before-export",
      operation: "result_join", parameters_digest: "a" * 64, expected_generation: 0) { {data: {}} }
    context = {kind: "result", project_id: "ace", assignment_id: "export", attempt_id: "result",
      peer_uid: Process.uid, binding: {"head" => @head}, request_id_or_event_id: "exported-result", generation: 1}
    plan = canonical.import_plan(**context, artifacts: [JSON.generate(result)],
      admitted_after_event_digest: journal.read_events("export").last.fetch("digest"))
    journal.mutate(assignment_id: "export", attempt_id: "result", mutation_id: "import-export",
      operation: "result_join", parameters_digest: "b" * 64, expected_generation: 1) { plan.merge(data: {}) }
    reference = plan.fetch(:references).first
    artifact = {"path" => reference.fetch("ref"), "sha256" => reference.fetch("sha256")}
    receipt = {"operation" => "review", "verdict" => "succeeded", "head" => @head,
      "producer" => {"actor" => "worker"}, "review" => {"head" => @head, "verdict" => "approved",
        "reviewer" => {"actor" => "reviewer"}}, "checks" => [{"name" => "tests", "verdict" => "passed"}],
      "artifacts" => [artifact], "campaign" => {"id" => id, "result" => artifact}}
    pinned = journal.ref_value
    reader = ->(data, supplied) {
      canonical.read({"ref" => supplied.fetch("path"), "sha256" => supplied.fetch("sha256")},
        **context.merge(binding: {"head" => data.fetch("head")}), commit: pinned)
    }
    verifier = Ace::Assign::Molecules::ReceiptVerifier.new(artifact_reader: reader)
    # Disposable projection is irrelevant to the canonical imported bytes.
    path = File.join(@test_dir, artifact.fetch("path"))
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "replacement")
    File.write(".git/info/exclude", "evidence/\n")
    current = manager.status(id)
    assert current.fetch("accepted"), current.fetch("reasons").inspect
    assert_equal result.fetch("result_identity"), current.fetch("result_identity")
    Ace::Review::Organisms::CampaignManager.stub(:new, manager) do
      verifier.verify_accepted_evidence!(receipt, live_head: @head, repo_root: @test_dir)
      changed = receipt.merge("head" => "f" * 40)
      assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
        verifier.verify_accepted_evidence!(changed, live_head: changed.fetch("head"), repo_root: @test_dir)
      end
      invalid = receipt.merge("campaign" => {"id" => "different", "result" => artifact})
      assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
        verifier.verify_accepted_evidence!(invalid, live_head: @head, repo_root: @test_dir)
      end
      File.write("candidate.rb", "puts :uncommitted\n")
      assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
        verifier.verify_accepted_evidence!(receipt, live_head: @head, repo_root: @test_dir)
      end
    end
  end
end
