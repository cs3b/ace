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
          attr_accessor :create_calls, :report_calls, :report_result

          def initialize
            super([], [])
            @create_calls = []
            @report_calls = []
            @report_result = "rpt001"
          end

          def create_conflict(title:, question_lines:, task:, to:)
            create_calls << {title: title, question_lines: question_lines, task: task, to: to}
            event = "hitl01"
            events << event
            event
          end

          def create_report(title:, body_lines:, task:, result:, to:)
            report_calls << {title: title, body_lines: body_lines, task: task,
              result: result, to: to}
            report_result
          end

          def send_report(event_id)
            sent << event_id
            true
          end
        end

        FakeConfigLoader = Struct.new(:config, :lenient_overseer) do
          def initialize(config, lenient_overseer = nil)
            super(config, lenient_overseer)
          end

          def load(path: nil)
            raise Error, "not ready: no config" if config.nil?

            config
          end

          def overseer(path: nil)
            lenient_overseer
          end
        end

        def task_model
          Ace::Task::Models::Task.new(id: "8xg.t.aaa", title: "Fixture", status: "pending",
            path: "/proj/.ace-tasks/8xg.t.aaa-fixture")
        end

        def orchestrator(provision_decision:, executor_result: {config: nil, assignments: []},
          hitl: FakeHitl.new, config: nil, task: task_model, lenient_overseer: nil,
          sequence_composer: nil, start_config_writer: nil
        )
          PrepareOrchestrator.new(
            project_root: "/proj",
            task_probe: FakeTaskProbe.new(task),
            provision_probe: FakeProvisionProbe.new(provision_decision),
            executor_probe: FakeExecutorProbe.new(executor_result),
            hitl_reporter: hitl,
            config_loader: FakeConfigLoader.new(config, lenient_overseer),
            sequence_composer: sequence_composer || FakeSequenceComposer.new,
            start_config_writer: start_config_writer)
        end

        # Never touches the filesystem: records the leg-config write call.
        FakeStartConfigWriter = Struct.new(:calls) do
          def initialize
            super([])
          end

          def call(task:, sequence:, overseer:, dry_run:)
            calls << {task: task, sequence: sequence, overseer: overseer, dry_run: dry_run}
            sequence.map do |entry|
              {"role" => entry["role"], "assignment" => entry["assignment"],
               "path" => ".ace-local/coworker/prepare/#{entry['role']}.yml",
               "disposition" => dry_run ? "planned" : "created"}
            end
          end
        end

        # Never touches the filesystem: success path entries only.
        FakeSequenceComposer = Struct.new(:calls, :error) do
          def initialize(error: nil)
            super([], error)
          end

          def call(task:, roles:)
            calls << {task: task, roles: roles}
            raise Error, error if error

            roles.each_with_index.map do |role, index|
              {"role" => role, "position" => index + 1, "of" => roles.length,
               "assignment" => "seq#{index + 1}", "disposition" => "created",
               "steps" => 1, "outcome" => "#{role} outcome"}
            end
          end
        end

        def created_decision
          {disposition: :created, reason: "created", worktree_path: "/proj/.ace-wt/t.8xg-t-aaa",
           branch: "8xg-aaa-branch"}
        end

        def test_happy_create_returns_preparation
          composer = FakeSequenceComposer.new
          config_writer = FakeStartConfigWriter.new
          hitl = FakeHitl.new
          result = orchestrator(provision_decision: created_decision, sequence_composer: composer,
            start_config_writer: config_writer, hitl: hitl)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker reviewer], to: "overseer@lab")

          assert_equal "created", result.worktree["disposition"]
          assert_equal "/proj/.ace-wt/t.8xg-t-aaa", result.worktree["path"]
          assert_equal %w[worker reviewer], result.roles
          assert_equal "8xg.t.aaa", result.task
          assert_equal "/proj/.ace-tasks/8xg.t.aaa-fixture", result.task_path
          refute result.conflict?
          assert_equal [{task: "8xg.t.aaa", roles: %w[worker reviewer]}], composer.calls
          assert_equal %w[worker reviewer], result.assignments.map { |a| a["role"] }
          assert_equal "created", result.assignments.first["disposition"]

          # L4.3: one start config per leg, written into the worktree
          # with the resolved overseer, reported in the result payload.
          assert_equal [{task: "8xg.t.aaa", sequence: result.assignments,
            overseer: "overseer@lab", dry_run: false}], config_writer.calls
          assert_equal %w[worker reviewer], result.start_configs.map { |c| c["role"] }
          assert_equal "created", result.start_configs.first["disposition"]
          assert_equal ".ace-local/coworker/prepare/worker.yml", result.start_configs.first["path"]
          assert_equal result.start_configs, result.to_h["start_configs"]

          # L4.4: a successful preparation ends with a readiness REPORT
          # to the overseer (no reply expected): what was prepared plus
          # the exact first step, created and delivered via ace-hitl.
          assert_equal 1, hitl.report_calls.length
          call = hitl.report_calls.first
          assert_equal "8xg.t.aaa", call[:task]
          assert_equal "overseer@lab", call[:to]
          assert_equal "success", call[:result]
          assert_includes call[:title], "Preparation ready - 8xg.t.aaa"
          body = call[:body_lines].join("\n")
          assert_includes body, "/proj/.ace-wt/t.8xg-t-aaa"
          assert_includes body, "worker: seq1"
          assert_includes body, "start config worker: .ace-local/coworker/prepare/worker.yml"
          assert_includes body, "first leg: ace-coworker start --config " \
            ".ace-local/coworker/prepare/worker.yml"
          assert_equal({"kind" => "readiness", "event" => "rpt001", "delivered" => true},
            result.report)
          assert_equal result.report, result.to_h["report"]
          assert_equal ["rpt001"], hitl.sent
        end

        def test_start_config_overseer_falls_back_to_config_overseer
          config = Models::Config.new(role: "planner", instructions: "roles/planner.md",
            start_prompt: "go", task: "8xg.t.aaa", assignment: "z", overseer: "cfg-overseer",
            source_path: nil)
          config_writer = FakeStartConfigWriter.new
          orchestrator(provision_decision: created_decision, config: config,
            start_config_writer: config_writer)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker])

          assert_equal "cfg-overseer", config_writer.calls.first[:overseer]
        end

        def test_missing_start_config_overseer_is_a_gap_not_ready
          composer = FakeSequenceComposer.new
          config_writer = FakeStartConfigWriter.new
          hitl = FakeHitl.new
          result = orchestrator(provision_decision: created_decision, sequence_composer: composer,
            start_config_writer: config_writer, hitl: hitl)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker])

          # L4.4: a missing overseer address is a GAP — never reported as
          # a ready commission, and no unprepared coworker is started.
          assert result.conflict?
          assert_equal "missing_overseer", result.conflict["kind"]
          assert result.dry_run == false
          assert_nil result.worktree, "a gap never renders a ready worktree"
          assert_nil result.report, "a gap sends no readiness report"
          assert_equal 1, composer.calls.length,
            "assignments are composed first (their own validation errors win)"
          assert_empty config_writer.calls
          detail = result.conflict["detail"]
          assert_includes detail, "no overseer address for the start configs"
          assert_includes detail, "NOT ready"
          assert_includes detail, "prepared: worktree /proj/.ace-wt/t.8xg-t-aaa"
          assert_includes detail, "prepared: assignment worker -> seq1"
          assert_includes detail, "re-run prepare with --to"
          # The same resolution that failed means no escalation can be
          # delivered either — the gap carries the explicit note instead.
          assert_nil result.conflict["hitl_event"]
          assert_includes detail, "cannot report conflict: no overseer address"
          assert_empty hitl.create_calls
          assert_empty hitl.report_calls
        end

        def test_dry_run_reports_planned_start_configs_without_writes
          config_writer = FakeStartConfigWriter.new
          hitl = FakeHitl.new
          result = orchestrator(provision_decision: created_decision.merge(disposition: :reuse),
            start_config_writer: config_writer, hitl: hitl)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker], to: "overseer@lab", dry_run: true)

          assert_equal ["planned"], result.start_configs.map { |c| c["disposition"] }
          assert_equal [true], config_writer.calls.map { |c| c[:dry_run] }
          assert_nil result.report, "dry-run sends no readiness report"
          assert_empty hitl.report_calls
        end

        def test_sequence_composition_error_is_a_gap_escalated_to_the_overseer
          composer = FakeSequenceComposer.new(error: "role 'planner' has no assignment process")
          hitl = FakeHitl.new
          result = orchestrator(provision_decision: created_decision, sequence_composer: composer,
            hitl: hitl)
            .call(task_ref: "8xg.t.aaa", roles: %w[planner], to: "overseer@lab")

          # L4.4: a role error is a GAP with its reason, escalated as a
          # decision question — never a ready commission.
          assert result.conflict?
          assert_equal "role_sequence", result.conflict["kind"]
          assert_includes result.conflict["detail"], "no assignment process"
          assert_equal "hitl01", result.conflict["hitl_event"]
          assert_equal ["hitl01"], hitl.sent
          assert_nil result.report
          question = hitl.create_calls.first[:question_lines].join("\n")
          assert_includes question, "role_sequence"
          assert_includes question, "no assignment process"
          assert_includes question, "worktree preserved at /proj/.ace-wt/t.8xg-t-aaa"
        end

        def test_sequence_composition_error_without_recipient_keeps_gap_visible
          composer = FakeSequenceComposer.new(error: "unknown role 'planner'")
          hitl = FakeHitl.new
          result = orchestrator(provision_decision: created_decision, sequence_composer: composer,
            hitl: hitl)
            .call(task_ref: "8xg.t.aaa", roles: %w[planner])

          assert result.conflict?
          assert_equal "role_sequence", result.conflict["kind"]
          assert_includes result.conflict["detail"], "unknown role 'planner'"
          assert_includes result.conflict["detail"], "cannot report conflict: no overseer address"
          assert_nil result.conflict["hitl_event"]
          assert_empty hitl.create_calls
        end

        def test_readiness_report_delivery_failure_keeps_event_for_retry
          hitl = FakeHitl.new
          def hitl.send_report(_event_id)
            sent << _event_id
            false
          end
          result = orchestrator(provision_decision: created_decision,
            start_config_writer: FakeStartConfigWriter.new, hitl: hitl)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker], to: "overseer@lab")

          refute result.conflict?, "delivery failure never undoes the preparation"
          assert_equal({"kind" => "readiness", "event" => "rpt001", "delivered" => false},
            result.report)
        end

        def test_readiness_report_create_failure_is_recorded_not_raised
          hitl = FakeHitl.new
          hitl.report_result = Molecules::HitlReporter::Failure.new(
            stage: "create", message: "hitl unavailable")
          result = orchestrator(provision_decision: created_decision,
            start_config_writer: FakeStartConfigWriter.new, hitl: hitl)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker], to: "overseer@lab")

          refute result.conflict?
          assert_equal({"kind" => "readiness", "error" => "hitl unavailable"}, result.report)
        end

        def test_readiness_report_missing_hitl_binary_is_recorded_not_raised
          hitl = FakeHitl.new
          def hitl.create_report(**)
            raise Error, "required CLI 'ace-hitl' not found; install the ace-hitl gem"
          end
          result = orchestrator(provision_decision: created_decision,
            start_config_writer: FakeStartConfigWriter.new, hitl: hitl)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker], to: "overseer@lab")

          refute result.conflict?
          assert_equal({"kind" => "readiness",
            "error" => "required CLI 'ace-hitl' not found; install the ace-hitl gem"},
            result.report)
        end

        def test_conflict_and_dry_run_paths_skip_sequence_composition
          composer = FakeSequenceComposer.new
          hitl = FakeHitl.new
          orchestrator(provision_decision: created_decision.merge(disposition: :would_create),
            sequence_composer: composer)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker], dry_run: true)
          orchestrator(provision_decision: created_decision.merge(disposition: :conflict_mismatch,
            reason: "other task"), hitl: hitl, sequence_composer: composer)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker], to: "overseer@lab")

          assert_empty composer.calls
        end

        def test_reuse_performs_no_writes_and_no_escalation
          hitl = FakeHitl.new
          reuse = created_decision.merge(disposition: :reuse)
          executor = {config: nil,
            assignments: [{"id" => "a1", "name" => "w", "state" => "paused", "progress" => "0/2"}]}
          result = orchestrator(provision_decision: reuse, executor_result: executor, hitl: hitl,
            start_config_writer: FakeStartConfigWriter.new)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker], to: "overseer@lab")

          assert_equal "reused", result.worktree["disposition"]
          assert_empty hitl.create_calls, "reuse escalates no conflict"
          assert_equal 1, hitl.report_calls.length,
            "the commission still ends with its readiness report (L4.4)"
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
          assert_equal({"assignment" => "abc123", "state" => "running", "source" => "config"},
            result.active_executor)
          assert_equal result.active_executor, result.to_h["active_executor"]
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

        def test_recipient_falls_back_to_lenient_overseer_on_partial_config
          hitl = FakeHitl.new
          # Full ConfigSchema validation fails (planner-side partial config),
          # but the lenient field read still finds the overseer.
          orchestrator(
            provision_decision: {disposition: :conflict_mismatch, reason: "foreign", worktree_path: "/w"},
            hitl: hitl, config: nil, lenient_overseer: "partial-overseer"
          ).call(task_ref: "8xg.t.aaa", roles: %w[worker])

          assert_equal "partial-overseer", hitl.create_calls.first[:to]
        end

        def test_conflict_without_any_overseer_surfaces_config_load_error
          hitl = FakeHitl.new
          result = orchestrator(
            provision_decision: {disposition: :conflict_mismatch, reason: "foreign", worktree_path: "/w"},
            hitl: hitl, config: nil, lenient_overseer: nil
          ).call(task_ref: "8xg.t.aaa", roles: %w[worker])

          assert result.conflict?
          assert_includes result.conflict["detail"], "no overseer address"
          assert_includes result.conflict["detail"], "coworker config load failed: not ready: no config"
          assert_empty hitl.create_calls
        end

        def test_missing_hitl_binary_still_renders_conflict
          hitl = FakeHitl.new
          def hitl.create_conflict(**)
            raise Error, "required CLI 'ace-hitl' not found; install the ace-hitl gem"
          end
          executor = {config: {"assignment" => "abc123"},
            assignments: [{"id" => "abc123", "name" => "w", "state" => "running", "progress" => "1/2"}]}
          result = orchestrator(provision_decision: created_decision.merge(disposition: :reuse),
            executor_result: executor, hitl: hitl)
            .call(task_ref: "8xg.t.aaa", roles: %w[worker], to: "overseer@lab")

          assert result.conflict?
          assert_equal "active_executor", result.conflict["kind"]
          assert_nil result.conflict["hitl_event"]
          assert_includes result.conflict["detail"], "required CLI 'ace-hitl' not found"
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
