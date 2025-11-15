# frozen_string_literal: true

require 'pathname'

module Ace
  module GitCommit
    module Molecules
      # PathResolver handles path resolution and filtering for commits
      class PathResolver
        attr_reader :last_error

        def initialize(git_executor)
          @git = git_executor
          @last_error = nil
        end

        # Resolve paths to actual file lists
        # Expands directories, glob patterns to files within them
        # @param paths [Array<String>] Paths (files, directories, or glob patterns)
        # @return [Array<String>] List of files
        def resolve_paths(paths)
          return [] if paths.nil? || paths.empty?

          resolved = []
          paths.each do |path|
            if glob_pattern?(path)
              # Expand glob pattern to matching tracked files
              files = expand_glob_pattern(path)
              resolved.concat(files)
            elsif File.directory?(path)
              # Get all tracked files in directory
              files = files_in_path(path)
              resolved.concat(files)
            elsif File.exist?(path)
              # Single file
              resolved << path
            else
              # Path doesn't exist - we'll validate later
              resolved << path
            end
          end

          resolved.uniq.sort
        end

        # Filter files to only those within specified paths
        # @param all_files [Array<String>] All files
        # @param allowed_paths [Array<String>] Allowed paths
        # @return [Array<String>] Filtered files
        def filter_by_paths(all_files, allowed_paths)
          return all_files if allowed_paths.nil? || allowed_paths.empty?

          all_files.select do |file|
            allowed_paths.any? { |path| file_in_path?(file, path) }
          end
        end

        # Get all tracked files within specified path
        # @param path [String] Path to search
        # @return [Array<String>] List of tracked files
        def files_in_path(path)
          result = @git.execute("ls-files", path)
          result.strip.split("\n").reject(&:empty?)
        rescue GitError => e
          @last_error = e.message
          []
        end

        # Get modified files within specified paths
        # @param paths [Array<String>] Paths to check
        # @param staged [Boolean] Check staged or unstaged changes
        # @return [Array<String>] Modified files
        def modified_files_in_paths(paths, staged: false)
          return [] if paths.nil? || paths.empty?

          args = ["diff", "--name-only"]
          args << "--cached" if staged

          modified = []
          paths.each do |path|
            result = @git.execute(*args, path)
            files = result.strip.split("\n").reject(&:empty?)
            modified.concat(files)
          end

          modified.uniq.sort
        rescue GitError => e
          @last_error = e.message
          []
        end

        # Validate that paths exist
        # @param paths [Array<String>] Paths to validate
        # @return [Hash] Validation result with :valid and :invalid paths
        def validate_paths(paths)
          return { valid: [], invalid: [] } if paths.nil? || paths.empty?

          valid = []
          invalid = []

          paths.each do |path|
            if File.exist?(path)
              valid << path
            else
              invalid << path
            end
          end

          { valid: valid, invalid: invalid }
        end

        # Check if all paths exist
        # @param paths [Array<String>] Paths to check
        # @return [Boolean] True if all exist
        def all_paths_exist?(paths)
          return true if paths.nil? || paths.empty?
          paths.all? { |path| File.exist?(path) }
        end

        # Check if path contains glob pattern characters
        # @param path [String] Path to check
        # @return [Boolean] True if path is a glob pattern
        def glob_pattern?(path)
          # Check for common glob metacharacters
          path.include?('*') || path.include?('?') || path.include?('[') || path.include?('{')
        end

        # Check if path is within repository boundaries
        # @param path [String] Path to check
        # @return [Boolean] True if path is within repository
        def within_repository?(path)
          return false unless File.exist?(path)

          expanded = File.expand_path(path)
          repo_root = @git.execute("rev-parse", "--show-toplevel").strip
          expanded.start_with?(File.expand_path(repo_root))
        rescue GitError => e
          @last_error = e.message
          false
        end

        private

        # Expand glob pattern to matching tracked files
        # Uses Dir.glob for filesystem matching, then filters by git-tracked files
        # @param pattern [String] Glob pattern
        # @return [Array<String>] List of matching tracked files
        def expand_glob_pattern(pattern)
          # First, expand glob pattern on filesystem
          filesystem_matches = Dir.glob(pattern, File::FNM_PATHNAME | File::FNM_DOTMATCH)

          # Remove . and .. entries
          filesystem_matches.reject! { |f| f.end_with?('/.') || f.end_with?('/..') }

          # Filter to only files (exclude directories)
          filesystem_matches.select! { |f| File.file?(f) }

          # Get all tracked files from git
          tracked_files = get_all_tracked_files

          # Return intersection: files that match glob AND are tracked
          filesystem_matches & tracked_files
        rescue StandardError => e
          @last_error = "Failed to expand glob pattern '#{pattern}': #{e.message}"
          []
        end

        # Get all tracked files in the repository, with caching
        # @return [Array<String>] List of all git-tracked files
        def get_all_tracked_files
          return @tracked_files if @tracked_files

          result = @git.execute("ls-files")
          @tracked_files = result.strip.split("\n").reject(&:empty?)
        rescue GitError => e
          @last_error = e.message
          @tracked_files = [] # Cache empty array on error
        end

        # Check if file is within path
        # @param file [String] File path
        # @param path [String] Directory or file path
        # @return [Boolean] True if file is in path
        def file_in_path?(file, path)
          # Handle exact file match
          return true if file == path

          # Normalize path by removing trailing slash for comparison
          normalized_path = path.chomp('/')

          # Use Pathname for robust directory checking
          # Ascend through file's directory hierarchy and check for path match
          Pathname.new(file).ascend.any? { |p| p.to_s == normalized_path }
        end
      end
    end
  end
end
