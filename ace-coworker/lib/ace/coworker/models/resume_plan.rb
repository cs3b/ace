# frozen_string_literal: true

module Ace
  module Coworker
    module Models
      # Immutable resume plan derived from the assignment snapshot, the
      # worktree git state, and the report helper state. No IO.
      class ResumePlan
        attr_reader :disposition, :preserved_steps, :remaining_steps,
          :in_flight, :in_flight_cause, :step_report_path,
          :effect_caution_steps, :git, :redeliver_event_id

        def initialize(disposition:, preserved_steps: [], remaining_steps: [],
          in_flight: nil, in_flight_cause: nil, step_report_path: nil,
          effect_caution_steps: [], git: {}, redeliver_event_id: nil)
          @disposition = disposition
          @preserved_steps = preserved_steps.map(&:freeze).freeze
          @remaining_steps = remaining_steps.map(&:freeze).freeze
          @in_flight = in_flight
          @in_flight_cause = in_flight_cause
          @step_report_path = step_report_path
          @effect_caution_steps = effect_caution_steps.map(&:freeze).freeze
          @git = git.freeze
          @redeliver_event_id = redeliver_event_id
        end

        def continue?
          disposition == :continue
        end

        def to_h
          {
            "disposition" => disposition.to_s,
            "preserved_steps" => preserved_steps,
            "remaining_steps" => remaining_steps,
            "in_flight" => in_flight,
            "in_flight_cause" => in_flight_cause,
            "step_report_path" => step_report_path,
            "effect_caution_steps" => effect_caution_steps,
            "git" => git,
            "redeliver_event_id" => redeliver_event_id
          }
        end
      end
    end
  end
end
