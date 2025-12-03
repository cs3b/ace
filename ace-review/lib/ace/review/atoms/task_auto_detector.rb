# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Extracts task ID from branch name using configurable patterns
      # Pure function - no I/O operations
      #
      # This is a simplified version of ace-prompt's TaskPathResolver.extract_from_branch
      # that doesn't require ace-taskflow integration for the extraction logic.
      class TaskAutoDetector
        # Extract task ID from branch name using configurable patterns
        # @param branch_name [String] e.g., "117-feature-name", "121.01-archive"
        # @param patterns [Array<String>|nil] Optional regex patterns (uses default if nil)
        # @return [String|nil] task ID or nil if not found
        #
        # Default pattern matches:
        #   117-feature → "117"
        #   121.01-archive → "121.01"
        # Does not match:
        #   main → nil
        #   feature-123 → nil (number not at start)
        def self.extract_from_branch(branch_name, patterns: nil)
          return nil if branch_name.nil? || branch_name.empty?
          return nil if branch_name == "HEAD" # Detached HEAD state

          # Use provided patterns or default pattern
          patterns ||= ['^(\d+(?:\.\d+)?)-']

          patterns.each do |pattern|
            begin
              regex = Regexp.new(pattern)
              match = branch_name.match(regex)
              return match[1] if match && match[1]
            rescue RegexpError => e
              warn "Warning: Invalid auto_save_branch_pattern '#{pattern}': #{e.message}"
              next
            end
          end

          nil
        end
      end
    end
  end
end
