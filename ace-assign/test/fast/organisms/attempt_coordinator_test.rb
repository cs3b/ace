# frozen_string_literal: true

require_relative "../../test_helper"
require "json"
require "open3"
require "fileutils"
require "digest"

module Ace
  module Assign
    class AttemptCoordinatorTest < AceAssignTestCase
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
        @identity = Molecules::ExecutionIdentityResolver::Identity.new(
          actor: "mc", role: "coordinator", runtime: "local:test", adapter: "local"
        )
        @worker = Molecules::ExecutionIdentityResolver::Identity.new(
          actor: "fork-1", role: "worker", runtime: "fork:1", adapter: "service"
        )
      end

      def build_coordinator
        Organisms::AttemptCoordinator.new(
          cache_base: @cache_dir,
          repo_root: @repo,
          journal: Molecules::EvidenceJournal.new(
            repo_root: @repo,
            ref: "refs/ace/execution",
            checkout_root: File.join(@cache_dir, "evidence-co")
          ),
          identity_resolver: stub_resolver,
          lifecycle_exclusion: Molecules::LifecycleExclusion.new(root: File.join(@cache_dir, ".exclusion"))
        )
      end

      def stub_resolver
        resolver = Molecules::ExecutionIdentityResolver.new(adapter: "local")
        resolver.define_singleton_method(:resolve) { @fixed_identity }
        resolver.define_singleton_method(:fixed_identity=) { |value| @fixed_identity = value }
        resolver.fixed_identity = @identity
        resolver
      end

      def create_assignment(managed: true)
        manager = Molecules::AssignmentManager.new(cache_base: @cache_dir)
        manager.create(
          name: "coordinator-test",
          source_config: "job.yaml",
          task_id: managed ? "8wr.t.qjl" : nil,
          project_id: "ace"
        )
      end

      def build_receipt(attempt, overrides = {})
        artifact_path = File.join(@repo, "receipt-artifact.txt")
        File.write(artifact_path, "execution evidence artifact")
        artifact = {
          "path" => "receipt-artifact.txt",
          "sha256" => Digest::SHA256.hexdigest("execution evidence artifact")
        }

        data = {
          "attempt_id" => attempt.attempt_id,
          "assignment_id" => attempt.binding.assignment_id,
          "project_id" => attempt.binding.project_id,
          "scope" => attempt.binding.scope,
          "operation" => "implement",
          "producer" => {"actor" => "fork-1", "role" => "worker", "runtime" => "fork:1"},
          "head" => git(@repo, "rev-parse", "HEAD").strip,
          "verdict" => "succeeded",
          "artifacts" => [artifact],
          "checks" => [{"name" => "ace-test", "verdict" => "passed"}]
        }.merge(overrides)
        path = File.join(@cache_dir, "receipt-#{attempt.attempt_id}-#{rand(10_000)}.json")
        File.write(path, JSON.generate(data))
        path
      end

      def git(dir, *argv)
        out, stderr, status = Open3.capture3("git", *argv, chdir: dir, stdin_data: "")
        flunk "git #{argv.join(' ')} failed: #{stderr}" unless status.success?
        out
      end

      # The stubbed resolver owns identity resolution (trusted coordinator);
      # this documents the acting identity context in each scenario.
      def with_identity(_identity)
        yield
      end

      def test_start_binds_immutable_facts_and_journals_managed_start
        coordinator = build_coordinator
        assignment = create_assignment

        attempt = with_identity(@identity) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        end

        assert_equal "running", attempt.state
        assert_equal "010", attempt.binding.scope
        assert_equal "ace", attempt.binding.project_id
        assert_equal "8wr.t.qjl", attempt.binding.task_id
        assert_equal git(@repo, "rev-parse", "HEAD").strip, attempt.binding.base_head
        assert_equal "refs/ace/execution", attempt.binding.evidence_git_ref
        refute_nil attempt.journal_commit

        events = coordinator.store.list(assignment.id)
        assert_equal 1, events.size

        # Mutable base_head captured once; candidate/journal tracked separately
        assert_nil attempt.candidate_head
      end

      def test_repeated_identical_start_returns_same_attempt
        coordinator = build_coordinator
        assignment = create_assignment

        first = with_identity(@identity) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        end
        second = with_identity(@identity) do
          coordinator.start(assignment_id: assignment.id, step: " 010 ", project_id: "ace")
        end

        assert_equal first.attempt_id, second.attempt_id
      end

      def test_repeated_start_from_different_actor_conflicts
        coordinator = build_coordinator
        assignment = create_assignment

        coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        other = Molecules::ExecutionIdentityResolver::Identity.new(
          actor: "someone-else", role: "coordinator", runtime: "local:elsewhere", adapter: "local"
        )
        error = assert_raises(AttemptErrors::Conflict) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace", identity: other)
        end
        assert_includes error.message, "already owns"
      end

      def test_reconcile_validates_journal_state_before_resolving
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: build_receipt(attempt))

        # Crash window: local record regressed to uncertain after the journal
        # already accepted the succeeded receipt.
        coordinator.store.save(Models::Attempt.new(binding: attempt.binding, state: "uncertain"))

        error = assert_raises(AttemptErrors::InvalidState) do
          coordinator.reconcile(attempt_id: attempt.attempt_id)
        end
        assert_includes error.message, "Journal shows"
      end

      def test_managed_reconcile_chains_resolution_and_receipt_in_one_commit
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        transition = Models::EvidenceEvent.build(
          type: "transition",
          attempt_id: attempt.attempt_id,
          payload: {"from" => "running", "to" => "uncertain", "reason" => "interrupted"}
        )
        journal = Molecules::EvidenceJournal.new(
          repo_root: @repo, ref: "refs/ace/execution", checkout_root: File.join(@cache_dir, "evidence-co")
        )
        journal.append(assignment_id: assignment.id, attempt_id: attempt.attempt_id, events: [transition])

        receipt = build_receipt(attempt, "producer" => {"actor" => "mc", "role" => "coordinator", "runtime" => "local:test"})
        reconciled = coordinator.reconcile(attempt_id: attempt.attempt_id, receipt_path: receipt)
        assert_equal "succeeded", reconciled.state

        events = journal.read_events(assignment.id)
        types = events.map { |event| event["type"] }
        reconciliation_index = types.index("reconciliation")
        refute_nil reconciliation_index
        assert_equal "receipt_accepted", types[reconciliation_index + 1]
        assert_equal events[reconciliation_index]["digest"], events[reconciliation_index + 1]["previous_digest"]
      end

      def test_reconcile_recovers_from_journal_after_full_cache_loss
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        # Entire assignment cache entry vanishes; only the journal remains.
        FileUtils.rm_rf(File.join(@cache_dir, assignment.id))

        error = assert_raises(AttemptErrors::InvalidState) do
          coordinator.reconcile(attempt_id: attempt.attempt_id)
        end
        # The journal-recorded process (this test process) is live, so
        # recovery succeeds and classification refuses — not NotFound.
        assert_includes error.message, "live"
      end

      def test_lost_ownership_race_records_stopped_and_conflicts
        coordinator = build_coordinator
        assignment = create_assignment
        ours = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        rival = Molecules::ExecutionIdentityResolver::Identity.new(
          actor: "rival", role: "service", runtime: "herdr:rival", adapter: "service"
        )
        rival_binding = Models::AttemptBinding.new(
          attempt_id: "atrival9", assignment_id: assignment.id, scope: "010.01", project_id: "ace",
          actor: rival.actor, role: rival.role, runtime: rival.runtime, base_head: ours.binding.base_head,
          task_id: "8wr.t.qjl", created_at: Time.now.utc
        )
        rival_intent = Models::EvidenceEvent.build(type: "intent", attempt_id: "atrival9", payload: {
          "assignment_id" => assignment.id, "scope" => "010.01", "project_id" => "ace",
          "task_id" => "8wr.t.qjl", "base_head" => ours.binding.base_head
        })
        @journal = Molecules::EvidenceJournal.new(
          repo_root: @repo, ref: "refs/ace/execution", checkout_root: File.join(@cache_dir, "evidence-co")
        )
        @journal.append(assignment_id: assignment.id, attempt_id: "atrival9", events: [rival_intent])

        error = assert_raises(AttemptErrors::Conflict) do
          coordinator.send(:yield_lost_ownership_race, ours, assignment.id, "010")
        end
        assert_includes error.message, "recorded stopped without executing"

        journal_state = @journal.derived_attempts(assignment.id).find { |a| a.attempt_id == ours.attempt_id }
        assert_equal "stopped", journal_state.state
      end

      def test_conflicting_start_cannot_launch_second_writer
        coordinator = build_coordinator
        assignment = create_assignment

        with_identity(@identity) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        end

        error = assert_raises(AttemptErrors::Conflict) do
          with_identity(@identity) do
            coordinator.start(assignment_id: assignment.id, step: "010", project_id: "other-project")
          end
        end
        assert_equal 5, error.exit_code
      end

      def test_taskless_attempt_stays_local_only
        coordinator = build_coordinator
        assignment = create_assignment(managed: false)

        attempt = with_identity(@identity) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        end

        assert_equal "local_only", attempt.recovery_mode
        assert_nil attempt.journal_commit
        assert_equal 2, attempt.events.size
        assert_equal %w[intent process_start], attempt.events.map { |event| event["type"] }
      end

      def test_accepted_receipt_pins_candidate_and_never_moves_candidate_head
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = with_identity(@identity) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        end
        candidate_before = git(@repo, "rev-parse", "HEAD").strip

        finished = coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: build_receipt(attempt))

        assert_equal "succeeded", finished.state
        assert_equal candidate_before, finished.candidate_head
        assert_equal candidate_before, git(@repo, "rev-parse", "HEAD").strip
        assert_nil coordinator.store.active(assignment.id, "010")

        journal = Molecules::EvidenceJournal.new(
          repo_root: @repo, ref: "refs/ace/execution", checkout_root: File.join(@cache_dir, "evidence-co")
        )
        receipts = journal.accepted_receipts(assignment.id)
        assert_equal 1, receipts.size
        assert_equal "succeeded", receipts.first["verdict"]
      end

      def test_changed_candidate_sha_is_rejected_even_for_task_only_edits
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = with_identity(@identity) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        end
        stale_head = git(@repo, "rev-parse", "HEAD").strip

        File.write(File.join(@repo, "notes.md"), "task-only edit\n")
        git(@repo, "add", "notes.md")
        git(@repo, "commit", "-m", "move candidate")

        error = assert_raises(AttemptErrors::ReceiptRejected) do
          coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: build_receipt(attempt, "head" => stale_head))
        end
        assert_includes error.message, "stale"
      end

      def test_worker_identity_cannot_accept_succeeded_finish
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = with_identity(@worker) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        end

        error = assert_raises(AttemptErrors::ReceiptRejected) do
          coordinator.finish(
            attempt_id: attempt.attempt_id,
            receipt_path: build_receipt(attempt),
            identity: @worker
          )
        end
        assert_includes error.message, "may not accept"
      end

      def test_terminal_attempt_accepts_no_new_effects
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = with_identity(@identity) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        end
        coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: build_receipt(attempt))

        error = assert_raises(AttemptErrors::InvalidState) do
          coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: build_receipt(attempt))
        end
        assert_includes error.message, "immutable"
      end

      def test_taskless_attempts_block_external_effects
        coordinator = build_coordinator
        assignment = create_assignment(managed: false)
        attempt = with_identity(@identity) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        end

        error = assert_raises(AttemptErrors::InvalidState) do
          coordinator.finish(
            attempt_id: attempt.attempt_id,
            receipt_path: build_receipt(attempt, "operation" => "merge")
          )
        end
        assert_includes error.message, "Taskless"
      end

      def test_merge_requires_executed_independent_review_for_current_head
        coordinator = build_coordinator
        assignment = create_assignment

        review_attempt = with_identity(@identity) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        end
        head = git(@repo, "rev-parse", "HEAD").strip
        review_receipt = build_receipt(
          review_attempt,
          "operation" => "review",
          "review" => {"reviewer" => {"actor" => "codex", "runtime" => "codex:r1"}, "verdict" => "approved", "head" => head}
        )
        coordinator.finish(attempt_id: review_attempt.attempt_id, receipt_path: review_receipt)

        merge_attempt = with_identity(@identity) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        end

        error = assert_raises(AttemptErrors::ReceiptRejected) do
          coordinator.finish(
            attempt_id: merge_attempt.attempt_id,
            receipt_path: build_receipt(merge_attempt, "operation" => "merge", "head" => "0" * 40)
          )
        end

        assert_includes error.message, "stale"
        merge_receipt = build_receipt(merge_attempt, "operation" => "merge")
        merged = coordinator.finish(attempt_id: merge_attempt.attempt_id, receipt_path: merge_receipt)
        assert_equal "succeeded", merged.state
      end

      def test_status_projects_attempt_fields
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = with_identity(@identity) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        end

        projection = coordinator.status(assignment.id)

        assert_equal attempt.attempt_id, projection["attempt_id"]
        assert_equal "running", projection["state"]
        assert_equal "010", projection["scope"]
        assert projection["base_head"]
        assert_equal "refs/ace/execution", projection["evidence_git_ref"]
        assert projection["journal_commit"]
        assert_nil projection["candidate_head"]
      end

      def test_reconcile_running_attempt_without_process_start_becomes_stopped
        coordinator = build_coordinator
        assignment = create_assignment(managed: false)
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        intent_only = [Models::EvidenceEvent.build(
          type: "intent", attempt_id: attempt.attempt_id, payload: {"scope" => "010"}
        )]
        rewrite_events(coordinator, attempt, intent_only)

        reconciled = coordinator.reconcile(attempt_id: attempt.attempt_id)

        assert_equal "stopped", reconciled.state
        assert_nil coordinator.store.active(assignment.id, "010")
      end

      def test_reconcile_running_attempt_with_dead_process_becomes_uncertain
        coordinator = build_coordinator
        assignment = create_assignment(managed: false)
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        dead = Process.spawn("true")
        Process.wait(dead)
        events = [
          Models::EvidenceEvent.build(type: "intent", attempt_id: attempt.attempt_id, payload: {"scope" => "010"}),
          Models::EvidenceEvent.build(
            type: "process_start",
            attempt_id: attempt.attempt_id,
            payload: {"runtime" => "local:test", "pid" => dead},
            previous_digest: nil
          )
        ]
        rewrite_events(coordinator, attempt, events)

        reconciled = coordinator.reconcile(attempt_id: attempt.attempt_id)

        assert_equal "uncertain", reconciled.state
        refute_nil coordinator.store.active(assignment.id, "010")
      end

      def test_reconcile_refuses_verifiably_live_process
        coordinator = build_coordinator
        assignment = create_assignment(managed: false)
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        child = Process.spawn("sleep", "10")
        begin
          events = [
            Models::EvidenceEvent.build(type: "intent", attempt_id: attempt.attempt_id, payload: {"scope" => "010"}),
            Models::EvidenceEvent.build(
              type: "process_start",
              attempt_id: attempt.attempt_id,
              payload: {"runtime" => "local:test", "pid" => child}
            )
          ]
          rewrite_events(coordinator, attempt, events)

          error = assert_raises(AttemptErrors::InvalidState) do
            coordinator.reconcile(attempt_id: attempt.attempt_id)
          end
          assert_includes error.message, "live"
        ensure
          Process.kill("TERM", child)
          Process.wait(child)
        end
      end

      def test_reconcile_uncertain_without_receipt_never_resolves
        coordinator = build_coordinator
        assignment = create_assignment(managed: false)
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        force_state(coordinator, attempt, "uncertain")

        error = assert_raises(AttemptErrors::InvalidState) do
          coordinator.reconcile(attempt_id: attempt.attempt_id)
        end
        assert_includes error.message, "receipt"

        assert_equal "uncertain", coordinator.store.find(attempt.attempt_id).state
      end

      def test_reconcile_uncertain_resolves_with_boundary_attributed_receipt
        coordinator = build_coordinator
        assignment = create_assignment(managed: false)
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        force_state(coordinator, attempt, "uncertain")

        receipt = build_receipt(attempt, "producer" => {"actor" => "mc", "role" => "coordinator", "runtime" => "local:test"})
        reconciled = coordinator.reconcile(attempt_id: attempt.attempt_id, receipt_path: receipt)

        assert_equal "succeeded", reconciled.state
        assert coordinator.store.find(attempt.attempt_id).terminal?
        assert_nil coordinator.store.active(assignment.id, "010")
      end

      def test_reconcile_rejects_receipt_from_unrecorded_boundary
        coordinator = build_coordinator
        assignment = create_assignment(managed: false)
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        force_state(coordinator, attempt, "uncertain")

        receipt = build_receipt(attempt, "producer" => {"actor" => "someone-else", "role" => "worker", "runtime" => "fork:9"})

        error = assert_raises(AttemptErrors::ReceiptRejected) do
          coordinator.reconcile(attempt_id: attempt.attempt_id, receipt_path: receipt)
        end
        assert_includes error.message, "execution boundary"
      end

      def test_reconcile_refuses_terminal_attempts
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: build_receipt(attempt))

        error = assert_raises(AttemptErrors::InvalidState) do
          coordinator.reconcile(attempt_id: attempt.attempt_id)
        end
        assert_includes error.message, "immutable"
      end

      private

      def rewrite_events(coordinator, attempt, events)
        rewritten = Models::Attempt.new(
          binding: attempt.binding,
          state: attempt.state,
          events: events
        )
        coordinator.store.save(rewritten)
        rewritten
      end

      def force_state(coordinator, attempt, state)
        forced = Models::Attempt.new(
          binding: attempt.binding,
          state: state,
          journal_commit: attempt.journal_commit,
          events: attempt.events
        )
        coordinator.store.save(forced)
        forced
      end

      public

      def test_attempt_ids_are_unique_under_clock_resolution_collisions
        coordinator = build_coordinator
        assignment = create_assignment

        Ace::B36ts.stub(:now, -> { "atsame1" }) do
          first = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
          second = coordinator.start(assignment_id: assignment.id, step: "020", project_id: "ace")

          refute_equal first.attempt_id, second.attempt_id
          assert coordinator.store.load(assignment.id, first.attempt_id)
          assert coordinator.store.load(assignment.id, second.attempt_id)
        end
      end

      def test_concurrent_finishes_cannot_persist_contradictory_terminal_outcomes
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        succeeded_receipt = build_receipt(attempt)
        failed_receipt = build_receipt(attempt, "verdict" => "failed")

        errors = []
        threads = [succeeded_receipt, failed_receipt].map do |receipt|
          Thread.new do
            coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: receipt)
          rescue Ace::Assign::Error => e
            errors << e
          end
        end
        threads.each(&:join)

        final = coordinator.store.load(assignment.id, attempt.attempt_id)
        assert final.terminal?
        assert_equal 1, final.accepted_receipts.size
        assert_equal 1, errors.size
      end

      def test_managed_start_recovers_active_attempt_from_journal_after_local_loss
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        # Simulate a wiped local cache while the journal survives.
        FileUtils.rm_rf(File.join(@cache_dir, assignment.id, "attempts"))

        recovered = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        assert_equal attempt.attempt_id, recovered.attempt_id
        assert_equal "running", recovered.state
        assert_equal "010", recovered.binding.scope
        assert_equal "ace", recovered.binding.project_id
        refute_nil recovered.journal_commit
      end

      def test_journal_backed_attempt_blocks_conflicting_writer_after_local_loss
        coordinator = build_coordinator
        assignment = create_assignment
        coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        FileUtils.rm_rf(File.join(@cache_dir, assignment.id, "attempts"))

        error = assert_raises(AttemptErrors::Conflict) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "other-project")
        end
        assert_includes error.message, "already owns"
      end

      def test_finish_consults_journal_state_before_accepting
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: build_receipt(attempt))

        # Simulate a crash after the journaled receipt but before the local save.
        rolled_back = Models::Attempt.new(binding: attempt.binding, state: "running")
        coordinator.store.save(rolled_back)

        contradictory = build_receipt(attempt, "verdict" => "failed")
        error = assert_raises(AttemptErrors::InvalidState) do
          coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: contradictory)
        end
        assert_includes error.message, "Journal shows"
      end

      def test_reconcile_recovers_journal_only_attempts_by_id
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        FileUtils.rm_rf(File.join(@cache_dir, assignment.id, "attempts"))

        # The journal-recorded process (this test process) is still live, so
        # recovery succeeds and classification refuses — not NotFound.
        error = assert_raises(AttemptErrors::InvalidState) do
          coordinator.reconcile(attempt_id: attempt.attempt_id)
        end
        assert_includes error.message, "live"
      end

      def test_overlapping_subtree_scopes_cannot_create_competing_writers
        coordinator = build_coordinator
        assignment = create_assignment

        coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        %w[010.01 010.01.02].each do |overlapping|
          error = assert_raises(AttemptErrors::Conflict) do
            coordinator.start(assignment_id: assignment.id, step: overlapping, project_id: "ace")
          end
          assert_includes error.message, "overlaps"
        end
      end

      def test_ancestor_scope_cannot_start_under_active_descendant_owner
        coordinator = build_coordinator
        assignment = create_assignment

        coordinator.start(assignment_id: assignment.id, step: "010.01", project_id: "ace")

        error = assert_raises(AttemptErrors::Conflict) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        end
        assert_includes error.message, "overlaps"
      end

      class RecordingExclusion < Molecules::LifecycleExclusion
        attr_reader :shared_multi_keys

        def initialize(root:)
          super(root: root)
          @shared_multi_keys = []
        end

        def with_shared_multi(keys, **options)
          @shared_multi_keys << keys
          super
        end
      end

      def test_start_shares_task_then_assignment_keys
        assignment = create_assignment # managed: carries task_id 8wr.t.qjl
        exclusion = RecordingExclusion.new(root: File.join(@cache_dir, ".exclusion"))
        coordinator = Organisms::AttemptCoordinator.new(
          cache_base: @cache_dir,
          repo_root: @repo,
          journal: Molecules::EvidenceJournal.new(
            repo_root: @repo,
            ref: "refs/ace/execution",
            checkout_root: File.join(@cache_dir, "evidence-co")
          ),
          identity_resolver: stub_resolver,
          lifecycle_exclusion: exclusion
        )

        coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        keys = exclusion.shared_multi_keys.first
        assert_equal [exclusion.task_key("8wr.t.qjl"), exclusion.assignment_key(assignment.id)], keys
      end

      def test_start_refuses_after_prune_recorded_removal
        coordinator = build_coordinator
        assignment = create_assignment

        exclusion = Molecules::LifecycleExclusion.new(root: File.join(@cache_dir, ".exclusion"))
        exclusion.record_removed!(exclusion.assignment_key(assignment.id))

        error = assert_raises(AttemptErrors::Conflict) do
          coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        end
        assert_includes error.message, "was pruned"
      end
    end
  end
end
