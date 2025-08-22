# frozen_string_literal: true

require_relative "../../atoms/context/template_parser"
require_relative "../../error"

module CodingAgentTools
  module Molecules
    module Context
      # MarkdownYamlExtractor - Molecule for extracting YAML from <context-tool-config> tagged blocks
      #
      # Responsibilities:
      # - Extract YAML configuration from <context-tool-config> blocks in markdown
      # - Handle multiple blocks with precedence rules (first block wins)
      # - Parse extracted YAML and validate structure
      # - Provide backward compatibility with existing Context Definition sections
      class MarkdownYamlExtractor
        # Initialize extractor with template parser
        def initialize
          @template_parser = CodingAgentTools::Atoms::Context::TemplateParser.new
        end

        # Extract YAML from markdown content with tagged blocks
        #
        # @param content [String] Markdown content
        # @return [Hash] {success: Boolean, template: Hash, yaml_content: String, source_format: Symbol, error: String}
        def extract_yaml_from_markdown(content)
          return {success: false, error: "Content cannot be nil"} if content.nil?
          return {success: false, error: "Content cannot be empty"} if content.strip.empty?

          # Try new tagged format first
          tagged_result = extract_from_tagged_blocks(content)
          return tagged_result if tagged_result[:success]

          # Fall back to legacy Context Definition format for backward compatibility
          legacy_result = extract_from_context_definition(content)
          return legacy_result if legacy_result[:success]

          # If neither format succeeds, return the most specific error
          # Prioritize tagged block errors if blocks were found (parsing issues)
          # Otherwise use the generic "no configuration found" error
          if !find_context_tool_config_blocks(content).empty?
            tagged_result  # Return the tagged block parsing error
          elsif /^## Context Definition\s*\n/m.match?(content)
            legacy_result  # Return the legacy parsing error
          else
            # If neither format is found
            {
              success: false,
              error: "No <context-tool-config> blocks or Context Definition sections found in markdown"
            }
          end
        rescue => e
          {success: false, error: "YAML extraction failed: #{e.message}"}
        end

        # Extract YAML from <context-tool-config> tagged blocks
        #
        # @param content [String] Markdown content
        # @return [Hash] Extraction result
        def extract_from_tagged_blocks(content)
          blocks = find_context_tool_config_blocks(content)

          if blocks.empty?
            return {success: false, error: "No <context-tool-config> blocks found"}
          end

          # Use first block found, warn about others
          yaml_content = blocks.first
          warning = (blocks.length > 1) ? "Multiple <context-tool-config> blocks found, using first one" : nil

          # Parse the YAML content
          parse_result = @template_parser.parse_string(yaml_content)

          if parse_result[:success]
            result = {
              success: true,
              template: parse_result[:template],
              yaml_content: yaml_content,
              source_format: :tagged_blocks,
              total_blocks: blocks.length
            }
            result[:warning] = warning if warning
            result
          else
            {
              success: false,
              error: "Failed to parse YAML from <context-tool-config> block: #{parse_result[:error]}",
              yaml_content: yaml_content,
              source_format: :tagged_blocks
            }
          end
        end

        # Extract YAML from legacy Context Definition section (backward compatibility)
        #
        # @param content [String] Markdown content
        # @return [Hash] Extraction result
        def extract_from_context_definition(content)
          legacy_result = @template_parser.parse_agent_context(content)

          if legacy_result[:success]
            {
              success: true,
              template: legacy_result[:template],
              yaml_content: extract_yaml_from_legacy_section(content),
              source_format: :context_definition
            }
          else
            {
              success: false,
              error: legacy_result[:error],
              source_format: :context_definition
            }
          end
        end

        # Find all <context-tool-config> blocks in content
        #
        # @param content [String] Markdown content
        # @return [Array<String>] Array of YAML content from blocks
        def find_context_tool_config_blocks(content)
          blocks = []

          # Pattern to match <context-tool-config> blocks
          pattern = /<context-tool-config>\s*\n(.*?)\n<\/context-tool-config>/m

          content.scan(pattern) do |match|
            yaml_content = match[0].strip
            blocks << yaml_content unless yaml_content.empty?
          end

          blocks
        end

        # Extract YAML content from legacy Context Definition section
        #
        # @param content [String] Markdown content
        # @return [String] YAML content or empty string
        def extract_yaml_from_legacy_section(content)
          # Look for Context Definition section
          context_match = content.match(/^## Context Definition\s*\n(.*?)(?=^## |\z)/m)
          return "" unless context_match

          context_section = context_match[1].strip

          # Extract YAML from code blocks
          yaml_match = context_section.match(/```(?:yaml|yml)?\s*\n(.*?)\n```/m)
          return "" unless yaml_match

          yaml_match[1]
        end

        # Check if content has any extractable YAML configuration
        #
        # @param content [String] Markdown content
        # @return [Boolean] True if extractable configuration found
        def has_extractable_config?(content)
          return false if content.nil? || content.strip.empty?

          # Check for tagged blocks
          return true unless find_context_tool_config_blocks(content).empty?

          # Check for legacy format
          context_match = content.match(/^## Context Definition\s*\n(.*?)(?=^## |\z)/m)
          return false unless context_match

          # Check if Context Definition has YAML blocks
          context_section = context_match[1].strip
          yaml_match = context_section.match(/```(?:yaml|yml)?\s*\n(.*?)\n```/m)
          !yaml_match.nil?
        end

        # Get extraction summary for display
        #
        # @param extraction_result [Hash] Result from extract_yaml_from_markdown
        # @return [String] Human-readable summary
        def extraction_summary(extraction_result)
          return "Extraction failed: #{extraction_result[:error]}" unless extraction_result[:success]

          lines = []
          lines << "YAML extracted successfully:"

          case extraction_result[:source_format]
          when :tagged_blocks
            lines << "  Source: <context-tool-config> tagged blocks"
            if extraction_result[:total_blocks] && extraction_result[:total_blocks] > 1
              lines << "  Blocks found: #{extraction_result[:total_blocks]} (using first)"
            end
          when :context_definition
            lines << "  Source: Legacy Context Definition section"
          end

          if extraction_result[:template]
            template = extraction_result[:template]
            lines << "  Files: #{template[:files].length} pattern(s)"
            lines << "  Commands: #{template[:commands].length} command(s)"
            lines << "  Format: #{template[:format] || "default"}"
          end

          if extraction_result[:warning]
            lines << "  Warning: #{extraction_result[:warning]}"
          end

          lines.join("\n")
        end

        # Validate that a markdown document has properly formatted context configuration
        #
        # @param content [String] Markdown content
        # @return [Hash] Validation result
        def validate_markdown_config(content)
          return {valid: false, error: "Content cannot be nil"} if content.nil?
          return {valid: false, error: "Content cannot be empty"} if content.strip.empty?

          # Check for extractable configuration
          unless has_extractable_config?(content)
            return {
              valid: false,
              error: "No <context-tool-config> blocks or Context Definition sections found"
            }
          end

          # Try to extract and parse
          extraction_result = extract_yaml_from_markdown(content)

          if extraction_result[:success]
            {
              valid: true,
              source_format: extraction_result[:source_format],
              template: extraction_result[:template],
              total_blocks: extraction_result[:total_blocks],
              warning: extraction_result[:warning]
            }
          else
            {
              valid: false,
              error: extraction_result[:error],
              source_format: extraction_result[:source_format]
            }
          end
        rescue => e
          {valid: false, error: "Validation failed: #{e.message}"}
        end
      end
    end
  end
end
