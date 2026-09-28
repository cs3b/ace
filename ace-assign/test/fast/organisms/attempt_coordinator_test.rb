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
          identity_resolver: stub_resolver
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
        assert_includes error.message, "terminal"
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
    end
  end
end
