# frozen_string_literal: true

require_relative "../atoms/frontmatter_extractor"
require_relative "../atoms/yaml_parser"
require_relative "../atoms/skill_schema_loader"
require_relative "../atoms/allowed_tools_validator"
require_relative "../atoms/comment_validator"
require_relative "../models/lint_result"
require_relative "../models/validation_error"

module Ace
  module Lint
    module Molecules
      # Validates skill, workflow, and agent markdown files
      # Applies schema-based validation based on file type
      class SkillValidator
        class << self
          # Validate a skill/workflow/agent file
          # @param file_path [String] Path to the file
          # @param type [Symbol] File type (:skill, :workflow, :agent)
          # @param options [Hash] Validation options
          # @return [Models::LintResult] Validation result
          def validate(file_path, type, options: {})
            content = File.read(file_path)
            validate_content(file_path, content, type, options: options)
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

          # Validate content directly
          # @param file_path [String] Path for reporting
          # @param content [String] File content
          # @param type [Symbol] File type
          # @param options [Hash] Validation options
          # @return [Models::LintResult] Validation result
          def validate_content(file_path, content, type, options: {})
            errors = []
            warnings = []

            # Load schema for this type
            schema = Atoms::SkillSchemaLoader.schema_for(type)

            if schema.empty?
              warnings << Models::ValidationError.new(
                message: "No schema defined for type '#{type}'",
                severity: :warning
              )
              return Models::LintResult.new(
                file_path: file_path,
                success: true,
                errors: [],
                warnings: warnings
              )
            end

            # Extract frontmatter
            extraction = Atoms::FrontmatterExtractor.extract(content)

            unless extraction[:has_frontmatter]
              error_msg = extraction[:error] || "No frontmatter found"
              return Models::LintResult.new(
                file_path: file_path,
                success: false,
                errors: [Models::ValidationError.new(line: 1, message: error_msg)]
              )
            end

            # Parse frontmatter YAML
            parse_result = Atoms::YamlParser.parse(extraction[:frontmatter])

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

            unless frontmatter.is_a?(Hash)
              return Models::LintResult.new(
                file_path: file_path,
                success: false,
                errors: [Models::ValidationError.new(line: 1, message: "Frontmatter must be a hash/object")]
              )
            end

            # Build field line map for accurate error reporting
            field_lines = build_field_line_map(extraction[:frontmatter])

            # Validate required fields
            required_fields = schema["required_fields"] || []
            required_fields.each do |field|
              next if frontmatter.key?(field)

              # Missing fields report at line 1 (start of frontmatter)
              errors << Models::ValidationError.new(
                line: 2,
                message: "Missing required field: '#{field}'"
              )
            end

            # Validate field types and patterns
            field_validations = schema["field_validations"] || {}
            field_validations.each do |field, rules|
              next unless frontmatter.key?(field)

              line = field_lines[field] || 2
              field_errors = validate_field(field, frontmatter[field], rules, line: line)
              errors.concat(field_errors)
            end

            # Validate allowed-tools if present
            if frontmatter.key?("allowed-tools")
              line = field_lines["allowed-tools"] || 2
              tools_errors = validate_allowed_tools(frontmatter["allowed-tools"], line: line)
              errors.concat(tools_errors)
            end

            # Validate required comments (for skills)
            required_comments = schema["required_comments"] || []
            if required_comments.any?
              missing_comments = Atoms::CommentValidator.validate(content, required_comments: required_comments)
              missing_comments.each do |comment|
                errors << Models::ValidationError.new(
                  line: 1,
                  message: "Missing required comment: '#{comment}'"
                )
              end
            end

            # Check trailing newline
            unless content.end_with?("\n")
              warnings << Models::ValidationError.new(
                message: "File should end with a newline",
                severity: :warning
              )
            end

            Models::LintResult.new(
              file_path: file_path,
              success: errors.empty?,
              errors: errors,
              warnings: warnings
            )
          end

          private

          # Build a map of field names to their line numbers in frontmatter
          # @param frontmatter_content [String] Raw frontmatter YAML content
          # @return [Hash<String, Integer>] Map of field name to line number (1-indexed, offset by 2 for ---)
          def build_field_line_map(frontmatter_content)
            field_lines = {}
            frontmatter_content.each_line.with_index do |line, index|
              # Match field definitions at the start of a line (e.g., "name:" or "allowed-tools:")
              if line =~ /\A([a-zA-Z][a-zA-Z0-9_-]*):/
                field_name = ::Regexp.last_match(1)
                # Add 2: +1 for 0-index to 1-index, +1 for opening ---
                field_lines[field_name] = index + 2
              end
            end
            field_lines
          end

          # Validate a single field against its rules
          # @param field [String] Field name
          # @param value [Object] Field value
          # @param rules [Hash] Validation rules
          # @param line [Integer] Line number for error reporting
          # @return [Array<Models::ValidationError>] List of errors
          def validate_field(field, value, rules, line: 1)
            errors = []

            # Type validation
            case rules["type"]
            when "string"
              unless value.is_a?(String)
                errors << Models::ValidationError.new(
                  line: line,
                  message: "Field '#{field}' must be a string"
                )
                return errors
              end

              # Pattern validation
              if rules["pattern"]
                begin
                  pattern = Regexp.new(rules["pattern"])
                  unless value.match?(pattern)
                    error_msg = rules["error_message"] || "Field '#{field}' must match pattern: #{rules["pattern"]}"
                    errors << Models::ValidationError.new(line: line, message: error_msg)
                  end
                rescue RegexpError => e
                  errors << Models::ValidationError.new(
                    line: line,
                    message: "Invalid pattern for field '#{field}': #{e.message}"
                  )
                end
              end

              # Allowed values validation
              if rules["values"]
                unless rules["values"].include?(value)
                  error_msg = rules["error_message"] || "Field '#{field}' must be one of: #{rules["values"].join(", ")}"
                  errors << Models::ValidationError.new(line: line, message: error_msg)
                end
              end

            when "boolean"
              unless [true, false].include?(value)
                errors << Models::ValidationError.new(
                  line: line,
                  message: "Field '#{field}' must be a boolean (true/false)"
                )
              end

            when "array"
              unless value.is_a?(Array) || value.is_a?(String)
                errors << Models::ValidationError.new(
                  line: line,
                  message: "Field '#{field}' must be an array"
                )
              end
            end

            errors
          end

          # Validate allowed-tools entries
          # @param tools [Array, String] Tools to validate
          # @param line [Integer] Line number for error reporting
          # @return [Array<Models::ValidationError>] List of errors
          def validate_allowed_tools(tools, line: 1)
            known_tools = Atoms::SkillSchemaLoader.known_tools
            known_bash_prefixes = Atoms::SkillSchemaLoader.known_bash_prefixes

            tool_errors = Atoms::AllowedToolsValidator.validate(
              tools,
              known_tools: known_tools,
              known_bash_prefixes: known_bash_prefixes
            )

            tool_errors.map do |error|
              Models::ValidationError.new(
                line: line,
                message: "Invalid allowed-tools entry: #{error[:message]}"
              )
            end
          end
        end
      end
    end
  end
end
