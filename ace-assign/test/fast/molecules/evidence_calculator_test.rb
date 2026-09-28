# frozen_string_literal: true

require_relative "../../test_helper"
require "json"
require "open3"
require "fileutils"
require "digest"

module Ace
  module Assign
    class EvidenceCalculatorTest < AceAssignTestCase
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
        @journal = Molecules::EvidenceJournal.new(
          repo_root: @repo,
          ref: "refs/ace/execution",
          checkout_root: File.join(@cache_dir, "evidence-co")
        )
        @identity = Molecules::ExecutionIdentityResolver::Identity.new(
          actor: "mc", role: "coordinator", runtime: "local:test", adapter: "local"
        )
      end

      def git(dir, *argv)
        out, stderr, status = Open3.capture3("git", *argv, chdir: dir, stdin_data: "")
        flunk "git #{argv.join(' ')} failed: #{stderr}" unless status.success?
        out.strip
      end

      def build_coordinator
        resolver = Molecules::ExecutionIdentityResolver.new(adapter: "local")
        resolver.define_singleton_method(:resolve) { @fixed }
        resolver.define_singleton_method(:fixed=) { |value| @fixed = value }
        resolver.fixed = @identity

        Organisms::AttemptCoordinator.new(
          cache_base: @cache_dir,
          repo_root: @repo,
          journal: @journal,
          identity_resolver: resolver
        )
      end

      def create_assignment(managed: true)
        Molecules::AssignmentManager.new(cache_base: @cache_dir).create(
          name: "evidence-test",
          source_config: "job.yaml",
          task_id: managed ? "8wr.t.qjl" : nil,
          project_id: "ace"
        )
      end

      def accept_receipt(coordinator, attempt, operation, head: nil, reviewer: nil)
        artifact_path = File.join(@repo, "artifact-#{attempt.attempt_id}.txt")
        File.write(artifact_path, "evidence #{operation}")
        receipt = {
          "attempt_id" => attempt.attempt_id,
          "assignment_id" => attempt.binding.assignment_id,
          "project_id" => attempt.binding.project_id,
          "scope" => attempt.binding.scope,
          "operation" => operation,
          "producer" => {"actor" => "fork-1", "role" => "worker", "runtime" => "fork:1"},
          "head" => head || git(@repo, "rev-parse", "HEAD"),
          "verdict" => "succeeded",
          "artifacts" => [{
            "path" => "artifact-#{attempt.attempt_id}.txt",
            "sha256" => Digest::SHA256.hexdigest("evidence #{operation}")
          }],
          "checks" => [{"name" => "ace-test", "verdict" => "passed"}]
        }
        if reviewer
          receipt["review"] = {
            "reviewer" => {"actor" => reviewer, "runtime" => "reviewer:r1"},
            "verdict" => "approved",
            "head" => receipt["head"]
          }
        end
        path = File.join(@cache_dir, "receipt-#{attempt.attempt_id}.json")
        File.write(path, JSON.generate(receipt))
        coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: path)
      end

      def calculate(auto_merge: false)
        calculator = Molecules::EvidenceCalculator.new(
          cache_base: @cache_dir, repo_root: @repo, journal: @journal
        )
        calculator.calculate(auto_merge: auto_merge)
      end

      def test_calculate_without_assignment_reports_missing_evidence
        evidence = calculate(auto_merge: true)

        assert evidence[:head]
        assert evidence[:tree]
        assert evidence[:changed_scope_digest]
        assert_equal "missing", evidence[:review_receipt]
        assert_equal "missing", evidence[:release_receipt]
        assert_equal "unknown", evidence[:feedback_state]
        assert_equal "approval-required", evidence[:merge_decision]
        assert_nil evidence[:attempt]
        assert_nil evidence[:evidence_git_ref]
        assert evidence[:decision_digest]
      end

      def test_accepted_current_head_review_authorizes_auto_merge
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        accept_receipt(coordinator, attempt, "review", reviewer: "codex")

        evidence = calculate(auto_merge: true)

        assert_equal "current", evidence[:review_receipt]
        assert_equal "terminal", evidence[:feedback_state]
        assert_equal "authorized", evidence[:merge_decision]
        assert_empty evidence[:unresolved_effects]
        assert_equal "refs/ace/execution", evidence[:evidence_git_ref]
        assert evidence[:journal_commit]
        assert_equal attempt.binding.base_head, evidence[:base_head]
        refute_nil evidence[:candidate_head]
      end

      def test_review_evidence_for_stale_head_never_authorizes
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        accept_receipt(coordinator, attempt, "review", reviewer: "codex")

        File.write(File.join(@repo, "extra.md"), "candidate moved\n")
        git(@repo, "add", "extra.md")
        git(@repo, "commit", "-m", "move candidate")

        evidence = calculate(auto_merge: true)

        assert_equal "stale", evidence[:review_receipt]
        assert_equal "open", evidence[:feedback_state]
        assert_equal "approval-required", evidence[:merge_decision]
      end

      def test_uncertain_attempt_blocks_authorization_and_signals_uncertainty
        coordinator = build_coordinator
        assignment = create_assignment
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")

        uncertain = Models::Attempt.new(
          binding: attempt.binding,
          state: "uncertain",
          candidate_head: attempt.candidate_head,
          journal_commit: attempt.journal_commit,
          effects: [{"operation" => "merge", "intent_recorded_at" => Time.now.utc.iso8601}]
        )
        coordinator.store.save(uncertain)

        evidence = calculate(auto_merge: true)

        assert_equal "uncertain", evidence[:feedback_state]
        assert_equal "approval-required", evidence[:merge_decision]
        assert_includes evidence[:unresolved_effects], "merge"
        assert_equal "uncertain", evidence[:attempt]["state"]
      end

      def test_taskless_receipts_count_from_local_attempt_records
        coordinator = build_coordinator
        assignment = create_assignment(managed: false)
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
        accept_receipt(coordinator, attempt, "implement")

        evidence = calculate(auto_merge: true)

        assert_equal "terminal", evidence[:feedback_state]
        assert_nil evidence[:evidence_git_ref]
        refute_nil evidence[:candidate_head]
        # Taskless attempts never claim Git-backed recovery
        assert_equal "local_only", evidence[:attempt]["recovery_mode"]
      end

      def test_merge_decision_is_never_report_only
        evidence = calculate(auto_merge: false)

        assert_includes %w[authorized approval-required], evidence[:merge_decision]
        refute_includes evidence.keys, :feedback_state_hardcoded
        assert_includes %w[terminal open uncertain unknown], evidence[:feedback_state]
      end
    end
  end
end
