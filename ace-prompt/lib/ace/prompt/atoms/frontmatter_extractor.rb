# frozen_string_literal: true

require "yaml"

module Ace
  module Prompt
    module Atoms
      # Extract YAML frontmatter from markdown content
      class FrontmatterExtractor
        FRONTMATTER_REGEX = /\A---\s*\n(.*?)\n---\s*\n(.*)\z/m

        # Extract frontmatter and content from text
        # @param text [String] Full text with optional frontmatter
        # @return [Array<Hash, String>] Tuple of [frontmatter_hash, content_without_frontmatter]
        def self.extract(text)
          return [{}, text] if text.nil? || text.empty?

          match = text.match(FRONTMATTER_REGEX)
          return [{}, text] unless match

          begin
            frontmatter = YAML.safe_load(match[1]) || {}
            content = match[2]
            [frontmatter, content]
          rescue Psych::SyntaxError
            # Invalid YAML - return empty frontmatter and full text
            [{}, text]
          end
        end

        # Check if text has frontmatter
        # @param text [String] Text to check
        # @return [Boolean] True if frontmatter exists
        def self.has_frontmatter?(text)
          return false if text.nil? || text.empty?
          text.match?(FRONTMATTER_REGEX)
        end
      end
    end
  end
end
