# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "ace/assign/molecules/canonical_evidence"

module Ace
  module Assign
    class CanonicalReceiptReaderTest < AceAssignTestCase
      def git(root, *args)
        output, error, status = Open3.capture3("git", "-C", root, *args)
        assert status.success?, error
        output.strip
      end

      def with_import
        with_temp_cache do |cache|
          root = Dir.mktmpdir("canonical-receipt-", cache)
          repo = File.join(root, "repo")
          FileUtils.mkdir_p(repo)
          git(repo, "init", "-b", "main")
          git(repo, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "candidate")
          head = git(repo, "rev-parse", "HEAD")
          journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(root, "evidence"))
          journal.mutate(assignment_id: "assignment-1", attempt_id: "attempt-1", mutation_id: "before-import",
            operation: "reader_fixture", parameters_digest: "a" * 64, expected_generation: 0) { {data: {}} }
          importer = Molecules::CanonicalEvidence.new(journal: journal)
          context = {kind: "review", project_id: "fixture", assignment_id: "assignment-1", attempt_id: "attempt-1",
                     peer_uid: Process.uid, binding: {"head" => head}, request_id_or_event_id: "review-1", generation: 1}
          plan = importer.import_plan(**context, artifacts: ["canonical reviewed artifact"],
            admitted_after_event_digest: journal.read_events("assignment-1").last.fetch("digest"))
          journal.mutate(assignment_id: "assignment-1", attempt_id: "attempt-1", mutation_id: "import",
            operation: "reader_fixture", parameters_digest: "b" * 64, expected_generation: 1) { plan.merge(data: {}) }
          reference = plan.fetch(:references).first
          receipt = {"attempt_id" => "attempt-1", "assignment_id" => "assignment-1", "project_id" => "fixture",
                     "scope" => "030", "operation" => "review", "head" => head, "verdict" => "succeeded",
                     "producer" => {"actor" => "worker", "role" => "worker", "runtime" => "herdr"},
                     "artifacts" => [{"path" => reference["ref"], "sha256" => reference["sha256"]}],
                     "checks" => [{"name" => "actual-reader-fixture", "verdict" => "passed"}],
                     "review" => {"head" => head, "verdict" => "approved", "reviewer" => {"actor" => "reviewer"}}}
          reader = ->(data, artifact) do
            importer.read({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
              **context.merge(binding: {"head" => data.fetch("head")}))
          end
          verifier = Molecules::ReceiptVerifier.new(artifact_reader: reader)
          yield verifier, receipt, journal, repo, head, root
        end
      end

      def test_new_receipt_reads_canonical_bytes_despite_replaced_workspace_projection
        with_import do |verifier, receipt, _journal, repo, head, _root|
          artifact = receipt.fetch("artifacts").first
          path = File.join(repo, artifact.fetch("path"))
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, "malicious replacement")
          binding = Models::AttemptBinding.new(attempt_id: "attempt-1", assignment_id: "assignment-1",
            project_id: "fixture", scope: "030", actor: "worker", role: "worker", runtime: "herdr", base_head: head, created_at: Time.now.utc)
          identity = Molecules::ExecutionIdentityResolver::Identity.new(actor: "authority", role: "service", runtime: "fixture")
          accepted = verifier.verify!(receipt, attempt: Models::Attempt.new(binding: binding, state: "running"),
            identity: identity, live_head: head, repo_root: repo)
          assert_equal "succeeded", accepted.verdict
          assert_equal "malicious replacement", File.read(path)
          verifier.verify_accepted_evidence!(receipt, live_head: head, repo_root: repo, historical: true)
        end
      end

      def test_missing_canonical_import_never_falls_back_to_correct_workspace_on_historical_read
        with_import do |verifier, receipt, journal, repo, head, _root|
          path = receipt.fetch("artifacts").first.fetch("path")
          FileUtils.mkdir_p(File.dirname(File.join(repo, path)))
          File.write(File.join(repo, path), "canonical reviewed artifact")
          checkout = journal.send(:checkout_dir)
          old = journal.ref_value
          git(checkout, "rm", "--", path)
          git(checkout, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "delete import")
          changed = git(checkout, "rev-parse", "HEAD")
          git(repo, "update-ref", journal.ref, changed, old)
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            verifier.verify_accepted_evidence!(receipt, live_head: head, repo_root: repo, historical: true)
          end
        end
      end

      def test_changed_candidate_cannot_rebind_prior_canonical_review_on_historical_read
        with_import do |verifier, receipt, _journal, repo, _head, _root|
          changed = Marshal.load(Marshal.dump(receipt))
          changed["head"] = "f" * 40
          changed["review"]["head"] = changed["head"]
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            verifier.verify_accepted_evidence!(changed, live_head: changed["head"], repo_root: repo, historical: true)
          end
        end
      end
    end
  end
end
