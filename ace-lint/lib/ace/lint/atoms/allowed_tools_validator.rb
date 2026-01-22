# frozen_string_literal: true

module Ace
  module Lint
    module Atoms
      # Validates allowed-tools entries against known tools list
      # Handles both simple tool names and Bash(prefix:*) patterns
      class AllowedToolsValidator
        # Pattern to match Bash(prefix:*) format
        # e.g., "Bash(ace-git:*)", "Bash(npm:*)"
        BASH_PATTERN_REGEX = /\ABash\(([^:]+):\*\)\z/

        class << self
          # Validate allowed-tools array
          # @param tools [Array<String>, String] Tool entries to validate
          # @param known_tools [Array<String>] List of known tool names
          # @param known_bash_prefixes [Array<String>] List of known Bash command prefixes
          # @return [Array<Hash>] List of validation errors with :tool and :message
          def validate(tools, known_tools:, known_bash_prefixes:)
            errors = []

            # Handle string format (comma-separated)
            tools_array = normalize_tools(tools)

            tools_array.each do |tool|
              tool = tool.to_s.strip
              next if tool.empty?

              error = validate_single_tool(tool, known_tools, known_bash_prefixes)
              errors << error if error
            end

            errors
          end

          private

          # Normalize tools to array format
          # @param tools [Array, String, nil] Tools in various formats
          # @return [Array<String>] Normalized array of tool names
          def normalize_tools(tools)
            case tools
            when Array
              tools.flatten
            when String
              # Handle comma-separated string format from workflow files
              tools.split(",").map(&:strip)
            when nil
              []
            else
              [tools.to_s]
            end
          end

          # Validate a single tool entry
          # @param tool [String] Tool name or Bash pattern
          # @param known_tools [Array<String>] Known tool names
          # @param known_bash_prefixes [Array<String>] Known Bash prefixes
          # @return [Hash, nil] Error hash or nil if valid
          def validate_single_tool(tool, known_tools, known_bash_prefixes)
            # Check for Bash(prefix:*) pattern
            if (match = tool.match(BASH_PATTERN_REGEX))
              prefix = match[1]
              return validate_bash_prefix(prefix, known_bash_prefixes)
            end

            # Check for simple tool name
            validate_tool_name(tool, known_tools)
          end

          # Validate a Bash prefix
          # @param prefix [String] The Bash command prefix
          # @param known_prefixes [Array<String>] Known prefixes
          # @return [Hash, nil] Error hash or nil if valid
          def validate_bash_prefix(prefix, known_prefixes)
            return nil if known_prefixes.include?(prefix)

            {
              tool: "Bash(#{prefix}:*)",
              message: "Unknown Bash prefix '#{prefix}'. Known prefixes: #{known_prefixes.first(5).join(", ")}... (#{known_prefixes.size} total)"
            }
          end

          # Validate a simple tool name
          # @param tool [String] Tool name
          # @param known_tools [Array<String>] Known tools
          # @return [Hash, nil] Error hash or nil if valid
          def validate_tool_name(tool, known_tools)
            return nil if known_tools.include?(tool)

            {
              tool: tool,
              message: "Unknown tool '#{tool}'. Known tools: #{known_tools.first(5).join(", ")}... (#{known_tools.size} total)"
            }
          end
        end
      end
    end
  end
end
