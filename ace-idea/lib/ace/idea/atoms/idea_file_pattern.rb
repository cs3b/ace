# frozen_string_literal: true

module Ace
  module Idea
    module Atoms
      # Provides glob patterns for finding idea spec files.
      # Ideas use the .idea.s.md extension to distinguish from task .s.md files.
      module IdeaFilePattern
        # Glob pattern for idea spec files within a directory
        FILE_GLOB = "*.idea.s.md"

        # Full file extension for idea spec files
        FILE_EXTENSION = ".idea.s.md"

        # Build the spec filename for an idea
        # @param id [String] Raw 6-char b36ts ID
        # @param slug [String] Kebab-case slug
        # @return [String] Spec filename (e.g., "8ppq7w-dark-mode.idea.s.md")
        def self.spec_filename(id, slug)
          "#{id}-#{slug}#{FILE_EXTENSION}"
        end

        # Build the folder name for an idea
        # @param id [String] Raw 6-char b36ts ID
        # @param slug [String] Kebab-case slug
        # @return [String] Folder name (e.g., "8ppq7w-dark-mode")
        def self.folder_name(id, slug)
          "#{id}-#{slug}"
        end

        # Check if a filename matches the idea spec pattern
        # @param filename [String] Filename to check
        # @return [Boolean] True if it's an idea spec file
        def self.idea_file?(filename)
          filename.to_s.end_with?(FILE_EXTENSION)
        end
      end
    end
  end
end
