# frozen_string_literal: true

module Ace
  module Taskflow
    module Commands
      # Shared helper methods for command classes
      module Helpers
        private

        # Filter glob patterns to only include those relevant to a specific type directory
        # @param glob [Array, nil] Array of glob patterns
        # @param type_dir [String] The type directory (e.g., "tasks", "ideas")
        # @return [Array, nil] Filtered glob patterns or nil if empty
        def filter_glob_by_type(glob, type_dir)
          return nil unless glob.is_a?(Array)

          filtered = glob.select { |pattern| pattern.start_with?("#{type_dir}/") || !pattern.include?('/') }
          filtered.empty? ? nil : filtered
        end

        # Strip task ID prefix from title (e.g., "122.04 - Orchestration Workflow" -> "Orchestration Workflow")
        # Handles patterns like: "122 - Title", "122.04 - Title", "122.04- Title", "122.04 – Title"
        # @param title [String, nil] Title potentially with ID prefix
        # @return [String, nil] Title without ID prefix
        def strip_task_id_from_title(title)
          return title unless title

          title.sub(/^\d+(\.\d+)?\s*[-–]\s*/, "")
        end
      end
    end
  end
end
