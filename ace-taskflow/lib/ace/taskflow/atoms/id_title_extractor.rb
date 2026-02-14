# frozen_string_literal: true

require "ace/b36ts"

module Ace
  module Taskflow
    module Atoms
      # Extract ID and title from directory/file names using Base36 compact ID format
      # Format: 6-character Base36 ID followed by hyphen and title (e.g., "abc123-my-idea")
      module IdTitleExtractor
        # Extract ID and title from a directory/file name
        # Only supports Base36 compact format (6 alphanumeric characters)
        # @param name [String] Directory or filename (without extension)
        # @return [Array<String, String>] [id, title] pair
        def self.extract_from_dirname(name, **)
          case name
          in /^([0-9a-z]{6})-(.*)$/i
            # Compact Base36 format: "abc123-my-idea"
            # Validate it's actually a Base36 compact ID
            potential_id = $1
            if Ace::B36ts.detect_format(potential_id) == :"2sec"
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
          in /^([0-9a-z]{6})-(.*)$/i
            # Remove Base36 ID prefix with validation
            potential_id = $1
            if Ace::B36ts.detect_format(potential_id) == :"2sec"
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
