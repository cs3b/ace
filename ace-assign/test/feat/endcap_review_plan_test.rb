# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "ace/assign/authority/endcap"

module Ace
  module Assign
    # Tests the pending canonical review transaction, not native-origin
    # admission. No fixture launch state stands in for installed cross-UID proof.
    class EndcapReviewPlanTest < AceAssignTestCase
      def git(root, *args)
        output, error, status = Open3.capture3("git", "-C", root, *args)
        assert status.success?, error
        output.strip
      end

      def fixture
        with_temp_cache do |cache|
          repo = File.join(cache, "repo")
          FileUtils.mkdir_p(repo)
          git(repo, "init", "-b", "main")
          git(repo, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "candidate")
          head = git(repo, "rev-parse", "HEAD")
          journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(cache, "journal"),
            mode: :protected, evidence_reader: ->(*) { raise "service reader not used by review fixture" },
            service_authorizer: ->(*) { raise "service policy not used by review fixture" })
          intent = Models::EvidenceEvent.build(type: "intent", attempt_id: "attempt-1", payload: {
            "assignment_id" => "assignment-1", "project_id" => "fixture", "task_id" => "task-1", "scope" => "030",
            "base_head" => head, "actor" => "worker", "role" => "worker", "runtime" => "herdr"})
          journal.append(assignment_id: "assignment-1", attempt_id: "attempt-1", events: [intent])
          params = {"assignment_id" => "assignment-1", "attempt_id" => "attempt-1"}
          current = {"head" => head, "candidate_generation" => 1}
          review = current.merge("review_id" => "review-1", "reviewer_uid" => Process.uid,
            "reviewer_actor" => "uid-#{Process.uid}", "reviewer_process_binding" => {"fixture" => "pending-context-only"})
          artifact = "executed fixture evidence\x00\r\n".b
          receipt = {"assignment_id" => "assignment-1", "attempt_id" => "attempt-1", "project_id" => "fixture",
            "scope" => "030", "operation" => "review", "head" => head, "verdict" => "succeeded",
            "producer" => {"actor" => "worker", "role" => "worker", "runtime" => "herdr"},
            "artifacts" => [{"path" => "private-review-report", "sha256" => Digest::SHA256.hexdigest(artifact)}],
            "checks" => [{"name" => "executed-review-check", "verdict" => "passed"}],
            "review" => {"head" => head, "verdict" => "approved", "reviewer" => {"actor" => review.fetch("reviewer_actor")}}}
          admitted = {receipt: receipt, artifacts: [artifact], receipt_sha256: Digest::SHA256.hexdigest(JSON.generate(receipt))}
          endcap = Authority::Endcap.new(deployment: Object.new, launch: Object.new)
          yield endcap, journal, params, current, review, admitted
        end
      end

      def plan(endcap, journal, params, current, review, admitted)
        endcap.send(:accept_review_plan, journal, journal.read_events("assignment-1"), params,
          {"project_id" => "fixture", "worker_actor" => "worker"}, current, review, admitted)
      end

      def test_pending_review_bytes_and_receipt_verify_without_workspace_and_accept_in_one_cas
        fixture do |endcap, journal, params, current, review, admitted|
          before = journal.ref_value
          prepared = plan(endcap, journal, params, current, review, admitted)
          assert_equal before, journal.ref_value
          reference = prepared.fetch(:references).first
          assert_raises(AttemptErrors::EvidenceUnavailable) { journal.blob(reference.fetch("ref")) }
          journal.mutate(assignment_id: "assignment-1", attempt_id: "attempt-1", mutation_id: "accept-review",
            operation: "accept_review", parameters_digest: "a" * 64, expected_generation: 0) { prepared }
          assert_equal admitted.fetch(:artifacts).first, journal.blob(reference.fetch("ref"))
          assert_equal %w[intent evidence_import authority_mutation], journal.read_events("assignment-1").map { |event| event.fetch("type") }
          assert_equal "approved", prepared.dig(:data, "review_receipt", "review", "verdict")
          assert_equal "private-review-report", admitted.dig(:receipt, "artifacts", 0, "path")
        end
      end

      def test_forged_reviewer_actor_failed_check_changed_candidate_and_bad_receipt_digest_never_mutate
        fixture do |endcap, journal, params, current, review, admitted|
          before = journal.ref_value
          variants = []
          variants << Marshal.load(Marshal.dump(admitted)).tap { |item| item[:receipt]["review"]["reviewer"]["actor"] = "forged" }
          variants << Marshal.load(Marshal.dump(admitted)).tap { |item| item[:receipt]["checks"][0]["verdict"] = "failed" }
          variants << Marshal.load(Marshal.dump(admitted)).tap { |item| item[:receipt]["head"] = "b" * 40 }
          variants << Marshal.load(Marshal.dump(admitted)).tap { |item| item[:receipt]["digest"] = "c" * 64 }
          variants.each do |item|
            assert_raises(AttemptErrors::ReceiptRejected) { plan(endcap, journal, params, current, review, item) }
            assert_equal before, journal.ref_value
          end
          assert_equal ["intent"], journal.read_events("assignment-1").map { |event| event.fetch("type") }
        end
      end

      def test_historical_approval_rechecks_imported_bytes_and_exact_candidate
        fixture do |endcap, journal, params, current, review, admitted|
          journal.mutate(assignment_id: "assignment-1", attempt_id: "attempt-1", mutation_id: "assign-review",
            operation: "assign_review", parameters_digest: "a" * 64, expected_generation: 0) { {data: review} }
          prepared = plan(endcap, journal, params, current, review, admitted)
          journal.mutate(assignment_id: "assignment-1", attempt_id: "attempt-1", mutation_id: "accept-review",
            operation: "accept_review", parameters_digest: "b" * 64, expected_generation: 1) { prepared }
          map = {"project_id" => "fixture", "worker_uid" => Process.uid + 1}
          read = ->(candidate) { endcap.send(:approved_review!, journal, journal.read_events("assignment-1"), params, map, candidate) }
          before = journal.ref_value
          assert_equal review.fetch("review_id"), read.call(current).fetch("review_id")
          assert_equal before, journal.ref_value
          assert_raises(AttemptErrors::ReceiptRejected) { read.call(current.merge("head" => "b" * 40)) }
          assert_raises(AttemptErrors::ReceiptRejected) { read.call(current.merge("candidate_generation" => 2)) }
          # Keep a matching workspace file: protected historical reads must
          # still reject a canonical artifact changed in the journal ref.
          reference = prepared.fetch(:references).first.fetch("ref")
          File.binwrite(File.join(journal.repo_root, "private-review-report"), admitted.fetch(:artifacts).first)
          journal.send(:with_lock) do
            checkout = journal.send(:checkout_dir)
            File.binwrite(File.join(checkout, reference), "replacement")
            git(checkout, "add", reference)
            git(checkout, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "alter canonical artifact")
            git(journal.repo_root, "update-ref", journal.ref, git(checkout, "rev-parse", "HEAD"))
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { read.call(current) }
        end
      end
    end
  end
end
