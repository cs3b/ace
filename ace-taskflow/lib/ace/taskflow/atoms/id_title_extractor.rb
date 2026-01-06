# frozen_string_literal: true

require "ace/timestamp"

module Ace
  module Taskflow
    module Atoms
      # Extract ID and title from directory/file names supporting multiple ID formats
      # Supports both timestamp (YYYYMMDD-HHMMSS) and Base36 compact ID formats
      module IdTitleExtractor
        # Extract ID and title from a directory/file name
        # Supports both timestamp and compact Base36 formats
        # @param name [String] Directory or filename (without extension)
        # @param warn_deprecated [Proc] Optional callback for deprecation warnings
        # @return [Array<String, String>] [id, title] pair
        def self.extract_from_dirname(name, warn_deprecated: nil)
          # Try timestamp format first: "20250924-165837-my-idea"
          if name =~ /^(\d{8}-\d{6})-(.*)$/
            id = ::Regexp.last_match(1)
            title = ::Regexp.last_match(2).tr("-", " ").strip
            # Issue deprecation warning for old timestamp format
            warn_deprecated&.call(name)
            return [id, title]
          end

          # Try compact Base36 format: "abc123-my-idea"
          # Compact IDs are exactly 6 alphanumeric characters
          if name =~ /^([0-9a-z]{6})-(.*)$/i
            potential_id = ::Regexp.last_match(1)
            if Ace::Timestamp.detect_format(potential_id) == :compact
              id = potential_id
              title = ::Regexp.last_match(2).tr("-", " ").strip
              return [id, title]
            end
          end

          # Fallback: no recognized ID format
          # Return nil for ID and the whole name as title
          [nil, name.tr("-", " ").strip]
        end

        # Extract title from a directory/file name (ID removal only)
        # Used by retro_loader which only needs the title component
        # @param name [String] Directory or filename (without extension)
        # @return [String] Extracted title with ID prefix removed
        def self.extract_title_from_dirname(name)
          # Remove timestamp prefix: YYYYMMDD-HHMMSS-
          if name =~ /^(\d{8}-\d{6})-(.*)$/
            return $2
          end

          # Remove Base36 ID prefix with validation
          if name =~ /^([0-9a-z]{6})-(.*)$/i
            potential_id = $1
            if Ace::Timestamp.detect_format(potential_id) == :compact
              return $2
            end
          end

          # No recognized ID prefix, return name as-is
          name
        end
      end
    end
  end
end
