# frozen_string_literal: true

require_relative "../../test_helper"
require "json"
require "open3"
require "fileutils"
require "digest"

module Ace
  module Assign
    class FixedMergePrimitiveTest < AceAssignTestCase
      REF = "refs/ace/execution"
      HEAD_A = "a" * 40
      HEAD_B = "b" * 40

      def setup
        super
        with_temp_cache do |cache_dir|
          @cache_dir = cache_dir
          @repo = File.join(cache_dir, "candidate")
          FileUtils.mkdir_p(@repo)
          git(@repo, "init", "-b", "main")
          git(@repo, "config", "user.name", "test")
          git(@repo, "config", "user.email", "test@example.com")
          File.write(File.join(@repo, "work.txt"), "candidate work\n")
          git(@repo, "add", "work.txt")
          git(@repo, "commit", "-m", "candidate base")
        end
      end

      def test_admission_is_durable_once_and_replays_the_original_reference
        coordinator = build_coordinator
        record = admission
        admitted = coordinator.admit_fixed_merge_request(record)
        assert_equal "pending", admitted.fetch("state")
        assert_match(/\Afmr1-[A-Za-z0-9_-]{40,86}\z/, admitted.fetch("reference"))
        assert admitted.fetch("journal_commit")
        # The canonical record is the sole queue/effect record: it lives in
        # the evidence ref and nowhere else.
        stored = journal.fixed_merge_request("request-1")
        assert_equal admitted.fetch("reference"), stored.fetch("reference")
        replay = coordinator.admit_fixed_merge_request(record)
        assert_equal admitted.fetch("reference"), replay.fetch("reference")
        assert_equal admitted.fetch("input_digest"), replay.fetch("input_digest")
        # Any different field under the same request ID refuses before effect.
        error = assert_raises(AttemptErrors::Conflict) do
          coordinator.admit_fixed_merge_request(record.merge("input_digest" => "9" * 64))
        end
        assert_includes error.message, "different input"
        error = assert_raises(AttemptErrors::Conflict) do
          coordinator.admit_fixed_merge_request(admission(queue_entry: "020"))
        end
        assert_includes error.message, "different input"
      end

      def test_effect_begins_once_and_a_restarted_receiver_cannot_rebegin
        coordinator = build_coordinator
        admitted = coordinator.admit_fixed_merge_request(admission)
        begun = coordinator.begin_fixed_merge_effect(admitted.fetch("request_id"))
        assert_equal "uncertain", begun.fetch("state")
        # Restart: a fresh coordinator over the same canonical state sees the
        # same record and replays "already started" — at most one merge.
        restarted = build_coordinator
        replayed = restarted.begin_fixed_merge_effect(admitted.fetch("request_id"))
        assert_equal "uncertain", replayed.fetch("state")
        assert_equal begun.fetch("claimed_at"), replayed.fetch("claimed_at")
      end

      def test_terminal_settlement_binds_the_exact_receipt_and_is_immutable
        coordinator = build_coordinator
        admitted = coordinator.admit_fixed_merge_request(admission)
        coordinator.begin_fixed_merge_effect(admitted.fetch("request_id"))
        receipt = terminal_receipt(admitted)
        settled = coordinator.settle_fixed_merge_effect(admitted.fetch("request_id"),
          terminal_status: "succeeded", receipt: receipt)
        assert_equal "succeeded", settled.fetch("state")
        assert_equal receipt, settled.fetch("receipt")
        error = assert_raises(AttemptErrors::InvalidState) do
          coordinator.settle_fixed_merge_effect(admitted.fetch("request_id"),
            terminal_status: "succeeded", receipt: terminal_receipt(admitted))
        end
        assert_includes error.message, "terminal"
        error = assert_raises(AttemptErrors::InvalidState) do
          coordinator.begin_fixed_merge_effect(admitted.fetch("request_id"))
        end
        assert_includes error.message, "terminal"
      end

      def test_failure_is_terminal_only_with_no_effect_evidence
        coordinator = build_coordinator
        admitted = coordinator.admit_fixed_merge_request(admission)
        receipt = terminal_receipt(admitted, terminal_status: "failed")
        error = assert_raises(AttemptErrors::ReceiptRejected) do
          coordinator.settle_fixed_merge_effect(admitted.fetch("request_id"),
            terminal_status: "failed", receipt: receipt)
        end
        assert_includes error.message, "invalid"
        unproven = receipt.merge(
          "effect" => {"started_at" => nil, "finished_at" => "2026-10-12T11:01:00Z",
                       "outcome" => "failed_no_effect", "failure_code" => "merge_failed_no_effect",
                       "no_effect_evidence" => nil}
        )
        error = assert_raises(AttemptErrors::ReceiptRejected) do
          coordinator.settle_fixed_merge_effect(admitted.fetch("request_id"),
            terminal_status: "failed", receipt: unproven)
        end
        assert_includes error.message, "no_effect_evidence"
        proven = terminal_receipt(admitted, terminal_status: "failed").merge(
          "effect" => {"started_at" => nil, "finished_at" => "2026-10-12T11:01:00Z",
                       "outcome" => "failed_no_effect", "failure_code" => "merge_failed_no_effect",
                       "no_effect_evidence" => {"reference" => "evidence/no-effect-1", "sha256" => "0" * 64}},
          "remote_observation" => nil
        )
        settled = coordinator.settle_fixed_merge_effect(admitted.fetch("request_id"),
          terminal_status: "failed", receipt: proven)
        assert_equal "failed", settled.fetch("state")
      end

      def test_tampered_or_foreign_receipts_are_rejected
        coordinator = build_coordinator
        admitted = coordinator.admit_fixed_merge_request(admission)
        receipt = terminal_receipt(admitted)
        tampered = deep_copy(receipt)
        tampered["effect"]["outcome"] = "already_merged"
        tampered["effect"]["started_at"] = "2026-10-12T11:00:00Z"
        # already_merged is still a structurally valid succeeded receipt; the
        # binding to the canonical record is what a tampered document breaks.
        tampered["reference"] = "fmr1-#{"B" * 40}"
        error = assert_raises(AttemptErrors::ReceiptRejected) do
          coordinator.settle_fixed_merge_effect(admitted.fetch("request_id"),
            terminal_status: "succeeded", receipt: tampered)
        end
        assert_includes error.message, "invalid"
        foreign = deep_copy(receipt)
        foreign["request_id"] = "other-request"
        assert_raises(AttemptErrors::ReceiptRejected) do
          coordinator.settle_fixed_merge_effect(admitted.fetch("request_id"),
            terminal_status: "succeeded", receipt: foreign)
        end
        unbound = deep_copy(receipt)
        unbound["request"]["input"] = deep_copy(unbound.dig("request", "input")).merge("forge" => "other")
        assert_raises(AttemptErrors::ReceiptRejected) do
          coordinator.settle_fixed_merge_effect(admitted.fetch("request_id"),
            terminal_status: "succeeded", receipt: unbound)
        end
        # Ruling r4: the terminal digest must RE-DERIVE from the embedded
        # binding. A record admitted with a stored digest that its own binding
        # does not derive to can never settle: the echoed stored value passes
        # the identity checks, but re-derivation rejects it.
        echo = coordinator.admit_fixed_merge_request(
          admission(request_id: "request-echo", authorization: "decision-2")
            .merge("input_digest" => "e" * 64)
        )
        coordinator.begin_fixed_merge_effect("request-echo")
        echo_receipt = terminal_receipt(echo)
        error = assert_raises(AttemptErrors::ReceiptRejected) do
          coordinator.settle_fixed_merge_effect("request-echo",
            terminal_status: "succeeded", receipt: echo_receipt)
        end
        assert_includes error.message, "re-derive"
      end

      def test_read_only_status_resolves_exact_selectors_only
        coordinator = build_coordinator
        admitted = coordinator.admit_fixed_merge_request(admission)
        selectors = {reference: admitted.fetch("reference"), request_id: "request-1",
                     project_id: "atlas", assignment_id: admitted.fetch("assignment_id"),
                     attempt_id: admitted.fetch("attempt_id"), queue_entry: "010",
                     input_digest: admitted.fetch("input_digest")}
        record = coordinator.fixed_merge_status(**selectors)
        assert_equal "pending", record.fetch("state")
        assert_equal admitted.fetch("reference"), record.fetch("reference")
        assert record.frozen?
        # Any mismatched selector or unknown reference answers identically.
        coordinator.fixed_merge_status(**selectors).tap do |probe|
          selectors.each_key do |key|
            next if key == :reference
            broken = selectors.merge(key => broken_value(key))
            assert_nil coordinator.fixed_merge_status(**broken), "expected mismatch for #{key}"
          end
        end
        assert_nil coordinator.fixed_merge_status(**selectors.merge(reference: "fmr1-#{"Z" * 40}"))
        assert_nil coordinator.fixed_merge_status(**selectors.merge(request_id: "other-request"))
      end

      def test_authorization_is_consumed_until_no_effect_is_proven
        coordinator = build_coordinator
        coordinator.admit_fixed_merge_request(admission)
        error = assert_raises(AttemptErrors::AuthorizationConflict) do
          coordinator.admit_fixed_merge_request(admission(request_id: "request-2"))
        end
        assert_includes error.message, "not currently valid"
        # A terminal record with proven no-effect evidence frees the exact
        # authorization for a new reviewed request.
        path = File.join(@repo, "evidence", "no-effect-request-1")
        FileUtils.mkdir_p(File.dirname(path))
        content = "no merge occurred for request-1\n"
        File.write(path, content)
        admitted = journal.fixed_merge_request("request-1")
        coordinator.begin_fixed_merge_effect("request-1")
        proven = terminal_receipt(admitted, terminal_status: "failed").merge(
          "effect" => {"started_at" => nil, "finished_at" => "2026-10-12T11:01:00Z",
                       "outcome" => "failed_no_effect", "failure_code" => "merge_failed_no_effect",
                       "no_effect_evidence" => {"reference" => "evidence/no-effect-request-1",
                                                "sha256" => Digest::SHA256.hexdigest(content)}},
          "remote_observation" => nil
        )
        coordinator.settle_fixed_merge_effect("request-1", terminal_status: "failed", receipt: proven)
        second = coordinator.admit_fixed_merge_request(admission(request_id: "request-2"))
        assert_equal "pending", second.fetch("state")
        refute_equal second.fetch("reference"), admitted.fetch("reference")
      end

      def test_records_live_only_in_the_canonical_evidence_ref
        coordinator = build_coordinator
        coordinator.admit_fixed_merge_request(admission)
        commit = journal.ref_value
        paths = git(@repo, "ls-tree", "-r", "--name-only", commit).lines.map(&:strip)
        assert_includes paths, "execution/merge-requests/request-1.json"
        refute paths.any? { |path| path.start_with?("execution/requests/") },
          "fixed merge records must not reuse the generic service request family"
        # The receiver owns no local ledger: the record is only readable
        # through the canonical journal.
        assert_equal 1, journal.fixed_merge_request_records.size
      end

      private

      def build_coordinator
        Organisms::AttemptCoordinator.new(
          cache_base: @cache_dir,
          repo_root: @repo,
          journal: journal,
          lifecycle_exclusion: Molecules::LifecycleExclusion.new(root: File.join(@cache_dir, ".exclusion"))
        )
      end

      def journal
        @journal ||= Molecules::EvidenceJournal.new(repo_root: @repo, ref: REF,
          checkout_root: File.join(@cache_dir, "evidence-co"))
      end

      def managed_attempt
        @managed_attempt ||= begin
          coordinator = build_coordinator
          manager = Molecules::AssignmentManager.new(cache_base: @cache_dir)
          assignment = manager.create(name: "fixed-merge-test", source_config: "job.yaml",
            task_id: "8x3.t.xz9", project_id: "atlas")
          attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "atlas")
          [assignment.id, attempt.attempt_id]
        end
      end

      def admission(overrides = {})
        assignment_id, attempt_id = managed_attempt
        {
          "request_id" => "request-1",
          "project_id" => "atlas",
          "assignment_id" => assignment_id,
          "attempt_id" => attempt_id,
          "queue_entry" => "010",
          "operation" => "merge",
          "authorization" => "decision-1",
          "input_digest" => canonical_binding_digest(assignment_id, attempt_id),
          "request" => valid_request_document,
          "principal" => "13005",
          "receiver_id" => "ordinary-receiver",
          "configuration_sha256" => "f" * 64,
          "execution_identity" => {"checkout_id" => "checkout-1", "worktree_id" => "worktree-1",
                                   "branch" => "feat/x"},
          "state" => "pending"
        }.merge(overrides)
      end

      # Spec ruling r4: the admission digest is derived from the full
      # eight-field binding via the shared canonical implementation.
      def canonical_binding_digest(assignment_id, attempt_id, request_id: "request-1",
        authorization: "decision-1", input: valid_request_document)
        Atoms::FixedMergeSchemas.canonical_request_digest(
          project: "atlas", assignment: assignment_id, attempt: attempt_id,
          queue_entry: "010", authorization: authorization,
          request_id: request_id, input: input
        )
      end

      def valid_request_document
        {
          "schema" => "ace.lab.service.ordinary-merge-request/v1",
          "forge" => "forgejo",
          "pr_url" => "https://forge.example.com/acme/widget/pulls/7",
          "head_repository" => "acme/widget",
          "head_ref" => "refs/heads/feat/x",
          "candidate_head" => HEAD_A,
          "base_repository" => "acme/widget",
          "base_ref" => "refs/heads/main",
          "expected_base_head" => HEAD_B,
          "method" => "merge",
          "review_evidence" => {
            "schema" => "ace.review.acceptance-reference/v1",
            "reference" => "review-123", "reviewer" => "independent-reviewer",
            "verdict" => "approved", "reviewed_head" => HEAD_A,
            "recorded_at" => "2026-10-12T10:00:00Z", "record_sha256" => "c" * 64
          },
          "test_evidence" => [{
            "schema" => "ace.test.execution-reference/v1",
            "reference" => "test-run-9", "candidate_head" => HEAD_A,
            "command" => "bin/ace-test ace-lab fast", "result" => "passed",
            "recorded_at" => "2026-10-12T10:30:00Z", "receipt_sha256" => "d" * 64
          }]
        }
      end

      def terminal_receipt(record, terminal_status: "succeeded")
        document = record.fetch("request")
        {
          "schema" => "ace.assign.fixed-effect-receipt/v1",
          "reference" => record.fetch("reference"),
          "request_id" => record.fetch("request_id"),
          "input_digest" => record.fetch("input_digest"),
          "terminal_status" => terminal_status,
          "request" => {
            "project" => record.fetch("project_id"), "assignment" => record.fetch("assignment_id"),
            "attempt" => record.fetch("attempt_id"), "queue_entry" => record.fetch("queue_entry"),
            "operation" => "merge", "authorization" => record.fetch("authorization"),
            "input" => document
          },
          "producer" => {"receiver_id" => record.fetch("receiver_id"),
                         "principal" => record.fetch("principal"),
                         "configuration_sha256" => record.fetch("configuration_sha256")},
          "effect" => {"started_at" => "2026-10-12T11:00:00Z", "finished_at" => "2026-10-12T11:01:00Z",
                       "outcome" => "merged", "failure_code" => nil, "no_effect_evidence" => nil},
          "remote_observation" => {
            "forge_instance" => document.fetch("forge"),
            "pr_identity_url" => document.fetch("pr_url"),
            "target_repository_identity" => document.fetch("base_repository"),
            "target_ref_observed" => document.fetch("base_ref"),
            "merged_candidate_head" => document.fetch("candidate_head"),
            "admission_target_head" => document.fetch("expected_base_head"),
            "resulting_target_head" => "1" * 40,
            "merge_commit" => "1" * 40,
            "checkout_id" => record.dig("execution_identity", "checkout_id"),
            "worktree_id" => record.dig("execution_identity", "worktree_id"),
            "branch" => record.dig("execution_identity", "branch")
          }
        }
      end

      def broken_value(key)
        {reference: "fmr1-#{"Z" * 40}", request_id: "other", project_id: "borealis",
         assignment_id: "other-assignment", attempt_id: "other-attempt", queue_entry: "020",
         input_digest: "9" * 64}.fetch(key)
      end

      def deep_copy(value)
        JSON.parse(JSON.generate(value))
      end

      def git(dir, *argv)
        out, stderr, status = Open3.capture3("git", *argv, chdir: dir, stdin_data: "")
        flunk "git #{argv.join(" ")} failed: #{stderr}" unless status.success?
        out
      end
    end
  end
end
