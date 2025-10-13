# frozen_string_literal: true

require 'yaml'
require 'psych'

module Ace
  module Lint
    module Atoms
      # Pure function to parse YAML with Psych
      class YamlParser
        # Parse YAML content with Psych
        # @param content [String] YAML content
        # @return [Hash] Result with :success, :data, :errors
        def self.parse(content)
          return { success: false, data: nil, errors: ['Empty content'] } if content.nil? || content.strip.empty?

          begin
            data = Psych.safe_load(
              content,
              permitted_classes: [Date, Time, Symbol],
              permitted_symbols: [],
              aliases: true
            )

            {
              success: true,
              data: data,
              errors: []
            }
          rescue Psych::SyntaxError => e
            {
              success: false,
              data: nil,
              errors: [format_psych_error(e)]
            }
          rescue StandardError => e
            {
              success: false,
              data: nil,
              errors: ["YAML parsing error: #{e.message}"]
            }
          end
        end

        # Validate YAML syntax without parsing data
        # @param content [String] YAML content
        # @return [Hash] Result with :valid, :errors
        def self.validate(content)
          result = parse(content)
          {
            valid: result[:success],
            errors: result[:errors]
          }
        end

        def self.format_psych_error(error)
          # Extract line number and message from Psych error
          if error.line && error.column
            "Line #{error.line}, Column #{error.column}: #{error.problem}"
          elsif error.line
            "Line #{error.line}: #{error.problem}"
          else
            "YAML syntax error: #{error.message}"
          end
        end
      end
    end
  end
end
