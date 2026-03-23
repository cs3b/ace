# frozen_string_literal: true

require_relative "../atoms/frontmatter_extractor"
require_relative "../atoms/yaml_validator"
require_relative "../models/lint_result"
require_relative "../models/validation_error"
require "ace/core/molecules/frontmatter_free_policy"
require "yaml"
require "date"
require "time"

module Ace
  module Lint
    module Molecules
      # Validates frontmatter schema and required fields
      class FrontmatterValidator
        DEFAULT_REQUIRED_FIELDS = %w[doc-type purpose].freeze

        # Validate frontmatter in a file
        # @param file_path [String] Path to file with frontmatter
        # @param required_fields [Array<String>] Required frontmatter fields
        # @return [Models::LintResult] Validation result
        def self.lint(file_path, required_fields: DEFAULT_REQUIRED_FIELDS)
          content = File.read(file_path)
          lint_content(file_path, content, required_fields: required_fields)
        rescue Errno::ENOENT
          Models::LintResult.new(
            file_path: file_path,
            success: false,
            errors: [Models::ValidationError.new(message: "File not found: #{file_path}")]
          )
        rescue => e
          Models::LintResult.new(
            file_path: file_path,
            success: false,
            errors: [Models::ValidationError.new(message: "Error reading file: #{e.message}")]
          )
        end

        # Validate frontmatter in content
        # @param file_path [String] Path for reference
        # @param content [String] File content
        # @param required_fields [Array<String>] Required frontmatter fields
        # @return [Models::LintResult] Validation result
        def self.lint_content(file_path, content, required_fields: DEFAULT_REQUIRED_FIELDS)
          errors = []

          # Extract frontmatter
          extraction = Atoms::FrontmatterExtractor.extract(content)

          unless extraction[:has_frontmatter]
            if frontmatter_free_file?(file_path)
              return Models::LintResult.new(
                file_path: file_path,
                success: true,
                errors: [],
                warnings: []
              )
            end

            error_msg = extraction[:error] || "No frontmatter found"
            return Models::LintResult.new(
              file_path: file_path,
              success: false,
              errors: [Models::ValidationError.new(line: 1, message: error_msg)]
            )
          end

          # Parse frontmatter YAML
          parse_result = Atoms::YamlValidator.parse(extraction[:frontmatter])

          unless parse_result[:success]
            parse_errors = parse_result[:errors].map do |msg|
              Models::ValidationError.new(line: 1, message: "Frontmatter YAML error: #{msg}")
            end
            return Models::LintResult.new(
              file_path: file_path,
              success: false,
              errors: parse_errors
            )
          end

          frontmatter = parse_result[:data]

          # Validate required fields
          unless frontmatter.is_a?(Hash)
            return Models::LintResult.new(
              file_path: file_path,
              success: false,
              errors: [Models::ValidationError.new(line: 1, message: "Frontmatter must be a hash/object")]
            )
          end

          required_fields.each do |field|
            next if frontmatter.key?(field)

            errors << Models::ValidationError.new(
              line: 1,
              message: "Missing required field: '#{field}'"
            )
          end

          Models::LintResult.new(
            file_path: file_path,
            success: errors.empty?,
            errors: errors,
            warnings: []
          )
        end

        def self.frontmatter_free_file?(file_path)
          Ace::Core::Molecules::FrontmatterFreePolicy.match?(
            file_path,
            patterns: frontmatter_free_patterns,
            project_root: Dir.pwd
          )
        end
        private_class_method :frontmatter_free_file?

        def self.frontmatter_free_patterns
          require "ace/support/config"
          config = Ace::Support::Config.create.resolve_namespace("docs").to_h
          Ace::Core::Molecules::FrontmatterFreePolicy.patterns(config: config)
        rescue
          Ace::Core::Molecules::FrontmatterFreePolicy::DEFAULT_PATTERNS
        end
        private_class_method :frontmatter_free_patterns
      end
    end
  end
end
