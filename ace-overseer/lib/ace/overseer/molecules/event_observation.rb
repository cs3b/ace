# frozen_string_literal: true
require "ace/hitl/molecules/event_observation"

module Ace
  module Overseer
    module Molecules
      # Read-only adoption filter. HITL owns semantic revisions; the existing
      # private task tree owns report adoption and continuation, never this view.
      class EventObservation
        def initialize(hitl: nil, task_manager: nil)
          @hitl = hitl || Ace::Hitl::Molecules::EventObservation.new
          @tasks = task_manager || Ace::Task::Organisms::TaskManager.new
        end

        def call(owner:, scope: "current", limit: 500)
          projection = @hitl.call(owner: owner, scope: scope, limit: limit)
          managers = @tasks.list(in_folder: "all").select { |task| !task.metadata["project_task"].to_s.empty? }
          settled, pending = projection.fetch("events").partition do |event|
            next false unless event["type"] == "report"
            verdict = Atoms::ReportInterpretation.evaluate(event: event, managers: managers)
            next false unless verdict[:status] == :duplicate
            manager = managers.find { |task| task.id.to_s == verdict[:manager_ref] }
            # A persisted report alone is not proof its continuation ran. Keep
            # active managers eligible after restart; their existing gates reconcile
            # the same attempt. Only completed trees suppress historical reports.
            manager && ([manager] + Array(manager.subtasks)).all? { |task| Ace::Task::Atoms::TaskValidationRules.terminal_status?(task.status.to_s) }
          end
          projection.merge("events" => pending, "settled" => settled)
        end
      end
    end
  end
end
