# frozen_string_literal: true

require "fileutils"

module Ace
  module Review
    module Molecules
      # Manages feedback directory structure and file organization.
      #
      # Handles creation of feedback directories, archiving of resolved items,
      # and listing of feedback files.
      #
      # Directory structure:
      #   {base_path}/
      #     feedback/
      #       {id}-{slug}.s.md
      #       {id}-{slug}.s.md
      #       _archived/
      #         {id}-{slug}.s.md
      #
      # @example Ensure directories exist
      #   manager = FeedbackDirectoryManager.new
      #   manager.ensure_directory("/project")     #=> "/project/feedback"
      #   manager.ensure_archive("/project")       #=> "/project/feedback/_archived"
      #
      # @example Archive a resolved item
      #   manager.archive("/project/feedback/abc123-bug-fix.s.md")
      #   #=> { success: true, path: "/project/feedback/_archived/abc123-bug-fix.s.md" }
      #
      class FeedbackDirectoryManager
        # Subdirectory name for feedback files
        FEEDBACK_DIR = "feedback"

        # Subdirectory name for archived files
        ARCHIVE_DIR = "_archived"

        # File extension for feedback files
        FILE_EXTENSION = ".s.md"

        # Get the feedback directory path for a base path
        #
        # @param base_path [String] The base project path
        # @return [String] The feedback directory path
        def feedback_path(base_path)
          File.join(base_path, FEEDBACK_DIR)
        end

        # Get the archive directory path for a base path
        #
        # @param base_path [String] The base project path
        # @return [String] The archive directory path
        def archive_path(base_path)
          File.join(base_path, FEEDBACK_DIR, ARCHIVE_DIR)
        end

        # Ensure the feedback directory exists
        #
        # @param base_path [String] The base project path
        # @return [String] The feedback directory path
        def ensure_directory(base_path)
          path = feedback_path(base_path)
          FileUtils.mkdir_p(path)
          path
        end

        # Ensure the archive directory exists
        #
        # @param base_path [String] The base project path
        # @return [String] The archive directory path
        def ensure_archive(base_path)
          path = archive_path(base_path)
          FileUtils.mkdir_p(path)
          path
        end

        # Archive a feedback file by moving it to the _archived subdirectory
        #
        # @param file_path [String] Path to the feedback file to archive
        # @return [Hash] Result with :success and :path or :error
        def archive(file_path)
          validate_archive_inputs(file_path)

          # Determine the archive destination
          feedback_dir = File.dirname(file_path)
          archive_dir = File.join(feedback_dir, ARCHIVE_DIR)
          filename = File.basename(file_path)
          dest_path = File.join(archive_dir, filename)

          # Ensure archive directory exists
          FileUtils.mkdir_p(archive_dir)

          # Move file to archive
          FileUtils.mv(file_path, dest_path)

          {success: true, path: dest_path}
        rescue Errno::ENOENT
          {success: false, error: "File not found: #{file_path}"}
        rescue Errno::EACCES
          {success: false, error: "Permission denied: #{file_path}"}
        rescue => e
          {success: false, error: "Failed to archive file: #{e.message}"}
        end

        # List all feedback files in a directory
        #
        # @param directory [String] The feedback directory to list
        # @param include_archived [Boolean] Whether to include archived files (default: false)
        # @return [Array<String>] Array of file paths
        def list_files(directory, include_archived: false)
          return [] unless Dir.exist?(directory)

          files = []

          # List files in main directory (excluding _archived subdirectory)
          main_files = Dir.glob(File.join(directory, "*#{FILE_EXTENSION}"))
          files.concat(main_files)

          # Include archived files if requested
          if include_archived
            archive_dir = File.join(directory, ARCHIVE_DIR)
            if Dir.exist?(archive_dir)
              archived_files = Dir.glob(File.join(archive_dir, "*#{FILE_EXTENSION}"))
              files.concat(archived_files)
            end
          end

          files.sort
        end

        # Check if a feedback directory exists
        #
        # @param base_path [String] The base project path
        # @return [Boolean] True if feedback directory exists
        def exists?(base_path)
          Dir.exist?(feedback_path(base_path))
        end

        # Check if the archive directory exists
        #
        # @param base_path [String] The base project path
        # @return [Boolean] True if archive directory exists
        def archive_exists?(base_path)
          Dir.exist?(archive_path(base_path))
        end

        # Count feedback files in a directory
        #
        # @param directory [String] The feedback directory
        # @param include_archived [Boolean] Whether to include archived files
        # @return [Hash] Counts with :active, :archived, and :total keys
        def count_files(directory)
          return {active: 0, archived: 0, total: 0} unless Dir.exist?(directory)

          active = Dir.glob(File.join(directory, "*#{FILE_EXTENSION}")).count
          archived = 0

          archive_dir = File.join(directory, ARCHIVE_DIR)
          if Dir.exist?(archive_dir)
            archived = Dir.glob(File.join(archive_dir, "*#{FILE_EXTENSION}")).count
          end

          {active: active, archived: archived, total: active + archived}
        end

        private

        # Validate inputs for archive operation
        #
        # @param file_path [String] The file path to validate
        # @raise [ArgumentError] If inputs are invalid
        def validate_archive_inputs(file_path)
          raise ArgumentError, "file_path is required" if file_path.nil? || file_path.empty?

          unless file_path.end_with?(FILE_EXTENSION)
            raise ArgumentError, "file must have #{FILE_EXTENSION} extension"
          end

          raise ArgumentError, "file does not exist: #{file_path}" unless File.exist?(file_path)
        end
      end
    end
  end
end
