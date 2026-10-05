# frozen_string_literal: true

require_relative "atomic_service_mutation_test"

module Ace
  module Assign
    class AtomicServiceMutationTest
      def with_review_replay
        fixture do |journal, _importer, _context, binding, _repo|
          worker = {"uid" => Process.uid + 1, "pid" => 100}
          map = {"project_id" => "fixture", "worker_uid" => worker.fetch("uid")}
          body = "exact original input"
          params = binding.slice("assignment_id", "attempt_id", "operation", "input_digest", "target", "candidate_generation")
            .merge("request_id" => "request-2", "mapping_id" => "mapping-1", "authorization" => "decision-1",
              "service_id" => "executor", "worker_process_binding" => worker,
              "head" => binding.fetch("candidate_head"), "expected_generation" => 1,
              "transfer" => {"sha256" => Digest::SHA256.hexdigest(body), "bytes" => body.bytesize})
          record = binding.merge(params.except("head", "expected_generation", "transfer"),
            "caller_uid" => worker.fetch("uid"), "dispatch_phase" => "issued", "state" => "uncertain")
          claim = journal.mutate(assignment_id: "assignment-1", attempt_id: "attempt-1", mutation_id: "claim-service",
            operation: "request_service", parameters_digest: Atoms::EvidenceDigest.digest(params), expected_generation: 1,
            with_replay: true) { {data: record, service_updates: [
              {request_id: "request-2", expected: nil, replacement: record, event_type: "service_claim"}]} }
          deployment = Object.new
          deployment.define_singleton_method(:mapping) { |_| map }
          launch = Object.new
          launch.define_singleton_method(:with_assignment) { |**_, &block| block.call(journal, {}) }
          kernel = Object.new
          kernel.define_singleton_method(:live!) { |_| true }
          policy = Object.new
          policy.define_singleton_method(:visible!) { |**_| true }
          policy.define_singleton_method(:input_binding) { |bytes, **_| raise "bad input" unless bytes == body }
          upload = Object.new
          upload.define_singleton_method(:count) { 1 }
          upload.define_singleton_method(:bytes) { body }
          endcap = Authority::Endcap.new(deployment: deployment, launch: launch, kernel: kernel, service_policy: policy)
          request = {"operation" => "request_service", "project_id" => "fixture", "mutation_id" => "claim-service", "params" => params}
          yield endcap, request, upload, claim, journal
        end
      end

      def test_review_exact_request_replay_keeps_acceptance_metadata
        with_review_replay do |endcap, request, upload, claim|
          reply = endcap.dispatch(request: request, peer: {"uid" => Process.uid}, role: :executor, transfer: upload)
          expected = claim.fetch(:data).slice("generation", "journal_commit")
          assert_equal expected, reply.fetch(:data).slice("generation", "journal_commit")
        end
      end

      def test_review_conflicting_mutation_id_is_rejected_on_request_replay
        with_review_replay do |endcap, request, upload, _claim|
          # The fixture already bound this ID to operation=fixture and other parameters.
          request["mutation_id"] = "claim"
          assert_raises(AttemptErrors::Conflict) do
            endcap.dispatch(request: request, peer: {"uid" => Process.uid}, role: :executor, transfer: upload)
          end
        end
      end

      def test_new_mutation_for_exact_existing_request_retains_truth_without_another_claim
        with_review_replay do |endcap, request, upload, _claim, journal|
          record = journal.service_request("request-2")
          request["mutation_id"] = "retained-request"
          assert_raises(AttemptErrors::Conflict) do
            endcap.dispatch(request: request, peer: {"uid" => Process.uid}, role: :executor, transfer: upload)
          end
          request["params"]["expected_generation"] = 2
          reply = endcap.dispatch(request: request, peer: {"uid" => Process.uid}, role: :executor, transfer: upload)
          refute reply.fetch(:replayed)
          assert_equal "retained", reply.dig(:data, "claim")
          assert_equal 3, reply.dig(:data, "generation")
          assert_equal record, journal.service_request("request-2")
          assert_equal 1, journal.read_events("assignment-1").count { |event| event["type"] == "service_claim" && event.dig("payload", "request_id") == "request-2" }
        end
      end

      def test_exact_claim_replay_keeps_original_acceptance_metadata_beside_current_terminal_truth
        with_review_replay do |endcap, request, upload, claim, journal|
          record = journal.service_request("request-2")
          bytes = "ace-service-attestation request:request-2 input:#{record.fetch("input_digest")} outcome:failed\nobserved failure"
          canonical = Molecules::CanonicalEvidence.new(journal: journal)
          context = Authority::ServiceEvidence.new(journal: journal).context(record)
          plan = canonical.import_plan(**context, artifacts: [bytes], admitted_after_event_digest: journal.read_events("assignment-1").last.fetch("digest"))
          receipt = record.slice(*Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge("outcome" => "failed", "evidence" => plan.fetch(:references))
          failed = record.merge("state" => "failed", "receipt" => receipt, "failed_at" => Time.now.utc.iso8601(9))
          mutate(journal, "later-failure", 2) { plan.merge(data: {}, service_updates: [
            {request_id: "request-2", expected: record, replacement: failed, event_type: "service_transition"}]) }
          current = journal.ref_value
          reply = endcap.dispatch(request: request, peer: {"uid" => Process.uid}, role: :executor, transfer: upload)
          assert reply.fetch(:replayed)
          assert_equal "failed", reply.dig(:data, "state")
          assert_equal "retained", reply.dig(:data, "claim")
          assert_equal claim.fetch(:data).slice("generation", "journal_commit"), reply.fetch(:data).slice("generation", "journal_commit")
          refute_equal current, reply.dig(:data, "journal_commit")
          assert_equal current, journal.ref_value
        end
      end
    end
  end
end
