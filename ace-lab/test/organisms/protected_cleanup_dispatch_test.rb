# frozen_string_literal: true
require_relative "../support/protected_service_boundary_fixture"

class ProtectedCleanupDispatchTest < Minitest::Test
  include ProtectedServiceBoundaryFixture

  def owner_binding
    {"unit" => "cleanup.service", "invocation_id" => "a" * 32, "entry_sha256" => "b" * 64,
      "process_binding" => {"pid" => 77, "uid" => 0, "gid" => 0, "groups" => [0],
        "started_at" => "linux:boot:900", "host" => "host", "parent_pid" => 1}}
  end

  def cleanup_submission
    submission, = prepared_submission
    tuple = {"project_id" => "project", "mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
    input = {"schema" => "ace.protected-workspace-prune/v1", "maintenance" => tuple,
      "target" => tuple.merge("resource" => "workspace:project:mapping:assignment", "artifact_digest" => "a" * 64,
        "descriptor_sha256" => "b" * 64, "binding_event_digest" => "c" * 64, "release_event_digest" => "d" * 64, "journal_commit" => "e" * 40),
      "publication" => {"descriptor_sha256" => "f" * 64, "installation_ref" => {"path" => "/etc/lab/installation.json", "bytes" => 1, "sha256" => "0" * 64}},
      "preservation" => {"head" => @head, "branch" => nil, "destinations" => [], "manifest_sha256" => "2" * 64}}
    operation = "prune-preserved-workspace"
    @document.fetch("operations")[operation] = @document.fetch("operations").fetch("publish").dup
    submission = submission.merge("operation" => operation, "input_digest" => Ace::Lab::Atoms::ServiceInput.digest(input),
      "target" => Ace::Lab::Atoms::ServiceInput.target(input))
    @document.fetch("authorizations")["decision"] = @document.fetch("authorizations").fetch("decision").merge(
      "operation" => operation, "input_digest" => submission.fetch("input_digest"), "target" => submission.fetch("target"))
    [submission, JSON.generate(input)]
  end

  def request_and_begin(client, submission, bytes)
    claim = client.call("request_service", submission.merge("service_id" => "executor", "worker_process_binding" => @worker),
      mutation_id: "cleanup-request", upload_parts: [bytes], purpose: :service_input, timeout: 30)
    params = submission.slice("assignment_id", "attempt_id", "head", "candidate_generation", "request_id").merge(
      "claim_binding" => claim.data.fetch("claim_binding"), "expected_generation" => claim.data.fetch("generation"))
    [claim, params]
  end

  def test_actual_client_journal_dispatch_retains_independent_original_owner_and_replay_cannot_issue_again
    fixture do
      submission, bytes = cleanup_submission
      reads = 0
      original = owner_binding
      selected = Object.new
      selected.define_singleton_method(:identity!) { reads += 1; original }
      @policy.instance_variable_set(:@cleanup_owner, selected) # Installed identity boundary is controlled, not the canonical owner.
      client = start_service_server
      claim, params = request_and_begin(client, submission, bytes)
      started = client.call("begin_dispatch", params, mutation_id: "cleanup-begin", upload_parts: [bytes], purpose: :service_input)
      assert_equal "permitted", started.data.fetch("invocation")
      assert_equal original, started.data.fetch("operation_owner_binding")
      assert_equal original, @journal.service_request(submission.fetch("request_id")).fetch("operation_owner_binding")
      record = @journal.service_request(submission.fetch("request_id"))
      assert_equal original, Ace::Assign::Authority::ServiceEvidence.new(journal: @journal).context(record).dig(:binding, "operation_owner_binding")
      assert_operator reads, :>=, 2
      events = @journal.read_events("assignment", commit: started.data.fetch("journal_commit"))
      accepted = events.find { |event| event.dig("payload", "operation") == "begin_dispatch" }
      assert_equal original, accepted.dig("payload", "data", "operation_owner_binding")
      before = reads
      replay = client.call("begin_dispatch", params, mutation_id: "cleanup-begin", upload_parts: [bytes], purpose: :service_input)
      assert replay.replayed
      assert_equal "already_started", replay.data.fetch("invocation")
      assert_equal before, reads, "historical replay cannot reacquire a new root execution permission"
      assert_equal claim.data.fetch("claim_binding"), started.data.fetch("claim_binding")
      canonical = @journal.ref_value
      assert_raises(Ace::Assign::AttemptErrors::Conflict) do
        @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "changed-root",
          operation: "fixture", parameters_digest: "f" * 64, expected_generation: generation) do
          {data: {}, service_updates: [{request_id: record.fetch("request_id"), expected: record,
            replacement: record.merge("operation_owner_binding" => original.merge("invocation_id" => "c" * 32)), event_type: "service_transition"}]}
        end
      end
      assert_equal canonical, @journal.ref_value
    end
  end

  def test_root_replacement_at_lower_cas_admission_refuses_without_dispatch_event
    fixture do
      submission, bytes = cleanup_submission
      reads = 0
      original = owner_binding
      selected = Object.new
      selected.define_singleton_method(:identity!) do
        reads += 1
        reads == 1 ? original : original.merge("invocation_id" => "c" * 32)
      end
      @policy.instance_variable_set(:@cleanup_owner, selected)
      client = start_service_server
      _, params = request_and_begin(client, submission, bytes)
      before = @journal.ref_value
      error = assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
        client.call("begin_dispatch", params, mutation_id: "cleanup-begin", upload_parts: [bytes], purpose: :service_input)
      end
      assert_includes error.message, "unauthorized"
      assert_equal before, @journal.ref_value
      assert_equal "issued", @journal.service_request(submission.fetch("request_id")).fetch("dispatch_phase")
      refute @journal.service_request(submission.fetch("request_id")).key?("operation_owner_binding")
      @policy.instance_variable_set(:@cleanup_owner, nil)
      assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
        client.call("begin_dispatch", params, mutation_id: "cleanup-missing-owner", upload_parts: [bytes], purpose: :service_input)
      end
      assert_equal before, @journal.ref_value
    end
  end
end
