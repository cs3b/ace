# frozen_string_literal: true

module Ace
  module Coworker
    module Models
      # Queue state model representing a snapshot of the work queue.
      #
      # Pure data carrier with no business logic (ATOM pattern).
      # Provides convenient accessors for queue analysis.
      #
      # @example
      #   state = QueueState.new(steps: steps, session: session)
      #   state.current  # => Step with status :in_progress
      #   state.pending  # => Array of pending steps
      class QueueState
        attr_reader :steps, :session

        # @param steps [Array<Step>] All steps in queue order
        # @param session [Session] Session metadata
        def initialize(steps:, session:)
          @steps = steps.freeze
          @session = session
          @children_index = build_children_index(steps)
        end

        # Get current in-progress step
        # @return [Step, nil] Current step or nil
        def current
          steps.find { |s| s.status == :in_progress }
        end

        # Get all pending steps
        # @return [Array<Step>] Pending steps
        def pending
          steps.select { |s| s.status == :pending }
        end

        # Get all done steps
        # @return [Array<Step>] Completed steps
        def done
          steps.select { |s| s.status == :done }
        end

        # Get all failed steps
        # @return [Array<Step>] Failed steps
        def failed
          steps.select { |s| s.status == :failed }
        end

        # Get next pending step
        # @return [Step, nil] Next step to work on
        def next_pending
          pending.first
        end

        # Check if queue is empty
        # @return [Boolean]
        def empty?
          steps.empty?
        end

        # Check if all steps are complete (no pending or in_progress)
        # @return [Boolean]
        def complete?
          steps.all?(&:complete?)
        end

        # Get step by number
        # @param number [String] Step number (e.g., "010", "040")
        # @return [Step, nil] Found step
        def find_by_number(number)
          # Normalize to string without leading zeros for comparison
          normalized = number.to_s.sub(/^0+/, "")
          steps.find do |s|
            s.number.sub(/^0+/, "") == normalized || s.number == number.to_s
          end
        end

        # Get last step in queue
        # @return [Step, nil] Last step
        def last
          steps.last
        end

        # Get last completed step
        # @return [Step, nil] Last done step
        def last_done
          done.last
        end

        # Total step count
        # @return [Integer] Number of steps
        def size
          steps.size
        end

        # Summary for display
        # @return [Hash] Summary statistics
        def summary
          {
            total: size,
            done: done.size,
            in_progress: current ? 1 : 0,
            pending: pending.size,
            failed: failed.size
          }
        end

        # Get all direct children of a step (O(1) via index)
        # @param parent_number [String] Parent step number
        # @return [Array<Step>] Direct child steps
        def children_of(parent_number)
          @children_index[parent_number] || []
        end

        # Get all descendants (children, grandchildren, etc.) of a step
        # @param parent_number [String] Parent step number
        # @return [Array<Step>] All descendant steps
        def descendants_of(parent_number)
          steps.select { |s| Atoms::JobNumbering.child_of?(s.number, parent_number) }
        end

        # Check if a step has any incomplete children
        # @param parent_number [String] Parent step number
        # @return [Boolean] True if any child is not done
        def has_incomplete_children?(parent_number)
          children_of(parent_number).any? { |s| s.status != :done }
        end

        # Get next workable step considering hierarchy.
        # A step is workable if it's pending and has no incomplete children.
        # Prefers children of current/recent work.
        # @return [Step, nil] Next step to work on
        def next_workable
          # First, find pending steps
          pending_steps = pending

          # Filter to steps that don't have incomplete children
          workable = pending_steps.reject { |s| has_incomplete_children?(s.number) }

          # Return first workable step (already sorted by number)
          workable.first
        end

        # Get all step numbers as an array
        # @return [Array<String>] All step numbers
        def all_numbers
          steps.map(&:number)
        end

        # Get top-level (root) steps only
        # @return [Array<Step>] Steps with no parent
        def top_level
          steps.select { |s| Atoms::JobNumbering.top_level?(s.number) }
        end

        # Build hierarchical structure for display
        # @return [Array<Hash>] Nested structure with :step and :children keys
        def hierarchical
          build_hierarchy(nil)
        end

        private

        # Build index of children by parent number for O(1) lookups
        # @param steps [Array<Step>] All steps
        # @return [Hash<String, Array<Step>>] Parent number => children mapping
        def build_children_index(steps)
          index = Hash.new { |h, k| h[k] = [] }
          steps.each do |step|
            parsed = Atoms::JobNumbering.parse(step.number)
            index[parsed[:parent]] << step if parsed[:parent]
          end
          index
        end

        def build_hierarchy(parent_number)
          parent_steps = if parent_number.nil?
                           top_level
                         else
                           children_of(parent_number)
                         end

          parent_steps.map do |step|
            {
              step: step,
              children: build_hierarchy(step.number)
            }
          end
        end
      end
    end
  end
end
