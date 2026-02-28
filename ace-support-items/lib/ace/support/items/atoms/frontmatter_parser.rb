# frozen_string_literal: true

require "yaml"

module Ace
  module Support
    module Items
      module Atoms
        # Pure function to parse YAML frontmatter from markdown files.
        # Extracts frontmatter hash and body content from `---` delimited blocks.
        class FrontmatterParser
          # Parse YAML frontmatter from markdown content
          # @param content [String] The markdown content with optional frontmatter
          # @return [Hash] Parsed frontmatter data (empty hash if no frontmatter)
          def self.parse_frontmatter(content)
            return {} if content.nil? || content.empty?
            return {} unless content.start_with?("---\n")

            end_index = content.index("\n---\n", 4)
            return {} unless end_index

            yaml_content = content[4...end_index]

            begin
              YAML.safe_load(yaml_content, permitted_classes: [Date, Time, Symbol]) || {}
            rescue Psych::SyntaxError
              {}
            end
          end

          # Extract content after frontmatter
          # @param content [String] The markdown content with optional frontmatter
          # @return [String] The content without frontmatter
          def self.extract_body(content)
            return "" if content.nil? || content.empty?

            if content.start_with?("---\n")
              end_index = content.index("\n---\n", 4)
              if end_index
                return content[(end_index + 5)..] || ""
              end
            end

            content
          end

          # Parse both frontmatter and body
          # @param content [String] The markdown content
          # @return [Array(Hash, String)] Tuple of [frontmatter, body]
          def self.parse(content)
            [parse_frontmatter(content), extract_body(content)]
          end
        end
      end
    end
  end
end
