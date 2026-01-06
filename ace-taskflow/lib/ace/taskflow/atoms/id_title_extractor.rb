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
          case name
          in /^(\d{8}-\d{6})-(.*)$/
            # Timestamp format: "20250924-165837-my-idea"
            id = $1
            title = $2.tr("-", " ").strip
            warn_deprecated&.call(name)
            [id, title]
          in /^([0-9a-z]{6})-(.*)$/i
            # Compact Base36 format: "abc123-my-idea"
            # Validate it's actually a Base36 compact ID
            potential_id = $1
            if Ace::Timestamp.detect_format(potential_id) == :compact
              title = $2.tr("-", " ").strip
              [potential_id, title]
            else
              # Not a valid Base36 ID, treat as no ID
              [nil, name.tr("-", " ").strip]
            end
          else
            # No recognized ID format
            [nil, name.tr("-", " ").strip]
          end
        end

        # Extract title from a directory/file name (ID removal only)
        # Used by retro_loader which only needs the title component
        # @param name [String] Directory or filename (without extension)
        # @return [String] Extracted title with ID prefix removed
        def self.extract_title_from_dirname(name)
          case name
          in /^(\d{8}-\d{6})-(.*)$/
            # Remove timestamp prefix: YYYYMMDD-HHMMSS-
            $2
          in /^([0-9a-z]{6})-(.*)$/i
            # Remove Base36 ID prefix with validation
            potential_id = $1
            if Ace::Timestamp.detect_format(potential_id) == :compact
              $2
            else
              name
            end
          else
            # No recognized ID prefix, return name as-is
            name
          end
        end
      end
    end
  end
end
