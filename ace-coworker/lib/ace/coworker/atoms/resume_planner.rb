# frozen_string_literal: true

module Ace
  module Coworker
    module Atoms
      # Pure derivation of the resume plan: ace-assign is the only step
      # truth, the worktree git state is the only change truth, and the
      # report helper state decides create-vs-resend. Never plans a new
      # task/assignment/worktree and never plans resetting local changes.
      class ResumePlanner
        EFFECT_PATTERN = /merge|publish|deploy|release|push/i.freeze

        # @param snapshot [Models::AssignmentSnapshot]
        # @param report_state [Hash, nil] .ace-local/coworker/reports/<id>.json
        # @param git_state [Hash] branch/ahead_behind/dirty_entries/last_commit
        # @param step_cause [String, nil] recorded error of the in-flight step
        # @param step_report_path [String, nil] report file of the in-flight step
        # @return [Models::ResumePlan]
        def self.plan(snapshot:, report_state: nil, git_state: {},
          step_cause: nil, step_report_path: nil)
          if snapshot.completion_verdict == :complete
            return complete_plan(report_state, git_state)
          end

          continue_plan(snapshot, report_state, git_state,
            step_cause: step_cause, step_report_path: step_report_path)
        end

        def self.complete_plan(report_state, git_state)
          delivered = report_state.is_a?(Hash) && report_state["delivery"].to_s.start_with?("delivered")
          if delivered
            Models::ResumePlan.new(disposition: :complete, git: git_state)
          else
            Models::ResumePlan.new(disposition: :report, git: git_state,
              redeliver_event_id: report_state.is_a?(Hash) ? report_state["event_id"] : nil)
          end
        end

        # Single source of truth for the in-flight step: last active, else
        # last failed, else first remaining. The orchestrator uses this to
        # decide whose evidence to read; the planner renders the same step.
        def self.in_flight_step(snapshot)
          remaining = snapshot.steps.reject(&:done?)
          remaining.reverse.find { |s| s.status == "active" } ||
            remaining.reverse.find { |s| s.status == "failed" } ||
            remaining.first
        end

        def self.continue_plan(snapshot, report_state, git_state, step_cause:, step_report_path:)
          preserved = snapshot.steps.select(&:done?).map { |s| "#{s.number} #{s.name}" }
          remaining = snapshot.steps.reject(&:done?)
          in_flight_step = in_flight_step(snapshot)

          remaining_lines = remaining.map { |s| "#{s.number} #{s.name} (#{s.status})" }
          caution = remaining_lines.select { |line| line.match?(EFFECT_PATTERN) }.uniq

          Models::ResumePlan.new(disposition: :continue,
            preserved_steps: preserved,
            remaining_steps: remaining_lines,
            in_flight: in_flight_step && {
              "number" => in_flight_step.number, "name" => in_flight_step.name,
              "status" => in_flight_step.status
            },
            in_flight_cause: step_cause,
            step_report_path: step_report_path,
            effect_caution_steps: caution,
            git: git_state,
            redeliver_event_id: report_state.is_a?(Hash) ? report_state["event_id"] : nil)
        end
      end
    end
  end
end
