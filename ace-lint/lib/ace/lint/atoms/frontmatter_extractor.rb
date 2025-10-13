# frozen_string_literal: true

module Ace
  module Lint
    module Atoms
      # Pure function to extract frontmatter from markdown
      class FrontmatterExtractor
        # Extract frontmatter and content from markdown
        # @param content [String] Markdown content with potential frontmatter
        # @return [Hash] Result with :frontmatter, :body, :has_frontmatter
        def self.extract(content)
          return empty_result if content.nil? || content.empty?

          # Check if content starts with frontmatter delimiter
          unless content.start_with?("---\n") || content.start_with?("---\r\n")
            return {
              frontmatter: nil,
              body: content,
              has_frontmatter: false
            }
          end

          # Find the ending delimiter
          # Start search after the first "---\n"
          start_index = content.index("\n") + 1
          end_match = content.match(/\n---\n|\n---\r\n/, start_index)

          unless end_match
            return {
              frontmatter: nil,
              body: content,
              has_frontmatter: false,
              error: "Missing closing '---' delimiter for frontmatter"
            }
          end

          end_index = end_match.begin(0)

          # Extract frontmatter YAML (between the delimiters)
          frontmatter_content = content[4...end_index]

          # Extract body content (after the closing delimiter)
          body_start = end_match.end(0)
          body_content = content[body_start..-1] || ''

          {
            frontmatter: frontmatter_content,
            body: body_content,
            has_frontmatter: true
          }
        end

        # Check if content has frontmatter
        # @param content [String] Markdown content
        # @return [Boolean] True if frontmatter detected
        def self.has_frontmatter?(content)
          return false if content.nil? || content.empty?

          (content.start_with?("---\n") || content.start_with?("---\r\n")) &&
            (content.include?("\n---\n") || content.include?("\n---\r\n"))
        end

        def self.empty_result
          {
            frontmatter: nil,
            body: '',
            has_frontmatter: false,
            error: 'Empty content'
          }
        end
      end
    end
  end
end
