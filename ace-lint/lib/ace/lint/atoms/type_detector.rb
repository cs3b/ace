# frozen_string_literal: true

module Ace
  module Lint
    module Atoms
      # Pure function to detect file type from extension or content
      class TypeDetector
        EXTENSION_MAP = {
          '.md' => :markdown,
          '.markdown' => :markdown,
          '.yml' => :yaml,
          '.yaml' => :yaml
        }.freeze

        # Detect file type from file path and optional content
        # @param file_path [String] Path to the file
        # @param content [String, nil] File content for content-based detection
        # @return [Symbol] File type (:markdown, :yaml, :unknown)
        def self.detect(file_path, content: nil)
          # Try extension-based detection first
          ext = File.extname(file_path).downcase
          type = EXTENSION_MAP[ext]
          return type if type

          # Try content-based detection if content provided
          return detect_from_content(content) if content

          :unknown
        end

        # Detect if file has frontmatter
        # @param content [String] File content
        # @return [Boolean] True if frontmatter detected
        def self.has_frontmatter?(content)
          return false if content.nil? || content.empty?

          content.start_with?("---\n") && content.include?("\n---\n")
        end

        def self.detect_from_content(content)
          return :unknown if content.nil? || content.empty?

          # Check for markdown indicators
          if markdown_content?(content)
            :markdown
          # Check for YAML indicators
          elsif yaml_content?(content)
            :yaml
          else
            :unknown
          end
        end

        def self.markdown_content?(content)
          # Look for common markdown patterns
          content.match?(/^\#{1,6}\s+\S/) || # Headers
            content.match?(/^\*\s+\S/) || # Unordered lists
            content.match?(/^\d+\.\s+\S/) || # Ordered lists
            content.match?(/```/) || # Code blocks
            has_frontmatter?(content) # Frontmatter indicates markdown
        end

        def self.yaml_content?(content)
          # Look for YAML patterns (key: value)
          content.match?(/^\w+:\s*\S/) ||
            content.match?(/^-\s+\w+:/) # Array of objects
        end
      end
    end
  end
end
