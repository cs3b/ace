# frozen_string_literal: true

require_relative "../atoms/frontmatter_extractor"
require_relative "../atoms/yaml_validator"
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

            # Validate required nested fields
            required_nested_fields = schema["required_nested_fields"] || []
            required_nested_fields.each do |field_path|
              value = dig_value(frontmatter, field_path)
              next if present_value?(value)

              line = field_lines[field_path.split(".").first] || 2
              errors << Models::ValidationError.new(
                line: line,
                message: "Missing required field: '#{field_path}'"
              )
            end

            # Validate field types and patterns
            field_validations = schema["field_validations"] || {}
            field_validations.each do |field, rules|
              value = field.include?(".") ? dig_value(frontmatter, field) : frontmatter[field]
              next if value.nil?

              line = field_lines[field.split(".").first] || 2
              field_errors = validate_field(field, value, rules, line: line)
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

            if type.to_sym == :skill
              errors.concat(validate_skill_specific_rules(frontmatter, field_lines))
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

          def dig_value(data, field_path)
            keys = field_path.split(".")
            current = data
            keys.each do |key|
              return nil unless current.is_a?(Hash) && current.key?(key)

              current = current[key]
            end
            current
          end

          def present_value?(value)
            !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
          end

          def validate_skill_specific_rules(frontmatter, field_lines)
            errors = []
            line = field_lines["skill"] || 2

            skill_data = frontmatter["skill"]
            unless skill_data.is_a?(Hash)
              return errors
            end

            unknown_skill_keys = skill_data.keys - %w[kind execution]
            unknown_skill_keys.each do |key|
              errors << Models::ValidationError.new(
                line: line,
                message: "Unknown field under 'skill': '#{key}'"
              )
            end

            execution_data = skill_data["execution"]
            if execution_data && !execution_data.is_a?(Hash)
              errors << Models::ValidationError.new(
                line: line,
                message: "Field 'skill.execution' must be a mapping/object"
              )
            elsif execution_data.is_a?(Hash)
              unknown_execution_keys = execution_data.keys - ["workflow"]
              unknown_execution_keys.each do |key|
                errors << Models::ValidationError.new(
                  line: line,
                  message: "Unknown field under 'skill.execution': '#{key}'"
                )
              end
            end

            assign_data = frontmatter["assign"]
            if assign_data
              assign_line = field_lines["assign"] || 2
              kind = skill_data["kind"]
              if kind == "capability"
                errors << Models::ValidationError.new(
                  line: assign_line,
                  message: "Field 'assign' is only allowed for workflow/orchestration skills"
                )
              end

              unless assign_data.is_a?(Hash)
                errors << Models::ValidationError.new(
                  line: assign_line,
                  message: "Field 'assign' must be a mapping/object"
                )
                return errors
              end

              unknown_assign_keys = assign_data.keys - %w[source phases]
              unknown_assign_keys.each do |key|
                errors << Models::ValidationError.new(
                  line: assign_line,
                  message: "Unknown field under 'assign': '#{key}'"
                )
              end

              phase_names = Array(assign_data["phases"]).filter_map do |phase|
                phase.is_a?(Hash) ? phase["name"] : nil
              end
              phase_names.group_by(&:itself).each do |name, grouped|
                next unless grouped.length > 1

                errors << Models::ValidationError.new(
                  line: assign_line,
                  message: "Duplicate assign phase name: '#{name}'"
                )
              end
            end

            errors.concat(validate_integration_rules(frontmatter, field_lines))
            errors
          end

          def validate_integration_rules(frontmatter, field_lines)
            integration = frontmatter["integration"]
            return [] unless integration

            line = field_lines["integration"] || 2
            known = Atoms::SkillSchemaLoader.known_integration_providers

            unless integration.is_a?(Hash)
              return [Models::ValidationError.new(line: line, message: "Field 'integration' must be a mapping/object")]
            end

            errors = []
            unknown_keys = integration.keys - %w[targets providers]
            unknown_keys.each do |key|
              errors << Models::ValidationError.new(
                line: line,
                message: "Unknown field under 'integration': '#{key}'"
              )
            end

            targets = integration["targets"]
            if targets && !targets.is_a?(Array)
              errors << Models::ValidationError.new(
                line: line,
                message: "Field 'integration.targets' must be an array"
              )
            end

            Array(targets).each do |provider|
              next if known.include?(provider.to_s)

              errors << Models::ValidationError.new(
                line: line,
                message: "Unknown integration provider '#{provider}'"
              )
            end

            providers = integration["providers"]
            if providers && !providers.is_a?(Hash)
              errors << Models::ValidationError.new(
                line: line,
                message: "Field 'integration.providers' must be a mapping/object"
              )
              return errors
            end

            (providers || {}).each do |provider, provider_config|
              unless known.include?(provider.to_s)
                errors << Models::ValidationError.new(
                  line: line,
                  message: "Unknown integration provider '#{provider}'"
                )
                next
              end

              unless provider_config.is_a?(Hash)
                errors << Models::ValidationError.new(
                  line: line,
                  message: "Field 'integration.providers.#{provider}' must be a mapping/object"
                )
                next
              end

              unknown_provider_keys = provider_config.keys - ["frontmatter"]
              unknown_provider_keys.each do |key|
                errors << Models::ValidationError.new(
                  line: line,
                  message: "Unknown field under 'integration.providers.#{provider}': '#{key}'"
                )
              end

              frontmatter_overrides = provider_config["frontmatter"]
              next if frontmatter_overrides.nil? || frontmatter_overrides.is_a?(Hash)

              errors << Models::ValidationError.new(
                line: line,
                message: "Field 'integration.providers.#{provider}.frontmatter' must be a mapping/object"
              )
            end

            errors
          end
        end
      end
    end
  end
end
