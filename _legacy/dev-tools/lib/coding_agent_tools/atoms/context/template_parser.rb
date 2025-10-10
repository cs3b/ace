# frozen_string_literal: true

require_relative "../yaml_reader"

module CodingAgentTools
  module Atoms
    module Context
      # TemplateParser - Atom for parsing YAML template structures
      #
      # Responsibilities:
      # - Parse and validate YAML template format
      # - Extract files and commands lists from templates
      # - Provide standardized template structure validation
      class TemplateParser
        # Expected template structure
        VALID_KEYS = %w[files commands format embed_document_source].freeze

        # Parse YAML template from file
        #
        # @param file_path [String] Path to YAML template file
        # @return [Hash] {success: Boolean, template: Hash, error: String}
        def parse_file(file_path)
          return {success: false, error: "File path cannot be nil"} if file_path.nil?
          return {success: false, error: "File not found: #{file_path}"} unless File.exist?(file_path)

          begin
            parsed_yaml = CodingAgentTools::Atoms::YamlReader.read_file(file_path)
            validate_and_normalize_template(parsed_yaml)
          rescue CodingAgentTools::Error => e
            {success: false, error: e.message}
          rescue => e
            {success: false, error: "Failed to parse template file: #{e.message}"}
          end
        end

        # Parse YAML template from string
        #
        # @param yaml_string [String] YAML template content
        # @return [Hash] {success: Boolean, template: Hash, error: String}
        def parse_string(yaml_string)
          return {success: false, error: "YAML string cannot be nil"} if yaml_string.nil?
          return {success: false, error: "YAML string cannot be empty"} if yaml_string.strip.empty?

          begin
            parsed_yaml = CodingAgentTools::Atoms::YamlReader.parse_content(yaml_string)
            validate_and_normalize_template(parsed_yaml)
          rescue CodingAgentTools::Error => e
            {success: false, error: e.message}
          rescue => e
            {success: false, error: "Failed to parse template string: #{e.message}"}
          end
        end

        # Extract context definition from agent markdown file
        #
        # @param agent_content [String] Agent markdown content
        # @return [Hash] {success: Boolean, template: Hash, error: String}
        def parse_agent_context(agent_content)
          return {success: false, error: "Agent content cannot be nil"} if agent_content.nil?

          # Look for Context Definition section in markdown
          context_match = agent_content.match(/^## Context Definition\s*\n(.*?)(?=^## |\z)/m)

          unless context_match
            return {success: false, error: "No 'Context Definition' section found in agent file"}
          end

          context_section = context_match[1].strip

          # Extract YAML from code blocks
          yaml_match = context_section.match(/```(?:yaml|yml)?\s*\n(.*?)\n```/m)

          unless yaml_match
            return {success: false, error: "No YAML code block found in Context Definition section"}
          end

          yaml_content = yaml_match[1]
          parse_string(yaml_content)
        rescue => e
          {success: false, error: "Failed to parse agent context: #{e.message}"}
        end

        # Parse markdown with <context-tool-config> tags (new format)
        #
        # @param markdown_content [String] Markdown content with tagged blocks
        # @return [Hash] {success: Boolean, template: Hash, error: String}
        def parse_markdown_with_tags(markdown_content)
          return {success: false, error: "Markdown content cannot be nil"} if markdown_content.nil?

          # Find <context-tool-config> blocks
          pattern = /<context-tool-config>\s*\n(.*?)\n<\/context-tool-config>/m
          match = markdown_content.match(pattern)

          unless match
            return {success: false, error: "No <context-tool-config> block found in markdown"}
          end

          yaml_content = match[1].strip
          parse_string(yaml_content)
        rescue => e
          {success: false, error: "Failed to parse markdown with tags: #{e.message}"}
        end

        private

        # Validate and normalize template structure
        #
        # @param parsed_yaml [Hash] Parsed YAML content
        # @return [Hash] {success: Boolean, template: Hash, error: String}
        def validate_and_normalize_template(parsed_yaml)
          return {success: false, error: "Template must be a Hash"} unless parsed_yaml.is_a?(Hash)

          # Check for unknown keys
          unknown_keys = parsed_yaml.keys - VALID_KEYS
          unless unknown_keys.empty?
            return {success: false, error: "Unknown template keys: #{unknown_keys.join(", ")}"}
          end

          # Normalize template structure
          normalized_template = {
            files: normalize_files_list(parsed_yaml["files"]),
            commands: normalize_commands_list(parsed_yaml["commands"]),
            format: parsed_yaml["format"],
            embed_document_source: parsed_yaml["embed_document_source"]
          }

          # Validate that at least files or commands are specified
          if normalized_template[:files].empty? && normalized_template[:commands].empty?
            return {success: false, error: "Template must specify at least 'files' or 'commands'"}
          end

          {success: true, template: normalized_template}
        rescue => e
          {success: false, error: "Template validation failed: #{e.message}"}
        end

        # Normalize files list to array of strings
        #
        # @param files_value [nil, String, Array] Files specification
        # @return [Array<String>] Normalized files list
        def normalize_files_list(files_value)
          case files_value
          when nil
            []
          when String
            [files_value]
          when Array
            files_value.map(&:to_s)
          else
            raise ArgumentError, "'files' must be a string or array of strings"
          end
        end

        # Normalize commands list to array of strings
        #
        # @param commands_value [nil, String, Array] Commands specification
        # @return [Array<String>] Normalized commands list
        def normalize_commands_list(commands_value)
          case commands_value
          when nil
            []
          when String
            [commands_value]
          when Array
            commands_value.map(&:to_s)
          else
            raise ArgumentError, "'commands' must be a string or array of strings"
          end
        end
      end
    end
  end
end
