# frozen_string_literal: true

require_relative "../molecules/config_loader"
require_relative "../molecules/task_probe"
require_relative "../molecules/assignment_metadata"
require_relative "../molecules/assignment_probe"
require_relative "../molecules/step_evidence_reader"
require_relative "../molecules/hitl_reporter"
require_relative "../molecules/task_record_writer"
require_relative "../molecules/report_state_store"
require_relative "../atoms/outcome_planner"
require_relative "../atoms/report_record_formatter"

module Ace
  module Coworker
    module Organisms
      # Orchestrates `ace-coworker report`: derive the outcome (ace-assign
      # is the only truth), write the durable record into the task folder
      # FIRST, keep helper state under .ace-local/coworker/, then report
      # through the ace-hitl CLI. Outcome and delivery are strictly
      # separated: a completed assignment with an undelivered report keeps
      # the work success plus an explicit delivery error; an execution
      # error records its cause and the unfinished step — never a false
      # work done.
      class ReportOrchestrator
        ReportResult = Struct.new(:outcome, :record_path, :event_id, :delivery, :message,
          :exit_code, :created_event, keyword_init: true)

        def initialize(project_root: nil, config_loader: nil, task_probe: nil,
          assignment_probe: nil, evidence_reader: nil, reporter: nil,
          record_writer: nil, state_store: nil, config: nil)
          @config = config || Ace::Coworker.config
          @project_root = project_root || Molecules::ProjectRoot.new.resolve
          @config_loader = config_loader || Molecules::ConfigLoader.new(project_root: @project_root, defaults: @config)
          @task_probe = task_probe || Molecules::TaskProbe.new(project_root: @project_root)
          @assignment_probe = assignment_probe || Molecules::AssignmentProbe.new(project_root: @project_root)
          @evidence_reader = evidence_reader || Molecules::StepEvidenceReader.new(project_root: @project_root)
          @reporter = reporter || Molecules::HitlReporter.new(project_root: @project_root)
        end

        # @param config_path [String, nil]
        # @param assignment [String, nil] override (default: config assignment)
        # @param result [String, nil] explicit --result
        # @param message [String, nil] explicit cause
        # @param step [String, nil] explicit --step
        # @param no_send [Boolean]
        # @param dry_run [Boolean]
        # @return [ReportResult]
        def call(config_path: nil, assignment: nil, result: nil, message: nil,
          step: nil, no_send: false, dry_run: false)
          cfg = @config_loader.load(path: config_path)
          assignment_id = assignment.to_s.strip.empty? ? cfg.assignment : assignment.to_s.strip
          @task_probe.resolve!(cfg.task)
          @assignment_metadata ||= Molecules::AssignmentMetadata.new(project_root: @project_root)
          @assignment_metadata.verify_task_match!(assignment_id, cfg.task)
          snapshot = @assignment_probe.snapshot(assignment_id)

          step_evidence = @evidence_reader.read(assignment_id, failed_step_number(snapshot))
          outcome = Atoms::OutcomePlanner.plan(snapshot,
            explicit_result: result, message: message,
            step_evidence: step_evidence, step_override: step)

          record_writer = Molecules::TaskRecordWriter.new(task_path: @task_probe.resolve!(cfg.task))
          state_store = Molecules::ReportStateStore.new(project_root: @project_root)

          return dry_run_result(outcome, cfg) if dry_run

          record_path = record_writer.write(assignment_id,
            Atoms::ReportRecordFormatter.format(outcome, cfg, record_path: placeholder_record_path(cfg, assignment_id)))

          # Rerun rules: same result with an existing event => send-only
          # redelivery (retrying delivery never retries the assignment).
          state = state_store.read(assignment_id) || {}
          event_id = nil
          created_event = false
          if state["result"] == outcome.result && state["event_id"] && event_exists?(state["event_id"])
            event_id = state["event_id"]
          elsif report_via_hitl?(cfg, outcome)
            event_id = @reporter.create(outcome, cfg)
            if event_id.is_a?(Molecules::HitlReporter::Failure)
              return failure_result(outcome, cfg, record_path, nil,
                "outcome recorded: #{outcome.result} at #{record_path}; HITL create failed: #{event_id.message}")
            end
            created_event = true
          end

          delivery = nil
          if event_id && !no_send
            send_result = @reporter.send_report(event_id)
            if send_result == true
              delivery = "delivered (event #{event_id})"
            else
              # Bind the event in helper state even on delivery failure so a
              # rerun resends instead of duplicating the event.
              state_store.write(assignment_id, {
                "result" => outcome.result, "event_id" => event_id,
                "record" => record_path, "delivery" => nil,
                "updated_at" => Time.now.utc.iso8601
              })
              return failure_result(outcome, cfg, record_path, event_id,
                "outcome recorded: #{outcome.result} at #{record_path}; delivery failed: #{send_result.message}")
            end
          end

          state_store.write(assignment_id, {
            "result" => outcome.result, "event_id" => event_id,
            "record" => record_path, "delivery" => delivery,
            "updated_at" => Time.now.utc.iso8601
          })
          rewrite_record_with_delivery(record_writer, assignment_id, outcome, cfg, event_id, delivery)

          finish_result(outcome, cfg, record_path, event_id, delivery, created_event)
        end

        private

        def report_via_hitl?(cfg, outcome)
          return true if outcome.success?

          # errors.on_failure=stop: record locally, skip HITL entirely.
          cfg.on_failure != "stop"
        end

        def event_exists?(event_id)
          pattern = File.join(@project_root, ".ace-local", "hitl", "**", "#{event_id}-*")
          !Dir.glob(pattern).empty?
        end

        def failed_step_number(snapshot)
          failed = snapshot.steps.reverse.find { |s| s.status == "failed" } ||
            snapshot.steps.find { |s| s.status == "active" } ||
            snapshot.steps.find { |s| s.status == "pending" }
          failed&.number
        end

        def placeholder_record_path(cfg, assignment_id)
          ".ace-tasks/#{cfg.task}/coworker/#{assignment_id}.md"
        end

        def rewrite_record_with_delivery(record_writer, assignment_id, outcome, cfg, event_id, delivery)
          record_writer.write(assignment_id,
            Atoms::ReportRecordFormatter.format(outcome, cfg,
              event_id: event_id, delivery: delivery || "not attempted",
              record_path: placeholder_record_path(cfg, assignment_id)))
        end

        def dry_run_result(outcome, cfg)
          ReportResult.new(outcome: outcome, record_path: nil, event_id: nil,
            delivery: nil, created_event: false,
            message: "dry-run: outcome #{outcome.result} (nothing written)", exit_code: 0)
        end

        def failure_result(outcome, cfg, record_path, event_id, message)
          ReportResult.new(outcome: outcome, record_path: record_path, event_id: event_id,
            delivery: nil, created_event: !event_id.nil?, message: message, exit_code: 1)
        end

        def finish_result(outcome, cfg, record_path, event_id, delivery, created_event)
          if outcome.success?
            message = "outcome recorded: success at #{record_path}"
            message += delivery ? "; #{delivery}" : "; delivery not attempted"
            ReportResult.new(outcome: outcome, record_path: record_path, event_id: event_id,
              delivery: delivery, message: message, created_event: created_event, exit_code: 0)
          else
            message = "outcome recorded: error at #{record_path}"
            message += "; #{delivery}" if delivery
            ReportResult.new(outcome: outcome, record_path: record_path, event_id: event_id,
              delivery: delivery, message: message, created_event: created_event, exit_code: 1)
          end
        end
      end
    end
  end
end
