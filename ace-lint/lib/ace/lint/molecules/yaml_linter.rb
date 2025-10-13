# frozen_string_literal: true

require_relative '../atoms/yaml_parser'
require_relative '../models/lint_result'
require_relative '../models/validation_error'

module Ace
  module Lint
    module Molecules
      # Validates YAML syntax via Psych
      class YamlLinter
        # Validate YAML file
        # @param file_path [String] Path to YAML file
        # @return [Models::LintResult] Validation result
        def self.lint(file_path)
          content = File.read(file_path)
          lint_content(file_path, content)
        rescue Errno::ENOENT
          Models::LintResult.new(
            file_path: file_path,
            success: false,
            errors: [Models::ValidationError.new(message: "File not found: #{file_path}")]
          )
        rescue StandardError => e
          Models::LintResult.new(
            file_path: file_path,
            success: false,
            errors: [Models::ValidationError.new(message: "Error reading file: #{e.message}")]
          )
        end

        # Validate YAML content
        # @param file_path [String] Path for reference
        # @param content [String] YAML content
        # @return [Models::LintResult] Validation result
        def self.lint_content(file_path, content)
          result = Atoms::YamlParser.validate(content)

          errors = result[:errors].map do |msg|
            Models::ValidationError.new(message: msg, severity: :error)
          end

          Models::LintResult.new(
            file_path: file_path,
            success: result[:valid],
            errors: errors,
            warnings: []
          )
        end
      end
    end
  end
end
