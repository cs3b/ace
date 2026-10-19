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
      #   recorded on a step (non-terminal steps preferred), or by the
      #   managing task's project_task plus exactly one non-terminal
      #   step. An event that fits no open allocation is :unmatched, kept
      #   for clarification, never success (an ambiguous cross-manager
      #   match is also :unmatched).
      # - The processed report ID is recorded on the step; a repeated
      #   delivery of the same ID is :duplicate: re-delivery never
      #   retries the work or re-runs a role. So does a success report
      #   with a NEW id whose only assignment match is a terminal step:
      #   there is no reopen path, so a re-sent report on a done step
      #   resolves to the recorded result instead of re-advancing it.
      # - A question (:needs_answer) or a report whose result is not
      #   "success" (:error) never advances a step; the step stays open.
      module ReportInterpretation
        SUCCESS_RESULT = "success"
        REPORT_TYPE = "report"
        PROCESSED_REPORT_KEY = "processed_report"
        REPORT_RESULT_KEY = "report_result"

        # @param event [Hash] {"id","type","result","task","assignment"}
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

          # A success report whose only assignment match is a terminal
          # step is a re-send under a new id: there is no reopen path,
          # so resolve to the recorded result instead of re-advancing
          # the done step (or re-running its continuation).
          if matched[:terminal] && !question?(event) &&
              event["result"].to_s == SUCCESS_RESULT
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
        # @return [String] the report result; questions never consult it
        #   (they return before any set is built) and a missing result is
        #   never "success"
        def self.effective_result(event)
          event["result"].to_s
        end

        # @return [Boolean] whether the event is a question (awaits an
        #   answer), not a report
        def self.question?(event)
          event["type"] != REPORT_TYPE
        end

        # Matching precedence: an assignment reference recorded on a step
        # is the strongest binding, with non-terminal steps preferred (a
        # terminal match can only ever resolve to :duplicate, never a
        # fresh advance); otherwise the managing task's project_task must
        # match the reported task AND leave exactly one non-terminal step
        # as the report's target. A match that is ambiguous across
        # managers (or across steps) fits no open allocation and returns
        # nil.
        #
        # @return [Hash{manager:, step:, terminal:}, nil]
        def self.match(event, managers)
          assignment = event["assignment"].to_s
          if assignment != ""
            matches = managers.flat_map do |manager|
              steps_of(manager).filter_map do |step|
                {manager: manager, step: step} if step.metadata["assignment"].to_s == assignment
              end
            end
            active = matches.reject { |matched| terminal?(matched[:step]) }
            unless matches.empty?
              candidates = active.empty? ? matches : active
              if candidates.size == 1
                return {manager: candidates.first[:manager], step: candidates.first[:step],
                        terminal: active.empty?}
              end

              return nil
            end
          end

          task = event["task"].to_s
          matches = managers.filter_map do |manager|
            next unless manager.metadata["project_task"].to_s == task && task != ""

            active = steps_of(manager).reject { |step| terminal?(step) }
            {manager: manager, step: active.first} if active.size == 1
          end
          return nil if matches.size > 1
          return nil if matches.empty?

          {manager: matches.first[:manager], step: matches.first[:step], terminal: false}
        end

        # @return [String] why the event fit no open allocation
        def self.unmatched_reason(event)
          refs = []
          refs << "task #{event['task']}" if event["task"].to_s != ""
          refs << "assignment #{event['assignment']}" if event["assignment"].to_s != ""
          refs = ["no references"] if refs.empty?

          "event #{event['id']} (#{refs.join(', ')}) matches no open step in the overseer tree"
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
