# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module Context
      # InputFormatDetector - Molecule for detecting input format from file extension and content
      #
      # Responsibilities:
      # - Detect input format from file extension
      # - Differentiate between YAML files, agent markdown files, and regular markdown files
      # - Provide format information for processing pipeline
      class InputFormatDetector
        # Supported input formats
        FORMATS = {
          yaml: :yaml_file,
          agent_markdown: :agent_file,
          instruction_markdown: :markdown_file
        }.freeze

        # Detect input format from file path or content
        #
        # @param input [String] File path or string content
        # @return [Hash] {format: Symbol, file_path: String} or {format: Symbol, content: String}
        def detect_format(input)
          return {success: false, error: "Input cannot be nil"} if input.nil?
          return {success: false, error: "Input cannot be empty"} if input.strip.empty?

          # Check if input is a file path
          if looks_like_file_path?(input) && File.exist?(input)
            format = detect_file_format(input)
            {success: true, format: format, file_path: input}
          else
            # Treat as string content
            format = detect_content_format(input)
            {success: true, format: format, content: input}
          end
        rescue => e
          {success: false, error: "Format detection failed: #{e.message}"}
        end

        # Check if input string looks like a file path
        #
        # @param input [String] Input string
        # @return [Boolean] True if it looks like a file path
        def looks_like_file_path?(input)
          # Check for file extensions or path separators
          input.include?("/") || input.include?("\\") || input.include?(".")
        end

        # Detect format from file path
        #
        # @param file_path [String] Path to file
        # @return [Symbol] Format identifier
        def detect_file_format(file_path)
          extension = File.extname(file_path).downcase
          basename = File.basename(file_path, extension)

          case extension
          when ".yml", ".yaml"
            :yaml_file
          when ".md"
            if basename.end_with?(".ag")
              # Check content to distinguish between old and new agent formats
              if File.exist?(file_path)
                content = File.read(file_path)
                if has_context_config_tag?(content)
                  :markdown_file  # New agent format with <context-tool-config> tags
                else
                  :agent_file     # Old agent format with Context Definition sections
                end
              else
                :agent_file  # Default to old format if can't read file
              end
            else
              :markdown_file
            end
          else
            # Default to treating as markdown if it contains context tags
            if File.exist?(file_path) && has_context_config_tag?(File.read(file_path))
              :markdown_file
            else
              :unknown
            end
          end
        rescue
          :unknown
        end

        # Detect format from string content
        #
        # @param content [String] String content
        # @return [Symbol] Format identifier
        def detect_content_format(content)
          # Check for YAML content (starts with key:value or ---)
          if looks_like_yaml?(content)
            :yaml_string
          elsif has_context_config_tag?(content)
            :markdown_string
          elsif content.include?(":") && !content.include?("#")
            # Default to YAML string if it looks structured
            :yaml_string
          else
            :markdown_string
          end
        end

        # Check if content has context-tool-config tags
        #
        # @param content [String] Content to check
        # @return [Boolean] True if tags are found
        def has_context_config_tag?(content)
          content.include?("<context-tool-config>")
        end

        # Check if content looks like YAML
        #
        # @param content [String] Content to check
        # @return [Boolean] True if it looks like YAML
        def looks_like_yaml?(content)
          # Simple heuristic: starts with --- or contains key: value patterns
          trimmed = content.strip
          trimmed.start_with?("---") ||
            (trimmed.lines.any? { |line| line.match?(/^\s*\w+\s*:/) } &&
             !trimmed.include?("<context-tool-config>"))
        end

        # Get format description for display
        #
        # @param format [Symbol] Format identifier
        # @return [String] Human-readable format description
        def format_description(format)
          case format
          when :yaml_file
            "YAML template file"
          when :yaml_string
            "YAML template string"
          when :agent_file
            "Agent markdown file (.ag.md)"
          when :markdown_file
            "Instruction markdown file with <context-tool-config> tags"
          when :markdown_string
            "Markdown string with <context-tool-config> tags"
          when :unknown
            "Unknown format"
          else
            "Unrecognized format: #{format}"
          end
        end

        # Validate that format is supported for context tool
        #
        # @param format [Symbol] Format identifier
        # @return [Boolean] True if format is supported
        def supported_format?(format)
          [:yaml_file, :yaml_string, :agent_file, :markdown_file, :markdown_string].include?(format)
        end
      end
    end
  end
end
