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
      end
    end
  end
end
