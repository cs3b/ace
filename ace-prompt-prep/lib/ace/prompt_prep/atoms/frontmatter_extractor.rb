# frozen_string_literal: true

require "yaml"

module Ace
  module PromptPrep
    module Atoms
      # Extract YAML frontmatter from markdown content
      class FrontmatterExtractor
        FRONTMATTER_DELIMITER = /^---\s*$/

        # Extract frontmatter and body from content
        #
        # @param content [String] The content to parse
        # @return [Hash] Hash with :frontmatter, :body, :has_frontmatter keys
        def self.extract(content)
          return empty_result(content) if content.nil? || content.empty?

          lines = content.lines
          return empty_result(content) unless lines.first&.match?(FRONTMATTER_DELIMITER)

          # Find closing delimiter
          closing_index = lines[1..].find_index { |line| line.match?(FRONTMATTER_DELIMITER) }
          return empty_result(content) unless closing_index

          # Extract frontmatter YAML (between delimiters)
          frontmatter_lines = lines[1..closing_index]
          frontmatter_yaml = frontmatter_lines.join

          # Parse YAML
          begin
            frontmatter = YAML.safe_load(frontmatter_yaml) || {}
          rescue Psych::SyntaxError, Psych::DisallowedClass => e
            # Invalid YAML - return as if no frontmatter
            return empty_result(content, error: "Invalid YAML in frontmatter: #{e.message}")
          end

          # Extract body (everything after closing delimiter)
          body_start = closing_index + 2 # +1 for array index offset, +1 for closing delimiter
          body = lines[body_start..].join

          {
            frontmatter: frontmatter,
            raw_frontmatter: frontmatter_yaml,
            body: body,
            has_frontmatter: true,
            error: nil
          }
        end

        # Helper to return empty result
        def self.empty_result(content, error: nil)
          {
            frontmatter: {},
            raw_frontmatter: nil,
            body: content || "",
            has_frontmatter: false,
            error: error
          }
        end

        private_class_method :empty_result
      end
    end
  end
end
