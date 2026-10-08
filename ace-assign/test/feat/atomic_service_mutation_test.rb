# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "ace/assign/molecules/canonical_evidence"
require "ace/assign/authority/service_evidence"
require "ace/assign/authority/endcap"

module Ace
  module Assign
    class AtomicServiceMutationTest < AceAssignTestCase
      def git(root, *args)
        out, error, status = Open3.capture3("git", "-C", root, *args)
        assert status.success?, error
        out.strip
      end

      def fixture(mapping_id: nil, suffix: "")
        with_temp_cache do |cache|
          repo = File.join(cache, "repo#{suffix}")
          FileUtils.mkdir_p(repo)
          git(repo, "init", "-b", "main")
          git(repo, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "candidate")
          binding = {"request_id" => "request-1", "assignment_id" => "assignment-1", "attempt_id" => "attempt-1",
            "project_id" => "fixture", "operation" => "publish", "input_digest" => "a" * 64,
            "target" => {"resource" => "fixture"}, "candidate_head" => git(repo, "rev-parse", "HEAD"),
            "executor_uid" => Process.uid, "transport" => "unix", "dispatch_ticket_id" => "fixture-ticket",
            "claim_binding" => "b" * 64, "candidate_generation" => 1, "claim_generation" => 1, "policy_digest" => "c" * 64}
          binding["mapping_id"] = mapping_id if mapping_id
          importer = nil
          owner = nil
          reader = ->(reference, record, state, pending) { owner.call(reference, record, state, pending) }
          journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(cache, "journal#{suffix}"),
            mode: :protected, evidence_reader: reader, service_authorizer: ->(*) {})
          importer = Molecules::CanonicalEvidence.new(journal: journal)
          owner = Authority::ServiceEvidence.new(journal: journal)
          context = owner.context(binding)
          claim = binding.merge("state" => "accepted")
          mutate(journal, "claim", 0) do
            {data: {}, service_updates: [{request_id: "request-1", expected: nil, replacement: claim, event_type: "service_claim"}]}
          end
          yield journal, importer, context, binding, repo
        end
      end

      def mutate(journal, id, generation, &block)
        journal.mutate(assignment_id: "assignment-1", attempt_id: "attempt-1", mutation_id: id,
          operation: "fixture", parameters_digest: Digest::SHA256.hexdigest(id), expected_generation: generation, &block)
      end

      def completion(journal, importer, context, binding, failed: false)
        outcome = failed ? "failed" : "succeeded"
        state = failed ? "failed-settled" : "succeeded"
        bytes = "ace-service-attestation request:#{binding.fetch("request_id")} input:#{binding.fetch("input_digest")} outcome:#{outcome}#{failed ? " no-effect:true" : ""}\nexact artifact bytes\r\n"
        plan = importer.import_plan(**context, artifacts: [bytes],
          admitted_after_event_digest: journal.read_events("assignment-1").last.fetch("digest"))
        receipt = binding.slice(*Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge(
          "outcome" => outcome, "evidence" => plan.fetch(:references))
        record = binding.merge("state" => state, "receipt" => receipt)
        plan.merge(data: {"state" => state}, service_updates: [
          {request_id: binding.fetch("request_id"), expected: journal.service_request(binding.fetch("request_id")), replacement: record, event_type: "service_transition"}])
      end

      def test_pending_never_masks_changed_terminal_event_history_bytes
        %w[request-0 request-2].each do |other_id|
          fixture(mapping_id: "map", suffix: "raw-#{other_id}") do |journal, importer, _context, binding, _repo|
            other = binding.merge("request_id" => other_id)
            mutate(journal, "other-claim", 1) { {data: {}, service_updates: [
              {request_id: other_id, expected: nil, replacement: other.merge("state" => "accepted"), event_type: "service_claim"}]} }
            context = Authority::ServiceEvidence.new(journal: journal).context(other)
            mutate(journal, "other-complete", 2) { completion(journal, importer, context, other) }
            owner = Authority::Endcap.new(deployment: Object.new, launch: Object.new)
            query = -> { owner.service_settlement_evidence!(journal: journal, events: journal.read_events("assignment-1"),
              params: binding.slice("mapping_id", "assignment_id", "attempt_id"), map: {"project_id" => "fixture"}, commit: journal.ref_value) }
            assert_raises(AttemptErrors::ServiceSettlementPending) { query.call }
            event = journal.read_events("assignment-1").find { |entry| entry["type"] == "service_transition" }
            old = journal.ref_value
            checkout = journal.send(:checkout_dir)
            path = File.join(checkout, "execution", "assignment-1", "events", journal.send(:event_filename, event))
            File.binwrite(path, File.binread(path) + " ")
            git(checkout, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-am", "changed original event bytes")
            changed = git(checkout, "rev-parse", "HEAD")
            git(journal.repo_root, "update-ref", journal.ref, changed, old)
            error = assert_raises(AttemptErrors::EvidenceUnavailable) { query.call }
            refute_kind_of AttemptErrors::ServiceSettlementPending, error
          end
        end
      end

      def test_authenticated_pending_never_masks_later_or_earlier_corrupt_service_record
        %w[request-0 request-2].each do |other_id|
          fixture(mapping_id: "map", suffix: other_id) do |journal, _importer, _context, binding, _repo|
            other = binding.merge("request_id" => other_id, "state" => "accepted")
            mutate(journal, "other-claim", 1) { {data: {}, service_updates: [
              {request_id: other_id, expected: nil, replacement: other, event_type: "service_claim"}]} }
            records = journal.service_request_records.map do |record|
              record["request_id"] == other_id ? record.merge("input_digest" => "z" * 64) : record
            end
            assert_equal 2, records.size
            refute_equal journal.service_request(other_id), records.find { |record| record["request_id"] == other_id }
            owner = Authority::Endcap.new(deployment: Object.new, launch: Object.new)
            journal.stub(:service_request_records, records) do
              error = assert_raises(AttemptErrors::EvidenceUnavailable) do
                owner.service_settlement_evidence!(journal: journal, events: journal.read_events("assignment-1"),
                  params: binding.slice("mapping_id", "assignment_id", "attempt_id"), map: {"project_id" => "fixture"},
                  commit: journal.ref_value)
              end
              refute_kind_of AttemptErrors::ServiceSettlementPending, error
            end
          end
        end
      end

      def test_settlement_projection_pending_is_authenticated_and_injected_challenge_refuses
        fixture(mapping_id: "map") do |journal, importer, _context, binding, _repo|
          owner = Authority::Endcap.new(deployment: Object.new, launch: Object.new)
          params = binding.slice("mapping_id", "assignment_id", "attempt_id")
          query = -> { owner.service_settlement_evidence!(journal: journal, events: journal.read_events("assignment-1"),
            params: params, map: {"project_id" => "fixture"}, commit: journal.ref_value) }
          assert_raises(AttemptErrors::ServiceSettlementPending) { query.call }
          altered = journal.service_request("request-1").merge("input_digest" => "z" * 64)
          journal.stub(:service_request_records, [altered]) do
            error = assert_raises(AttemptErrors::EvidenceUnavailable) { query.call }
            refute_kind_of AttemptErrors::ServiceSettlementPending, error
          end
          # Actual failed-settled coverage now uses the public challenge/import
          # producer in authority/service_settlement_test.rb. A shape-only
          # fixture selector no longer grants settlement evidence authority.
          current = journal.service_request("request-1")
          challenged = current.merge("no_effect_challenge" => "fixture-challenge", "challenge_generation" => 1,
            "challenge_event_digest" => journal.read_events("assignment-1").last.fetch("digest"))
          error = assert_raises(AttemptErrors::EvidenceUnavailable) do
            Authority::ServiceEvidence.new(journal: journal).context(challenged, no_effect: true)
          end
          refute_kind_of AttemptErrors::ServiceSettlementPending, error
          assert_raises(AttemptErrors::ServiceSettlementPending) { query.call }
          empty_params = params.merge("attempt_id" => "empty-attempt")
          assert_equal [], owner.service_settlement_evidence!(journal: journal, events: [], params: empty_params,
            map: {"project_id" => "fixture"}, commit: journal.ref_value).fetch("services")
        end
      end

      def test_settlement_projection_authenticates_exact_terminal_transition_and_imports
        fixture(mapping_id: "map") do |journal, importer, context, binding, _repo|
          plan = completion(journal, importer, context, binding)
          mutate(journal, "complete", 1) { plan }
          owner = Authority::Endcap.new(deployment: Object.new, launch: Object.new)
          params = binding.slice("mapping_id", "assignment_id", "attempt_id")
          commit = journal.ref_value
          events = journal.read_events("assignment-1", commit: commit)
          evidence = owner.service_settlement_evidence!(journal: journal, events: events, params: params,
            map: {"project_id" => "fixture"}, commit: commit)
          transition = events.find { |event| event["type"] == "service_transition" }
          assert_equal commit, evidence.fetch("commit")
          assert_equal [{"request_id" => "request-1", "state" => "succeeded", "event_digest" => transition.fetch("digest"),
            "record_digest" => transition.dig("payload", "record_digest"), "receipt_digest" => transition.dig("payload", "receipt_digest"),
            "evidence_refs" => plan.fetch(:references)}], evidence.fetch("services")
          assert_raises(FrozenError) { evidence.fetch("services").first.fetch("evidence_refs").first["ref"].replace("changed") }
          assert owner.service_settlement_complete!(journal: journal, events: events, params: params,
            map: {"project_id" => "fixture"}, commit: commit)
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            owner.service_settlement_evidence!(journal: journal, events: events.drop(1), params: params,
              map: {"project_id" => "fixture"}, commit: commit)
          end
        end
      end

      def test_pending_import_record_event_and_reply_share_one_commit_with_exact_bytes
        fixture do |journal, importer, context, binding, repo|
          git(journal.send(:checkout_dir), "config", "core.autocrlf", "true")
          plan = completion(journal, importer, context, binding)
          result = mutate(journal, "complete", 1) { plan }
          assert_equal "succeeded", journal.service_request("request-1").fetch("state")
          assert_equal plan.fetch(:blobs).values.first, importer.read(plan.fetch(:references).first, **context)
          events = journal.read_events("assignment-1")
          assert_equal %w[evidence_import service_transition authority_mutation], events.last(3).map { |event| event.fetch("type") }
          assert_equal result.fetch("journal_commit"), journal.mutation_result("complete").fetch("journal_commit")
          assert_equal binding.fetch("candidate_head"), git(repo, "rev-parse", "HEAD")
          coordinator = Organisms::AttemptCoordinator.new(repo_root: repo, journal: journal)
          assert coordinator.send(:verify_service_evidence!, plan.fetch(:references), binding, "succeeded")
          owner = Authority::ServiceEvidence.new(journal: journal)
          %w[attempt_id claim_binding executor_uid candidate_generation].each do |field|
            altered = binding.merge(field => (binding[field].is_a?(Integer) ? binding[field] + 1 : "different"))
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              owner.call(plan.fetch(:references).first, altered, "succeeded", nil)
            end
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { owner.context(binding, no_effect: true) }
        end
      end

      def test_repeated_dispatch_plan_only_reports_retained_state_without_fresh_permission
        fixture do |journal, _importer, _context, binding, _repo|
          current = journal.service_request("request-1")
          started = current.merge("service_id" => "executor", "dispatch_phase" => "dispatch_started")
          # Install a separate exact record through the journal owner; this
          # checks retained-ticket projection, not native launch admission.
          started["request_id"] = "request-2"
          mutate(journal, "started-fixture", 1) { {data: {}, service_updates: [
            {request_id: "request-2", expected: nil, replacement: started, event_type: "service_claim"}]} }
          deployment = Object.new
          deployment.define_singleton_method(:project) { |_| {"service_receivers" => {"executor" => {"executor_uid" => Process.uid}},
            "service_executor_uids" => [Process.uid], "worker_uids" => [Process.uid + 1]} }
          kernel = Object.new
          kernel.define_singleton_method(:live!) { |_| true }
          endcap = Authority::Endcap.new(deployment: deployment, launch: Object.new, kernel: kernel)
          params = binding.slice("assignment_id", "attempt_id", "claim_binding").merge("request_id" => "request-2")
          before = journal.ref_value
          plan = endcap.send(:service_begin_plan, journal, [], params, {"project_id" => "fixture"}, {"uid" => Process.uid}, :executor, "unused")
          assert_equal "already_started", plan.dig(:data, "invocation")
          refute plan.key?(:service_updates)
          assert_equal before, journal.ref_value
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            endcap.send(:service_begin_plan, journal, [], params.merge("claim_binding" => "d" * 64),
              {"project_id" => "fixture"}, {"uid" => Process.uid}, :executor, "unused")
          end
          params["expected_generation"] = 2
          params["transfer"] = {"fixture" => "retained reply projection only"}
          journal.mutate(assignment_id: "assignment-1", attempt_id: "attempt-1", mutation_id: "lost-begin-reply",
            operation: "begin_dispatch", parameters_digest: Atoms::EvidenceDigest.digest(params), expected_generation: 2,
            with_replay: true) { {data: endcap.send(:service_projection, started).merge("invocation" => "permitted")} }
          launch = Object.new
          launch.define_singleton_method(:with_assignment) { |**_, &block| block.call(journal, {}) }
          policy = Object.new
          policy.define_singleton_method(:visible!) { |**_| true }
          policy.define_singleton_method(:input_binding) do |bytes, expected_digest:, expected_target:, operation:|
            raise "wrong original operation" unless operation == "publish"
            raise SecurityError, "input differs" unless bytes == "unused exact replay input" && expected_digest == "a" * 64 && expected_target == {"resource" => "fixture"}
          end
          input = Object.new
          input.define_singleton_method(:count) { 1 }
          input.define_singleton_method(:bytes) { "unused exact replay input" }
          replay_owner = Authority::Endcap.new(deployment: deployment, launch: launch, kernel: kernel, service_policy: policy)
          before = journal.ref_value
          replay = replay_owner.send(:dispatch_service, {"operation" => "begin_dispatch", "mutation_id" => "lost-begin-reply"},
            params, {"project_id" => "fixture", "worker_uid" => Process.uid + 1}, {"uid" => Process.uid}, :executor, input)
          assert replay.fetch(:replayed)
          assert_equal "already_started", replay.dig(:data, "invocation")
          assert_equal before, journal.ref_value
          input.define_singleton_method(:bytes) { "changed body under unchanged replay parameters" }
          assert_raises(SecurityError) do
            replay_owner.send(:dispatch_service, {"operation" => "begin_dispatch", "mutation_id" => "lost-begin-reply"},
              params, {"project_id" => "fixture", "worker_uid" => Process.uid + 1}, {"uid" => Process.uid}, :executor, input)
          end
          assert_equal before, journal.ref_value
        end
      end

      def test_rejected_staging_cannot_leak_into_later_append
        fixture do |journal, importer, context, binding, _repo|
          plan = completion(journal, importer, context, binding)
          before = journal.ref_value
          original = journal.method(:stage_service_records)
          journal.define_singleton_method(:stage_service_records) { |*| raise IOError, "injected staging failure" }
          assert_raises(IOError) { mutate(journal, "complete", 1) { plan } }
          journal.define_singleton_method(:stage_service_records, original)
          assert_equal before, journal.ref_value
          event = Models::EvidenceEvent.build(type: "recovery_observation", attempt_id: "attempt-1",
            previous_digest: journal.read_events("assignment-1").last.fetch("digest"), payload: {"fixture" => true})
          journal.append(assignment_id: "assignment-1", attempt_id: "attempt-1", events: [event])
          assert_equal "accepted", journal.service_request("request-1").fetch("state")
          assert_nil journal.mutation_result("complete")
          assert_raises(AttemptErrors::EvidenceUnavailable) { journal.blob(plan.fetch(:references).first.fetch("ref")) }
          refute journal.read_events("assignment-1").any? { |entry| entry.fetch("type") == "evidence_import" }
        end
      end

      def test_completion_plan_imports_exact_executor_truth_without_new_origin_permission
        fixture do |journal, _importer, _context, binding, _repo|
          existing = journal.service_request("request-1")
          started = existing.merge("state" => "uncertain", "dispatch_phase" => "dispatch_started")
          mutate(journal, "begin-fixture", 1) { {data: {}, service_updates: [
            {request_id: "request-1", expected: existing, replacement: started, event_type: "service_transition"}]} }
          bytes = "ace-service-attestation request:request-1 input:#{binding.fetch("input_digest")} outcome:succeeded\nobserved result\r\n".b
          receipt = binding.slice(*Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge("outcome" => "succeeded",
            "evidence" => [{"ref" => "private-handler-result", "sha256" => Digest::SHA256.hexdigest(bytes)}])
          admitted = {receipt: receipt, artifacts: [bytes], receipt_sha256: Digest::SHA256.hexdigest(JSON.generate(receipt))}
          kernel = Object.new
          kernel.define_singleton_method(:live!) { |_| true }
          owner = Authority::Endcap.new(deployment: Object.new, launch: Object.new, kernel: kernel)
          params = binding.slice("request_id", "assignment_id", "attempt_id", "claim_binding", "candidate_generation").merge("head" => binding.fetch("candidate_head"))
          prepare = ->(item) { owner.send(:service_completion_plan, journal, journal.read_events("assignment-1"), params,
            {"project_id" => "fixture"}, {"uid" => Process.uid}, :executor, item) }
          plan = prepare.call(admitted)
          assert_equal "uncertain", journal.service_request("request-1").fetch("state")
          mutate(journal, "complete-observation", 2) { plan }
          assert_equal "succeeded", journal.service_request("request-1").fetch("state")
          assert_equal bytes, journal.blob(plan.fetch(:references).first.fetch("ref"))
          before = journal.ref_value
          replay = prepare.call(admitted)
          refute replay.key?(:service_updates)
          refute replay.key?(:blobs)
          assert_equal before, journal.ref_value
          changed = admitted.merge(receipt_sha256: "f" * 64)
          assert_raises(AttemptErrors::Conflict) { prepare.call(changed) }
          launch = Object.new
          launch.define_singleton_method(:with_assignment) { |**_, &block| block.call(journal, {}) }
          revoked_policy = Object.new
          revoked_policy.define_singleton_method(:visible!) { |**_| raise SecurityError, "worker grant revoked" }
          transport_owner = Authority::Endcap.new(deployment: Object.new, launch: launch, kernel: kernel, service_policy: revoked_policy)
          parts = [JSON.generate(receipt), bytes]
          upload = Object.new
          upload.define_singleton_method(:count) { parts.size }
          upload.define_singleton_method(:bytes) { |index: 0| parts.fetch(index) }
          wire_params = params.merge("receipt_sha256" => admitted.fetch(:receipt_sha256), "expected_generation" => 3)
          result = transport_owner.send(:dispatch_service, {"operation" => "complete_service", "mutation_id" => "completion-retry"},
            wire_params, {"project_id" => "fixture"}, {"uid" => Process.uid}, :executor, upload)
          assert_equal "succeeded", result.dig(:data, "state")
          assert_equal "succeeded", journal.service_request("request-1").fetch("state")
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            owner.send(:service_completion_plan, journal, journal.read_events("assignment-1"), params,
              {"project_id" => "fixture"}, {"uid" => Process.uid + 1}, :executor, admitted)
          end
        end
      end

      def test_ephemeral_original_input_is_bounded_immutable_and_never_persisted
        fixture do |journal, _importer, _context, _binding, repo|
          existing = journal.service_request("request-1")
          replacement = existing.merge("dispatch_phase" => "issued", "state" => "uncertain")
          body = "private-original-input-#{SecureRandom.hex(16)}"
          observed = nil
          journal.instance_variable_set(:@service_authorizer, lambda do |_old, _record, pending|
            observed = pending.fetch(:service_inputs)
            assert observed.frozen?
            assert observed.fetch("request-1").frozen?
            assert_equal body, observed.fetch("request-1")
            assert_raises(FrozenError) { observed.fetch("request-1") << "changed" }
          end)
          plan = {data: {"state" => "uncertain"}, service_inputs: {"request-1" => body}, service_updates: [
            {request_id: "request-1", expected: existing, replacement: replacement, event_type: "service_transition"}]}
          before = journal.ref_value
          [{"wrong-request" => body}, {"request-1" => ""}, {"request-1" => "x" * (64 * 1024 + 1)}].each do |inputs|
            error = assert_raises(ArgumentError) { mutate(journal, "ephemeral", 1) { plan.merge(service_inputs: inputs) } }
            refute_includes error.message, body
            assert_equal before, journal.ref_value
          end
          reply = mutate(journal, "ephemeral", 1) { plan }
          refute_includes JSON.generate(reply), body
          refute_includes JSON.generate(journal.read_events("assignment-1")), body
          git(repo, "ls-tree", "-r", "--name-only", journal.ref_value).lines.each do |path|
            refute_includes git(repo, "show", "#{journal.ref_value}:#{path.strip}"), body
          end
          body << "caller mutation"
          refute_equal body, observed.fetch("request-1")
        end
      end

      def test_lower_protected_fresh_write_without_original_input_refuses_before_policy_or_origin
        fixture do |journal, _importer, _context, binding, _repo|
          owner = Authority::Endcap.new(deployment: Object.new, launch: Object.new)
          journal.instance_variable_set(:@service_authorizer, ->(existing, replacement, pending) {
            owner.authorize_service_update!(journal: journal, existing: existing, replacement: replacement, pending: pending)
          })
          before = journal.ref_value
          replacement = binding.merge("request_id" => "request-2", "state" => "uncertain", "dispatch_phase" => "issued")
          error = assert_raises(AttemptErrors::UnauthorizedIdentity) do
            mutate(journal, "unbound-input", 1) { {data: {}, service_updates: [
              {request_id: "request-2", expected: nil, replacement: replacement, event_type: "service_claim"}]} }
          end
          assert_match(/original input/, error.message)
          assert_equal before, journal.ref_value
          assert_nil journal.service_request("request-2")
        end
      end

      def test_lost_cas_rechecks_owner_policy_before_any_partial_acceptance
        fixture do |journal, importer, context, binding, _repo|
          plan = completion(journal, importer, context, binding)
          before = journal.ref_value
          journal.define_singleton_method(:update_ref_cas) do |*|
            @service_authorizer = ->(*) { raise AttemptErrors::UnauthorizedIdentity, "revoked" }
            false
          end
          assert_raises(AttemptErrors::UnauthorizedIdentity) { mutate(journal, "complete", 1) { plan } }
          assert_equal before, journal.ref_value
          assert_equal "accepted", journal.service_request("request-1").fetch("state")
          assert_nil journal.mutation_result("complete")
          assert_raises(AttemptErrors::EvidenceUnavailable) { journal.blob(plan.fetch(:references).first.fetch("ref")) }
        end
      end

      def test_record_projection_corruption_cannot_claim_canonical_terminal_truth
        fixture do |journal, importer, context, binding, repo|
          plan = completion(journal, importer, context, binding)
          mutate(journal, "complete", 1) { plan }
          checkout = journal.send(:checkout_dir)
          path = "execution/requests/request-1.json"
          record = JSON.parse(File.read(File.join(checkout, path)))
          record["receipt"]["evidence"][0]["sha256"] = "b" * 64
          File.write(File.join(checkout, path), JSON.pretty_generate(record))
          old = journal.ref_value
          git(checkout, "add", "--", path)
          git(checkout, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "corrupt record")
          git(repo, "update-ref", journal.ref, git(checkout, "rev-parse", "HEAD"), old)
          assert_raises(AttemptErrors::EvidenceUnavailable) { journal.service_request("request-1") }
          assert_raises(AttemptErrors::EvidenceUnavailable) { journal.service_request_records }
        end
      end

      def test_raw_blob_plan_cannot_bypass_service_owner_and_cross_attempt_update_is_refused
        fixture do |journal, _importer, _context, binding, _repo|
          before = journal.ref_value
          assert_raises(ArgumentError) do
            mutate(journal, "raw", 1) do
              {data: {}, blobs: {"execution/requests/request-1.json" => "{}"}}
            end
          end
          assert_raises(ArgumentError) do
            mutate(journal, "wrong-attempt", 1) do
              {data: {}, service_updates: [{request_id: "request-2", expected: nil, event_type: "service_claim",
                replacement: binding.merge("request_id" => "request-2", "attempt_id" => "other-attempt", "state" => "accepted")}]}
            end
          end
          assert_equal before, journal.ref_value
          assert_equal "accepted", journal.service_request("request-1").fetch("state")
        end
      end

      def test_deleted_import_cannot_be_replaced_by_workspace_evidence_on_terminal_read
        fixture do |journal, importer, context, binding, repo|
          plan = completion(journal, importer, context, binding)
          mutate(journal, "complete", 1) { plan }
          path = plan.fetch(:references).first.fetch("ref")
          FileUtils.mkdir_p(File.dirname(File.join(repo, path)))
          File.binwrite(File.join(repo, path), plan.fetch(:blobs).fetch(path))
          checkout = journal.send(:checkout_dir)
          old = journal.ref_value
          git(checkout, "rm", "--", path)
          git(checkout, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "delete import")
          git(repo, "update-ref", journal.ref, git(checkout, "rev-parse", "HEAD"), old)
          assert_raises(AttemptErrors::EvidenceUnavailable) { journal.service_request("request-1") }
          coordinator = Organisms::AttemptCoordinator.new(repo_root: repo, journal: journal)
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            coordinator.send(:verify_service_evidence!, plan.fetch(:references), binding, "succeeded")
          end
        end
      end
    end
  end
end
