# frozen_string_literal: true

module Ace
  module Task
    module Atoms
      # Builds default frontmatter hash for new tasks matching the task schema.
      module TaskFrontmatterDefaults
        VALID_STATUSES = %w[pending in-progress done blocked draft skipped cancelled].freeze
        VALID_PRIORITIES = %w[critical high medium low].freeze

        # Build a frontmatter hash with defaults for missing values.
        #
        # @param id [String] Formatted task ID (required)
        # @param status [String] Task status (default: "pending")
        # @param priority [String, nil] Priority level
        # @param tags [Array<String>] Tags
        # @param dependencies [Array<String>] Dependency task IDs
        # @param created_at [Time, nil] Creation time
        # @param parent [String, nil] Parent task ID for subtasks
        # @return [Hash] Frontmatter hash
        def self.build(id:, status: "pending", priority: nil, tags: [], dependencies: [], created_at: nil, parent: nil)
          fm = {
            "id" => id,
            "status" => status || "pending",
            "priority" => priority || "medium",
            "created_at" => format_time(created_at)
          }
          fm["estimate"] = nil
          fm["dependencies"] = dependencies || []
          fm["tags"] = tags || []
          fm["parent"] = parent if parent
          fm
        end

        # Format time for frontmatter
        # @param time [Time, nil]
        # @return [String, nil]
        def self.format_time(time)
          return nil unless time

          time.strftime("%Y-%m-%d %H:%M:%S")
        end
      end
    end
  end
end
