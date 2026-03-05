# frozen_string_literal: true

module Ace
  module Assign
    module Models
      # Phase data model representing a work queue item.
      #
      # Pure data carrier with no business logic (ATOM pattern).
      # All attributes are immutable after initialization.
      #
      # @example
      #   phase = Phase.new(
      #     number: "010",
      #     name: "init-project",
      #     status: :pending,
      #     instructions: "Create project structure..."
      #   )
      class Phase
        # Valid status values
        STATUSES = %i[pending in_progress done failed].freeze

        # Valid context values for execution context
        VALID_CONTEXTS = %w[fork].freeze

        attr_reader :number, :name, :status, :instructions, :report, :error,
                    :started_at, :completed_at, :added_by, :parent, :file_path, :skill, :context,
                    :fork_launch_pid, :fork_tracked_pids, :fork_pid_updated_at, :fork_pid_file,
                    :stall_reason

        # @param number [String] Phase number (e.g., "010", "010.01")
        # @param name [String] Phase name
        # @param status [Symbol] Phase status (:pending, :in_progress, :done, :failed)
        # @param instructions [String] Phase instructions (markdown)
        # @param report [String, nil] Completion report content
        # @param error [String, nil] Error message (if failed)
        # @param started_at [Time, nil] When work started
        # @param completed_at [Time, nil] When completed/failed
        # @param added_by [String, nil] How phase was added (nil, "dynamic", "retry_of:NNN")
        # @param parent [String, nil] Parent phase number (for sub-phases)
        # @param file_path [String, nil] Path to phase file
        # @param skill [String, nil] Skill reference for this phase (e.g., "ace-task-work")
        # @param context [String, nil] Execution context ("fork" for Task tool execution)
        # @param fork_launch_pid [Integer, nil] PID of the process that launched the fork run
        # @param fork_tracked_pids [Array<Integer>, nil] Observed subprocess/descendant PIDs during fork execution
        # @param fork_pid_updated_at [Time, nil] Timestamp when fork PID metadata was last updated
        # @param fork_pid_file [String, nil] Path to fork PID metadata file
        # @param stall_reason [String, nil] Last agent message captured when fork stalled
        def initialize(number:, name:, status:, instructions:, report: nil, error: nil,
                       started_at: nil, completed_at: nil, added_by: nil, parent: nil,
                       file_path: nil, skill: nil, context: nil,
                       fork_launch_pid: nil, fork_tracked_pids: nil, fork_pid_updated_at: nil,
                       fork_pid_file: nil, stall_reason: nil)
          validate_status!(status)
          validate_context!(context) if context

          @number = number.freeze
          @name = name.freeze
          @status = status
          @instructions = instructions.freeze
          @report = report&.freeze
          @error = error&.freeze
          @started_at = started_at
          @completed_at = completed_at
          @added_by = added_by&.freeze
          @parent = parent&.freeze
          @file_path = file_path&.freeze
          @skill = skill&.freeze
          @context = context&.freeze
          @fork_launch_pid = fork_launch_pid&.to_i
          @fork_tracked_pids = Array(fork_tracked_pids).map(&:to_i).uniq.sort.freeze
          @fork_pid_updated_at = fork_pid_updated_at
          @fork_pid_file = fork_pid_file&.freeze
          @stall_reason = stall_reason&.freeze
        end

        # Check if phase is complete (done or failed)
        # @return [Boolean]
        def complete?
          %i[done failed].include?(status)
        end

        # Check if phase can be worked on
        # @return [Boolean]
        def workable?
          status == :pending || status == :in_progress
        end

        # Check if this is a retry of another phase
        # @return [Boolean]
        def retry?
          added_by&.start_with?("retry_of:")
        end

        # Check if this phase should run in a forked context (subagent)
        # @return [Boolean]
        def fork?
          context == "fork"
        end

        # Get the original phase number if this is a retry
        # @return [String, nil] Original phase number
        def retry_of
          return nil unless retry?

          added_by.sub("retry_of:", "")
        end

        # Convert to frontmatter hash for YAML serialization
        # @return [Hash] Frontmatter data
        def to_frontmatter
          {
            "name" => name,
            "status" => status.to_s,
            "skill" => skill,
            "context" => context,
            "started_at" => started_at&.iso8601,
            "completed_at" => completed_at&.iso8601,
            "fork_launch_pid" => fork_launch_pid,
            "fork_tracked_pids" => fork_tracked_pids,
            "fork_pid_updated_at" => fork_pid_updated_at&.iso8601,
            "fork_pid_file" => fork_pid_file,
            "error" => error,
            "stall_reason" => stall_reason,
            "added_by" => added_by,
            "parent" => parent
          }.compact
        end

        # Convert to display row for status table
        # @return [Hash] Display row data
        def to_display_row
          {
            file: File.basename(file_path || "#{number}-#{name}.ph.md"),
            status: status.to_s,
            name: name,
            error: error
          }
        end

        private

        def validate_status!(status)
          return if STATUSES.include?(status)

          raise ArgumentError, "Invalid status: #{status}. Must be one of: #{STATUSES.join(', ')}"
        end

        def validate_context!(context)
          return if VALID_CONTEXTS.include?(context)

          raise ArgumentError, "Invalid context '#{context}'. Valid values: #{VALID_CONTEXTS.join(', ')}"
        end
      end
    end
  end
end
