# frozen_string_literal: true

require "open3"
require "timeout"

module CodingAgentTools
  module Molecules
    # ToolMetadataExtractor - Molecule for extracting metadata from executable tools
    #
    # Responsibilities:
    # - Extract descriptions from tool --help output
    # - Parse command-line help information
    # - Handle various help output formats
    # - Provide fallback descriptions for tools without help
    class ToolMetadataExtractor
      HELP_FLAGS = ["--help", "-h", "help"].freeze
      TIMEOUT_SECONDS = 5

      def initialize
        @description_cache = {}
      end

      # Extracts description from a tool's --help output
      #
      # @param tool_path [String] Path to the executable tool
      # @return [String] Description of the tool
      def extract_description(tool_path)
        return @description_cache[tool_path] if @description_cache.key?(tool_path)

        description = try_extract_description(tool_path)
        @description_cache[tool_path] = description
        description
      end

      private

      def try_extract_description(tool_path)
        tool_name = File.basename(tool_path)

        # Try different help flags
        HELP_FLAGS.each do |help_flag|
          description = extract_from_help_output(tool_path, help_flag)
          return description if description && !description.empty?
        end

        # Fallback to generic description based on tool name
        generate_fallback_description(tool_name)
      rescue => e
        # If all extraction methods fail, provide a generic description
        "CLI tool (description unavailable: #{e.message})"
      end

      def extract_from_help_output(tool_path, help_flag)
        stdout, stderr, status = Open3.capture3(
          tool_path, help_flag,
          timeout: TIMEOUT_SECONDS,
          chdir: File.dirname(tool_path)
        )

        return nil unless status.success?

        # Parse the help output to extract description
        parse_help_output(stdout, stderr, File.basename(tool_path))
      rescue Timeout::Error
        nil
      rescue => e
        # Log error but don't fail - we'll try other methods
        nil
      end

      def parse_help_output(stdout, stderr, tool_name)
        output = stdout.empty? ? stderr : stdout
        return nil if output.empty?

        lines = output.split("\n").map(&:strip)

        # Look for description patterns in help output
        description = find_description_in_lines(lines, tool_name)
        
        # Clean up and format the description
        clean_description(description) if description
      end

      def find_description_in_lines(lines, tool_name)
        # Pattern 1: dry-cli style "desc" line
        lines.each do |line|
          if line.match(/^desc\s*[:"]\s*(.+?)["']?$/i)
            return $1
          elsif line.match(/^description\s*[:"]\s*(.+?)["']?$/i)
            return $1
          end
        end

        # Pattern 2: First non-empty line after usage that looks like a description
        usage_found = false
        lines.each do |line|
          if line.match(/^usage:/i) || line.match(/^#{Regexp.escape(tool_name)}/i)
            usage_found = true
            next
          end

          next unless usage_found
          next if line.empty?
          next if line.match(/^(options?|arguments?|examples?|commands?):/i)
          next if line.start_with?("-") # Skip option lines

          # This looks like a description line
          return line if line.length > 10 && line.match?(/[a-z]/)
        end

        # Pattern 3: Look for lines that start with capital letters and contain spaces
        lines.each do |line|
          next if line.length < 10
          next if line.match?(/^[-\w]+:/) # Skip section headers
          next if line.start_with?("-") # Skip options
          
          if line.match?(/^[A-Z][^:]*[a-z]/) && line.include?(" ")
            return line
          end
        end

        nil
      end

      def clean_description(description)
        # Remove quotes and clean up whitespace
        cleaned = description.gsub(/^["']|["']$/, "").strip
        
        # Ensure it ends with a period if it doesn't already have punctuation
        unless cleaned.match?(/[.!?]$/)
          cleaned += "."
        end

        # Capitalize first letter
        cleaned[0] = cleaned[0].upcase if cleaned.length > 0

        cleaned
      end

      def generate_fallback_description(tool_name)
        # Generate description based on tool name patterns
        case tool_name
        when /^git-(.+)/
          "Enhanced git #{$1} with additional functionality."
        when /^llm-(.+)/
          "LLM integration tool for #{$1.tr('-', ' ')}."
        when /^nav-(.+)/
          "Navigation tool for #{$1.tr('-', ' ')}."
        when /^task-(.+)/
          "Task management tool for #{$1.tr('-', ' ')}."
        when /^code-(.+)/
          "Code #{$1.tr('-', ' ')} tool."
        when /^release-(.+)/
          "Release management tool for #{$1.tr('-', ' ')}."
        when /^reflection-(.+)/
          "Reflection and analysis tool for #{$1.tr('-', ' ')}."
        when "handbook"
          "Development handbook access and management tool."
        else
          "Development automation tool."
        end
      end
    end
  end
end