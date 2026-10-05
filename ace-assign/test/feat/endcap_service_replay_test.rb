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
            "caller_uid" => worker.fetch("uid"), "dispatch_phase" => "issued", "state" => "uncertain",
            "launch_ticket" => "fixture-launch", "reservation_generation" => 1)
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
          kernel.define_singleton_method(:descendant?) { |*_args| true }
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

      def test_authorization_read_revalidates_body_and_policy_without_mutation_or_permission
        with_review_replay do |endcap, original, upload, _claim, journal|
          params = original.fetch("params").slice("mapping_id", "assignment_id", "attempt_id", "candidate_generation", "head", "request_id", "input_digest", "transfer")
          record = journal.service_request("request-2")
          params["claim_binding"] = record.fetch("claim_binding")
          request = original.merge("operation" => "service_authorization", "mutation_id" => nil, "params" => params)
          endcap.define_singleton_method(:active_origin) { |*| {"launch_ticket" => record["launch_ticket"], "reservation_generation" => record["reservation_generation"], "process_binding" => {"process_identity" => record["worker_process_binding"]}} }
          endcap.define_singleton_method(:candidate) { |*| {"head" => params["head"], "candidate_generation" => params["candidate_generation"]} }
          endcap.define_singleton_method(:approved_review!) { |*| true }
          endcap.define_singleton_method(:service_receiver!) { |*| true }
          policy = endcap.instance_variable_get(:@service_policy)
          calls = 0
          denied = false
          policy.define_singleton_method(:prepare!) do |binding, input_bytes:|
            raise SecurityError, "policy changed" if denied
            raise SecurityError, "body changed" unless input_bytes == "exact original input"
            calls += 1
            {policy_digest: binding.fetch("policy_digest"), operation_digest: "operation-digest"}
          end
          ref = journal.ref_value
          2.times do
            reply = endcap.dispatch(request: request, peer: {"uid" => Process.uid}, role: :executor, transfer: upload)
            assert_equal %w[candidate_generation claim_binding head operation_digest policy_digest request_id], reply.fetch(:data).keys.sort
            refute reply.fetch(:replayed)
            refute reply.fetch(:data).key?("invocation")
          end
          assert_equal 2, calls
          denied = true
          assert_raises(SecurityError) { endcap.dispatch(request: request, peer: {"uid" => Process.uid}, role: :executor, transfer: upload) }
          denied = false
          changed = Object.new
          changed.define_singleton_method(:count) { 1 }
          changed.define_singleton_method(:bytes) { "different body" }
          assert_raises(SecurityError) { endcap.dispatch(request: request, peer: {"uid" => Process.uid}, role: :executor, transfer: changed) }
          request["mutation_id"] = "not-a-read"
          assert_raises(ArgumentError) { endcap.dispatch(request: request, peer: {"uid" => Process.uid}, role: :executor, transfer: upload) }
          assert_equal ref, journal.ref_value
        end
      end

      def test_status_projects_current_owner_generation_for_begin_without_changing_original_replay
        with_review_replay do |endcap, request, upload, claim, journal|
          original = Marshal.load(Marshal.dump(request))
          request["mutation_id"] = "second-endcap-mutation"
          request["params"]["expected_generation"] = 2
          endcap.dispatch(request: request, peer: {"uid" => Process.uid}, role: :executor, transfer: upload)
          record = journal.service_request("request-2")
          params = request.fetch("params").slice("mapping_id", "assignment_id", "attempt_id", "candidate_generation", "head", "request_id")
          status = request.merge("operation" => "service_status", "mutation_id" => nil, "params" => params)
          projected = endcap.dispatch(request: status, peer: {"uid" => Process.uid}, role: :executor)
          assert_equal 3, projected.dig(:data, "generation")
          refute projected.fetch(:data).key?("invocation")
          begin_params = params.merge("claim_binding" => record.fetch("claim_binding"), "expected_generation" => 2,
            "transfer" => request.dig("params", "transfer"))
          begin_request = request.merge("operation" => "begin_dispatch", "mutation_id" => "begin-after-status", "params" => begin_params)
          assert_raises(AttemptErrors::Conflict) { endcap.dispatch(request: begin_request, peer: {"uid" => Process.uid}, role: :executor, transfer: upload) }
          endcap.define_singleton_method(:active_origin) { |*| {"launch_ticket" => record["launch_ticket"], "reservation_generation" => record["reservation_generation"], "process_binding" => {"process_identity" => record["worker_process_binding"]}} }
          endcap.define_singleton_method(:candidate) { |*| {"head" => params["head"], "candidate_generation" => params["candidate_generation"]} }
          endcap.define_singleton_method(:approved_review!) { |*| true }
          endcap.define_singleton_method(:service_receiver!) { |*| true }
          endcap.instance_variable_get(:@service_policy).define_singleton_method(:prepare!) { |*args, **kwargs| {} }
          begin_params["expected_generation"] = projected.dig(:data, "generation")
          started = endcap.dispatch(request: begin_request, peer: {"uid" => Process.uid}, role: :executor, transfer: upload)
          assert_equal "permitted", started.dig(:data, "invocation")
          assert_equal 4, started.dig(:data, "generation")
          after = endcap.dispatch(request: status, peer: {"uid" => Process.uid}, role: :executor)
          assert_equal 4, after.dig(:data, "generation")
          replay = endcap.dispatch(request: original, peer: {"uid" => Process.uid}, role: :executor, transfer: upload)
          assert_equal claim.fetch(:data).slice("generation", "journal_commit"), replay.fetch(:data).slice("generation", "journal_commit")
        end
      end

      def test_executor_status_refuses_absent_and_revoked_current_visibility
        with_review_replay do |endcap, request, _upload, _claim, journal|
          params = request.fetch("params").slice("mapping_id", "assignment_id", "attempt_id", "candidate_generation", "head", "request_id")
          status = request.merge("operation" => "service_status", "mutation_id" => nil, "params" => params)
          before = journal.ref_value
          policy = endcap.instance_variable_get(:@service_policy)
          %w[absent revoked].each do |state|
            policy.define_singleton_method(:visible!) { |**_| raise SecurityError, "#{state} project visibility" }
            assert_raises(SecurityError) { endcap.dispatch(request: status, peer: {"uid" => Process.uid}, role: :executor) }
            assert_equal before, journal.ref_value
          end
        end
      end

      def test_retained_request_refuses_live_same_uid_sibling_of_recorded_native_worker
        with_review_replay do |endcap, request, upload, _claim, journal|
          kernel = endcap.instance_variable_get(:@kernel)
          kernel.define_singleton_method(:descendant?) { |*_args| false }
          # Same UID and kernel-live observation alone are not attempt ownership.
          request["params"]["worker_process_binding"] = request.dig("params", "worker_process_binding").merge("pid" => 101)
          request["mutation_id"] = "sibling-retained-read"
          request["params"]["expected_generation"] = 2
          before = journal.ref_value
          assert_raises(AttemptErrors::UnauthorizedIdentity) { endcap.dispatch(request: request, peer: {"uid" => Process.uid}, role: :executor, transfer: upload) }
          assert_equal before, journal.ref_value
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
