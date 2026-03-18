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
      #   state = QueueState.new(phases: phases, assignment: assignment)
      #   state.current  # => Phase with status :in_progress
      #   state.pending  # => Array of pending phases
      class QueueState
        attr_reader :phases, :assignment

        # @param phases [Array<Phase>] All phases in queue order
        # @param assignment [Assignment] Assignment metadata
        def initialize(phases:, assignment:)
          @phases = phases.freeze
          @assignment = assignment
          @children_index = build_children_index(phases)
        end

        # Get current in-progress phase
        # @return [Phase, nil] Current phase or nil
        def current
          in_progress_phases.first
        end

        # Get all in-progress phases
        # @return [Array<Phase>] In-progress phases
        def in_progress_phases
          phases.select { |s| s.status == :in_progress }
        end

        # Get all pending phases
        # @return [Array<Phase>] Pending phases
        def pending
          phases.select { |s| s.status == :pending }
        end

        # Get all done phases
        # @return [Array<Phase>] Completed phases
        def done
          phases.select { |s| s.status == :done }
        end

        # Get all failed phases
        # @return [Array<Phase>] Failed phases
        def failed
          phases.select { |s| s.status == :failed }
        end

        # Get next pending phase
        # @return [Phase, nil] Next phase to work on
        def next_pending
          pending.first
        end

        # Check if queue is empty
        # @return [Boolean]
        def empty?
          phases.empty?
        end

        # Check if all phases are complete (no pending or in_progress)
        # @return [Boolean]
        def complete?
          phases.all?(&:complete?)
        end

        # Get phase by number
        # @param number [String] Phase number (e.g., "010", "040")
        # @return [Phase, nil] Found phase
        def find_by_number(number)
          # Normalize to string without leading zeros for comparison
          normalized = number.to_s.sub(/^0+/, "")
          phases.find do |s|
            s.number.sub(/^0+/, "") == normalized || s.number == number.to_s
          end
        end

        # Get last phase in queue
        # @return [Phase, nil] Last phase
        def last
          phases.last
        end

        # Get last completed phase
        # @return [Phase, nil] Last done phase
        def last_done
          done.last
        end

        # Total phase count
        # @return [Integer] Number of phases
        def size
          phases.size
        end

        # Computed assignment state based on phase statuses
        #
        # States (checked in priority order):
        # - :empty     - No phases in queue
        # - :completed - All phases complete (done or failed)
        # - :failed    - Has failed phase(s) but NOT all complete (stuck)
        # - :running   - Has in_progress phase with recent activity (< 1 hour)
        # - :stalled   - Has in_progress phase but stale (> 1 hour)
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

        # Check if the current in_progress phase has recent activity
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
            in_progress: in_progress_phases.size,
            pending: pending.size,
            failed: failed.size
          }
        end

        # Get all direct children of a phase (O(1) via index)
        # @param parent_number [String] Parent phase number
        # @return [Array<Phase>] Direct child phases
        def children_of(parent_number)
          @children_index[parent_number] || []
        end

        # Get all descendants (children, grandchildren, etc.) of a phase
        # @param parent_number [String] Parent phase number
        # @return [Array<Phase>] All descendant phases
        def descendants_of(parent_number)
          phases.select { |s| Atoms::PhaseNumbering.child_of?(s.number, parent_number) }
        end

        # Check whether a phase number belongs to a subtree rooted at root_number.
        #
        # @param root_number [String] Subtree root phase number
        # @param phase_number [String] Candidate phase number
        # @return [Boolean] True when candidate is root or descendant of root
        def in_subtree?(root_number, phase_number)
          phase_number == root_number || Atoms::PhaseNumbering.child_of?(phase_number, root_number)
        end

        # Get all phases in a subtree (root + descendants), preserving queue order.
        #
        # @param root_number [String] Subtree root phase number
        # @return [Array<Phase>] Subtree phases in queue order
        def subtree_phases(root_number)
          phases.select { |s| in_subtree?(root_number, s.number) }
        end

        # Check whether all phases in a subtree are complete.
        #
        # @param root_number [String] Subtree root phase number
        # @return [Boolean] True when every subtree phase is complete
        def subtree_complete?(root_number)
          scoped = subtree_phases(root_number)
          return false if scoped.empty?

          scoped.all?(&:complete?)
        end

        # Check whether a subtree has at least one failed phase.
        #
        # @param root_number [String] Subtree root phase number
        # @return [Boolean] True when any subtree phase failed
        def subtree_failed?(root_number)
          subtree_phases(root_number).any? { |s| s.status == :failed }
        end

        # Get the current in-progress phase within a subtree.
        #
        # @param root_number [String] Subtree root phase number
        # @return [Phase, nil] In-progress phase inside subtree, if any
        def current_in_subtree(root_number)
          in_progress_in_subtree(root_number).first
        end

        # Get all in-progress phases within a subtree.
        #
        # @param root_number [String] Subtree root phase number
        # @return [Array<Phase>] In-progress phases inside subtree
        def in_progress_in_subtree(root_number)
          subtree_phases(root_number)
            .select { |s| s.status == :in_progress }
        end

        # Get next workable phase constrained to a subtree.
        #
        # @param root_number [String] Subtree root phase number
        # @return [Phase, nil] Next pending workable phase inside subtree
        def next_workable_in_subtree(root_number)
          subtree_phases(root_number)
            .select { |s| s.status == :pending }
            .reject { |s| has_incomplete_children?(s.number) }
            .first
        end

        # Build ancestor chain from closest parent to root.
        #
        # @param number [String] Phase number
        # @return [Array<String>] Ancestor numbers, nearest first
        def ancestor_chain(number)
          chain = []
          parent = Atoms::PhaseNumbering.parent_of(number)
          while parent
            chain << parent
            parent = Atoms::PhaseNumbering.parent_of(parent)
          end
          chain
        end

        # Find nearest ancestor (or self) that has context: fork.
        #
        # @param number [String] Phase number
        # @return [Phase, nil] Nearest fork-scoped phase
        def nearest_fork_ancestor(number)
          phase = find_by_number(number)
          return nil unless phase

          return phase if phase.fork?

          ancestor_chain(number).each do |ancestor_number|
            ancestor = find_by_number(ancestor_number)
            return ancestor if ancestor&.fork?
          end

          nil
        end

        # Check if a phase has any incomplete children
        # @param parent_number [String] Parent phase number
        # @return [Boolean] True if any child is not done
        def has_incomplete_children?(parent_number)
          children_of(parent_number).any? { |s| s.status != :done }
        end

        # Get next workable phase considering hierarchy.
        # A phase is workable if it's pending and has no incomplete children.
        # Prefers children of current/recent work.
        # @return [Phase, nil] Next phase to work on
        def next_workable
          # First, find pending phases
          pending_phases = pending

          # Filter to phases that don't have incomplete children
          workable = pending_phases.reject { |s| has_incomplete_children?(s.number) }

          # Return first workable phase (already sorted by number)
          workable.first
        end

        # Get all phase numbers as an array
        # @return [Array<String>] All phase numbers
        def all_numbers
          phases.map(&:number)
        end

        # Get top-level (root) phases only
        # @return [Array<Phase>] Phases with no parent
        def top_level
          phases.select { |s| Atoms::PhaseNumbering.top_level?(s.number) }
        end

        # Build hierarchical structure for display
        # @return [Array<Hash>] Nested structure with :step and :children keys
        def hierarchical
          build_hierarchy(nil)
        end

        private

        # Build index of children by parent number for O(1) lookups
        # @param phases [Array<Phase>] All phases
        # @return [Hash<String, Array<Phase>>] Parent number => children mapping
        def build_children_index(phases)
          index = Hash.new { |h, k| h[k] = [] }
          phases.each do |phase|
            parsed = Atoms::PhaseNumbering.parse(phase.number)
            index[parsed[:parent]] << phase if parsed[:parent]
          end
          index
        end

        def build_hierarchy(parent_number)
          parent_phases = if parent_number.nil?
                            top_level
                          else
                            children_of(parent_number)
                          end

          parent_phases.map do |phase|
            {
              step: phase,
              children: build_hierarchy(phase.number)
            }
          end
        end
      end
    end
  end
end
