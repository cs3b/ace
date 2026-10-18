# frozen_string_literal: true

require_relative "../test_helper"
require "ace/task/organisms/task_manager"

module Ace
  module Coworker
    module Organisms
      class PrepareOrchestratorTest < AceCoworkerTestCase
        FakeTaskProbe = Struct.new(:task) do
          def resolve(_ref)
            task
          end
        end

        FakeProvisionProbe = Struct.new(:decision) do
          def ensure_prepared(task_ref:, expected_task_id:, dry_run:)
            decision.merge(_task_ref: task_ref, _expected: expected_task_id, _dry_run: dry_run)
          end
        end

        FakeExecutorProbe = Struct.new(:probe_result) do
          attr_reader :probed_path

          def probe(worktree_path)
            @probed_path = worktree_path
            probe_result
          end
        end

        FakeHitl = Struct.new(:events, :sent) do
          attr_accessor :create_calls

          def initialize
            super([], [])
            @create_calls = []
          end

          def create_conflict(title:, question_lines:, task:, to:)
            create_calls << {title: title, question_lines: question_lines, task: task, to: to}
            event = "hitl01"
            events << event
            event
          end

          def send_report(event_id)
            sent << event_id
            true
          end
        end

        FakeConfigLoader = Struct.new(:config) do
          def load(path: nil)
            raise Error, "not ready: no config" if config.nil?

            config
          end
        end

        def task_model
          Ace::Task::Models::Task.new(id: "8xg.t.aaa", title: "Fixture", status: "pending",
            path: "/proj/.ace-tasks/8xg.t.aaa-fixture")
        end

        def orchestrator(provision_decision:, executor_result: {config: nil, assignments: []},
          hitl: FakeHitl.new, config: nil, task: task_model
        )
          PrepareOrchestrator.new(
            project_root: "/proj",
            task_probe: FakeTaskProbe.new(task),
            provision_probe: FakeProvisionProbe.new(provision_decision),
            executor_probe: FakeExecutorProbe.new(executor_result),
            hitl_reporter: hitl,
            config_loader: FakeConfigLoader.new(config))
        end

        def created_decision
          {disposition: :created, reason: "created", worktree_path: "/proj/.ace-wt/t.8xg-t-aaa",
           branch: "8xg-aaa-branch"}
        end

        def test_happy_create_returns_preparation
          result = orchestrator(provision_decision: created_decision)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker reviewer], to: "overseer@lab")

          assert_equal "created", result.worktree["disposition"]
          assert_equal "/proj/.ace-wt/t.8xg-t-aaa", result.worktree["path"]
          assert_equal %w[worker reviewer], result.roles
          assert_equal "8xg.t.aaa", result.task
          assert_equal "/proj/.ace-tasks/8xg.t.aaa-fixture", result.task_path
          refute result.conflict?
        end

        def test_reuse_performs_no_writes_and_no_escalation
          hitl = FakeHitl.new
          reuse = created_decision.merge(disposition: :reuse)
          executor = {config: nil,
            assignments: [{"id" => "a1", "name" => "w", "state" => "paused", "progress" => "0/2"}]}
          result = orchestrator(provision_decision: reuse, executor_result: executor, hitl: hitl)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker])

          assert_equal "reused", result.worktree["disposition"]
          assert_empty hitl.create_calls
          assert_equal "/proj/.ace-wt/t.8xg-t-aaa", result.worktree["path"]
          assert_equal "paused", result.worktree_assignments.first["state"]
        end

        def test_active_executor_conflict_escalates_once_and_preserves_worktree
          hitl = FakeHitl.new
          executor = {config: {"assignment" => "abc123"},
            assignments: [{"id" => "abc123", "name" => "w", "state" => "running", "progress" => "1/2"}]}
          result = orchestrator(provision_decision: created_decision.merge(disposition: :reuse),
            executor_result: executor, hitl: hitl)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker], to: "overseer@lab")

          assert result.conflict?
          assert_equal "active_executor", result.conflict["kind"]
          assert_includes result.conflict["detail"], "abc123"
          assert_includes result.conflict["detail"], "running"
          assert_equal "hitl01", result.conflict["hitl_event"]
          assert_equal ["hitl01"], hitl.sent
          assert_equal 1, hitl.create_calls.length
          assert_equal "8xg.t.aaa/t.8xg-t-aaa", hitl.create_calls.first[:title].split(" - ", 2).last
          assert_nil result.worktree
        end

        def test_mismatched_worktree_conflict_escalates
          hitl = FakeHitl.new
          result = orchestrator(
            provision_decision: {disposition: :conflict_mismatch,
              reason: "resolved worktree belongs to task '8xg.t.bbb'",
              worktree_path: "/proj/.ace-wt/t.8xg-t-aaa"},
            hitl: hitl
          ).call(task_ref: "8xg.t.aaa", roles: %w[worker], to: "overseer@lab")

          assert_equal "mismatched_worktree", result.conflict["kind"]
          assert_equal "hitl01", result.conflict["hitl_event"]
          assert_equal 1, hitl.create_calls.length
        end

        def test_conflict_without_recipient_degrades_with_explicit_note
          hitl = FakeHitl.new
          result = orchestrator(
            provision_decision: {disposition: :conflict_mismatch, reason: "foreign", worktree_path: "/w"},
            hitl: hitl, config: nil
          ).call(task_ref: "8xg.t.aaa", roles: %w[worker])

          assert result.conflict?
          assert_nil result.conflict["hitl_event"]
          assert_includes result.conflict["detail"], "no overseer address"
          assert_empty hitl.create_calls
        end

        def test_recipient_falls_back_to_config_overseer
          hitl = FakeHitl.new
          config = Models::Config.new(role: "planner", instructions: "roles/planner.md",
            start_prompt: "go", task: "8xg.t.zzz", assignment: "z", overseer: "cfg-overseer",
            source_path: nil)
          orchestrator(
            provision_decision: {disposition: :conflict_mismatch, reason: "foreign", worktree_path: "/w"},
            hitl: hitl, config: config
          ).call(task_ref: "8xg.t.aaa", roles: %w[worker])

          assert_equal "cfg-overseer", hitl.create_calls.first[:to]
        end

        def test_dry_run_resolves_but_creates_no_events
          hitl = FakeHitl.new
          result = orchestrator(provision_decision: created_decision.merge(disposition: :would_create),
            hitl: hitl)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker], to: "overseer@lab", dry_run: true)

          assert_equal "would_create", result.worktree["disposition"]
          assert result.dry_run
          assert_empty hitl.create_calls
        end

        def test_dry_run_conflict_reports_without_escalation
          hitl = FakeHitl.new
          result = orchestrator(
            provision_decision: {disposition: :conflict_mismatch, reason: "foreign", worktree_path: "/w"},
            hitl: hitl
          ).call(task_ref: "8xg.t.aaa", roles: %w[worker], to: "overseer@lab", dry_run: true)

          assert_equal "mismatched_worktree", result.conflict["kind"]
          assert_nil result.conflict["hitl_event"]
          assert_empty hitl.create_calls
        end

        def test_missing_task_raises_specific_error
          error = assert_raises(Error) do
            orchestrator(provision_decision: created_decision, task: nil)
              .call(task_ref: "8xg.t.nope", roles: %w[worker])
          end

          assert_equal "task '8xg.t.nope' not found in this worktree", error.message
        end

        def test_operational_provision_error_raises_with_reason
          error = assert_raises(Error) do
            orchestrator(provision_decision: {disposition: :error, reason: "boom", worktree_path: nil})
              .call(task_ref: "8xg.t.aaa", roles: %w[worker])
          end

          assert_includes error.message, "boom"
          assert_includes error.message, "cannot prepare worktree"
        end
      end
    end
  end
end
