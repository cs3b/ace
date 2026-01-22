# frozen_string_literal: true

module Ace
  module Lint
    module Atoms
      # Validates presence of required YAML comments in frontmatter
      # Used for SKILL.md files that require documentation comments
      class CommentValidator
        class << self
          # Validate that required comments are present in the raw content
          # @param content [String] Raw file content (with frontmatter)
          # @param required_comments [Array<String>] Comment prefixes to check for
          # @return [Array<String>] List of missing comment patterns
          def validate(content, required_comments:)
            return [] if required_comments.nil? || required_comments.empty?
            return required_comments if content.nil? || content.empty?

            # Extract frontmatter section (between --- markers)
            frontmatter = extract_frontmatter_raw(content)
            return required_comments if frontmatter.nil?

            missing = []

            required_comments.each do |comment_pattern|
              # Check if the comment pattern exists in frontmatter
              # The pattern is like "# context:" - we check if it appears in the YAML section
              unless frontmatter.include?(comment_pattern)
                missing << comment_pattern
              end
            end

            missing
          end

          # Find the line number where a comment should be added
          # @param content [String] Raw file content
          # @return [Integer] Line number for error reporting (typically line 1-2)
          def frontmatter_start_line
            1
          end

          private

          # Extract raw frontmatter content including comments
          # @param content [String] Full file content
          # @return [String, nil] Raw frontmatter text or nil if not found
          def extract_frontmatter_raw(content)
            return nil unless content.start_with?("---\n", "---\r\n")

            # Find the ending delimiter
            start_index = content.index("\n") + 1
            end_match = content.match(/\n---\n|\n---\r\n/, start_index)

            return nil unless end_match

            # Return the raw frontmatter including comments
            content[0...end_match.end(0)]
          end
        end
      end
    end
  end
end
