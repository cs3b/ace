# frozen_string_literal: true

module Ace
  module Coworker
    module Models
      # Pure view of `ace-assign status --format json` for one assignment.
      class AssignmentSnapshot
        Step = Struct.new(:number, :name, :status, keyword_init: true) do
          def done?
            status == "done"
          end
        end

        attr_reader :id, :name, :state, :steps, :progress

        def initialize(id:, name:, state:, steps:, progress:)
          @id = id.freeze
          @name = name.freeze
          @state = state.freeze
          @steps = steps.map { |s| Step.new(number: s[:number], name: s[:name], status: s[:status]) }.freeze
          @progress = progress.freeze
        end

        def self.from_status_json(payload)
          assignment = payload["assignment"] || {}
          steps = (payload["steps"] || []).map { |s| {number: s["number"], name: s["name"], status: s["status"]} }
          new(
            id: assignment["id"].to_s,
            name: assignment["name"].to_s,
            state: assignment["state"].to_s,
            steps: steps,
            progress: payload["progress"].to_s
          )
        end

        # Deterministic completion verdict: complete only when the assignment
        # state is completed, the plan is non-empty, and every step is done.
        # Empty plans, failed steps, or pending/active steps are not complete.
        def completion_verdict
          return :complete if state == "completed" && !steps.empty? && steps.all?(&:done?)

          :incomplete
        end

        def incomplete_reasons
          reasons = []
          reasons << "assignment state is '#{state}' (not completed)" if state != "completed"
          reasons << "assignment plan is empty" if steps.empty?
          reasons << "#{steps.count { |s| s.status == 'failed' }} failed step(s)" if steps.any? { |s| s.status == "failed" }
          pending = steps.count { |s| s.status == "pending" }
          active = steps.count { |s| s.status == "active" }
          reasons << "#{pending} pending step(s)" if pending.positive?
          reasons << "#{active} active step(s)" if active.positive?
          reasons
        end

        def to_h
          {"id" => id, "name" => name, "state" => state, "progress" => progress,
           "steps" => steps.map { |s| {"number" => s.number, "name" => s.name, "status" => s.status} },
           "complete" => completion_verdict == :complete}
        end
      end
    end
  end
end
