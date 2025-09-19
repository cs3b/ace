# frozen_string_literal: true

require_relative "../../atoms/yaml_reader"

module CodingAgentTools
  module Molecules
    module Agents
      # ContextDefinitionParser - Molecule for parsing embedded context definitions in agent files
      #
      # Responsibilities:
      # - Find and extract Context Definition sections from agent markdown
      # - Parse embedded YAML context templates
      # - Support external template references
      # - Validate context definition structure
      class ContextDefinitionParser
        # Result of parsing context definition
        ContextParseResult = Struct.new(
          :success?, :context_template, :error, :template_type, :source_location
        ) do
          def valid?
            success? && !context_template.nil?
          end

          def embedded?
            template_type == :embedded
          end

          def external?
            template_type == :external
          end
        end

        # Expected context template fields
        VALID_CONTEXT_FIELDS = %w[files commands format].freeze

        # Parse context definition from agent content
        #
        # @param agent_content [String] Full agent markdown content
        # @return [ContextParseResult] Parse result with context template or error
        def self.parse_from_content(agent_content)
          return ContextParseResult.new(false, nil, "Content cannot be nil", nil, nil) if agent_content.nil?

          begin
            # Look for Context Definition section in markdown
            context_section = extract_context_section(agent_content)
            return ContextParseResult.new(false, nil, "No Context Definition section found", nil, nil) unless context_section

            # Try to parse as embedded YAML
            embedded_result = parse_embedded_yaml(context_section)
            return embedded_result if embedded_result.success?

            # Try to parse as external reference
            external_result = parse_external_reference(context_section)
            return external_result if external_result.success?

            # Neither format worked
            ContextParseResult.new(
              false, nil,
              "Context Definition must contain either YAML code block or external template reference",
              nil, nil
            )
          rescue => e
            ContextParseResult.new(false, nil, "Error parsing context definition: #{e.message}", nil, nil)
          end
        end

        # Parse context definition from agent file
        #
        # @param agent_file_path [String] Path to agent markdown file
        # @return [ContextParseResult] Parse result with context template or error
        def self.parse_from_file(agent_file_path)
          return ContextParseResult.new(false, nil, "File path cannot be nil", nil, nil) if agent_file_path.nil?
          return ContextParseResult.new(false, nil, "File not found: #{agent_file_path}", nil, nil) unless File.exist?(agent_file_path)

          begin
            content = File.read(agent_file_path, encoding: "UTF-8")
            result = parse_from_content(content)

            # Update source location for file-based parsing
            if result.success?
              result.source_location = agent_file_path
            end

            result
          rescue => e
            ContextParseResult.new(false, nil, "Error reading agent file: #{e.message}", nil, agent_file_path)
          end
        end

        # Validate context template structure
        #
        # @param context_template [Hash] Context template to validate
        # @return [Hash] Validation result with :valid?, :errors, :warnings
        def self.validate_context_template(context_template)
          result = {
            valid?: true,
            errors: [],
            warnings: []
          }

          return result if context_template.nil? || context_template.empty?

          # Check for unknown fields
          if context_template.is_a?(Hash)
            unknown_fields = context_template.keys.map(&:to_s) - VALID_CONTEXT_FIELDS
            unless unknown_fields.empty?
              result[:warnings] << "Unknown context fields: #{unknown_fields.join(", ")}"
            end

            # Validate that at least files or commands are specified
            has_files = context_template["files"] && !context_template["files"].empty?
            has_commands = context_template["commands"] && !context_template["commands"].empty?

            unless has_files || has_commands
              result[:errors] << "Context template must specify at least 'files' or 'commands'"
              result[:valid?] = false
            end

            # Validate files format
            if context_template["files"]
              unless valid_string_or_array?(context_template["files"])
                result[:errors] << "Context 'files' must be a string or array of strings"
                result[:valid?] = false
              end
            end

            # Validate commands format
            if context_template["commands"]
              unless valid_string_or_array?(context_template["commands"])
                result[:errors] << "Context 'commands' must be a string or array of strings"
                result[:valid?] = false
              end
            end

            # Validate format field
            if context_template["format"]
              valid_formats = %w[xml yaml markdown-xml]
              unless valid_formats.include?(context_template["format"])
                result[:warnings] << "Unknown format '#{context_template["format"]}', expected one of: #{valid_formats.join(", ")}"
              end
            end
          else
            result[:errors] << "Context template must be a hash"
            result[:valid?] = false
          end

          result
        end

        # Convert context definition to context tool compatible format
        #
        # @param context_template [Hash] Context template from agent
        # @return [Hash] Context tool compatible template
        def self.to_context_tool_format(context_template)
          return {} unless context_template.is_a?(Hash)

          {
            files: normalize_to_array(context_template["files"]),
            commands: normalize_to_array(context_template["commands"]),
            format: context_template["format"] || "markdown-xml"
          }.compact
        end

        class << self
          private

          # Extract Context Definition section from markdown content
          def extract_context_section(content)
            # Look for Context Definition section with various heading levels
            patterns = [
              /^## Context Definition\s*\n(.*?)(?=^## |\z)/m,
              /^### Context Definition\s*\n(.*?)(?=^### |\z)/m,
              /^# Context Definition\s*\n(.*?)(?=^# |\z)/m
            ]

            patterns.each do |pattern|
              match = content.match(pattern)
              return match[1].strip if match
            end

            nil
          end

          # Parse embedded YAML from context section
          def parse_embedded_yaml(context_section)
            # Look for YAML code blocks
            yaml_patterns = [
              /```(?:yaml|yml)\s*\n(.*?)\n```/m,
              /```\s*\n(.*?)\n```/m  # Generic code block
            ]

            yaml_patterns.each do |pattern|
              match = context_section.match(pattern)
              next unless match

              yaml_content = match[1].strip
              next if yaml_content.empty?

              begin
                parsed_yaml = CodingAgentTools::Atoms::YamlReader.parse_content(yaml_content)
                validation = validate_context_template(parsed_yaml)

                if validation[:valid?]
                  return ContextParseResult.new(true, parsed_yaml, nil, :embedded, "embedded")
                else
                  return ContextParseResult.new(false, nil, validation[:errors].join("; "), nil, "embedded")
                end
              rescue => e
                return ContextParseResult.new(false, nil, "Invalid YAML in context definition: #{e.message}", nil, "embedded")
              end
            end

            ContextParseResult.new(false, nil, "No valid YAML code block found", nil, nil)
          end

          # Parse external template reference from context section
          def parse_external_reference(context_section)
            # Look for external template references
            patterns = [
              /template:\s*([^\s\n]+)/,
              /external:\s*([^\s\n]+)/,
              /file:\s*([^\s\n]+)/
            ]

            patterns.each do |pattern|
              match = context_section.match(pattern)
              next unless match

              template_path = match[1].strip

              # Validate template path exists
              if File.exist?(template_path)
                return ContextParseResult.new(true, {external_template: template_path}, nil, :external, template_path)
              else
                return ContextParseResult.new(false, nil, "External template not found: #{template_path}", nil, template_path)
              end
            end

            ContextParseResult.new(false, nil, "No valid external template reference found", nil, nil)
          end

          # Check if value is a valid string or array of strings
          def valid_string_or_array?(value)
            case value
            when String
              true
            when Array
              value.all? { |item| item.is_a?(String) }
            else
              false
            end
          end

          # Normalize value to array format
          def normalize_to_array(value)
            case value
            when nil
              []
            when String
              [value]
            when Array
              value
            else
              [value.to_s]
            end
          end
        end
      end
    end
  end
end
