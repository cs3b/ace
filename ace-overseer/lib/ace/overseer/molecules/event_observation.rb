# frozen_string_literal: true
require "ace/hitl/molecules/event_observation"
require "digest"

module Ace
  module Overseer
    module Molecules
      # Read-only standing observation (task 8xs.t.pu0.3). HITL owns
      # semantic revisions; the existing private task tree owns report
      # adoption and continuation, never this view. The projection arms
      # the started overseer with the six local source classes — HITL
      # events plus LocalSources (project tasks, _overseer tasks,
      # worktrees, coworker availability, assignment progress) — every
      # row read from its state owner, with per-source health so a
      # failing source degrades only itself and healthy silence projects
      # identical revisions (no model turns).
      class EventObservation
        def initialize(hitl: nil, task_manager: nil, local_sources: nil)
          @hitl = hitl || Ace::Hitl::Molecules::EventObservation.new
          @tasks = task_manager || Ace::Task::Organisms::TaskManager.new
          @local_sources = local_sources || LocalSources.new(task_manager: @tasks)
        end

        def call(owner:, scope: "current", limit: 500)
          projection = nil
          hitl_error = nil
          begin
            projection = @hitl.call(owner: owner, scope: scope, limit: limit)
          rescue StandardError => e
            hitl_error = e
          end

          local = @local_sources.call
          managers = @tasks.list(in_folder: "all").select { |task| !task.metadata["project_task"].to_s.empty? }

          if projection.nil?
            # A degraded HITL source degrades only itself: the local
            # sources keep projecting and the failure is visible data.
            events = local.fetch("events") + [health_marker("hitl", hitl_error)]
            sources = local.fetch("sources").merge(
              "hitl" => {"status" => "degraded", "error" => "#{hitl_error.class}: #{hitl_error.message}"}
            )
            return {"schema" => "ace.hitl.observation/v1",
                    "events" => events.sort_by { |row| row["key"] },
                    "settled" => [], "sources" => sources}
          end

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

          projection.merge("events" => (pending + local.fetch("events")).sort_by { |row| row["key"] },
            "settled" => settled,
            "sources" => local.fetch("sources").merge("hitl" => {"status" => "ok"}))
        end

        private

        def health_marker(name, error)
          {"key" => "source:#{name}",
           "revision" => Digest::SHA256.hexdigest("degraded:#{error.class}"),
           "type" => "source-health", "status" => "degraded",
           "error" => "#{error.class}: #{error.message}"}
        end
      end
    end
  end
end
