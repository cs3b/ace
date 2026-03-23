# frozen_string_literal: true

require "pathname"

module Ace
  module GitCommit
    module Molecules
      # PathResolver handles path resolution and filtering for commits
      class PathResolver
        attr_reader :last_error

        # Status codes for renames and copies in git porcelain format
        RENAME_STATUS = "R"
        COPY_STATUS = "C"

        private_constant :RENAME_STATUS, :COPY_STATUS

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

        # Validate that paths exist or have git changes (deleted/renamed files)
        # @param paths [Array<String>] Paths to validate
        # @return [Hash] Validation result with :valid and :invalid paths
        def validate_paths(paths)
          return {valid: [], invalid: []} if paths.nil? || paths.empty?

          valid = []
          invalid = []
          git_changed_paths = nil # Lazy load
          git_changed_set = nil   # Pre-computed Set for O(1) lookups

          paths.each do |path|
            if File.exist?(path)
              valid << path
            else
              # Check if path has git changes (deleted, renamed)
              git_changed_paths ||= paths_with_git_changes
              git_changed_set ||= git_changed_paths.map { |p| p.chomp("/") }.to_set
              if path_has_git_changes?(path, git_changed_paths, git_changed_set)
                valid << path
              else
                invalid << path
              end
            end
          end

          {valid: valid, invalid: invalid}
        end

        # Check if all paths exist or have git changes (deleted/renamed files)
        # @param paths [Array<String>] Paths to check
        # @return [Boolean] True if all paths are valid
        def all_paths_exist?(paths)
          return true if paths.nil? || paths.empty?
          result = validate_paths(paths)
          result[:invalid].empty?
        end

        # Check if path contains glob pattern characters
        # @param path [String] Path to check
        # @return [Boolean] True if path is a glob pattern
        def glob_pattern?(path)
          # Check for common glob metacharacters
          path.include?("*") || path.include?("?") || path.include?("[") || path.include?("{")
        end

        # Check if pattern is a simple (non-recursive) glob pattern
        # Simple globs like *.rb only match at current directory level
        # @param pattern [String] Pattern to check
        # @return [Boolean] True if pattern is a simple glob (not recursive)
        def simple_glob_pattern?(pattern)
          glob_pattern?(pattern) && !pattern.include?("**")
        end

        # Suggest a recursive alternative for simple glob patterns
        # @param pattern [String] Pattern to analyze
        # @return [String, nil] Suggested recursive pattern, or nil if not applicable
        def suggest_recursive_pattern(pattern)
          return nil unless simple_glob_pattern?(pattern)

          # For patterns starting with *, prepend **/ for recursive matching
          # e.g., "*.rb" -> "**/*.rb"
          return "**/#{pattern}" if pattern.start_with?("*")

          # For patterns with subdirectory like "dir/*.rb", insert **/ before the glob part
          # e.g., "dir/*.rb" -> "dir/**/*.rb"
          if pattern.include?("/")
            # Find the last directory separator before the glob portion
            last_slash = pattern.rindex("/")
            dir_part = pattern[0..last_slash]
            glob_part = pattern[(last_slash + 1)..]
            return "#{dir_part}**/#{glob_part}" if glob_part.include?("*")
          end

          nil
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

        # Expand glob pattern to matching committable files
        # Uses Dir.glob for filesystem matching, then filters by git-tracked AND untracked files
        # This includes both tracked files and new untracked files (excludes gitignored)
        # @param pattern [String] Glob pattern
        # @return [Array<String>] List of matching committable files
        def expand_glob_pattern(pattern)
          # First, expand glob pattern on filesystem
          filesystem_matches = Dir.glob(pattern, File::FNM_PATHNAME | File::FNM_DOTMATCH)

          # Remove . and .. entries
          filesystem_matches.reject! { |f| f.end_with?("/.", "/..") }

          # Filter to only files (exclude directories)
          filesystem_matches.select! { |f| File.file?(f) }

          # Get all committable files (tracked + untracked, excluding gitignored)
          committable_files = get_committable_files

          # Return intersection: files that match glob AND are committable
          filesystem_matches & committable_files
        rescue => e
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

        # Get untracked files (not ignored), with caching
        # @return [Array<String>] List of untracked files
        def get_untracked_files
          return @untracked_files if @untracked_files

          result = @git.execute("ls-files", "--others", "--exclude-standard")
          @untracked_files = result.strip.split("\n").reject(&:empty?)
        rescue GitError => e
          @last_error = e.message
          @untracked_files = [] # Cache empty array on error
        end

        # Get all files that can be committed (tracked + untracked)
        # This includes tracked files with changes AND new untracked files
        # @return [Array<String>] List of committable files
        def get_committable_files
          tracked = get_all_tracked_files
          untracked = get_untracked_files
          (tracked + untracked).uniq
        end

        # Get list of paths with git changes (deleted, renamed, modified)
        # Uses -z flag for NUL-terminated output to avoid quoting issues
        # Memoized to avoid multiple git status calls within the same resolver instance
        # @return [Array<String>] List of paths with git changes
        def paths_with_git_changes
          return @git_changed_paths if @git_changed_paths

          result = @git.execute("status", "--porcelain", "-z")
          @git_changed_paths = parse_porcelain_z_output(result)
        rescue GitError => e
          @last_error = e.message
          @git_changed_paths = [] # Cache empty array on error
        end

        # Parse NUL-terminated porcelain format output
        # Format: XY path\0 or for renames/copies: XY old_path\0new_path\0
        # @param output [String] Raw git status --porcelain -z output
        # @return [Array<String>] List of paths
        def parse_porcelain_z_output(output)
          paths = []
          entries = output.split("\0")

          i = 0
          while i < entries.length
            entry = entries[i]
            i += 1
            next if entry.empty?

            # Status is first 2 chars, then space, then path
            status = entry[0..1]
            path = entry[3..-1]

            # Check for rename (R) or copy (C) status - next entry is the new path
            if status.include?(RENAME_STATUS) || status.include?(COPY_STATUS)
              paths << path  # Old path
              paths << entries[i] if i < entries.length  # New path
              i += 1
            elsif path
              paths << path
            end
          end
          paths.compact
        end

        # Check if a path has git changes
        # @param path [String] Path to check
        # @param git_changed_paths [Array<String>] List of paths with git changes
        # @param changed_set [Set<String>] Pre-computed Set of normalized paths for O(1) lookups
        # @return [Boolean] True if path has git changes
        def path_has_git_changes?(path, git_changed_paths, changed_set)
          # Normalize and strip trailing slashes for consistent comparison
          normalized = normalize_to_repo_relative(path).chomp("/")

          # Check exact match first (O(1))
          return true if changed_set.include?(normalized)

          # Check if any changed path is within this directory
          git_changed_paths.any? do |changed|
            changed.chomp("/").start_with?("#{normalized}/")
          end
        end

        # Normalize path to repo-relative form
        # Handles: ./path, absolute paths, trailing slashes
        # @param path [String] Path to normalize
        # @return [String] Repo-relative path
        def normalize_to_repo_relative(path)
          # Remove trailing slashes for normalization
          clean = path.chomp("/")

          # Remove leading ./ prefix
          clean = clean.sub(%r{^\./}, "")

          # Handle absolute paths by making them relative to repo root
          if clean.start_with?("/")
            repo_root = fetch_repo_root
            if repo_root
              if clean == repo_root
                # Exact repo root match returns '.' for current directory
                clean = "."
              elsif clean.start_with?("#{repo_root}/")
                clean = clean.sub("#{repo_root}/", "")
              end
            end
          end

          clean
        end

        # Fetch and memoize repository root path
        # @return [String, nil] Repository root path or nil on error
        def fetch_repo_root
          return @repo_root if defined?(@repo_root)
          @repo_root = @git.execute("rev-parse", "--show-toplevel").strip
        rescue GitError
          @repo_root = nil
        end

        # Check if file is within path
        # @param file [String] File path
        # @param path [String] Directory or file path
        # @return [Boolean] True if file is in path
        def file_in_path?(file, path)
          # Handle exact file match
          return true if file == path

          # Normalize path by removing trailing slash for comparison
          normalized_path = path.chomp("/")

          # Use Pathname for robust directory checking
          # Ascend through file's directory hierarchy and check for path match
          Pathname.new(file).ascend.any? { |p| p.to_s == normalized_path }
        end
      end
    end
  end
end
