# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/service_delivery_evidence"
require "ace/assign/organisms/protected_delivery_coordinator"

class ServiceDeliveryEvidenceTest < AceAssignTestCase
  def test_pending_completion_reconstructs_original_input_without_any_journal_or_staging_read
    record, receipt, value = fixture_values
    proof = artifact(record, value)
    journal = Object.new
    journal.define_singleton_method(:method_missing) { |*| raise "no staging or journal read is permitted in pending validation" }
    event = Ace::Assign::Authority::ServiceDeliveryEvidence.new(journal: journal).completion_event(record: record,
      receipt: receipt, completion_digest: "c" * 64, artifacts: [proof])
    assert_equal "delivery", event.fetch(:type)
    payload = event.fetch(:payload)
    assert_equal "request", payload.fetch("service_request_id")
    assert_equal "c" * 64, payload.fetch("service_completion_digest")
    assert_equal Ace::Assign::Atoms::EvidenceDigest.digest(receipt), payload.fetch("service_receipt_digest")
    assert_equal receipt.fetch("evidence"), payload.fetch("service_evidence")
    assert_equal "service:13005", payload.fetch("producer").fetch("actor")
  end

  def test_valid_artifact_with_changed_method_or_coherent_provenance_cannot_replace_accepted_input
    [->(value) { value["method"] = "rebase" },
      ->(value) { value.fetch("delivery").fetch("pr_provenance")["head_ref"] = "different"
        value.fetch("receipt").fetch("pull_request")["head_ref"] = "different" }].each do |change|
      record, receipt, value = fixture_values
      change.call(value)
      error = assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
        Ace::Assign::Authority::ServiceDeliveryEvidence.new(journal: Object.new).completion_event(record: record,
          receipt: receipt, completion_digest: "c" * 64, artifacts: [artifact(record, value)])
      end
      assert_includes error.message, "originally accepted input"
    end
  end

  def test_decoded_duplicate_artifact_fields_cannot_enter_completion_plan
    record, receipt, value = fixture_values
    bytes = artifact(record, value).sub('"method":"squash"', '"method":"squash","\\u006dethod":"rebase"')
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      Ace::Assign::Authority::ServiceDeliveryEvidence.new(journal: Object.new).completion_event(record: record,
        receipt: receipt, completion_digest: "c" * 64, artifacts: [bytes])
    end
  end

  def test_pending_status_requires_original_input_digest_and_exact_commit_length_before_return
    target = {"resource" => "https://forge.example/owner/repo/pulls/25", "artifact_digest" => nil}
    selectors = {assignment_id: "assignment", attempt_id: "attempt", operation: "status", service_request_id: "request",
      candidate_head: "a" * 40, candidate_generation: 1, input_digest: "d" * 64, target: target}
    data = {"assignment_id" => "assignment", "attempt_id" => "attempt", "request_id" => "request",
      "candidate_head" => "a" * 40, "candidate_generation" => 1, "input_digest" => "d" * 64,
      "project_id" => "project", "target" => target, "operation" => "merge", "generation" => 2,
      "journal_commit" => "b" * 40, "state" => "uncertain"}
    calls = []
    client = Object.new
    client.define_singleton_method(:call) do |operation, binding|
      calls << [operation, binding]
      Struct.new(:data).new(data)
    end
    owner = Ace::Assign::Organisms::ProtectedDeliveryCoordinator.new(client: client, project_id: "project")
    assert_equal data, owner.perform(**selectors)
    data["input_digest"] = "e" * 64
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { owner.perform(**selectors) }
    data["input_digest"] = "d" * 64
    data["journal_commit"] = "b" * 52
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { owner.perform(**selectors) }
    assert_equal 3, calls.length
    assert calls.all? { |operation, _| operation == "service_status" }
  end

  private

  def artifact(record, value)
    "ace-service-attestation request:request input:#{record.fetch('input_digest')} outcome:succeeded\n#{JSON.generate(value)}\n"
  end

  def fixture_values
    url = "https://forge.example/owner/repo"
    target = {"resource" => "#{url}/pulls/25", "artifact_digest" => nil}
    delivery = {"forge_server" => "selected", "forge_default" => false,
      "pr_provenance" => {"mode" => "canonical", "head_repository_url" => url, "head_ref" => "feature",
        "base_repository_url" => url, "base_ref" => "main"}}
    input = {"target" => target, "delivery" => delivery, "method" => "squash"}
    record = {"request_id" => "request", "input_digest" => Ace::Assign::Atoms::EvidenceDigest.digest(input),
      "target" => target, "candidate_head" => "a" * 40, "executor_uid" => 13005}
    receipt = {"evidence" => [{"ref" => "evidence/imports/original", "sha256" => "d" * 64}]}
    pr = Ace::Git::ProviderPullRequest.new(server_name: "selected", number: 25, title: "Ship", body: "",
      state: :merged, head_ref: "feature", base_ref: "main", head_sha: "a" * 40, author: "worker", url: target.fetch("resource"),
      draft: false, merged_at: "2026-10-08T12:00:00Z", head_repository_url: url, base_repository_url: url, merge_commit_sha: "b" * 40)
    value = JSON.parse(JSON.generate({"server" => {"name" => "selected", "provider" => "forgejo", "url" => url},
      "delivery" => delivery, "method" => "squash", "candidate_head" => "a" * 40,
      "receipt" => Ace::Git::ProviderMutationReceipt.new(server_name: "selected", operation: :merge, pull_request: pr, idempotency: nil).to_h}))
    [record, receipt, value]
  end
end
