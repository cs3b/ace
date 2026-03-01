# frozen_string_literal: true

module Ace
  module Retro
    module Atoms
      # Provides glob patterns for finding retro files.
      # Retros use the .retro.md extension.
      module RetroFilePattern
        # Glob pattern for retro files within a directory
        FILE_GLOB = "*.retro.md".freeze

        # Full file extension for retro files
        FILE_EXTENSION = ".retro.md".freeze

        # Build the retro filename
        # @param id [String] Raw 6-char b36ts ID
        # @param slug [String] Kebab-case slug
        # @return [String] Retro filename (e.g., "8ppq7w-sprint-review.retro.md")
        def self.retro_filename(id, slug)
          "#{id}-#{slug}#{FILE_EXTENSION}"
        end

        # Build the folder name for a retro
        # @param id [String] Raw 6-char b36ts ID
        # @param slug [String] Kebab-case slug
        # @return [String] Folder name (e.g., "8ppq7w-sprint-review")
        def self.folder_name(id, slug)
          "#{id}-#{slug}"
        end

        # Check if a filename matches the retro file pattern
        # @param filename [String] Filename to check
        # @return [Boolean] True if it's a retro file
        def self.retro_file?(filename)
          filename.to_s.end_with?(FILE_EXTENSION)
        end
      end
    end
  end
end
