# frozen_string_literal: true

require "yaml"

module Ace
  module Docs
    module Atoms
      # Pure function to extract and parse YAML frontmatter from markdown files
      # Supports ace-docs specific frontmatter schema
      class FrontmatterParser
        # Parse YAML frontmatter from markdown content
        # @param content [String] The markdown content with optional frontmatter
        # @return [Hash] Result hash with :frontmatter, :content, and :valid keys
        def self.parse(content)
          return empty_result if content.nil? || content.empty?

          # Check if content starts with YAML frontmatter
          unless content.start_with?("---\n")
            return {
              frontmatter: {},
              content: content,
              valid: false,
              errors: ["No frontmatter found"]
            }
          end

          # Find the ending delimiter
          end_index = content.index("\n---\n", 4)

          unless end_index
            return {
              frontmatter: {},
              content: content[4..-1] || "",
              valid: false,
              errors: ["Missing closing '---' delimiter for frontmatter"]
            }
          end

          # Extract and parse the YAML content
          yaml_content = content[4...end_index]
          body_content = content[(end_index + 5)..-1] || ""

          begin
            frontmatter = YAML.safe_load(
              yaml_content,
              permitted_classes: [Date, Time, Symbol],
              permitted_symbols: [],
              aliases: true
            ) || {}

            # Validate ace-docs required fields
            errors = validate_frontmatter(frontmatter)

            {
              frontmatter: frontmatter,
              content: body_content,
              valid: errors.empty?,
              errors: errors
            }
          rescue Psych::SyntaxError => e
            {
              frontmatter: {},
              content: body_content,
              valid: false,
              errors: ["YAML syntax error: #{e.message}"]
            }
          end
        end

        # Extract only the frontmatter without content
        # @param content [String] The markdown content
        # @return [Hash] The frontmatter data or empty hash
        def self.extract_frontmatter(content)
          result = parse(content)
          result[:frontmatter]
        end

        # Extract only the content without frontmatter
        # @param content [String] The markdown content
        # @return [String] The content without frontmatter
        def self.extract_content(content)
          result = parse(content)
          result[:content]
        end

        # Check if content has valid ace-docs frontmatter
        # @param content [String] The markdown content
        # @return [Boolean] true if valid ace-docs frontmatter exists
        def self.has_valid_frontmatter?(content)
          result = parse(content)
          result[:valid] && result[:frontmatter]["doc-type"]
        end

        private

        def self.empty_result
          {
            frontmatter: {},
            content: "",
            valid: false,
            errors: ["Empty content"]
          }
        end

        def self.validate_frontmatter(frontmatter)
          errors = []

          unless frontmatter.is_a?(Hash)
            errors << "Frontmatter must be a hash"
            return errors
          end

          # Required fields for ace-docs
          errors << "Missing required field: doc-type" unless frontmatter["doc-type"]
          errors << "Missing required field: purpose" unless frontmatter["purpose"]

          # Validate doc-type values
          if frontmatter["doc-type"]
            valid_types = %w[context guide template workflow reference api]
            unless valid_types.include?(frontmatter["doc-type"])
              errors << "Invalid doc-type: #{frontmatter["doc-type"]}. Must be one of: #{valid_types.join(', ')}"
            end
          end

          # Validate update configuration if present
          if frontmatter["update"]
            update = frontmatter["update"]
            if update["frequency"]
              valid_frequencies = %w[daily weekly monthly on-change]
              unless valid_frequencies.include?(update["frequency"])
                errors << "Invalid update frequency: #{update["frequency"]}"
              end
            end

            # Validate dates if present
            if update["last-updated"] && !valid_date?(update["last-updated"])
              errors << "Invalid date format for last-updated"
            end
          end

          errors
        end

        def self.valid_date?(date_value)
          case date_value
          when Date, Time
            true
          when String
            Date.parse(date_value)
            true
          else
            false
          end
        rescue ArgumentError
          false
        end
      end
    end
  end
end