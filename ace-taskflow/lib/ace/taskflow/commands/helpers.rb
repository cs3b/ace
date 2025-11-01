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
      end
    end
  end
end
