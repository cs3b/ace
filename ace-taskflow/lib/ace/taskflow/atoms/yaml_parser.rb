# frozen_string_literal: true

require "yaml"

module Ace
  module Taskflow
    module Atoms
      # Pure function to parse YAML frontmatter from markdown files
      class YamlParser
        # Parse YAML frontmatter from markdown content
        # @param content [String] The markdown content with optional frontmatter
        # @return [Hash] Parsed frontmatter data (empty hash if no frontmatter)
        def self.parse_frontmatter(content)
          return {} if content.nil? || content.empty?

          # Check if content starts with YAML frontmatter
          return {} unless content.start_with?("---\n")

          # Find the ending delimiter
          end_index = content.index("\n---\n", 4)
          return {} unless end_index

          # Extract and parse the YAML content
          yaml_content = content[4...end_index]

          begin
            YAML.safe_load(yaml_content, permitted_classes: [Date, Time]) || {}
          rescue Psych::SyntaxError
            {}
          end
        end

        # Extract content after frontmatter
        # @param content [String] The markdown content with optional frontmatter
        # @return [String] The content without frontmatter
        def self.extract_content(content)
          return "" if content.nil? || content.empty?

          # Check if content has frontmatter
          if content.start_with?("---\n")
            end_index = content.index("\n---\n", 4)
            if end_index
              # Return content after the closing delimiter
              return content[(end_index + 5)..-1] || ""
            end
          end

          # Return original content if no frontmatter
          content
        end

        # Parse both frontmatter and content
        # @param content [String] The markdown content
        # @return [Hash] Hash with :frontmatter and :content keys
        def self.parse(content)
          {
            frontmatter: parse_frontmatter(content),
            content: extract_content(content)
          }
        end
      end
    end
  end
end