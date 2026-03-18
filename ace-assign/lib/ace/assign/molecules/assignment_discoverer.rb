# frozen_string_literal: true

module Ace
  module Assign
    module Molecules
      # Discovers and enriches assignments with computed state.
      #
      # Combines AssignmentManager (file operations) with QueueScanner
      # (step scanning) to produce AssignmentInfo objects with full
      # state, progress, and current step information.
      class AssignmentDiscoverer
        # @param cache_base [String, nil] Base cache directory
        def initialize(cache_base: nil)
          @cache_base = cache_base || Ace::Assign.cache_dir
          @assignment_manager = AssignmentManager.new(cache_base: @cache_base)
          @queue_scanner = QueueScanner.new
        end

        # Find all assignments with computed state
        #
        # NOTE: Performance — This loads and enriches every assignment before filtering.
        # Acceptable for typical usage (< 50 assignments). If assignment counts grow large,
        # consider filtering by state at the manager level before enrichment to avoid
        # unnecessary QueueScanner.scan calls on completed assignments.
        #
        # @param include_completed [Boolean] Include completed assignments (default: false)
        # @return [Array<Models::AssignmentInfo>] Enriched assignments
        def find_all(include_completed: false)
          @assignment_manager.list
                             .map { |a| enrich_assignment(a) }
                             .select { |ai| include_completed || !ai.completed? }
        end

        # Find assignments by task reference (assignment name)
        #
        # @param task_ref [String] Task reference to filter by
        # @param active_only [Boolean] Only return active assignments (default: true)
        # @return [Array<Models::AssignmentInfo>] Matching assignments
        def find_by_task(task_ref:, active_only: true)
          find_all(include_completed: !active_only)
            .select { |ai| ai.assignment.name == task_ref }
        end

        private

        # Enrich an assignment with queue state to create AssignmentInfo
        #
        # @param assignment [Models::Assignment] Raw assignment
        # @return [Models::AssignmentInfo] Enriched assignment
        def enrich_assignment(assignment)
          state = @queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          Models::AssignmentInfo.new(assignment: assignment, queue_state: state)
        end
      end
    end
  end
end
