# frozen_string_literal: true

module CodingAgentTools
  module Models
    module Code
      # Represents a code review session with all its metadata
      # This is a pure data structure with no external dependencies
      ReviewSession = Struct.new(
        :session_id,      # Unique identifier for the session
        :session_name,    # Human-readable session name (e.g., "code-HEAD~1..HEAD-20240106-143052")
        :timestamp,       # ISO8601 timestamp when session was created
        :directory_path,  # Full path to session directory
        :focus,           # Review focus: 'code', 'tests', 'docs', or combination
        :target,          # Target specification: git range, file pattern, or special keyword
        :context_mode,    # Context loading mode: 'auto', 'none', or custom path
        :metadata,        # Additional metadata hash
        keyword_init: true
      ) do
        # Validate required fields
        def validate!
          raise ArgumentError, "session_id is required" if session_id.nil? || session_id.empty?
          raise ArgumentError, "session_name is required" if session_name.nil? || session_name.empty?
          raise ArgumentError, "timestamp is required" if timestamp.nil?
          raise ArgumentError, "directory_path is required" if directory_path.nil? || directory_path.empty?
          raise ArgumentError, "focus is required" if focus.nil? || focus.empty?
          raise ArgumentError, "target is required" if target.nil? || target.empty?
          true
        end

        # Check if session has multiple focus areas
        def multi_focus?
          focus.include?(" ")
        end

        # Get array of focus areas
        def focus_areas
          focus.split(" ")
        end

        # Get context mode with default
        def context_mode_with_default
          context_mode || "auto"
        end
      end
    end
  end
end
