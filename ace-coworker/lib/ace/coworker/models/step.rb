# frozen_string_literal: true

module Ace
  module Coworker
    module Models
      # Step data model representing a work queue item.
      #
      # Pure data carrier with no business logic (ATOM pattern).
      # All attributes are immutable after initialization.
      #
      # @example
      #   step = Step.new(
      #     number: "010",
      #     name: "init-project",
      #     status: :pending,
      #     instructions: "Create project structure..."
      #   )
      class Step
        # Valid status values
        STATUSES = %i[pending in_progress done failed].freeze

        attr_reader :number, :name, :status, :instructions, :report, :error,
                    :started_at, :completed_at, :added_by, :parent, :file_path

        # @param number [String] Step number (e.g., "010", "010.01")
        # @param name [String] Step name
        # @param status [Symbol] Step status (:pending, :in_progress, :done, :failed)
        # @param instructions [String] Step instructions (markdown)
        # @param report [String, nil] Completion report content
        # @param error [String, nil] Error message (if failed)
        # @param started_at [Time, nil] When work started
        # @param completed_at [Time, nil] When completed/failed
        # @param added_by [String, nil] How step was added (nil, "dynamic", "retry_of:NNN")
        # @param parent [String, nil] Parent task number (for subtasks)
        # @param file_path [String, nil] Path to step file
        def initialize(number:, name:, status:, instructions:, report: nil, error: nil,
                       started_at: nil, completed_at: nil, added_by: nil, parent: nil,
                       file_path: nil)
          validate_status!(status)

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
        end

        # Check if step is complete (done or failed)
        # @return [Boolean]
        def complete?
          %i[done failed].include?(status)
        end

        # Check if step can be worked on
        # @return [Boolean]
        def workable?
          status == :pending || status == :in_progress
        end

        # Check if this is a retry of another step
        # @return [Boolean]
        def retry?
          added_by&.start_with?("retry_of:")
        end

        # Get the original step number if this is a retry
        # @return [String, nil] Original step number
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
            "started_at" => started_at&.iso8601,
            "completed_at" => completed_at&.iso8601,
            "error" => error,
            "added_by" => added_by,
            "parent" => parent
          }.compact
        end

        # Convert to display row for status table
        # @return [Hash] Display row data
        def to_display_row
          {
            file: File.basename(file_path || "#{number}-#{name}.md"),
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
      end
    end
  end
end
