# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/service_delivery_evidence"
require "ace/git/forgejo"
require "ace/assign/organisms/protected_delivery_coordinator"
require "ace/assign/authority/endcap"

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

  def test_draft_and_ready_results_bind_original_input_and_operation
    %w[create update ready].each do |operation|
      record, receipt, value = fixture_values(operation: operation)
      owner = Ace::Assign::Authority::ServiceDeliveryEvidence.new(journal: Object.new)
      event = owner.completion_event(record: record, receipt: receipt,
        completion_digest: "c" * 64, artifacts: [artifact(record, value)])
      assert_equal operation, event.fetch(:payload).fetch("operation")
      assert_equal operation != "ready", event.fetch(:payload).fetch("pr").fetch("draft")
      assert_equal "https://forge.example/owner/repo/pulls/25", event.fetch(:payload).fetch("pr").fetch("url")
      value.fetch("input")["body"] = "changed" unless operation == "ready"
      value.fetch("receipt").fetch("pull_request")["head_sha"] = "e" * 40
      assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
        owner.completion_event(record: record, receipt: receipt, completion_digest: "c" * 64, artifacts: [artifact(record, value)])
      end
    end
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

  def test_cleanup_enrichment_uses_canonical_fresh_or_replayed_projection_without_an_extra_record_read
    [false, true].product(%w[merge prune-preserved-workspace], %w[request_service begin_dispatch]).each do |replayed, operation, rpc|
      reads, enrichments = 0, 0
      record = {"operation" => operation, "input_digest" => "d" * 64, "target" => {"resource" => "fixture"}}
      journal = Object.new
      journal.define_singleton_method(:service_request) { |_| reads += 1; record }
      journal.define_singleton_method(:mutate) do |**|
        {data: {"operation" => operation, "journal_commit" => "c" * 40}, replayed: replayed}
      end
      launch = Object.new
      launch.define_singleton_method(:with_assignment) { |**_, &block| block.call(journal, {}) }
      policy = Object.new
      policy.define_singleton_method(:input_binding) { |*, **| true }
      policy.define_singleton_method(:visible!) { |**| true }
      owner = Ace::Assign::Authority::Endcap.allocate
      owner.instance_variable_set(:@launch, launch)
      owner.define_singleton_method(:service_policy!) { policy }
      %i[authorize_service_transfer! protected_journal! service_executor! service_ticket! service_replay_binding!].each do |method|
        owner.define_singleton_method(method) { |*| true }
      end
      owner.define_singleton_method(:cleanup_service_mutation_event!) { |*| enrichments += 1; "e" * 64 }
      transfer = Struct.new(:bytes) { def count; 1; end }.new("{}")
      params = {"request_id" => "request", "assignment_id" => "assignment", "attempt_id" => "attempt", "expected_generation" => 1}.merge(record)
      result = owner.send(:dispatch_service, {"operation" => rpc, "mutation_id" => "begin"}, params,
        {"project_id" => "project", "worker_uid" => 13001}, {}, :executor, transfer)
      assert_equal 2, reads, "only input and ticket admission read; CAS/replay remains a separate owner"
      assert_equal operation == "prune-preserved-workspace" ? 1 : 0, enrichments
      selector = rpc == "request_service" ? "request_event_digest" : "dispatch_event_digest"
      assert_equal "e" * 64, result.fetch(:data).fetch(selector) if operation == "prune-preserved-workspace"
      assert_equal "already_started", result.fetch(:data).fetch("invocation") if replayed && rpc == "begin_dispatch"
    end
  end

  private

  def artifact(record, value)
    "ace-service-attestation request:request input:#{record.fetch('input_digest')} outcome:succeeded\n#{JSON.generate(value)}\n"
  end

  def fixture_values(operation: "merge")
    url = "https://forge.example/owner/repo"
    target = {"resource" => "#{url}/pulls/25", "artifact_digest" => nil}
    delivery = {"forge_server" => "selected", "forge_default" => false,
      "pr_provenance" => {"mode" => "canonical", "head_repository_url" => url, "head_ref" => "feature",
        "base_repository_url" => url, "base_ref" => "main"}}
    input = {"target" => target, "delivery" => delivery}
    if operation == "merge"
      input["method"] = "squash"
    elsif operation != "ready"
      input.merge!("title" => "Ship", "body" => "")
    end
    target["resource"] = url if operation == "create"
    record = {"operation" => operation, "request_id" => "request", "input_digest" => Ace::Assign::Atoms::EvidenceDigest.digest(input),
      "target" => target, "candidate_head" => "a" * 40, "executor_uid" => 13005}
    receipt = {"evidence" => [{"ref" => "evidence/imports/original", "sha256" => "d" * 64}]}
    pr = Ace::Git::ProviderPullRequest.new(server_name: "selected", number: 25, title: %w[create update].include?(operation) ? "WIP: Ship" : "Ship", body: "",
      state: operation == "merge" ? :merged : :open, head_ref: "feature", base_ref: "main", head_sha: "a" * 40, author: "worker", url: "#{url}/pulls/25",
      draft: %w[create update].include?(operation), merged_at: "2026-10-08T12:00:00Z", head_repository_url: url, base_repository_url: url, merge_commit_sha: "b" * 40)
    value = JSON.parse(JSON.generate({"server" => {"name" => "selected", "provider" => "forgejo", "url" => url},
      "delivery" => delivery, "method" => "squash", "candidate_head" => "a" * 40,
      "receipt" => Ace::Git::ProviderMutationReceipt.new(server_name: "selected", operation: operation.to_sym, pull_request: pr, idempotency: operation == "create" ? :created : nil).to_h}))
    unless operation == "merge"
      value.delete("delivery")
      value.delete("method")
      value.merge!("operation" => operation, "input" => input)
    end
    [record, receipt, value]
  end
end
