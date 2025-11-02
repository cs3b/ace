# frozen_string_literal: true

require 'yaml'

module Ace
  module Core
    module Atoms
      # Pure template parsing functions for context configurations
      module TemplateParser
        # Valid template configuration keys
        VALID_KEYS = %w[
          files commands format embed_document_source
          include exclude output chunk_limit max_size timeout
        ].freeze

        module_function

        # Parse template configuration from string
        # @param content [String] Template content (YAML or markdown with embedded YAML)
        # @return [Hash] {success: Boolean, config: Hash, error: String}
        def parse(content)
          return { success: false, error: "Content cannot be nil" } if content.nil?
          return { success: false, error: "Content cannot be empty" } if content.strip.empty?

          # Try to extract from markdown with tags first
          config = extract_from_markdown(content)

          # If not found, try to parse as direct YAML
          config ||= parse_yaml(content)

          if config.nil?
            return { success: false, error: "No valid configuration found" }
          end

          validate_config(config)
        rescue => e
          { success: false, error: "Failed to parse template: #{e.message}" }
        end

        # Extract configuration from markdown with <context-tool-config> tags
        # @param content [String] Markdown content
        # @return [Hash, nil] Extracted configuration or nil
        def extract_from_markdown(content)
          return nil if content.nil?

          # Look for <context-tool-config> block
          pattern = /<context-tool-config>\s*\n(.*?)\n<\/context-tool-config>/m
          match = content.match(pattern)

          return nil unless match

          yaml_content = match[1]
          parse_yaml(yaml_content)
        end

        # Extract configuration from agent markdown files
        # @param content [String] Agent markdown content
        # @return [Hash, nil] Extracted configuration or nil
        def extract_from_agent(content)
          return nil if content.nil?

          # Look for Context Definition section
          context_match = content.match(/^## Context Definition\s*\n(.*?)(?=^## |\z)/m)
          return nil unless context_match

          context_section = context_match[1].strip

          # Extract YAML from code block
          yaml_match = context_section.match(/```(?:yaml|yml)?\s*\n(.*?)\n```/m)
          return nil unless yaml_match

          yaml_content = yaml_match[1]
          parse_yaml(yaml_content)
        end

        # Parse YAML string to hash
        # @param yaml_string [String] YAML content
        # @return [Hash, nil] Parsed configuration or nil
        def parse_yaml(yaml_string)
          return nil if yaml_string.nil? || yaml_string.strip.empty?

          result = YAML.safe_load(yaml_string, permitted_classes: [Symbol])

          # Ensure it's a hash
          result.is_a?(Hash) ? stringify_keys(result) : nil
        rescue Psych::SyntaxError => e
          nil
        end

        # Validate configuration structure
        # @param config [Hash] Configuration to validate
        # @return [Hash] {success: Boolean, config: Hash, error: String}
        def validate_config(config)
          return { success: false, error: "Config must be a Hash" } unless config.is_a?(Hash)

          # Check for unknown keys
          unknown_keys = config.keys - VALID_KEYS
          unless unknown_keys.empty?
            return {
              success: false,
              error: "Unknown configuration keys: #{unknown_keys.join(', ')}"
            }
          end

          # Normalize arrays
          normalized = normalize_config(config)

          # Validate required content
          if normalized['files'].empty? && normalized['commands'].empty? &&
             normalized['include'].empty?
            return {
              success: false,
              error: "Configuration must specify 'files', 'commands', or 'include'"
            }
          end

          { success: true, config: normalized }
        end

        # Normalize configuration values
        # @param config [Hash] Configuration to normalize
        # @return [Hash] Normalized configuration
        def normalize_config(config)
          {
            'files' => to_array(config['files']),
            'commands' => to_array(config['commands']),
            'include' => to_array(config['include']),
            'exclude' => to_array(config['exclude']),
            'format' => config['format'],
            'embed_document_source' => config['embed_document_source'],
            'output' => config['output'],
            'chunk_limit' => config['chunk_limit'],
            'max_size' => config['max_size'],
            'timeout' => config['timeout']
          }.compact
        end

        # Convert value to array
        # @param value [nil, String, Array] Value to convert
        # @return [Array] Array of strings
        def to_array(value)
          case value
          when nil
            []
          when Array
            value.map(&:to_s)
          when String
            [value]
          else
            [value.to_s]
          end
        end

        # Merge multiple configurations
        # @param configs [Array<Hash>] Configurations to merge
        # @return [Hash] Merged configuration
        def merge_configs(*configs)
          configs = configs.flatten.compact

          return {} if configs.empty?

          result = {
            'files' => [],
            'commands' => [],
            'include' => [],
            'exclude' => []
          }

          configs.each do |config|
            next unless config.is_a?(Hash)

            # Concatenate arrays
            %w[files commands include exclude].each do |key|
              result[key].concat(to_array(config[key]))
            end

            # Take last non-nil value for other keys
            %w[format embed_document_source output chunk_limit max_size timeout].each do |key|
              result[key] = config[key] if config.key?(key)
            end
          end

          # Remove duplicates from arrays
          %w[files commands include exclude].each do |key|
            result[key].uniq!
          end

          result.compact
        end

        # Check if content appears to be a template
        # @param content [String] Content to check
        # @return [Boolean] true if content looks like a template
        def template?(content)
          return false if content.nil?

          # Check for various template indicators
          content.include?('<context-tool-config>') ||
            content.match?(/^files:\s*$/m) ||
            content.match?(/^commands:\s*$/m) ||
            content.match?(/^include:\s*$/m) ||
            content.match?(/^## Context Definition/m)
        end

        private

        # Convert all keys to strings recursively
        # @param hash [Hash] Hash with potentially mixed keys
        # @return [Hash] Hash with string keys
        module_function
        def stringify_keys(hash)
          return hash unless hash.is_a?(Hash)

          hash.each_with_object({}) do |(key, value), result|
            result[key.to_s] = value.is_a?(Hash) ? stringify_keys(value) : value
          end
        end
      end
    end
  end
end