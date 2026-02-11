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

        # Backward-compatible alias
        alias_method :steps, :phases
        alias_method :session, :assignment

        # Get current in-progress phase
        # @return [Phase, nil] Current phase or nil
        def current
          phases.find { |s| s.status == :in_progress }
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
