# frozen_string_literal: true

module Ace
  module Assign
    module Models
      # Queue state model representing a snapshot of the work queue.
      #
      # Pure data carrier with no business logic (ATOM pattern).
      # Provides convenient accessors for queue analysis.
      #
      # @example
      #   state = QueueState.new(steps: steps, assignment: assignment)
      #   state.current  # => Step with status :in_progress
      #   state.pending  # => Array of pending steps
      class QueueState
        attr_reader :steps, :assignment

        # @param steps [Array<Step>] All steps in queue order
        # @param assignment [Assignment] Assignment metadata
        def initialize(steps:, assignment:)
          @steps = steps.freeze
          @assignment = assignment
          @children_index = build_children_index(steps)
        end

        # Get current in-progress step
        # @return [Step, nil] Current step or nil
        def current
          in_progress_steps.first
        end

        # Get all in-progress steps
        # @return [Array<Step>] In-progress steps
        def in_progress_steps
          steps.select { |s| s.status == :in_progress }
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

        # Computed assignment state based on step statuses
        #
        # States (checked in priority order):
        # - :empty     - No steps in queue
        # - :completed - All steps complete (done or failed)
        # - :failed    - Has failed step(s) but NOT all complete (stuck)
        # - :running   - Has in_progress step with recent activity (< 1 hour)
        # - :stalled   - Has in_progress step but stale (> 1 hour)
        # - :paused    - Has pending but no in_progress (interrupted)
        #
        # @return [Symbol] Assignment state
        def assignment_state
          return :empty if empty?
          return :completed if complete?
          return :failed if failed.any?
          return :running if current && recently_active?
          return :stalled if current

          :paused
        end

        # Check if the current in_progress step has recent activity
        # @param threshold [Integer] Seconds since started_at to consider active (default: 1 hour)
        # @return [Boolean]
        def recently_active?(threshold: 3600)
          return false unless current&.started_at

          (Time.now - current.started_at) < threshold
        end

        # Summary for display
        # @return [Hash] Summary statistics
        def summary
          {
            total: size,
            done: done.size,
            in_progress: in_progress_steps.size,
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
          steps.select { |s| Atoms::StepNumbering.child_of?(s.number, parent_number) }
        end

        # Check whether a step number belongs to a subtree rooted at root_number.
        #
        # @param root_number [String] Subtree root step number
        # @param step_number [String] Candidate step number
        # @return [Boolean] True when candidate is root or descendant of root
        def in_subtree?(root_number, step_number)
          step_number == root_number || Atoms::StepNumbering.child_of?(step_number, root_number)
        end

        # Get all steps in a subtree (root + descendants), preserving queue order.
        #
        # @param root_number [String] Subtree root step number
        # @return [Array<Step>] Subtree steps in queue order
        def subtree_steps(root_number)
          steps.select { |s| in_subtree?(root_number, s.number) }
        end

        # Check whether all steps in a subtree are complete.
        #
        # @param root_number [String] Subtree root step number
        # @return [Boolean] True when every subtree step is complete
        def subtree_complete?(root_number)
          scoped = subtree_steps(root_number)
          return false if scoped.empty?

          scoped.all?(&:complete?)
        end

        # Check whether a subtree has at least one failed step.
        #
        # @param root_number [String] Subtree root step number
        # @return [Boolean] True when any subtree step failed
        def subtree_failed?(root_number)
          subtree_steps(root_number).any? { |s| s.status == :failed }
        end

        # Get the current in-progress step within a subtree.
        #
        # @param root_number [String] Subtree root step number
        # @return [Step, nil] In-progress step inside subtree, if any
        def current_in_subtree(root_number)
          in_progress_in_subtree(root_number).first
        end

        # Get all in-progress steps within a subtree.
        #
        # @param root_number [String] Subtree root step number
        # @return [Array<Step>] In-progress steps inside subtree
        def in_progress_in_subtree(root_number)
          subtree_steps(root_number)
            .select { |s| s.status == :in_progress }
        end

        # Get next workable step constrained to a subtree.
        #
        # @param root_number [String] Subtree root step number
        # @return [Step, nil] Next pending workable step inside subtree
        def next_workable_in_subtree(root_number)
          subtree_steps(root_number)
            .select { |s| s.status == :pending }
            .reject { |s| has_incomplete_children?(s.number) }
            .first
        end

        # Build ancestor chain from closest parent to root.
        #
        # @param number [String] Step number
        # @return [Array<String>] Ancestor numbers, nearest first
        def ancestor_chain(number)
          chain = []
          parent = Atoms::StepNumbering.parent_of(number)
          while parent
            chain << parent
            parent = Atoms::StepNumbering.parent_of(parent)
          end
          chain
        end

        # Find nearest ancestor (or self) that has context: fork.
        #
        # @param number [String] Step number
        # @return [Step, nil] Nearest fork-scoped step
        def nearest_fork_ancestor(number)
          step = find_by_number(number)
          return nil unless step

          return step if step.fork?

          ancestor_chain(number).each do |ancestor_number|
            ancestor = find_by_number(ancestor_number)
            return ancestor if ancestor&.fork?
          end

          nil
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
          steps.select { |s| Atoms::StepNumbering.top_level?(s.number) }
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
            parsed = Atoms::StepNumbering.parse(step.number)
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
