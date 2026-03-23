# frozen_string_literal: true

require "yaml"

module Ace
  module Support
    module Markdown
      module Atoms
        # Pure function to serialize frontmatter hash to YAML format
        # Handles delimiter wrapping and YAML formatting
        class FrontmatterSerializer
          # Serialize frontmatter hash to YAML string with delimiters
          # @param frontmatter [Hash] The frontmatter data
          # @param body [String, nil] Optional body content to append
          # @return [Hash] Result with :content (String), :valid (Boolean), :errors (Array)
          def self.serialize(frontmatter, body: nil)
            return empty_frontmatter_result if frontmatter.nil? || frontmatter.empty?

            unless frontmatter.is_a?(Hash)
              return {
                content: "",
                valid: false,
                errors: ["Frontmatter must be a hash, got #{frontmatter.class}"]
              }
            end

            begin
              # Convert to YAML
              yaml_content = YAML.dump(frontmatter).strip

              # Remove leading --- that YAML.dump adds
              yaml_content = yaml_content.sub(/^---\n/, "")

              # Build the document
              parts = ["---", yaml_content, "---"]

              # Add body if provided
              parts << "" << body.strip if body && !body.empty?

              {
                content: parts.join("\n"),
                valid: true,
                errors: []
              }
            rescue => e
              {
                content: "",
                valid: false,
                errors: ["YAML serialization error: #{e.message}"]
              }
            end
          end

          # Rebuild markdown document with frontmatter and body
          # @param frontmatter [Hash] The frontmatter data
          # @param body [String] The body content
          # @return [String] The complete markdown document
          def self.rebuild_document(frontmatter, body)
            result = serialize(frontmatter, body: body)
            raise ValidationError, result[:errors].join(", ") unless result[:valid]

            result[:content]
          end

          # Serialize frontmatter only (without body)
          # @param frontmatter [Hash] The frontmatter data
          # @return [String] The frontmatter section with delimiters
          def self.frontmatter_only(frontmatter)
            result = serialize(frontmatter)
            raise ValidationError, result[:errors].join(", ") unless result[:valid]

            result[:content]
          end

          private

          def self.empty_frontmatter_result
            {
              content: "---\n---",
              valid: true,
              errors: []
            }
          end
        end
      end
    end
  end
end
