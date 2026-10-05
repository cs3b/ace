# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "fileutils"

module Ace
  module Assign
    class JournalMutationTest < AceAssignTestCase
      def with_journal
        with_temp_cache do |cache|
          root = Dir.mktmpdir("journal-", cache)
          repo = File.join(root, "repo")
          FileUtils.mkdir_p(repo)
          git(repo, "init", "-b", "main")
          git(repo, "-c", "user.name=test", "-c", "user.email=test@localhost",
            "commit", "--allow-empty", "-m", "candidate")
          journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(root, "checkout"))
          yield journal, repo
        end
      end

      def git(repo, *args)
        output, error, status = Open3.capture3("git", *args, chdir: repo, stdin_data: "")
        assert status.success?, error
        output.strip
      end

      def mutate(journal, id: "mutation-1", digest: "a" * 64, expected: 0, &block)
        journal.mutate(assignment_id: "assignment-1", attempt_id: "attempt-1", mutation_id: id,
          operation: "fixture", parameters_digest: digest, expected_generation: expected, &block)
      end

      def plan(content = "artifact\n")
        {events: [{type: "evidence_import", payload: {"sha256" => Digest::SHA256.hexdigest(content)}}],
         blobs: {"evidence/imports/fixture-1" => content}, data: {"evidence_id" => "fixture-1"}}
      end

      def test_import_bytes_provenance_and_mutation_reply_commit_together
        with_journal do |journal, repo|
          candidate = git(repo, "rev-parse", "HEAD")
          reply = mutate(journal) { plan("binary\x00\n\n".b) }
          assert_equal 1, reply["generation"]
          assert_equal reply["journal_commit"], journal.ref_value
          assert_equal "binary\x00\n\n".b, journal.blob("evidence/imports/fixture-1")
          assert_equal %w[evidence_import authority_mutation], journal.read_events("assignment-1").map { |e| e["type"] }
          assert_equal candidate, git(repo, "rev-parse", "HEAD")
          FileUtils.rm_rf(journal.checkout_root)
          assert_equal "binary\x00\n\n".b, journal.blob("evidence/imports/fixture-1")
          assert_equal reply, mutate(journal) { flunk "exact replay must not execute mutation" }
        end
      end

      def test_original_reply_commit_survives_later_mutations_and_changed_input_refuses
        with_journal do |journal, _repo|
          first = mutate(journal) { plan }
          second = mutate(journal, id: "mutation-2", expected: 1) { {events: [], data: {"later" => true}} }
          refute_equal first["journal_commit"], second["journal_commit"]
          assert_equal first, mutate(journal) { flunk "replayed callback" }
          assert_raises(AttemptErrors::Conflict) { mutate(journal, digest: "b" * 64) { plan } }
          assert_raises(AttemptErrors::Conflict) { mutate(journal, id: "mutation-3", expected: 1) { plan } }
          assert_equal second["journal_commit"], journal.ref_value
        end
      end

      def test_refused_transaction_does_not_admit_artifacts_or_reply
        with_journal do |journal, _repo|
          assert_raises(AttemptErrors::ReceiptRejected) do
            mutate(journal) { raise AttemptErrors::ReceiptRejected, "invalid evidence" }
          end
          assert_nil journal.mutation_result("mutation-1")
          assert_empty journal.read_events("assignment-1")
          assert_raises(AttemptErrors::EvidenceUnavailable) { journal.blob("evidence/imports/fixture-1") }
        end
      end

      def test_immutable_import_paths_and_traversal_are_rejected
        with_journal do |journal, _repo|
          first = mutate(journal) { plan }
          assert_raises(AttemptErrors::Conflict) do
            mutate(journal, id: "mutation-2", expected: 1) { plan("replacement") }
          end
          assert_equal first["journal_commit"], journal.ref_value
          assert_raises(ArgumentError) { journal.blob("evidence/imports/../../escape") }
          assert_raises(ArgumentError) do
            mutate(journal, id: "mutation-3", expected: 1) do
              {events: [], data: {}, blobs: {"../escape" => "bad"}}
            end
          end
          assert_equal first["journal_commit"], journal.ref_value
        end
      end

      def test_failed_staging_cannot_leak_rejected_events_or_blobs_to_other_writers
        %i[append record service].each do |writer|
          with_journal do |journal, repo|
            # A real index lock makes git-add fail after the mutation files exist.
            journal.append(assignment_id: "seed", attempt_id: "seed", events: [
              Models::EvidenceEvent.build(type: "intent", attempt_id: "seed", payload: {})])
            checkout = File.join(journal.checkout_root, "journal")
            index = git(checkout, "rev-parse", "--git-path", "index.lock")
            index = File.expand_path(index, checkout)
            original_write = journal.method(:write_event_files)
            inject = true
            journal.define_singleton_method(:write_event_files) do |assignment, events|
              result = original_write.call(assignment, events)
              if inject
                File.write(index, "locked")
                inject = false
              end
              result
            end
            before = journal.ref_value
            assert_raises(AttemptErrors::EvidenceUnavailable) { mutate(journal) { plan } }
            assert_equal before, journal.ref_value
            FileUtils.rm_f(index)
            event = Models::EvidenceEvent.build(type: "intent", attempt_id: "attempt-1", payload: {})
            case writer
            when :append
              journal.append(assignment_id: "assignment-1", attempt_id: "attempt-1", events: [event])
            when :record
              journal.record(assignment_id: "assignment-1", attempt_id: "attempt-1", type: "intent", payload: {})
            when :service
              journal.claim_service_request({"request_id" => "request-clean", "assignment_id" => "assignment-1",
                "attempt_id" => "attempt-1", "input_digest" => "b" * 64}, guard: -> { nil })
            end
            refute journal.read_events("assignment-1").any? { |e| %w[evidence_import authority_mutation].include?(e["type"]) }
            assert_nil journal.mutation_result("mutation-1")
            assert_raises(AttemptErrors::EvidenceUnavailable) { journal.blob("evidence/imports/fixture-1") }
            assert_empty git(checkout, "status", "--porcelain")
          end
        end
      end

      def test_every_writer_discards_abandoned_disposable_transaction_files
        %i[append record service mutate].each do |writer|
          with_journal do |journal, repo|
            journal.append(assignment_id: "seed", attempt_id: "seed", events: [
              Models::EvidenceEvent.build(type: "intent", attempt_id: "seed", payload: {})])
            checkout = File.join(journal.checkout_root, "journal")
            rejected = Models::EvidenceEvent.build(type: "authority_mutation", attempt_id: "attempt-1",
              payload: {"mutation_id" => "rejected"})
            journal.send(:write_event_files, "assignment-1", [rejected])
            path = File.join(checkout, "evidence/imports/abandoned")
            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, "rejected bytes")
            candidate = git(repo, "rev-parse", "HEAD")
            case writer
            when :append
              journal.append(assignment_id: "assignment-1", attempt_id: "attempt-1", events: [
                Models::EvidenceEvent.build(type: "intent", attempt_id: "attempt-1", payload: {})])
            when :record
              journal.record(assignment_id: "assignment-1", attempt_id: "attempt-1", type: "intent", payload: {})
            when :service
              journal.claim_service_request({"request_id" => "request-clean", "assignment_id" => "assignment-1",
                "attempt_id" => "attempt-1", "input_digest" => "b" * 64}, guard: -> { nil })
            when :mutate
              mutate(journal) { plan }
            end
            refute journal.read_events("assignment-1").any? { |e| e.dig("payload", "mutation_id") == "rejected" }
            refute File.exist?(path)
            assert_empty git(checkout, "status", "--porcelain")
            assert_equal candidate, git(repo, "rev-parse", "HEAD")
          end
        end
      end

      def test_import_preserves_exact_bytes_under_line_conversion_and_clean_filters
        ["autocrlf", "filter"].each do |conversion|
          with_journal do |journal, repo|
            git(repo, "config", "core.autocrlf", "true")
            if conversion == "filter"
              git(repo, "config", "filter.evidence.clean", "tr a-z A-Z")
              git(repo, "config", "filter.evidence.smudge", "tr A-Z a-z")
              File.write(File.join(repo, ".git/info/attributes"), "evidence/imports/* filter=evidence\n")
            end
            content = "artifact\r\n\r\n".b
            first = mutate(journal) { plan(content) }
            assert_equal content, journal.blob("evidence/imports/fixture-1")
            event = journal.read_events("assignment-1").find { |e| e["type"] == "evidence_import" }
            assert_equal Digest::SHA256.hexdigest(content), event.dig("payload", "sha256")
            assert_equal first, mutate(journal) { flunk "replay must not rewrite bytes" }
            mutate(journal, id: "mutation-2", expected: 1) { plan(content) }
            assert_equal content, journal.blob("evidence/imports/fixture-1")
            FileUtils.rm_rf(journal.checkout_root)
            assert_equal content, journal.blob("evidence/imports/fixture-1")
          end
        end
      end

      def canonical_import(journal)
        intent = Models::EvidenceEvent.build(type: "intent", attempt_id: "attempt-1",
          payload: {"scope" => "010", "project_id" => "fixture", "actor" => "worker",
                    "role" => "worker", "runtime" => "herdr:fixture"})
        journal.append(assignment_id: "assignment-1", attempt_id: "attempt-1", events: [intent])
        verifier = Molecules::CanonicalEvidence.new(journal: journal)
        binding = {"request_id" => "request-1", "claim_binding" => "a" * 64}
        params = {kind: "service", project_id: "fixture", assignment_id: "assignment-1",
                  attempt_id: "attempt-1", peer_uid: Process.uid, binding: binding,
                  request_id_or_event_id: "request-1", generation: 1}
        content = "ace-service-attestation request:request-1 input:#{'a' * 64} outcome:succeeded\n"
        reply = mutate(journal) do |current, _commit, _generation|
          imported = verifier.import_plan(**params, admitted_after_event_digest: current.last.fetch("digest"),
            artifacts: [content])
          {events: imported.fetch(:events), blobs: imported.fetch(:blobs),
           data: {"evidence" => imported.fetch(:references)}}
        end
        [verifier, params, reply.fetch("evidence").first, content]
      end

      def test_canonical_import_verifies_exact_peer_binding_and_ignores_projections
        with_journal do |journal, _repo|
          verifier, params, reference, content = canonical_import(journal)
          assert_equal content, verifier.read(reference, **params)
          File.write(File.join(journal.checkout_root, "journal", reference.fetch("ref")), "forged projection")
          assert_equal content, verifier.read(reference, **params)
          %i[peer_uid generation project_id request_id_or_event_id binding].each do |key|
            altered = case key
            when :peer_uid, :generation then params[key] + 1
            when :binding then params[key].merge("claim_binding" => "b" * 64)
            else "other"
            end
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              verifier.read(reference, **params.merge(key => altered))
            end
          end
          FileUtils.rm_rf(journal.checkout_root)
          assert_equal content, verifier.read(reference, **params)
        end
      end

      def test_canonical_blob_corruption_refuses_instead_of_trusting_cached_evidence
        with_journal do |journal, repo|
          verifier, params, reference, _content = canonical_import(journal)
          path = File.join(journal.checkout_root, "journal")
          File.write(File.join(path, reference.fetch("ref")), "changed canonical bytes")
          git(path, "add", "--", reference.fetch("ref"))
          git(path, "-c", "user.name=test", "-c", "user.email=test@localhost", "commit", "-m", "corrupt blob")
          git(repo, "update-ref", journal.ref, git(path, "rev-parse", "HEAD"))
          assert_raises(AttemptErrors::EvidenceUnavailable) { verifier.read(reference, **params) }
        end
      end

      def test_intent_without_bound_process_remains_reserved_with_original_actor
        with_journal do |journal, _repo|
          canonical_import(journal)
          attempt = journal.derived_attempts("assignment-1").first
          assert_equal "reserved", attempt.state
          assert_equal "worker", attempt.binding.actor
          assert_equal "worker", attempt.binding.role
          assert_equal "herdr:fixture", attempt.binding.runtime
          assert_nil journal.read_events("assignment-1").find { |event| event["type"] == "process_start" }
        end
      end
    end
  end
