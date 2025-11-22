# frozen_string_literal: true

require_relative "../atoms/frontmatter_extractor"

module Ace
  module Prompt
    module Molecules
      # Read prompt file with frontmatter parsing
      class PromptReader
        class PromptNotFoundError < Ace::Prompt::Error; end

        # Read prompt file and extract frontmatter
        # @param path [String] Path to prompt file
        # @return [Hash] Hash with :frontmatter, :content, :full_text keys
        # @raise [PromptNotFoundError] if file doesn't exist
        def self.read(path)
          unless File.exist?(path)
            raise PromptNotFoundError, "Prompt file not found: #{path}"
          end

          full_text = File.read(path)
          frontmatter, content = Atoms::FrontmatterExtractor.extract(full_text)

          {
            frontmatter: frontmatter,
            content: content,
            full_text: full_text
          }
        end

        # Check if prompt file exists
        # @param path [String] Path to check
        # @return [Boolean] True if file exists
        def self.exists?(path)
          File.exist?(path)
        end
      end
    end
  end
end
