# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "ace/assign/molecules/canonical_evidence"

module Ace
  module Assign
    class AtomicServiceMutationTest < AceAssignTestCase
      def git(root, *args)
        out, error, status = Open3.capture3("git", "-C", root, *args)
        assert status.success?, error
        out.strip
      end

      def fixture
        with_temp_cache do |cache|
          repo = File.join(cache, "repo")
          FileUtils.mkdir_p(repo)
          git(repo, "init", "-b", "main")
          git(repo, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "candidate")
          binding = {"request_id" => "request-1", "assignment_id" => "assignment-1", "attempt_id" => "attempt-1",
            "project_id" => "fixture", "operation" => "publish", "input_digest" => "a" * 64,
            "target" => {"resource" => "fixture"}, "candidate_head" => git(repo, "rev-parse", "HEAD"),
            "executor_uid" => Process.uid, "transport" => "unix"}
          context = {kind: "service", project_id: "fixture", assignment_id: "assignment-1", attempt_id: "attempt-1",
            peer_uid: Process.uid, binding: binding, request_id_or_event_id: "request-1", generation: 1}
          importer = nil
          reader = lambda do |reference, _record, _state, pending|
            if pending && pending[:pending_events]
              importer.read_pending(reference, **context, **pending)
            else
              importer.read(reference, **context, commit: pending && pending[:commit] || importer.instance_variable_get(:@journal).ref_value)
            end
          end
          journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(cache, "journal"),
            mode: :protected, evidence_reader: reader, service_authorizer: ->(*) {})
          importer = Molecules::CanonicalEvidence.new(journal: journal)
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

      def completion(journal, importer, context, binding)
        bytes = "ace-service-attestation request:request-1 input:#{binding.fetch("input_digest")} outcome:succeeded\nexact artifact bytes\r\n"
        plan = importer.import_plan(**context, artifacts: [bytes],
          admitted_after_event_digest: journal.read_events("assignment-1").last.fetch("digest"))
        receipt = binding.merge("outcome" => "succeeded", "evidence" => plan.fetch(:references))
        record = binding.merge("state" => "succeeded", "receipt" => receipt)
        plan.merge(data: {"state" => "succeeded"}, service_updates: [
          {request_id: "request-1", expected: journal.service_request("request-1"), replacement: record, event_type: "service_transition"}])
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
        end
      end
    end
  end
end