end

module Ace
  module Assign
    class JournalMutationTest
      def test_transport_replay_metadata_comes_from_acceptance_even_after_callback_loses_cas
        with_journal do |journal, repo|
          lost = false
          original = journal.method(:update_ref_cas)
          journal.define_singleton_method(:update_ref_cas) do |new_commit, old|
            unless lost
              lost = true
              competing, error, status = Open3.capture3("git", "-c", "user.name=competitor",
                "-c", "user.email=competitor@localhost", "commit-tree", "#{new_commit}^{tree}",
                "-p", old, "-m", "competing canonical acceptance", chdir: repo, stdin_data: "")
              raise error unless status.success?
              _out, error, status = Open3.capture3("git", "update-ref", ref, competing.strip, old,
                chdir: repo, stdin_data: "")
              raise error unless status.success?
              next false
            end
            original.call(new_commit, old)
          end
          callbacks = 0
          reply = journal.mutate(assignment_id: "assignment-1", attempt_id: "attempt-1", mutation_id: "reservation",
            operation: "reserve_attempt", parameters_digest: "a" * 64, expected_generation: 0,
            with_replay: true) do
            callbacks += 1
            {events: [], data: {"attempt_id" => "attempt-1", "launch_ticket" => "ticket"}}
          end
          assert_equal 1, callbacks, "the losing proposal callback ran"
          assert_equal true, reply.fetch(:replayed), "a callback is not proof that this caller accepted the reservation"
          assert_equal journal.ref_value, reply.fetch(:data).fetch("journal_commit")
          assert_equal 1, journal.read_events("assignment-1").count { |event| event["type"] == "authority_mutation" }
          canonical = journal.mutate(assignment_id: "assignment-1", attempt_id: "attempt-1", mutation_id: "reservation",
            operation: "reserve_attempt", parameters_digest: "a" * 64, expected_generation: 0) { flunk "replay yielded" }
          assert_equal canonical, reply.fetch(:data), "metadata does not alter canonical result"
        end
      end

      def test_new_canonical_acceptance_reports_not_replayed
        with_journal do |journal, _repo|
          reply = journal.mutate(assignment_id: "assignment-1", attempt_id: "attempt-1", mutation_id: "reservation",
            operation: "reserve_attempt", parameters_digest: "a" * 64, expected_generation: 0,
            with_replay: true) { {events: [], data: {"launch_ticket" => "ticket"}} }
          assert_equal false, reply.fetch(:replayed)
          assert_equal journal.ref_value, reply.fetch(:data).fetch("journal_commit")
        end
      end
    end
  end
end
