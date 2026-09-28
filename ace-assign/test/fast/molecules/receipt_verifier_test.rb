# frozen_string_literal: true

require_relative "../../test_helper"
require "digest"

module Ace
  module Assign
    class ReceiptVerifierTest < AceAssignTestCase
      HEAD_A = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      HEAD_B = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

      def setup
        super
        @identity = Molecules::ExecutionIdentityResolver::Identity.new(
          actor: "mc", role: "coordinator", runtime: "local:test", adapter: "local"
        )
        @worker = Molecules::ExecutionIdentityResolver::Identity.new(
          actor: "fork-1", role: "worker", runtime: "fork:1", adapter: "service"
        )
        @attempt = Models::Attempt.new(
          binding: Models::AttemptBinding.new(
            attempt_id: "atver01",
            assignment_id: "8wrvrb",
            scope: "010",
            project_id: "ace",
            actor: "mc",
            role: "coordinator",
            runtime: "local:test",
            base_head: HEAD_A,
            task_id: "148",
            created_at: Time.now.utc
          ),
          state: "running"
        )
        with_temp_cache do |cache_dir|
          @outside_root = cache_dir
          @repo_root = File.join(cache_dir, "repo")
          FileUtils.mkdir_p(@repo_root)
        end
      end

      def build_receipt_data(overrides = {})
        File.write(File.join(@repo_root, "review-artifact.md"), "reviewed deliverable")
        base = {
          "attempt_id" => "atver01",
          "assignment_id" => "8wrvrb",
          "project_id" => "ace",
          "scope" => "010",
          "operation" => "implement",
          "producer" => {"actor" => "fork-1", "role" => "worker", "runtime" => "fork:1"},
          "head" => HEAD_A,
          "verdict" => "failed",
          "artifacts" => [],
          "checks" => []
        }
        base.merge(overrides)
      end

      def review_receipt_data(review_overrides = {})
        build_receipt_data(
          "operation" => "review",
          "verdict" => "succeeded",
          "artifacts" => [{"path" => "review-artifact.md", "sha256" => Digest::SHA256.hexdigest("reviewed deliverable")}],
          "checks" => [{"name" => "review-executed", "verdict" => "passed"}],
          "review" => {
            "reviewer" => {"actor" => "codex-reviewer", "runtime" => "codex:r1"},
            "verdict" => "approved",
            "head" => HEAD_A
          }.merge(review_overrides)
        )
      end

      def verify(data, identity: @identity, live_head: HEAD_A)
        Molecules::ReceiptVerifier.new.verify!(
          data, attempt: @attempt, identity: identity, live_head: live_head, repo_root: @repo_root
        )
      end

      def test_valid_failed_receipt_is_accepted_and_normalized
        receipt = verify(build_receipt_data)

        assert_instance_of Models::ExecutionReceipt, receipt
        assert_equal "failed", receipt.verdict
        assert_match(/\A[0-9a-f]{64}\z/, receipt.digest)
        assert_equal receipt.digest, verify(build_receipt_data).digest
      end

      def test_forbidden_fields_are_rejected
        ["stdout", "token", "environment", "terminal_output"].each do |field|
          data = build_receipt_data(field => "leak")
          error = assert_raises(AttemptErrors::ReceiptRejected) { verify(data) }
          assert_includes error.message, "forbidden"
        end
      end

      def test_missing_required_fields_are_rejected
        data = build_receipt_data
        data.delete("head")
        error = assert_raises(AttemptErrors::ReceiptRejected) { verify(data) }
        assert_includes error.message, "head"
      end

      def test_binding_mismatches_are_rejected
        verify_raises(build_receipt_data("attempt_id" => "atwrong")) { |e| assert_includes e.message, "attempt_id" }
        verify_raises(build_receipt_data("assignment_id" => "other")) { |e| assert_includes e.message, "assignment" }
        verify_raises(build_receipt_data("project_id" => "elsewhere")) { |e| assert_includes e.message, "project" }
        verify_raises(build_receipt_data("scope" => "020")) { |e| assert_includes e.message, "scope" }
      end

      def test_stale_head_is_rejected_against_live_candidate
        verify_raises(build_receipt_data("head" => HEAD_A), live_head: HEAD_B) do |e|
          assert_includes e.message, "stale"
        end
      end

      def test_worker_cannot_accept_succeeded_verdict
        verify_raises(build_receipt_data("verdict" => "succeeded"), identity: @worker) do |e|
          assert_includes e.message, "may not accept"
        end
      end

      def test_worker_may_submit_attributable_failed_result
        receipt = verify(build_receipt_data("verdict" => "failed"), identity: @worker)
        assert_equal "failed", receipt.verdict
      end

      def test_succeeded_verdict_requires_verifiable_artifact_digest
        File.write(File.join(@repo_root, "report.md"), "evidence body")
        digest = Digest::SHA256.hexdigest("evidence body")
        checks = [{"name" => "ace-test", "verdict" => "passed"}]
        good = [{"path" => "report.md", "sha256" => digest}]

        receipt = verify(build_receipt_data("verdict" => "succeeded", "artifacts" => good, "checks" => checks))
        assert_equal "succeeded", receipt.verdict

        verify_raises(build_receipt_data("verdict" => "succeeded", "artifacts" => [{"path" => "report.md", "sha256" => "0" * 64}], "checks" => checks)) do |e|
          assert_includes e.message, "digest mismatch"
        end

        verify_raises(build_receipt_data("verdict" => "succeeded", "artifacts" => [{"path" => "report-missing.md", "sha256" => digest}], "checks" => checks)) do |e|
          assert_includes e.message, "not found"
        end

        verify_raises(build_receipt_data("verdict" => "succeeded", "artifacts" => [{"path" => "../../etc/passwd", "sha256" => digest}], "checks" => checks)) do |e|
          assert_includes e.message, "not found"
        end
      end

      def test_symlinked_artifact_pointing_outside_the_root_is_rejected
        File.write(File.join(@outside_root, "secret.txt"), "external secret")
        File.symlink(File.join(@outside_root, "secret.txt"), File.join(@repo_root, "leak.md"))
        digest = Digest::SHA256.hexdigest("external secret")

        verify_raises(build_receipt_data(
          "verdict" => "succeeded",
          "artifacts" => [{"path" => "leak.md", "sha256" => digest}],
          "checks" => [{"name" => "ace-test", "verdict" => "passed"}]
        )) do |e|
          assert_includes e.message, "escapes"
        end
      end

      def test_succeeded_verdict_requires_executed_checks
        File.write(File.join(@repo_root, "report.md"), "evidence body")
        data = build_receipt_data(
          "verdict" => "succeeded",
          "artifacts" => [{"path" => "report.md", "sha256" => Digest::SHA256.hexdigest("evidence body")}],
          "checks" => []
        )

        verify_raises(data) { |e| assert_includes e.message, "executed check" }
      end

      def test_failing_check_rejects_succeeded_verdict
        data = build_receipt_data(
          "verdict" => "succeeded",
          "artifacts" => [{"path" => "review-artifact.md", "sha256" => Digest::SHA256.hexdigest("reviewed deliverable")}],
          "checks" => [{"name" => "ace-test", "verdict" => "failed"}]
        )
        verify_raises(data) { |e| assert_includes e.message, "ace-test" }
      end

      def test_same_author_and_reviewer_is_rejected
        data = review_receipt_data("reviewer" => {"actor" => "fork-1", "runtime" => "fork:1"})
        verify_raises(data) { |e| assert_includes e.message, "self-approval" }
      end

      def test_independent_review_for_exact_head_is_accepted
        receipt = verify(review_receipt_data)
        assert_equal "codex-reviewer", receipt.review["reviewer"]["actor"]
      end

      def test_review_head_mismatch_is_rejected
        data = review_receipt_data("head" => HEAD_B)
        verify_raises(data) { |e| assert_includes e.message, "review head" }
      end

      def test_report_only_approval_is_not_possible_without_review_verdict
        data = review_receipt_data("verdict" => nil, "reviewer" => {"actor" => "other"})
        data["review"].delete("verdict")
        verify_raises(data) { |e| assert_includes e.message, "approved" }
      end

      def test_supplied_digest_must_match_canonical_payload
        File.write(File.join(@repo_root, "review-artifact.md"), "reviewed deliverable")
        data = review_receipt_data
        data["digest"] = "0" * 64

        verify_raises(data) { |e| assert_includes e.message, "digest mismatch" }
      end

      def test_external_effect_operations_are_classified
        verifier = Molecules::ReceiptVerifier.new

        assert verifier.external_effect?("merge")
        assert verifier.external_effect?("publish")
        assert verifier.external_effect?("deploy")
        assert verifier.external_effect?("release")
        refute verifier.external_effect?("implement")
        refute verifier.external_effect?("review")
      end

      private

      def verify_raises(data, identity: @identity, live_head: HEAD_A)
        error = assert_raises(AttemptErrors::ReceiptRejected) do
          verify(data, identity: identity, live_head: live_head)
        end
        yield error
      end
    end
  end
end
