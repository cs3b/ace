# frozen_string_literal: true

module Ace
  module Support
    module Markdown
      module Atoms
        # Pure function to validate markdown documents and frontmatter
        # v0.1.0: Uses hardcoded validation rules
        # v0.2.0: Will support JSON Schema validation (see task 080)
        class DocumentValidator
          # Validate complete markdown content (frontmatter + body)
          # @param content [String] The complete markdown content
          # @param rules [Hash] Optional validation rules
          # @return [Hash] Result with :valid (Boolean), :errors (Array), :warnings (Array)
          def self.validate(content, rules: {})
            return invalid_result(["Empty content"]) if content.nil? || content.empty?

            errors = []
            warnings = []

            # Parse frontmatter
            extractor_result = FrontmatterExtractor.extract(content)

            unless extractor_result[:valid]
              errors.concat(extractor_result[:errors])
              return {valid: false, errors: errors, warnings: warnings}
            end

            # Validate frontmatter structure
            fm_errors = validate_frontmatter(extractor_result[:frontmatter], rules)
            errors.concat(fm_errors)

            # Validate body exists
            if extractor_result[:body].nil? || extractor_result[:body].strip.empty?
              warnings << "Empty body content"
            end

            {
              valid: errors.empty?,
              errors: errors,
              warnings: warnings
            }
          end

          # Validate only frontmatter hash
          # @param frontmatter [Hash] The frontmatter data
          # @param rules [Hash] Optional validation rules
          # @return [Hash] Result with :valid (Boolean), :errors (Array)
          def self.validate_frontmatter(frontmatter, rules = {})
            errors = []

            unless frontmatter.is_a?(Hash)
              errors << "Frontmatter must be a hash"
              return errors
            end

            # Apply required fields validation
            if rules[:required_fields]
              rules[:required_fields].each do |field|
                unless frontmatter.key?(field) || frontmatter.key?(field.to_s)
                  errors << "Missing required field: #{field}"
                end
              end
            end

            # Apply field type validation
            if rules[:field_types]
              rules[:field_types].each do |field, expected_type|
                value = frontmatter[field] || frontmatter[field.to_s]
                next unless value

                unless value.is_a?(expected_type)
                  errors << "Field '#{field}' must be #{expected_type}, got #{value.class}"
                end
              end
            end

            # Apply enum validation
            if rules[:enums]
              rules[:enums].each do |field, allowed_values|
                value = frontmatter[field] || frontmatter[field.to_s]
                next unless value

                unless allowed_values.include?(value)
                  errors << "Field '#{field}' must be one of #{allowed_values.join(", ")}, got '#{value}'"
                end
              end
            end

            errors
          end

          # Validate that content can be round-trip parsed
          # @param content [String] The markdown content
          # @return [Boolean] true if content can be safely parsed and rebuilt
          def self.can_round_trip?(content)
            return false if content.nil? || content.empty?

            begin
              # Extract frontmatter
              result = FrontmatterExtractor.extract(content)
              return false unless result[:valid]

              # Serialize back
              serialized = FrontmatterSerializer.serialize(
                result[:frontmatter],
                body: result[:body]
              )

              serialized[:valid]
            rescue
              false
            end
          end

          private

          def self.invalid_result(errors)
            {
              valid: false,
              errors: errors,
              warnings: []
            }
          end
        end
      end
    end
  end
end
