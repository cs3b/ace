# frozen_string_literal: true

module Ace
  module Coworker
    module Atoms
      # Pure rendering of a ResumePlan (table format). The brief is the
      # guidance the next role or tool reads to continue safely.
      class ResumeBriefFormatter
        # @param plan [Models::ResumePlan]
        # @param result [Organisms::ResumeOrchestrator::ResumeResult, nil]
        # @return [String]
        def self.format_table(plan, result = nil)
          lines = ["Coworker resume"]
          if plan.disposition == :report
            lines << "  assignment complete; report delivery missing"
            if plan.redeliver_event_id
              lines << "  resend event:      #{plan.redeliver_event_id} (same ID; retrying delivery never retries the assignment)"
            end
            lines << "  #{result.message}" if result.message
            return lines.join("\n")
          end

          if plan.disposition == :complete
            lines << "  assignment complete and delivered; nothing to resume"
            return lines.join("\n")
          end

          lines.concat(identity_lines(plan))
          lines.concat(preserved_lines(plan))
          lines.concat(remaining_lines(plan))
          lines.concat(in_flight_lines(plan))
          lines.concat(local_changes_lines(plan))
          lines.concat(effect_caution_lines(plan))
          lines.join("\n")
        end

        def self.identity_lines(plan)
          branch = plan.git["branch"] || "(detached)"
          ["  branch:            #{branch}"]
        end

        def self.preserved_lines(plan)
          return [] if plan.preserved_steps.empty?

          ["  preserved steps:"] + plan.preserved_steps.map { |s| "    done: #{s}" }
        end

        def self.remaining_lines(plan)
          return [] if plan.remaining_steps.empty?

          ["  remaining work:"] + plan.remaining_steps.map { |s| "    #{s}" }
        end

        def self.in_flight_lines(plan)
          return [] unless plan.in_flight

          step = plan.in_flight
          lines = ["  in-flight step:    #{step["number"]} #{step["name"]} (#{step["status"]})"]
          lines << "    recorded cause:  #{plan.in_flight_cause}" if plan.in_flight_cause
          lines << "    step report:     #{plan.step_report_path}" if plan.step_report_path
          lines << "    verify the effect from the current files/Git state and the step's own report before repeating it; do not reset local changes"
          lines
        end

        def self.local_changes_lines(plan)
          dirty = plan.git["dirty_entries"] || []
          return [] if dirty.empty?

          ["  local changes (preserved, never reset):"] + dirty.map { |entry| "    #{entry}" }
        end

        def self.effect_caution_lines(plan)
          return [] if plan.effect_caution_steps.empty?

          ["  effect caution:    uncertain external effect (merge/publish/deploy/release/push)?"] +
            plan.effect_caution_steps.map { |s| "    step: #{s}" } +
            ["    check the actual state with existing tools (e.g. ace-git status, PR evidence) or report a blocker;",
             "    never replay blindly; same task, assignment and worktree"]
          # never replay blindly; same task, assignment and worktree
        end
      end
    end
  end
end
