# frozen_string_literal: true

require "yaml"
require "date"

module Ace
  module Support
    module Config
      module Atoms
        # Pure YAML parsing functions
        module YamlParser
          module_function

          # Parse YAML string into Ruby hash
          # @param yaml_string [String] YAML content to parse
          # @return [Hash] Parsed YAML content
          # @raise [YamlParseError] if parsing fails
          def parse(yaml_string)
            return {} if yaml_string.nil? || yaml_string.strip.empty?

            YAML.safe_load(yaml_string, permitted_classes: [Symbol, Date], aliases: true)
          rescue Psych::SyntaxError => e
            raise YamlParseError, "Failed to parse YAML: #{e.message}"
          rescue Encoding::CompatibilityError, Encoding::InvalidByteSequenceError => e
            raise YamlParseError, "Failed to parse YAML (encoding error): #{e.message}"
          end

          # Convert Ruby hash to YAML string
          # @param data [Hash] Data to convert
          # @return [String] YAML representation
          def dump(data)
            return "" if data.nil? || data.empty?

            YAML.dump(data)
          end

          # Check if string is valid YAML
          # @param yaml_string [String] YAML content to validate
          # @return [Boolean] true if valid YAML
          def valid?(yaml_string)
            parse(yaml_string)
            true
          rescue YamlParseError
            false
          end
        end
      end
    end
  end
end
