# frozen_string_literal: true

require_relative "../test_helper"
require "digest"
require "open3"
require "ace/assign/atoms/fixed_merge_schemas"

module Ace
  module Lab
    class OrdinaryMergeReceiverTest < Minitest::Test
      HEAD_B = "b" * 40

      def setup
        @dir = Dir.mktmpdir("ordinary-receiver")
        @repo = File.join(@dir, "repo")
        FileUtils.mkdir_p(@repo)
        git("init", "-b", "main")
        git("config", "user.name", "test")
        git("config", "user.email", "test@example.com")
        File.write(File.join(@repo, "base.txt"), "base\n")
        git("add", "base.txt")
        git("commit", "-m", "base")
        @base_head = git("rev-parse", "HEAD")
        git("checkout", "-b", "feat/x")
        File.write(File.join(@repo, "feature.txt"), "candidate\n")
        git("add", "feature.txt")
        git("commit", "-m", "candidate")
        @candidate_head = git("rev-parse", "HEAD")

        cache = File.join(@dir, "cache")
        @coordinator = Ace::Assign::Organisms::AttemptCoordinator.new(cache_base: cache,
          repo_root: @repo, journal: Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @repo,
            checkout_root: File.join(@dir, "journal")),
          lifecycle_exclusion: Ace::Assign::Molecules::LifecycleExclusion.new(
            root: File.join(@dir, "exclusion")
          ))
        assignment = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache).create(
          name: "ordinary-receiver-test", source_config: "job.yaml", task_id: "8x3.t.xz9",
          project_id: "atlas"
        )
        @attempt = @coordinator.start(assignment_id: assignment.id, step: "010", project_id: "atlas")
        @assignment_id = assignment.id
        @attempt_id = @attempt.attempt_id

        @config = Molecules::OrdinaryReceiverConfig.new({
          "project" => "atlas", "receiver_id" => "ordinary-receiver",
          "socket_path" => "/tmp/unused-ordinary.sock", "receiver_uid" => Process.uid,
          "principal" => "overseer", "principal_uid" => Process.uid,
          "repo_path" => @repo, "policy_path" => "/etc/lab/ace-lab/authorization.yml",
          "execution_identity" => {"checkout_id" => "checkout-1", "worktree_id" => "wt-canonical",
                                   "branch" => "main"}
        })
        File.write(input_path, JSON.generate(valid_request))
      end

      def teardown
        FileUtils.rm_rf(@dir)
      end

      # ---- admission -------------------------------------------------------

      def test_valid_submission_admits_durably_and_returns_the_exact_ack
        envelope = receiver.handle(submission)
        assert_equal "ok", envelope.fetch("status")
        data = envelope.fetch("data")
        assert_equal "ace.lab.service.ordinary-merge-ack/v1", data.fetch("schema")
        assert_equal "accepted", data.fetch("type")
        assert_equal "request-1", data.fetch("request_id")
        assert_equal expected_digest, data.fetch("input_digest")
        assert_match(/\Afmr1-[A-Za-z0-9_-]{40,86}\z/, data.fetch("reference"))
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "pending", record.fetch("state")
        assert_equal "overseer", record.fetch("principal")
        assert_equal({"checkout_id" => "checkout-1", "worktree_id" => "wt-canonical",
                      "branch" => "main"}, record.fetch("execution_identity"))
      end

      def test_unknown_or_missing_selectors_refuse_as_invalid_request
        envelope = receiver.handle(submission.merge("argv" => ["/bin/merge"]))
        assert_equal "ordinary_merge_invalid_request", envelope.dig("error", "code")
        envelope = receiver.handle(submission.except("queue_entry"))
        assert_equal "ordinary_merge_invalid_request", envelope.dig("error", "code")
        envelope = receiver.handle(submission.merge("operation" => "publish"))
        assert_equal "ordinary_merge_invalid_request", envelope.dig("error", "code")
        assert_nil @coordinator.fixed_merge_record("request-1")
      end

      def test_receiver_project_and_principal_binding_refuse_as_selection_mismatch
        assert_equal "ordinary_merge_selection_mismatch",
          receiver.handle(submission.merge("receiver_id" => "other")).dig("error", "code")
        assert_equal "ordinary_merge_selection_mismatch",
          receiver.handle(submission.merge("project_id" => "borealis")).dig("error", "code")
        assert_equal "ordinary_merge_selection_mismatch",
          receiver.handle(submission.merge("principal" => "someone-else")).dig("error", "code")
      end

      def test_configuration_digest_mismatch_refuses_as_selection_mismatch
        other_policy = policy_document.merge("authorizations" =>
          policy_document.fetch("authorizations").merge("extra" => {}))
        drifted = build_receiver(policy_document: other_policy)
        envelope = drifted.handle(submission)
        assert_equal "ordinary_merge_selection_mismatch", envelope.dig("error", "code")
        assert_nil @coordinator.fixed_merge_record("request-1")
      end

      def test_digest_that_does_not_rederive_refuses_as_invalid_request
        envelope = receiver.handle(submission.merge("input_digest" => "9" * 64))
        assert_equal "ordinary_merge_invalid_request", envelope.dig("error", "code")
        assert_includes envelope.dig("error", "message"), "digest"
        assert_nil @coordinator.fixed_merge_record("request-1")
      end

      def test_invalid_request_document_refuses_before_admission
        broken = valid_request.merge("candidate_head" => "z" * 40)
        File.write(input_path, JSON.generate(broken))
        envelope = receiver.handle(submission_with_document(broken))
        assert_equal "ordinary_merge_invalid_request", envelope.dig("error", "code")
        joins = deep_copy(valid_request)
        joins["review_evidence"]["reviewed_head"] = "9" * 40
        envelope = receiver.handle(submission_with_document(joins))
        assert_equal "ordinary_merge_invalid_request", envelope.dig("error", "code")
      end

      def test_authorization_resolution_refuses_in_the_closed_family
        unrecorded = submission_with_document(valid_request, authorization: "unrecorded")
        envelope = receiver.handle(unrecorded)
        assert_equal "ordinary_merge_authorization_invalid", envelope.dig("error", "code")
        expired = policy_document.merge("authorizations" =>
          policy_document.fetch("authorizations").merge("decision-1" =>
            policy_document.fetch("authorizations").fetch("decision-1").merge(
              "expires_at" => "2020-01-01T00:00:00Z"
            )))
        envelope = build_receiver(policy_document: expired).handle(
          submission_for(expired)
        )
        assert_equal "ordinary_merge_authorization_invalid", envelope.dig("error", "code")
        assert_nil @coordinator.fixed_merge_record("request-1")
      end

      # ---- pre-effect target verification (moved-target refusal family) ----

      def test_candidate_absent_from_canonical_repo_refuses_as_target_changed
        document = valid_request.merge(
          "candidate_head" => "9" * 40,
          "review_evidence" => valid_request.fetch("review_evidence").merge(
            "reviewed_head" => "9" * 40),
          "test_evidence" => [valid_request.fetch("test_evidence").first.merge(
            "candidate_head" => "9" * 40)]
        )
        # An authorization decision bound to that (fictional) candidate: the
        # resolver passes, the canonical repository does not know the head.
        rebound = policy_document.merge("authorizations" =>
          policy_document.fetch("authorizations").merge("decision-1" =>
            policy_document.fetch("authorizations").fetch("decision-1").merge(
              "candidate_head" => "9" * 40,
              "input_digest" => expected_digest(document: document)
            )))
        envelope = build_receiver(policy_document: rebound).handle(
          submission_with_document(document).merge("configuration_sha256" =>
            Ace::Lab::Atoms::ServiceInput.digest(rebound))
        )
        assert_equal "ordinary_merge_target_changed", envelope.dig("error", "code")
        assert_nil @coordinator.fixed_merge_record("request-1")
      end

      def test_moved_base_head_refuses_as_target_changed_needs_rebase_family
        git("checkout", "main")
        File.write(File.join(@repo, "divergent.txt"), "divergent\n")
        git("add", "divergent.txt")
        git("commit", "-m", "divergent")
        envelope = receiver.handle(submission)
        assert_equal "ordinary_merge_target_changed", envelope.dig("error", "code")
        assert_nil @coordinator.fixed_merge_record("request-1")
      end

      # ---- execution lifecycle ---------------------------------------------

      def test_execute_performs_one_real_ff_merge_and_settles_the_terminal_receipt
        receiver.handle(submission)
        assert_equal :executed, receiver.execute("request-1")
        assert_equal @candidate_head, git("rev-parse", "refs/heads/main")
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "succeeded", record.fetch("state")
        receipt = record.fetch("receipt")
        assert_equal "ace.assign.fixed-effect-receipt/v1", receipt.fetch("schema")
        assert_equal "merged", receipt.dig("effect", "outcome")
        # ff proof join: merge_commit == resulting_target_head == candidate.
        assert_equal @candidate_head, receipt.dig("remote_observation", "resulting_target_head")
        assert_equal @candidate_head, receipt.dig("remote_observation", "merge_commit")
        assert_equal @candidate_head, receipt.dig("remote_observation", "merged_candidate_head")
        assert_equal "checkout-1", receipt.dig("remote_observation", "checkout_id")
        # Re-execution after terminal settlement never happens.
        assert_equal :skipped_terminal, receiver.execute("request-1")
      end

      def test_uncertain_record_is_never_re_executed_or_resubmitted
        receiver.handle(submission)
        @coordinator.begin_fixed_merge_effect("request-1")
        main_before = git("rev-parse", "refs/heads/main")
        assert_equal :skipped_terminal, receiver.execute("request-1")
        assert_equal main_before, git("rev-parse", "refs/heads/main")
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "uncertain", record.fetch("state")
        assert_nil record["receipt"]
      end

      def test_recovered_pending_record_executes_exactly_once_after_restart
        receiver.handle(submission)
        # Simulate a receiver restart with an identical installed config.
        restarted = build_receiver
        assert_equal [["request-1", :executed]], restarted.recover_pending!
        assert_equal @candidate_head, git("rev-parse", "refs/heads/main")
        assert_equal "succeeded", @coordinator.fixed_merge_record("request-1").fetch("state")
        # A second sweep adopts nothing: no duplicate execution.
        assert_equal [], restarted.recover_pending!
      end

      def test_recover_ignores_foreign_or_uncertain_records
        receiver.handle(submission)
        @coordinator.begin_fixed_merge_effect("request-1") # crashed lifecycle → uncertain
        assert_equal [], receiver.recover_pending!
        assert_equal "uncertain", @coordinator.fixed_merge_record("request-1").fetch("state")
      end

      def test_base_move_between_admission_and_effect_settles_failed_no_effect
        receiver.handle(submission)
        git("checkout", "main")
        File.write(File.join(@repo, "late.txt"), "late\n")
        git("add", "late.txt")
        git("commit", "-m", "late divergence")
        late_head = git("rev-parse", "HEAD")
        assert_equal :executed, receiver.execute("request-1")
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "failed", record.fetch("state")
        receipt = record.fetch("receipt")
        assert_equal "failed_no_effect", receipt.dig("effect", "outcome")
        evidence = receipt.dig("effect", "no_effect_evidence")
        assert evidence["reference"]
        assert_equal late_head, git("rev-parse", "refs/heads/main")
        attestation = File.read(File.join(@repo, evidence.fetch("reference")))
        assert_includes attestation, "request-1"
        assert_equal evidence.fetch("sha256"), Digest::SHA256.hexdigest(attestation)
      end

      def test_journal_conflicts_surface_as_closed_refusals
        receiver.handle(submission)
        lax = build_receiver(resolver: AlwaysAuthorize.new)
        # Same request ID, any different binding: the canonical record
        # conflicts — never a second effect under one request ID.
        envelope = lax.handle(submission_with_document(
          valid_request.merge("forge" => "other-forge")
        ))
        assert_equal "ordinary_merge_request_conflict", envelope.dig("error", "code")
        # The same authorization under another request ID: the journal's
        # authorization guard refuses — one live effect per authorization.
        envelope = lax.handle(submission_with_document(valid_request, request_id: "request-2"))
        assert_equal "ordinary_merge_authorization_invalid", envelope.dig("error", "code")
      end

      def test_receiver_owns_no_local_ledger_only_canonical_assign_state
        receiver.handle(submission)
        receiver.execute("request-1")
        refute Dir.exist?(File.join(@dir, "receiver-state"))
        record = @coordinator.fixed_merge_record("request-1")
        assert record.fetch("reference")
        assert record.fetch("receipt")
      end

      private

      def receiver
        @receiver ||= build_receiver
      end

      def build_receiver(policy_document: nil, resolver: nil)
        Organisms::OrdinaryMergeReceiver.new(config: @config, coordinator: @coordinator,
          policy_document: policy_document || self.policy_document, resolver: resolver)
      end

      # Test double standing in for a fully permissive decision — used only
      # to reach the journal's own conflict guards (the resolver is normally
      # the first line of defense in front of them).
      class AlwaysAuthorize
        def decide(_reference, _binding)
          Molecules::OrdinaryAdmissionResolver::Decision.new(authorized?: true,
            decision: {}, code: nil, message: nil)
        end
      end

      def policy_document
        @policy_document ||= {
          "operations" => {},
          "authorizations" => {
            "decision-1" => {
              "operation" => "merge", "project_id" => "atlas",
              "assignment_id" => @assignment_id, "attempt_id" => @attempt_id,
              "queue_entry" => "010", "input_digest" => expected_digest,
              "forge" => "forgejo", "pr_url" => "https://forge.example.com/acme/widget/pulls/7",
              "head_repository" => "acme/widget", "head_ref" => "refs/heads/feat/x",
              "candidate_head" => @candidate_head, "base_repository" => "acme/widget",
              "base_ref" => "refs/heads/main", "expected_base_head" => @base_head,
              "expires_at" => (Time.now.utc + 3600).iso8601
            }
          }
        }
      end

      def submission
        @submission ||= {
          "project_id" => "atlas", "assignment_id" => @assignment_id,
          "attempt_id" => @attempt_id, "queue_entry" => "010", "operation" => "merge",
          "authorization" => "decision-1", "request_id" => "request-1",
          "input_digest" => expected_digest, "request" => valid_request,
          "principal" => "overseer", "receiver_id" => "ordinary-receiver",
          "configuration_sha256" => Ace::Lab::Atoms::ServiceInput.digest(policy_document)
        }
      end

      def submission_with_document(document, request_id: "request-1", authorization: "decision-1")
        submission.merge("request" => deep_copy(document),
          "request_id" => request_id,
          "authorization" => authorization,
          "input_digest" => expected_digest(document: document, request_id: request_id,
            authorization: authorization))
      end

      # A submission whose configuration digest matches the given policy
      # document (the receiver re-derives the same digest from its own copy).
      def submission_for(policy_document)
        submission.merge("configuration_sha256" =>
          Ace::Lab::Atoms::ServiceInput.digest(policy_document))
      end

      def valid_request
        {
          "schema" => "ace.lab.service.ordinary-merge-request/v1",
          "forge" => "forgejo",
          "pr_url" => "https://forge.example.com/acme/widget/pulls/7",
          "head_repository" => "acme/widget",
          "head_ref" => "refs/heads/feat/x",
          "candidate_head" => @candidate_head,
          "base_repository" => "acme/widget",
          "base_ref" => "refs/heads/main",
          "expected_base_head" => @base_head,
          "method" => "merge",
          "review_evidence" => {
            "schema" => "ace.review.acceptance-reference/v1",
            "reference" => "review-123", "reviewer" => "independent-reviewer",
            "verdict" => "approved", "reviewed_head" => @candidate_head,
            "recorded_at" => "2026-10-12T10:00:00Z", "record_sha256" => "c" * 64
          },
          "test_evidence" => [{
            "schema" => "ace.test.execution-reference/v1",
            "reference" => "test-run-9", "candidate_head" => @candidate_head,
            "command" => "bin/ace-test ace-lab fast", "result" => "passed",
            "recorded_at" => "2026-10-12T10:30:00Z", "receipt_sha256" => "d" * 64
          }]
        }
      end

      def expected_digest(document: valid_request, request_id: "request-1", authorization: "decision-1")
        Ace::Assign::Atoms::FixedMergeSchemas.canonical_request_digest(
          project: "atlas", assignment: @assignment_id, attempt: @attempt_id,
          queue_entry: "010", authorization: authorization,
          request_id: request_id, input: JSON.parse(JSON.generate(document))
        )
      end

      def input_path
        File.join(@dir, "input.json")
      end

      def deep_copy(value)
        JSON.parse(JSON.generate(value))
      end

      def git(*argv)
        out, stderr, status = Open3.capture3("git", *argv, chdir: @repo)
        raise "git #{argv.first} failed: #{stderr}" unless status.success?
        out.strip
      end
    end
  end
end
