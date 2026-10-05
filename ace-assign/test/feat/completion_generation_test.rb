# frozen_string_literal: true

require_relative "endcap_service_replay_test"

module Ace
  module Assign
    class AtomicServiceMutationTest
      def with_late_completion
        with_review_replay do |endcap, request, upload, claim, journal|
          record = journal.service_request("request-2")
          started = record.merge("dispatch_phase" => "dispatch_started")
          mutate(journal, "fixture-begin", 2) { {data: {}, service_updates: [
            {request_id: "request-2", expected: record, replacement: started, event_type: "service_transition"}]} }
          request["mutation_id"] = "interleaved-endcap"
          request["params"]["expected_generation"] = 3
          endcap.dispatch(request: request, peer: {"uid" => Process.uid}, role: :executor, transfer: upload)
          body = "ace-service-attestation request:request-2 input:#{record.fetch('input_digest')} outcome:succeeded\nexact observed result"
          receipt = record.slice(*Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge("outcome" => "succeeded",
            "evidence" => [{"ref" => "private-result", "sha256" => Digest::SHA256.hexdigest(body)}])
          receipt_bytes = JSON.generate(receipt)
          parts = [receipt_bytes, body]
          transfer = Object.new
          transfer.define_singleton_method(:count) { parts.size }
          transfer.define_singleton_method(:bytes) { |index: 0| parts.fetch(index) }
          params = request.fetch("params").slice("mapping_id", "assignment_id", "attempt_id", "candidate_generation", "head", "request_id")
            .merge("claim_binding" => record.fetch("claim_binding"), "receipt_sha256" => Digest::SHA256.hexdigest(receipt_bytes),
              "transfer" => {"parts" => parts.map { |bytes| {"bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)} }})
          complete = request.merge("operation" => "complete_service", "mutation_id" => "late-completion", "params" => params)
          yield endcap, complete, transfer, journal, body, claim
        end
      end

      def test_interleaved_completion_records_truth_without_revoked_or_absent_status_grants
        with_late_completion do |endcap, complete, transfer, journal, _body, _claim|
          policy = endcap.instance_variable_get(:@service_policy)
          status_params = complete.fetch("params").slice("mapping_id", "assignment_id", "attempt_id", "candidate_generation", "head", "request_id")
          %w[revoked absent].each do |reason|
            policy.define_singleton_method(:visible!) { |**_| raise SecurityError, "#{reason} project visibility" }
            assert_raises(SecurityError) { endcap.dispatch(request: complete.merge("operation" => "service_status", "mutation_id" => nil,
              "params" => status_params), peer: {"uid" => Process.uid}, role: :executor) }
          end
          reply = endcap.dispatch(request: complete, peer: {"uid" => Process.uid}, role: :executor, transfer: transfer)
          assert_equal "succeeded", reply.dig(:data, "state")
          assert_equal 5, reply.dig(:data, "generation")
          refute reply.fetch(:data).key?("invocation")
          mutate(journal, "later-endcap", 5) { {data: {}} }
          replay = endcap.dispatch(request: complete, peer: {"uid" => Process.uid}, role: :executor, transfer: transfer)
          assert replay.fetch(:replayed)
          assert_equal reply.fetch(:data).slice("generation", "journal_commit"), replay.fetch(:data).slice("generation", "journal_commit")
          before = journal.ref_value
          %w[expected_generation generation_mode].each do |field|
            hostile = complete.merge("params" => complete.fetch("params").merge(field => 6))
            assert_raises(ArgumentError) { endcap.dispatch(request: hostile, peer: {"uid" => Process.uid}, role: :executor, transfer: transfer) }
          end
          changed = complete.merge("params" => complete.fetch("params").merge("claim_binding" => "f" * 64))
          assert_raises(AttemptErrors::UnauthorizedIdentity) { endcap.dispatch(request: changed, peer: {"uid" => Process.uid}, role: :executor, transfer: transfer) }
          receipt_bytes = transfer.bytes(index: 0)
          contradictory = JSON.generate(JSON.parse(receipt_bytes).merge("outcome" => "failed"))
          conflicting = Object.new
          conflicting.define_singleton_method(:count) { 2 }
          conflicting.define_singleton_method(:bytes) { |index: 0| index.zero? ? contradictory : transfer.bytes(index: 1) }
          conflict_request = complete.merge("params" => complete.fetch("params").merge("receipt_sha256" => Digest::SHA256.hexdigest(contradictory)))
          assert_raises(AttemptErrors::Conflict) { endcap.dispatch(request: conflict_request, peer: {"uid" => Process.uid}, role: :executor, transfer: conflicting) }
          assert_equal before, journal.ref_value
        end
      end

      def test_completion_cas_loss_revalidates_exact_executor_before_importing_any_bytes
        with_late_completion do |endcap, complete, transfer, journal, _body, _claim|
          kernel = endcap.instance_variable_get(:@kernel)
          live = true
          kernel.define_singleton_method(:live!) { |_| raise AttemptErrors::UnauthorizedIdentity, "executor incarnation changed" unless live }
          original = journal.method(:update_ref_cas)
          lost = false
          repo = journal.repo_root
          journal.define_singleton_method(:update_ref_cas) do |new_commit, old|
            unless lost
              lost = true
              competing, error, status = Open3.capture3("git", "-c", "user.name=competitor", "-c", "user.email=competitor@example.invalid",
                "commit-tree", "#{old}^{tree}", "-p", old, "-m", "interleaved canonical commit", chdir: repo)
              raise error unless status.success?
              _, error, status = Open3.capture3("git", "update-ref", ref, competing.strip, old, chdir: repo)
              raise error unless status.success?
              live = false
              next false
            end
            original.call(new_commit, old)
          end
          assert_raises(AttemptErrors::UnauthorizedIdentity) { endcap.dispatch(request: complete, peer: {"uid" => Process.uid}, role: :executor, transfer: transfer) }
          assert lost
          assert_equal "uncertain", journal.service_request("request-2").fetch("state")
          assert_nil journal.mutation_result("late-completion")
          assert_empty journal.read_events("assignment-1").select { |event| event["type"] == "evidence_import" }
        end
      end

      def test_completion_generation_mode_cannot_bypass_other_mutation_admission
        with_late_completion do |_endcap, _complete, _transfer, journal, _body, _claim|
          assert_raises(ArgumentError) do
            journal.mutate(assignment_id: "assignment-1", attempt_id: "attempt-1", mutation_id: "illegal-mode",
              operation: "request_service", parameters_digest: "a" * 64, expected_generation: nil, generation_mode: :recorded_completion) { flunk "must not yield" }
          end
          assert_raises(ArgumentError) do
            journal.mutate(assignment_id: "assignment-1", attempt_id: "attempt-1", mutation_id: "missing-generation",
              operation: "request_service", parameters_digest: "a" * 64, expected_generation: nil) { flunk "must not yield" }
          end
        end
      end
    end
  end
end
