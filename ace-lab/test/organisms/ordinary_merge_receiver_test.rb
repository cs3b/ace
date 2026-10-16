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
        @dir = File.realpath(Dir.mktmpdir("ordinary-receiver"))
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
          "repo_path" => @repo, "policy_path" => File.join(@dir, "authorization.yml"),
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

      def test_pr_url_of_another_repository_or_forge_refuses_as_selection_mismatch
        other_repo = valid_request.merge("pr_url" => "https://forge.example.com/other/repo/pulls/7")
        envelope = receiver.handle(submission_with_document(other_repo))
        assert_equal "ordinary_merge_selection_mismatch", envelope.dig("error", "code")
        other_forge = valid_request.merge("pr_url" => "https://elsewhere.example.com/acme/widget/pulls/7")
        envelope = receiver.handle(submission_with_document(other_forge))
        assert_equal "ordinary_merge_selection_mismatch", envelope.dig("error", "code")
        plain_http = valid_request.merge("pr_url" => "http://forge.example.com/acme/widget/pulls/7")
        envelope = receiver.handle(submission_with_document(plain_http))
        assert_equal "ordinary_merge_selection_mismatch", envelope.dig("error", "code")
        assert_nil @coordinator.fixed_merge_record("request-1")
      end

      def test_executor_self_review_evidence_refuses_pre_effect
        self_reviewed = valid_request.merge("review_evidence" =>
          valid_request.fetch("review_evidence").merge("reviewer" => "ordinary-receiver"))
        envelope = receiver.handle(submission_with_document(self_reviewed))
        assert_equal "ordinary_merge_evidence_invalid", envelope.dig("error", "code")
        principal_reviewed = valid_request.merge("review_evidence" =>
          valid_request.fetch("review_evidence").merge("reviewer" => "overseer"))
        envelope = receiver.handle(submission_with_document(principal_reviewed))
        assert_equal "ordinary_merge_evidence_invalid", envelope.dig("error", "code")
        assert_nil @coordinator.fixed_merge_record("request-1")
      end

      def test_configuration_digest_mismatch_refuses_as_selection_mismatch
        other_policy = policy_document.merge("operations" => {"extra" => {}})
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

      # Per-request trusted refresh: a decision revoked between admission
      # rounds fails closed on the NEXT request without a receiver restart.
      def test_authorization_resolution_refreshes_the_trusted_document_per_request
        unrecorded = submission_with_document(valid_request, authorization: "unrecorded")
        assert_equal "ordinary_merge_authorization_invalid", receiver.handle(unrecorded).dig("error", "code")
        refreshed = policy_document.merge("authorizations" =>
          policy_document.fetch("authorizations").merge("unrecorded" =>
            policy_document.fetch("authorizations").fetch("decision-1").merge(
              "input_digest" => expected_digest(request_id: "request-2",
                authorization: "unrecorded"),
              "expires_at" => (Time.now.utc + 3600).iso8601
            )))
        File.write(policy_path, YAML.safe_dump(refreshed))
        envelope = receiver.handle(submission_with_document(valid_request, request_id: "request-2",
          authorization: "unrecorded"))
        assert_equal "ok", envelope.fetch("status"), envelope
        assert @coordinator.fixed_merge_record("request-2")
      end

      def test_revoked_decision_after_acknowledgment_cannot_execute_on_recovery
        forge = ForgeDouble.new(prs: {7 => open_pr})
        receiver = build_receiver(forge: forge)
        assert_equal "ok", receiver.handle(submission)["status"]
        File.write(policy_path, YAML.safe_dump(policy_document.merge("authorizations" => {})))
        receiver.recover_pending!
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "failed", record["state"]
        refute forge.merge_invoked?
        assert_equal @base_head, git("rev-parse", "refs/heads/main")
      end

      def test_revocation_during_review_attachment_prevents_merge_post
        forge = ForgeDouble.new(prs: {7 => open_pr})
        policy = policy_document
        path = policy_path
        original = forge.method(:create_comment)
        forge.define_singleton_method(:create_comment) do |**args|
          File.write(path, YAML.safe_dump(policy.merge("authorizations" => {})))
          original.call(**args)
        end
        receiver = build_receiver(forge: forge)
        assert_equal "ok", receiver.handle(submission)["status"]
        receiver.execute("request-1")
        assert_equal "failed", @coordinator.fixed_merge_record("request-1")["state"]
        refute forge.merge_invoked?
      end

      def test_stale_producer_cannot_submit_after_static_policy_changes
        receiver = build_receiver
        changed = policy_document.merge("operations" => {"disabled" => {}})
        File.write(policy_path, YAML.safe_dump(changed))
        envelope = receiver.handle(submission)
        assert_equal "ordinary_merge_unavailable", envelope.dig("error", "code")
        assert_nil @coordinator.fixed_merge_record("request-1")
      end

      def test_owner_revocation_during_review_attachment_prevents_merge_post
        valid = true
        guard = lambda { raise Ace::Lab::InvalidConfigurationError, "installed owner changed" unless valid }
        forge = ForgeDouble.new(prs: {7 => open_pr})
        original = forge.method(:create_comment)
        forge.define_singleton_method(:create_comment) do |**args|
          valid = false
          original.call(**args)
        end
        selected = build_receiver(forge: forge, owner_guard: guard)
        assert_equal "ok", selected.handle(submission)["status"]
        selected.execute("request-1")
        assert_equal 1, forge.comments.size
        assert_equal 0, forge.merge_count
        assert_equal "failed", @coordinator.fixed_merge_record("request-1")["state"]
        assert_equal @base_head, git("rev-parse", "refs/heads/main")
      end

      # ---- pre-effect target verification (moved-target refusal family) ----

      def test_candidate_absent_from_canonical_repo_refuses_as_target_changed
        document = valid_request.merge(
          "candidate_head" => "9" * 40,
          "review_evidence" => valid_request.fetch("review_evidence").merge(
            "reviewed_head" => "9" * 40
          ),
          "test_evidence" => [valid_request.fetch("test_evidence").first.merge(
            "candidate_head" => "9" * 40
          )]
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
            Molecules::ServicePolicy.configuration_digest(rebound))
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

      def test_execute_invokes_the_forge_merge_and_settles_from_the_real_readback
        forge = ForgeDouble.new(prs: {7 => open_pr})
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        assert_equal :executed, quietly { receiver.execute("request-1") }
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "succeeded", record.fetch("state")
        receipt = record.fetch("receipt")
        assert_equal "ace.assign.fixed-effect-receipt/v1", receipt.fetch("schema")
        assert_equal "merged", receipt.dig("effect", "outcome")
        # ff proof join: merge_commit == resulting_target_head == candidate,
        # both from the REAL forge readback — never a local git observation.
        assert_equal @candidate_head, receipt.dig("remote_observation", "resulting_target_head")
        assert_equal @candidate_head, receipt.dig("remote_observation", "merge_commit")
        assert_equal @candidate_head, receipt.dig("remote_observation", "merged_candidate_head")
        assert_equal @base_head, receipt.dig("remote_observation", "admission_target_head")
        # Exact-head contract: the merge POST bound the approved candidate.
        assert_equal @candidate_head, forge.merge_kwargs.fetch(:head_commit_id)
        assert_equal "checkout-1", receipt.dig("remote_observation", "checkout_id")
        assert_equal "https://forge.example.com/acme/widget/pulls/7",
          receipt.dig("remote_observation", "pr_identity_url")
        # The receiver never updates the checked-out canonical main locally.
        assert_equal @base_head, git("rev-parse", "refs/heads/main")
        assert forge.merged?(7)
        # Re-execution after terminal settlement never happens.
        assert_equal :skipped_terminal, quietly { receiver.execute("request-1") }
      end

      def test_execute_attaches_the_independent_review_before_merging
        forge = ForgeDouble.new(prs: {7 => open_pr})
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        quietly { receiver.execute("request-1") }
        comments = forge.comments
        assert_equal 1, comments.size
        body = comments.first.fetch(:body)
        assert_includes body, "independent-reviewer"
        assert_includes body, "review-123"
        assert_includes body, @candidate_head
        assert_includes body, "reviewer-produced"
        assert forge.merged?(7)
      end

      def test_already_merged_readback_settles_succeeded_without_a_second_invocation
        forge = ForgeDouble.new(prs: {7 => open_pr.merge(
          "merged" => true, "merge_commit_sha" => @candidate_head
        )})
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        assert_equal :executed, quietly { receiver.execute("request-1") }
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "succeeded", record.fetch("state")
        assert_equal "already_merged", record.dig("receipt", "effect", "outcome")
        assert_equal @candidate_head, record.dig("receipt", "remote_observation", "merge_commit")
        refute forge.merge_invoked?
      end

      # A 404 readback AFTER an invoked merge is never a no-effect proof:
      # the merge POST happened, so the PR's absence (permission change,
      # deletion, visibility loss) cannot prove absence of effect. The
      # record stays uncertain with the original attempt and reference —
      # no attestation, no retry, exactly one invocation.
      def test_invoked_merge_with_absent_readback_leaves_uncertain_never_no_effect
        forge = ForgeDouble.new(prs: {7 => open_pr}, post_merge_absent: true)
        receiver = build_receiver(forge: forge)
        ack = receiver.handle(submission)
        reference = ack.fetch("data").fetch("reference")
        _out, err = capture_io { assert_equal :executed, receiver.execute("request-1") }
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "uncertain", record.fetch("state")
        assert_nil record["receipt"]
        # The original attempt and reference are preserved: reconciliation
        # happens by reference, never a resubmission.
        assert_equal reference, record.fetch("reference")
        assert_equal deep_copy(valid_request), deep_copy(record.fetch("request"))
        # NO no-effect attestation was written for an invoked merge.
        refute_includes git("ls-tree", "-r", "--name-only", "refs/ace/execution"), "execution/merge-evidence/"
        event = JSON.parse(err.lines.grep(/ordinary_merge_uncertain/).last)
        assert_equal "request-1", event.fetch("request_id")
        assert_equal "host-integrator", event.fetch("owner")
        assert_includes event.fetch("reason"), "after the merge invocation"
        assert_includes event.fetch("reason"), "cannot prove no effect"
        # Exactly one merge invocation: never a retry, never a re-invocation.
        assert_equal 1, forge.merge_count
      end

      # Same hard rule for the ambiguous invocation family: a 5xx merge
      # whose post-invocation readback reports the PR absent stays
      # uncertain — the forge may still be applying the invocation.
      def test_ambiguous_invocation_with_absent_readback_stays_uncertain
        forge = ForgeDouble.new(prs: {7 => open_pr},
          merge_outcome: ForgeDouble.result(:ambiguous, 502, "HTTP 502: bad gateway"),
          post_merge_absent: true)
        receiver = build_receiver(forge: forge)
        ack = receiver.handle(submission)
        _out, err = capture_io { assert_equal :executed, receiver.execute("request-1") }
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "uncertain", record.fetch("state")
        assert_nil record["receipt"]
        assert_equal ack.fetch("data").fetch("reference"), record.fetch("reference")
        assert_equal deep_copy(valid_request), deep_copy(record.fetch("request"))
        refute_includes git("ls-tree", "-r", "--name-only", "refs/ace/execution"), "execution/merge-evidence/"
        event = JSON.parse(err.lines.grep(/ordinary_merge_uncertain/).last)
        assert_equal "request-1", event.fetch("request_id")
        assert_equal "host-integrator", event.fetch("owner")
        assert_includes event.fetch("reason"), "cannot prove no effect"
        assert_equal 1, forge.merge_count
      end

      def test_forge_refused_merge_settles_failed_no_effect
        forge = ForgeDouble.new(prs: {7 => open_pr},
          merge_outcome: ForgeDouble.result(:refused, 405, "HTTP 405: not mergeable"))
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        assert_equal :executed, quietly { receiver.execute("request-1") }
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "failed", record.fetch("state")
        receipt = record.fetch("receipt")
        assert_equal "failed_no_effect", receipt.dig("effect", "outcome")
        attestation = git("show", "refs/ace/execution:#{receipt.dig('effect', 'no_effect_evidence', 'reference')}")
        assert_includes attestation, "not mergeable"
        refute forge.merged?(7)
      end

      def test_slow_definitive_forge_refusal_starts_a_new_bounded_settlement_read
        forge = ForgeDouble.new(prs: {7 => open_pr},
          merge_outcome: ForgeDouble.result(:refused, 405, "HTTP 405: not mergeable"))
        selected = build_receiver(forge: forge)
        assert_equal "ok", selected.handle(submission).fetch("status")
        with_slow_reply(forge, :merge_pull_request!) { quietly { selected.execute("request-1") } }
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "failed", record.fetch("state")
        assert_equal "failed_no_effect", record.dig("receipt", "effect", "outcome")
        assert_equal 1, forge.merge_count
        refute forge.merged?(7)
      end

      def test_revocation_during_slow_comment_settles_without_invoking_merge
        forge = ForgeDouble.new(prs: {7 => open_pr})
        selected = build_receiver(forge: forge)
        assert_equal "ok", selected.handle(submission).fetch("status")
        revoke = -> { File.write(policy_path, YAML.safe_dump(policy_document.merge("authorizations" => {}))) }
        with_slow_reply(forge, :create_comment, after: revoke) { quietly { selected.execute("request-1") } }
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "failed", record.fetch("state")
        assert_equal "failed_no_effect", record.dig("receipt", "effect", "outcome")
        assert_equal 0, forge.merge_count
        assert_equal @base_head, git("rev-parse", "refs/heads/main")
      end

      def test_ambiguous_invocation_with_unavailable_readback_leaves_uncertain_with_owner
        forge = ForgeDouble.new(prs: {7 => open_pr},
          merge_outcome: ForgeDouble.result(:ambiguous, nil, "HTTP 502: bad gateway"),
          readback_error: Molecules::ForgejoMergeAdapter::Unavailable.new("forge is unreachable"))
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        _out, err = capture_io { assert_equal :executed, receiver.execute("request-1") }
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "uncertain", record.fetch("state")
        assert_nil record["receipt"]
        event = JSON.parse(err.lines.grep(/ordinary_merge_uncertain/).last)
        assert_equal "request-1", event.fetch("request_id")
        assert_equal "host-integrator", event.fetch("owner")
        # Exactly one merge invocation: reconciliation is readback-only,
        # never a blind repeat.
        assert_equal 1, forge.merge_count
      end

      def test_unavailable_pre_effect_readback_never_invokes_and_leaves_uncertain
        forge = ForgeDouble.new(prs: {7 => open_pr}, fail_pre_readback: true,
          readback_error: Molecules::ForgejoMergeAdapter::Unavailable.new("forge is unreachable"))
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        _out, err = capture_io { assert_equal :executed, receiver.execute("request-1") }
        assert_equal "uncertain", @coordinator.fixed_merge_record("request-1").fetch("state")
        event = JSON.parse(err.lines.grep(/ordinary_merge_uncertain/).last)
        assert_equal "host-integrator", event.fetch("owner")
        refute forge.merge_invoked?
      end

      def test_ambiguous_invocation_reconciled_by_readback_showing_the_merge
        forge = ForgeDouble.new(prs: {7 => open_pr},
          merge_outcome: ForgeDouble.result(:ambiguous, nil, "HTTP 502: bad gateway"),
          post_merge_readback: {"merged" => true, "merge_commit_sha" => @candidate_head,
                                "head" => {"sha" => @candidate_head}, "base" => {"sha" => @base_head}})
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        assert_equal :executed, quietly { receiver.execute("request-1") }
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "succeeded", record.fetch("state")
        assert_equal @candidate_head, record.dig("receipt", "remote_observation", "merge_commit")
      end

      def test_forge_merge_at_another_head_never_settles_succeeded
        other = "e" * 40
        forge = ForgeDouble.new(prs: {7 => open_pr},
          post_merge_readback: {"merged" => true, "merge_commit_sha" => other,
                                "head" => {"sha" => other}, "base" => {"sha" => @base_head}})
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        _out, err = capture_io { assert_equal :executed, receiver.execute("request-1") }
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "uncertain", record.fetch("state")
        assert_nil record["receipt"]
        event = JSON.parse(err.lines.grep(/ordinary_merge_uncertain/).last)
        assert_equal "host-integrator", event.fetch("owner")
        assert_includes event.fetch("reason"), "not the approved candidate"
      end

      def test_pull_request_absent_from_the_forge_settles_failed_no_effect
        forge = ForgeDouble.new(prs: {})
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        assert_equal :executed, quietly { receiver.execute("request-1") }
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "failed", record.fetch("state")
        assert_equal "failed_no_effect", record.dig("receipt", "effect", "outcome")
        refute forge.merge_invoked?
      end

      def test_moved_pr_head_settles_failed_no_effect_without_invoking
        forge = ForgeDouble.new(prs: {7 => open_pr.merge("head" => {"sha" => "d" * 40})})
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        assert_equal :executed, quietly { receiver.execute("request-1") }
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "failed", record.fetch("state")
        assert_equal "failed_no_effect", record.dig("receipt", "effect", "outcome")
        refute forge.merge_invoked?
      end

      def test_moved_forge_base_settles_failed_no_effect_without_invoking
        forge = ForgeDouble.new(prs: {7 => open_pr.merge("base" => {"sha" => "f" * 40})})
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        assert_equal :executed, quietly { receiver.execute("request-1") }
        assert_equal "failed", @coordinator.fixed_merge_record("request-1").fetch("state")
        refute forge.merge_invoked?
      end

      def test_refused_review_attachment_settles_failed_no_effect_without_merging
        forge = ForgeDouble.new(prs: {7 => open_pr},
          comment_outcome: ForgeDouble.result(:refused, 403, "HTTP 403: forbidden"))
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        assert_equal :executed, quietly { receiver.execute("request-1") }
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "failed", record.fetch("state")
        assert_equal "failed_no_effect", record.dig("receipt", "effect", "outcome")
        refute forge.merge_invoked?
      end

      def test_uncertain_record_is_never_re_executed_or_resubmitted
        forge = ForgeDouble.new(prs: {7 => open_pr})
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        @coordinator.begin_fixed_merge_effect("request-1")
        assert_equal :skipped_terminal, quietly { receiver.execute("request-1") }
        assert_equal "uncertain", @coordinator.fixed_merge_record("request-1").fetch("state")
        assert_nil @coordinator.fixed_merge_record("request-1")["receipt"]
        refute forge.merge_invoked?
      end

      def test_recovered_pending_record_executes_exactly_once_after_restart
        forge = ForgeDouble.new(prs: {7 => open_pr})
        build_receiver(forge: forge).handle(submission)
        # Simulate a receiver restart with an identical installed config.
        restarted = build_receiver(forge: forge)
        assert_equal [["request-1", :executed]], quietly { restarted.recover_pending! }
        assert_equal "succeeded", @coordinator.fixed_merge_record("request-1").fetch("state")
        assert forge.merged?(7)
        # A second sweep adopts nothing: no duplicate execution.
        assert_equal [], quietly { restarted.recover_pending! }
        assert_equal 1, forge.merge_count
      end

      def test_recover_ignores_foreign_or_uncertain_records
        forge = ForgeDouble.new(prs: {7 => open_pr})
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        @coordinator.begin_fixed_merge_effect("request-1") # crashed lifecycle → uncertain
        assert_equal [], quietly { receiver.recover_pending! }
        assert_equal "uncertain", @coordinator.fixed_merge_record("request-1").fetch("state")
        refute forge.merge_invoked?
      end

      def test_base_move_between_admission_and_effect_settles_failed_no_effect
        forge = ForgeDouble.new(prs: {7 => open_pr})
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        git("checkout", "main")
        File.write(File.join(@repo, "late.txt"), "late\n")
        git("add", "late.txt")
        git("commit", "-m", "late divergence")
        late_head = git("rev-parse", "HEAD")
        assert_equal :executed, quietly { receiver.execute("request-1") }
        record = @coordinator.fixed_merge_record("request-1")
        assert_equal "failed", record.fetch("state")
        receipt = record.fetch("receipt")
        assert_equal "failed_no_effect", receipt.dig("effect", "outcome")
        evidence = receipt.dig("effect", "no_effect_evidence")
        assert evidence["reference"]
        assert_equal late_head, git("rev-parse", "refs/heads/main")
        attestation = git("show", "refs/ace/execution:#{evidence.fetch('reference')}")
        assert_includes attestation, "request-1"
        assert_equal evidence.fetch("sha256"), Digest::SHA256.hexdigest(attestation)
        refute forge.merge_invoked?
      end

      def test_journal_conflicts_surface_as_closed_refusals
        forge = ForgeDouble.new(prs: {7 => open_pr})
        build_receiver(forge: forge).handle(submission)
        lax = build_receiver(forge: forge, resolver: AlwaysAuthorize.new)
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
        forge = ForgeDouble.new(prs: {7 => open_pr})
        receiver = build_receiver(forge: forge)
        receiver.handle(submission)
        quietly { receiver.execute("request-1") }
        refute Dir.exist?(File.join(@dir, "receiver-state"))
        record = @coordinator.fixed_merge_record("request-1")
        assert record.fetch("reference")
        assert record.fetch("receipt")
      end

      def test_changed_installed_owner_refuses_new_admission_and_pending_dispatch
        valid = true
        guard = lambda { raise Ace::Lab::InvalidConfigurationError, "installed owner changed" unless valid }
        forge = ForgeDouble.new(prs: {7 => open_pr})
        selected = build_receiver(forge: forge, owner_guard: guard)
        assert_equal "ok", selected.handle(submission).fetch("status")
        valid = false
        refused = selected.handle(submission)
        assert_equal "ordinary_merge_unavailable", refused.dig("error", "code")
        assert_raises(Ace::Lab::InvalidConfigurationError) { selected.execute("request-1") }
        assert_raises(Ace::Lab::InvalidConfigurationError) { selected.recover_pending! }
        assert_equal 0, forge.merge_count
        assert_equal "pending", @coordinator.fixed_merge_record("request-1").fetch("state")
      end

      private

      def with_slow_reply(forge, method, after: -> {})
        original_clock = Process.method(:clock_gettime)
        original_reply = forge.method(method)
        elapsed = 0
        forge.define_singleton_method(method) do |**options|
          response = original_reply.call(**options)
          elapsed = 31
          after.call
          response
        end
        Process.stub(:clock_gettime, ->(clock, *options) {
          original_clock.call(clock, *options) + (clock == Process::CLOCK_MONOTONIC ? elapsed : 0)
        }) { yield }
      end

      # Runs the block capturing its service-log output (warn lines) and
      # returning the block value.
      def quietly
        result = nil
        capture_io { result = yield }
        result
      end

      def receiver
        @receiver ||= build_receiver
      end

      def build_receiver(policy_document: nil, resolver: nil, forge: ForgeDouble.new(prs: {}),
        config: @config, readback_attempts: 3, readback_backoff_seconds: 0.0, owner_guard: nil)
        document = policy_document || self.policy_document
        File.write(policy_path, YAML.safe_dump(document))
        Organisms::OrdinaryMergeReceiver.new(config: config, coordinator: @coordinator,
          policy_document: document,
          resolver: resolver || Molecules::OrdinaryAdmissionResolver.new(document,
            path: policy_path,
            loader: ->(path) { YAML.safe_load_file(path, permitted_classes: [Date, Time], aliases: true) }),
          forge_config: forge_config,
          forge_factory: forge ? ->(_document) { forge } : nil,
          readback_attempts: readback_attempts,
          readback_backoff_seconds: readback_backoff_seconds, owner_guard: owner_guard)
      end

      # The host-installed forge merge configuration this test deployment
      # provisions (matching the pr_url identities of the request fixtures).
      def forge_config
        @forge_config ||= Molecules::ForgeMergeConfig.new({
          "base_url" => "https://forge.example.com", "owner" => "acme", "repo" => "widget",
          "token" => "test-scoped-token", "merge_timeout_seconds" => 30,
          "escalation_owner" => "host-integrator",
          "review_attachment" => {"enabled" => true}
        })
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

      # In-process double standing in for the Forgejo merge adapter at the
      # receiver boundary — the forge HTTP layer itself is NEVER mocked: the
      # adapter tests run against the real lab forge and a real local HTTP
      # binding server (see ForgejoMergeAdapterTest). This double mirrors
      # the adapter's closed interface and simulates the forge side
      # (including the fast-forward-only semantics AND the server-side
      # exact-head binding: a merge bound to any head other than the PR's
      # current head is refused) so executor lifecycle tests stay hermetic.
      class ForgeDouble
        Unavailable = Molecules::ForgejoMergeAdapter::Unavailable

        Result = Molecules::ForgejoMergeAdapter::Result
        PR_INDEX = 7

        def self.result(outcome, status, reason)
          Result.new(outcome: outcome, status: status, reason: reason)
        end

        def initialize(prs:, merge_outcome: nil, readback_error: nil, comment_outcome: nil,
          post_merge_readback: nil, fail_pre_readback: false, post_merge_absent: false)
          @prs = prs
          @merge_outcome = merge_outcome
          @readback_error = readback_error
          @comment_outcome = comment_outcome
          @post_merge_readback = post_merge_readback
          @fail_pre_readback = fail_pre_readback
          @post_merge_absent = post_merge_absent
          @comments = []
          @merge_count = 0
          @merge_kwargs = nil
        end

        attr_reader :comments, :merge_count, :merge_kwargs

        def pull_request(owner:, repo:, index:)
          raise @readback_error if @readback_error &&
            (@merge_count.positive? || @fail_pre_readback)
          return nil if @post_merge_absent && @merge_count.positive?
          return @post_merge_readback if @post_merge_readback && @merge_count.positive?
          document = @prs[index]
          return nil unless document
          deep_copy(document)
        end

        def merge_pull_request!(owner:, repo:, index:, head_commit_id:)
          @merge_count += 1
          @merge_kwargs = {owner: owner, repo: repo, index: index,
                           head_commit_id: head_commit_id}
          return @merge_outcome if @merge_outcome
          document = @prs[index]
          unless document
            return Result.new(outcome: :refused, status: 409,
              reason: "HTTP 409: pull request is absent")
          end
          # The real forge's server-side exact-head binding: a merge bound
          # to any head other than the PR's current head is refused.
          unless document.dig("head", "sha") == head_commit_id
            return Result.new(outcome: :refused, status: 409,
              reason: "HTTP 409: head_commit_id does not match the pull request head")
          end
          document = document.merge("merged" => true,
            "merge_commit_sha" => document.dig("head", "sha"))
          @prs[index] = document
          Result.new(outcome: :invoked, status: 200, reason: nil)
        end

        def create_comment(owner:, repo:, index:, body:)
          @comments << {owner: owner, repo: repo, index: index, body: body}
          return @comment_outcome if @comment_outcome
          Result.new(outcome: :invoked, status: 201, reason: nil)
        end

        def merged?(index)
          @prs.dig(index, "merged") == true
        end

        def merge_invoked?
          @merge_count.positive?
        end

        private

        def deep_copy(value)
          JSON.parse(JSON.generate(value))
        end
      end

      def open_pr
        {"merged" => false, "merge_commit_sha" => nil,
         "head" => {"sha" => @candidate_head}, "base" => {"sha" => @base_head}}
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
          "configuration_sha256" => Molecules::ServicePolicy.configuration_digest(policy_document)
        }
      end

      def submission_with_document(document, request_id: "request-1", authorization: "decision-1",
        digest: nil)
        submission.merge("request" => deep_copy(document),
          "request_id" => request_id,
          "authorization" => authorization,
          "input_digest" => digest || expected_digest(document: document,
            request_id: request_id, authorization: authorization))
      end

      # A submission whose configuration digest matches the given policy
      # document (the receiver re-derives the same digest from its own copy).
      def submission_for(policy_document, request_id: "request-1")
        submission.merge("configuration_sha256" =>
          Molecules::ServicePolicy.configuration_digest(policy_document), "request_id" => request_id)
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

      def policy_path
        File.join(@dir, "authorization.yml")
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
