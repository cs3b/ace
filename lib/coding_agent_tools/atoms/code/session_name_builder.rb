# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    module Code
      # Builds session directory names from components
      # This is an atom - it has no dependencies on other gem components
      class SessionNameBuilder
        # Build session name from components
        # @param focus [String] review focus (e.g., 'code', 'tests', 'docs')
        # @param target [String] review target (e.g., 'HEAD~1..HEAD', file pattern)
        # @param timestamp [String] timestamp string
        # @return [String] formatted session name
        def build(focus, target, timestamp)
          sanitized_target = sanitize_target(target)
          "#{focus}-#{sanitized_target}-#{timestamp}"
        end

        # Build session name without timestamp
        # @param focus [String] review focus
        # @param target [String] review target
        # @return [String] formatted session name prefix
        def build_prefix(focus, target)
          sanitized_target = sanitize_target(target)
          "#{focus}-#{sanitized_target}"
        end

        private

        # Sanitize target string for use in directory names
        # @param target [String] raw target string
        # @return [String] sanitized target
        def sanitize_target(target)
          target
            .gsub(/\//, "-")           # Replace slashes with hyphens
            .gsub(/\s+/, "_")          # Replace spaces with underscores
            .gsub(/[^\w\-._]+/, "")    # Remove special characters except word chars, hyphens, dots, underscores
            .gsub(/^\.+|\.+$/, "")     # Remove leading/trailing dots
            .slice(0, 50)              # Limit length to prevent overly long names
        end
      end
    end
  end
end