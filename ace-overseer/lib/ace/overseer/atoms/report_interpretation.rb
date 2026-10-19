# frozen_string_literal: true

module Ace
  module Overseer
    module Atoms
      # Pure interpretation atom for the overseer queue (L6.5): maps an
      # incoming ace-hitl event (executor report or question) plus the
      # current private task tree to the actions the overseer performs.
      # No side effects here — every write goes through the existing
      # ace-task update surface driven by the returned set hashes.
      #
      # Semantics (queue.wf.md rule 5 and the lab contract):
      # - A report matches the current order by its assignment reference
      #   recorded on a step, or by the managing task's project_task plus
      #   exactly one non-terminal step. A report that fits no open
      #   allocation is :unmatched — kept for clarification, never success.
      # - The processed report ID is recorded on the step; a repeated
      #   delivery of the same ID is :duplicate — re-delivery never retries
      #   the work or re-runs a role.
      # - A question (:needs_answer) or a report whose result is not
      #   "success" (:error) never advances a step; the step stays open.
      module ReportInterpretation
        SUCCESS_RESULT = "success"
        REPORT_TYPE = "report"
        PROCESSED_REPORT_KEY = "processed_report"
        REPORT_RESULT_KEY = "report_result"

        # @param event [Hash] {"id","type","result","task","assignment","step"}
        # @param managers [Array<Object>] private-tree managing tasks
        #   responding to #id, #status, #metadata (Hash), #subtasks
        # @return [Hash] one of:
        #   {status: :success, manager_ref:, step_ref:,
        #      set: {status/report fields incl. the processed report ID}}
        #   {status: :error, manager_ref:, step_ref:, set:, escalate: true}
        #   {status: :needs_answer, manager_ref:, step_ref:, event_id:}
        #   {status: :duplicate, manager_ref:, step_ref:,
        #      recorded_result:}
        #   {status: :unmatched, reason:}
        def self.evaluate(event:, managers:)
          matched = match(event, managers)
          return {status: :unmatched, reason: unmatched_reason(event)} unless matched

          manager = matched[:manager]
          step = matched[:step]

          if step.metadata[PROCESSED_REPORT_KEY] == event["id"]
            return {
              status: :duplicate,
              manager_ref: manager.id.to_s,
              step_ref: step.id.to_s,
              recorded_result: step.metadata[REPORT_RESULT_KEY]
            }
          end

          base_set = {
            PROCESSED_REPORT_KEY => event["id"],
            REPORT_RESULT_KEY => effective_result(event)
          }

          if question?(event)
            # A question awaits its answer through the ace-hitl reply
            # surface; recording it on the step would pre-empt that answer,
            # so nothing is written and the step stays open.
            return {
              status: :needs_answer,
              manager_ref: manager.id.to_s,
              step_ref: step.id.to_s,
              event_id: event["id"]
            }
          end

          if effective_result(event) == SUCCESS_RESULT
            {
              status: :success,
              manager_ref: manager.id.to_s,
              step_ref: step.id.to_s,
              set: base_set.merge("status" => "done")
            }
          else
            {
              status: :error,
              manager_ref: manager.id.to_s,
              step_ref: step.id.to_s,
              set: base_set,
              escalate: true
            }
          end
        end

        # @param event [Hash]
        # @return [String] the report result, normalized: questions and
        #   missing results are never "success"
        def self.effective_result(event)
          return "" if question?(event)

          event["result"].to_s
        end

        # @return [Boolean] whether the event is a question (awaits an
        #   answer), not a report
        def self.question?(event)
          event["type"] != REPORT_TYPE
        end

        # Matching precedence: an assignment reference recorded on a step
        # is the strongest binding; otherwise the managing task's
        # project_task must match the reported task AND leave exactly one
        # non-terminal step as the report's target.
        #
        # @return [Hash{manager:, step:}, nil]
        def self.match(event, managers)
          assignment = event["assignment"].to_s
          by_assignment = managers.flat_map do |manager|
            steps_of(manager).filter_map do |step|
              {manager: manager, step: step} if assignment != "" &&
                step.metadata["assignment"].to_s == assignment
            end
          end
          return by_assignment.first if by_assignment.any?

          task = event["task"].to_s
          managers.filter_map do |manager|
            next unless manager.metadata["project_task"].to_s == task && task != ""

            active = steps_of(manager).reject { |step| terminal?(step) }
            {manager: manager, step: active.first} if active.size == 1
          end.first
        end

        # @return [String] why the event fit no open allocation
        def self.unmatched_reason(event)
          refs = []
          refs << "task #{event['task']}" if event["task"].to_s != ""
          refs << "assignment #{event['assignment']}" if event["assignment"].to_s != ""
          refs = ["no references"] if refs.empty?

          "report #{event['id']} (#{refs.join(', ')}) matches no open step in the overseer tree"
        end

        # Steps of a manager (its subtasks); a manager without subtasks
        # manages its own single scope.
        def self.steps_of(manager)
          steps = manager.respond_to?(:subtasks) ? Array(manager.subtasks) : []
          steps.empty? ? [manager] : steps
        end

        def self.terminal?(task)
          Ace::Task::Atoms::TaskValidationRules.terminal_status?(task.status.to_s)
        end
      end
    end
  end
end
