# frozen_string_literal: true

module Ace
  module Assign
    module Models
      # Enriched assignment model combining Assignment + QueueState.
      #
      # Pure data carrier with computed state (ATOM pattern).
      # Wraps an assignment with its queue state to provide
      # computed state, progress, and current step information.
      #
      # @example
      #   info = AssignmentInfo.new(assignment: assignment, queue_state: state)
      #   info.state          # => :running
      #   info.progress       # => "2/5"
      #   info.current_step  # => "020-implement"
      class AssignmentInfo
        attr_reader :assignment, :queue_state

        # @param assignment [Assignment] Assignment metadata
        # @param queue_state [QueueState] Queue state for this assignment
        def initialize(assignment:, queue_state:)
          @assignment = assignment
          @queue_state = queue_state
        end

        # Computed assignment state
        #
        # @return [Symbol] :empty, :failed, :completed, :running, or :paused
        def state
          queue_state.assignment_state
        end

        # Progress string (done/total)
        #
        # @return [String] Progress display (e.g., "2/5")
        def progress
          s = queue_state.summary
          "#{s[:done]}/#{s[:total]}"
        end

        # Current step display string
        #
        # @return [String] Current step name or "-"
        def current_step
          queue_state.current&.name || "-"
        end

        # Check if assignment is completed
        #
        # @return [Boolean]
        def completed?
          state == :completed
        end

        # Delegate common accessors to assignment
        def id = assignment.id
        def name = assignment.name
        def task_ref = assignment.name
        def updated_at = assignment.updated_at
        def created_at = assignment.created_at
        def parent = assignment.parent
      end
    end
  end
end
