# frozen_string_literal: true

module CodingAgentTools
  module Models
    # Represents a Claude command with all its attributes
    # This is a pure data carrier with no behavior or external dependencies
    ClaudeCommand = Struct.new(
      :name,           # String - Command name without extension
      :type,           # String - custom, generated, or missing
      :path,           # String - Relative path from project root (optional)
      :installed,      # Boolean - Whether installed in .claude/commands
      :valid,          # Boolean - Whether command is valid
      :size,           # Integer - File size in bytes (optional)
      :modified,       # Time - Last modification time (optional)
      :modified_iso,   # String - ISO format timestamp (optional)
      keyword_init: true
    ) do
      # Optional: Add convenience methods for data access
      def missing?
        type == "missing"
      end

      def custom?
        type == "custom"
      end

      def generated?
        type == "generated"
      end

      def to_h
        super.compact # Remove nil values
      end
    end
  end
end
