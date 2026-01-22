# frozen_string_literal: true

module Ace
  module Lint
    module Atoms
      # Pure function to detect file type from extension or content
      class TypeDetector
        BASENAME_MAP = {
          "Gemfile" => :ruby,
          "Rakefile" => :ruby
        }.freeze

        EXTENSION_MAP = {
          ".md" => :markdown,
          ".markdown" => :markdown,
          ".yml" => :yaml,
          ".yaml" => :yaml,
          ".rb" => :ruby,
          ".rake" => :ruby,
          ".gemspec" => :ruby
        }.freeze

        # Patterns for markdown subtype detection
        # SKILL.md or SKILLS.md (case-insensitive)
        SKILL_BASENAME_PATTERN = /\ASKILLS?\.md\z/i

        # *.wf.md for workflow files
        WORKFLOW_SUFFIX = ".wf.md"

        # *.ag.md for agent files
        AGENT_SUFFIX = ".ag.md"

        # Detect file type from file path and optional content
        # @param file_path [String] Path to the file
        # @param content [String, nil] File content for content-based detection
        # @return [Symbol] File type (:skill, :workflow, :agent, :markdown, :yaml, :ruby, :unknown)
        def self.detect(file_path, content: nil)
          return :unknown if file_path.nil? || file_path.to_s.empty?

          # Try basename-based detection for known Ruby entrypoints
          basename = File.basename(file_path)
          type = BASENAME_MAP[basename]
          return type if type

          # Try extension-based detection
          ext = File.extname(file_path).downcase
          type = EXTENSION_MAP[ext]

          # For markdown files, check for skill/workflow/agent subtypes
          if type == :markdown
            subtype = detect_markdown_subtype(file_path, basename)
            return subtype if subtype
            return :markdown
          end

          return type if type

          # Try content-based detection if content provided
          return detect_from_content(content) if content

          :unknown
        end

        # Detect markdown subtype based on filename patterns
        # @param file_path [String] Full path to the file
        # @param basename [String] File basename
        # @return [Symbol, nil] :skill, :workflow, :agent, or nil for regular markdown
        def self.detect_markdown_subtype(file_path, basename)
          # Check for SKILL.md or SKILLS.md (case-insensitive)
          return :skill if basename.match?(SKILL_BASENAME_PATTERN)

          # Check for *.wf.md (workflow files)
          return :workflow if file_path.downcase.end_with?(WORKFLOW_SUFFIX)

          # Check for *.ag.md (agent files)
          return :agent if file_path.downcase.end_with?(AGENT_SUFFIX)

          nil
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
