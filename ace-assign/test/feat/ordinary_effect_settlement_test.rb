# frozen_string_literal: true

require_relative "../test_helper"
require "ace/assign/authority/ordinary_effect_settlement"

module Ace
  module Assign
    class OrdinaryEffectSettlementTest < AceAssignTestCase
      def test_canonical_service_completion_survives_missing_local_files_and_owner_restart
        with_fixture do
          assert_raises(AttemptErrors::ServiceSettlementPending) { settlement }
          complete
          ref = @reference.fetch("ref")
          refute File.exist?(File.join(@repo, ref)), "caller checkout has never held the imported receipt artifact"
          FileUtils.rm_rf(@journal.checkout_root)
          @journal = journal
          assert_equal :local, @journal.evidence_mode, "canonical imports do not impersonate protected mode"
          assert_equal ["request"], settlement.fetch("service_requests")
          refute File.exist?(@journal.checkout_root), "read-only settlement must not recreate private checkout"
          # Pure schema checks cannot replace verification of imported bytes.
          corrupt = File.join(File.dirname(@repo), "corrupt-fixture")
          git("worktree", "add", "--detach", corrupt, @journal.ref_value)
          File.write(File.join(corrupt, ref), "wrong bytes")
          git("-C", corrupt, "add", "--", ref)
          git("-C", corrupt, "-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid", "commit", "-m", "corrupt fixture proof")
          git("update-ref", @journal.ref, git("-C", corrupt, "rev-parse", "HEAD").strip)
          assert_raises(AttemptErrors::EvidenceUnavailable) { settlement }
        end
      end

      def test_canonical_imported_service_bytes_must_attest_the_exact_request_and_outcome
        with_fixture do
          before = @journal.ref_value
          assert_raises(AttemptErrors::ReceiptRejected) { complete(content: "ace-service-attestation request:foreign input:#{'d' * 64} outcome:succeeded\n") }
          assert_equal before, @journal.ref_value
          assert_raises(AttemptErrors::ServiceSettlementPending) { settlement }
        end
      end

      def test_recovery_sibling_can_settle_exact_original_delivery_intent_in_the_same_assignment
        with_fixture do
          complete
          @journal.record(assignment_id: "assignment", attempt_id: "attempt", type: "delivery",
            payload: {"stage" => "intent", "operation" => "create", "head" => "a" * 40})
          intent = @journal.read_events("assignment").last
          result = {"stage" => "result", "operation" => "create", "head" => "a" * 40, "outcome" => "succeeded",
            "intent_digest" => intent.fetch("digest"), "intent_attempt_id" => "foreign"}
          @journal.record(assignment_id: "assignment", attempt_id: "recovery", type: "delivery", payload: result)
          assert_raises(AttemptErrors::ServiceSettlementPending) { settlement }
          @journal.record(assignment_id: "assignment", attempt_id: "recovery", type: "delivery", payload: result.merge("intent_attempt_id" => "attempt"))
          assert_equal ["request"], settlement.fetch("service_requests")
        end
      end

      private

      def with_fixture
        Dir.mktmpdir("ordinary-service-evidence-") do |root|
          @repo = File.join(root, "journal")
          FileUtils.mkdir_p(@repo)
          git("init", "-b", "main")
          git("-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "seed")
          @journal = journal
          @record = {"request_id" => "request", "assignment_id" => "assignment", "attempt_id" => "attempt", "project_id" => "atlas",
            "operation" => "deploy", "input_digest" => "d" * 64, "target" => {"resource" => "fixture", "artifact_digest" => nil},
            "candidate_head" => "a" * 40, "executor_uid" => Process.uid, "transport" => "fixture", "authorization" => "decision",
            "dispatch_ticket_id" => "ticket", "claim_binding" => "b" * 64, "candidate_generation" => 1,
            "claim_generation" => 1, "policy_digest" => "c" * 64}
          @journal.claim_service_request(@record, state: "uncertain")
          yield
        end
      end

      def journal
        selected = nil
        reader = ->(*args) { Authority::ServiceEvidence.new(journal: selected).call(*args) }
        selected = Molecules::EvidenceJournal.new(repo_root: @repo, checkout_root: File.join(File.dirname(@repo), "checkout"), evidence_reader: reader)
      end

      def complete(content: "ace-service-attestation request:request input:#{'d' * 64} outcome:succeeded\n")
        @journal.mutate(assignment_id: "assignment", attempt_id: "attempt", mutation_id: "complete",
          operation: "complete_service", expected_generation: 0, parameters_digest: "e" * 64) do |events, _prefix, _generation|
          current = @journal.service_request("request")
          context = Authority::ServiceEvidence.new(journal: @journal).context(current)
          plan = Molecules::CanonicalEvidence.new(journal: @journal).import_plan(**context,
            artifacts: [content], admitted_after_event_digest: events.last.fetch("digest"))
          @reference = plan.fetch(:references).first
          receipt = current.slice(*Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge("outcome" => "succeeded", "evidence" => plan.fetch(:references))
          plan.merge(service_updates: [{request_id: "request", expected: current, replacement: current.merge("state" => "succeeded", "receipt" => receipt), event_type: "service_transition"}], data: {})
        end
      end

      def settlement
        commit = @journal.ref_value
        Authority::OrdinaryEffectSettlement.new(journal: @journal).verify!(project: "atlas", assignment: "assignment", attempt: "attempt",
          events: @journal.read_events("assignment", commit: commit).select { |event| event["attempt_id"] == "attempt" }, commit: commit)
      end

      def git(*args)
        out, error, status = Open3.capture3("git", "-C", @repo, *args)
        raise error unless status.success?
        out
      end
    end
  end
end
