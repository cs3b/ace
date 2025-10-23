# frozen_string_literal: true

require "yaml"

module Ace
  module Support
    module Markdown
      module Atoms
        # Pure function to extract YAML frontmatter from markdown content
        # Separates frontmatter and body content for safe editing
        class FrontmatterExtractor
          # Extract frontmatter from markdown content
          # @param content [String] The markdown content with optional frontmatter
          # @return [Hash] Result with :frontmatter (Hash), :body (String), :valid (Boolean), :errors (Array)
          def self.extract(content)
            return empty_result if content.nil? || content.empty?

            # Check if content starts with YAML frontmatter delimiter
            unless content.start_with?("---\n")
              return {
                frontmatter: {},
                body: content,
                valid: false,
                errors: ["No frontmatter found"]
              }
            end

            # Find the ending delimiter (searching from position 4 to skip the opening ---)
            end_index = content.index("\n---\n", 4)

            unless end_index
              return {
                frontmatter: {},
                body: content[4..-1] || "",
                valid: false,
                errors: ["Missing closing '---' delimiter for frontmatter"]
              }
            end

            # Extract YAML content (between delimiters) and body content (after delimiters)
            yaml_content = content[4...end_index]
            body_content = content[(end_index + 5)..-1] || ""

            # Parse YAML with safe_load
            begin
              frontmatter = YAML.safe_load(
                yaml_content,
                permitted_classes: [Date, Time, Symbol],
                permitted_symbols: [],
                aliases: true
              ) || {}

              # Ensure frontmatter is a hash
              unless frontmatter.is_a?(Hash)
                return {
                  frontmatter: {},
                  body: body_content,
                  valid: false,
                  errors: ["Frontmatter must be a hash/object, got #{frontmatter.class}"]
                }
              end

              {
                frontmatter: frontmatter,
                body: body_content,
                valid: true,
                errors: []
              }
            rescue Psych::SyntaxError => e
              {
                frontmatter: {},
                body: body_content,
                valid: false,
                errors: ["YAML syntax error: #{e.message}"]
              }
            end
          end

          # Extract only the frontmatter hash
          # @param content [String] The markdown content
          # @return [Hash] The frontmatter data or empty hash
          def self.frontmatter_only(content)
            result = extract(content)
            result[:frontmatter]
          end

          # Extract only the body content without frontmatter
          # @param content [String] The markdown content
          # @return [String] The body content
          def self.body_only(content)
            result = extract(content)
            result[:body]
          end

          # Check if content has valid frontmatter
          # @param content [String] The markdown content
          # @return [Boolean] true if valid frontmatter exists
          def self.has_frontmatter?(content)
            result = extract(content)
            result[:valid]
          end

          private

          def self.empty_result
            {
              frontmatter: {},
              body: "",
              valid: false,
              errors: ["Empty content"]
            }
          end
        end
      end
    end
  end
end
