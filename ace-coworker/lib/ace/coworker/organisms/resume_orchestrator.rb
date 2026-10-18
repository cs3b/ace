# frozen_string_literal: true

require_relative "../molecules/config_loader"
require_relative "../molecules/task_probe"
require_relative "../molecules/assignment_metadata"
require_relative "../molecules/assignment_probe"
require_relative "../molecules/step_evidence_reader"
require_relative "../molecules/step_report_reader"
require_relative "../molecules/git_state_probe"
require_relative "../molecules/report_state_store"
require_relative "../atoms/resume_planner"
require_relative "report_orchestrator"

module Ace
  module Coworker
    module Organisms
      # Orchestrates `ace-coworker resume`: after an interruption, read the
      # existing assignment, task, and the REAL state of the same worktree,
      # and return to the remaining work. Same task/assignment/worktree —
      # never a new one; local changes are never reset; resume itself never
      # drives assignment steps. When the assignment is complete and only
      # delivery is missing, delegates to ReportOrchestrator (same event ID
      # resend). No journal/checkpoint store (ADR-034).
      class ResumeOrchestrator
        ResumeResult = Struct.new(:plan, :report_result, :message, :exit_code, keyword_init: true)

        def initialize(project_root: nil, config_loader: nil, task_probe: nil,
          assignment_probe: nil, evidence_reader: nil, report_reader: nil,
          git_probe: nil, state_store: nil, report_orchestrator: nil, config: nil)
          @config = config || Ace::Coworker.config
          @project_root = project_root || Molecules::ProjectRoot.new.resolve
          @config_loader = config_loader || Molecules::ConfigLoader.new(project_root: @project_root, defaults: @config)
          @task_probe = task_probe || Molecules::TaskProbe.new(project_root: @project_root)
          @assignment_metadata = Molecules::AssignmentMetadata.new(project_root: @project_root)
          @assignment_probe = assignment_probe || Molecules::AssignmentProbe.new(project_root: @project_root)
          @evidence_reader = evidence_reader || Molecules::StepEvidenceReader.new(project_root: @project_root)
          @report_reader = report_reader || Molecules::StepReportReader.new(project_root: @project_root)
          @git_probe = git_probe || Molecules::GitStateProbe.new(project_root: @project_root)
          @state_store_factory = state_store
          @report_orchestrator = report_orchestrator
        end

        # @return [ResumeResult]
        def call(config_path: nil, assignment: nil, dry_run: false)
          cfg = @config_loader.load(path: config_path)
          assignment_id = assignment.to_s.strip.empty? ? cfg.assignment : assignment.to_s.strip
          @task_probe.resolve!(cfg.task)
          @assignment_metadata.verify_task_match!(assignment_id, cfg.task)
          snapshot = @assignment_probe.snapshot(assignment_id)

          state_store = @state_store_factory || Molecules::ReportStateStore.new(project_root: @project_root)
          report_state = state_store.read(assignment_id)
          git_state = @git_probe.state

          in_flight_number = in_flight_step_number(snapshot)
          step_cause = @evidence_reader.read(assignment_id, in_flight_number)
          step_report = @report_reader.read(assignment_id, in_flight_number)

          plan = Atoms::ResumePlanner.plan(snapshot: snapshot,
            report_state: report_state, git_state: git_state,
            step_cause: step_cause,
            step_report_path: step_report && step_report["path"])

          case plan.disposition
          when :continue, :complete
            ResumeResult.new(plan: plan,
              message: plan.continue? ? "assignment in progress; resume the remaining work" : "assignment complete and delivered; nothing to resume",
              exit_code: 0)
          when :report
            return ResumeResult.new(plan: plan,
              message: "assignment complete; report delivery missing (dry-run: nothing sent)",
              exit_code: 0) if dry_run

            orchestrator = @report_orchestrator || ReportOrchestrator.new(project_root: @project_root, config: @config)
            report_result = orchestrator.call(config_path: config_path, assignment: assignment_id)
            ResumeResult.new(plan: plan, report_result: report_result,
              message: "assignment complete; redelivering the report: #{report_result.message}",
              exit_code: report_result.exit_code)
          end
        end

        private

        def in_flight_step_number(snapshot)
          Atoms::ResumePlanner.in_flight_step(snapshot)&.number
        end
      end
    end
  end
end
