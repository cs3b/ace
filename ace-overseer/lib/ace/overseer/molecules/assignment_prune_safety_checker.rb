# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      # Fail-closed safety classification for local assignment cache pruning.
      #
      # The cache directory of an assignment is disposable only when the
      # local assignment record is terminal:
      #
      # - the queue label must read completed (never proof by itself),
      # - the local step summary must show no active or pending steps; an
      #   unreadable summary blocks.
      #
      # Assignment state lives in `.ace-local/assign/`; no journal, attempt or
      # authority store participates in this decision.
      class AssignmentPruneSafetyChecker
        def initialize(assignment_discoverer_factory: nil)
          @assignment_discoverer_factory = assignment_discoverer_factory || -> { Ace::Assign::Molecules::AssignmentDiscoverer.new }
        end

        def check(assignment_id:)
          discoverer = @assignment_discoverer_factory.call
          info = discoverer.find_all(include_completed: true).find { |ai| ai.assignment.id == assignment_id }

          unless info
            return Models::AssignmentPruneCandidate.new(
              assignment_id: assignment_id,
              assignment_name: "",
              assignment_state: "not_found",
              location_path: "",
              work_terminal: false,
              reasons: ["assignment not found"]
            )
          end

          state = info.queue_state.assignment_state.to_s
          reasons = []
          reasons << "assignment still #{state}" unless state == "completed"

          work_terminal, work_reasons = terminal_work(info)
          reasons.concat(work_reasons)

          Models::AssignmentPruneCandidate.new(
            assignment_id: assignment_id,
            assignment_name: info.assignment.name,
            assignment_state: state,
            location_path: info.assignment.cache_dir,
            work_terminal: work_terminal,
            reasons: reasons
          )
        end

        private

        def terminal_work(info)
          summary = info.queue_state.summary
          unless summary.is_a?(Hash)
            return [false, ["assignment step state unreadable"]]
          end

          active = summary[:active].to_i
          pending = summary[:pending].to_i
          return [true, []] if active.zero? && pending.zero?

          [false, ["assignment has #{active} active and #{pending} pending step(s)"]]
        rescue => e
          [false, ["assignment step state unreadable: #{e.message}"]]
        end
      end
    end
  end
end
