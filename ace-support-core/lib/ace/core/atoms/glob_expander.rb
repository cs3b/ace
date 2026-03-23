# frozen_string_literal: true

require "pathname"

module Ace
  module Core
    module Atoms
      # Pure glob pattern expansion and file matching functions
      module GlobExpander
        module_function

        # Expand glob pattern to file paths
        # @param pattern [String] Glob pattern
        # @param base_dir [String] Base directory for relative patterns
        # @param flags [Integer] File::FNM_* flags for matching
        # @return [Array<String>] Matched file paths
        def expand(pattern, base_dir: Dir.pwd, flags: 0)
          return [] if pattern.nil? || pattern.empty?

          # Ensure base_dir is absolute
          base_dir = File.expand_path(base_dir)

          # Handle absolute patterns
          if pattern.start_with?("/")
            Dir.glob(pattern, flags).sort
          else
            # Make pattern relative to base_dir
            full_pattern = File.join(base_dir, pattern)
            Dir.glob(full_pattern, flags).map do |path|
              # Return relative paths from base_dir
              Pathname.new(path).relative_path_from(Pathname.new(base_dir)).to_s
            rescue ArgumentError
              # If we can't make it relative, return absolute
              path
            end.sort
          end
        rescue
          []
        end

        # Expand multiple glob patterns
        # @param patterns [Array<String>] Array of glob patterns
        # @param base_dir [String] Base directory for relative patterns
        # @param flags [Integer] File::FNM_* flags for matching
        # @return [Array<String>] Unique sorted file paths
        def expand_multiple(patterns, base_dir: Dir.pwd, flags: 0)
          return [] if patterns.nil? || patterns.empty?

          patterns = Array(patterns)
          results = []

          patterns.each do |pattern|
            results.concat(expand(pattern, base_dir: base_dir, flags: flags))
          end

          results.uniq.sort
        end

        # Check if path matches any of the patterns
        # @param path [String] File path to check
        # @param patterns [Array<String>] Patterns to match against
        # @param flags [Integer] File::FNM_* flags for matching
        # @return [Boolean] true if path matches any pattern
        def matches?(path, patterns, flags: File::FNM_PATHNAME)
          return false if path.nil? || patterns.nil?

          patterns = Array(patterns)
          patterns.any? do |pattern|
            File.fnmatch(pattern, path, flags)
          end
        end

        # Filter paths by exclusion patterns
        # @param paths [Array<String>] Paths to filter
        # @param exclude_patterns [Array<String>] Patterns to exclude
        # @param flags [Integer] File::FNM_* flags for matching
        # @return [Array<String>] Filtered paths
        def filter_excluded(paths, exclude_patterns, flags: File::FNM_PATHNAME)
          return paths if paths.nil? || exclude_patterns.nil? || exclude_patterns.empty?

          paths.reject do |path|
            matches?(path, exclude_patterns, flags: flags)
          end
        end

        # Expand pattern with exclusions
        # @param pattern [String] Glob pattern to expand
        # @param exclude [Array<String>] Patterns to exclude
        # @param base_dir [String] Base directory
        # @return [Array<String>] Matched paths excluding excluded ones
        def expand_with_exclusions(pattern, exclude: [], base_dir: Dir.pwd)
          expanded = expand(pattern, base_dir: base_dir)
          return expanded if exclude.nil? || exclude.empty?

          filter_excluded(expanded, exclude)
        end

        # Find files recursively with pattern
        # @param pattern [String] File name pattern
        # @param base_dir [String] Starting directory
        # @param max_depth [Integer] Maximum directory depth (nil for unlimited)
        # @return [Array<String>] Found file paths
        def find_files(pattern, base_dir: Dir.pwd, max_depth: nil)
          return [] if pattern.nil?

          base_dir = File.expand_path(base_dir)
          results = []

          # Build the glob pattern based on depth
          if max_depth.nil?
            glob_pattern = File.join(base_dir, "**", pattern)
          else
            # Build pattern with limited depth
            depth_pattern = (0..max_depth).map do |depth|
              parts = ["*"] * depth
              File.join(base_dir, *parts, pattern)
            end

            depth_pattern.each do |p|
              results.concat(Dir.glob(p))
            end

            return results.map do |path|
              Pathname.new(path).relative_path_from(Pathname.new(base_dir)).to_s
            rescue ArgumentError
              path
            end.uniq.sort
          end

          Dir.glob(glob_pattern).map do |path|
            Pathname.new(path).relative_path_from(Pathname.new(base_dir)).to_s
          rescue ArgumentError
            path
          end.sort
        end

        # Check if pattern is a glob pattern
        # @param pattern [String] Pattern to check
        # @return [Boolean] true if pattern contains glob characters
        def glob_pattern?(pattern)
          return false if pattern.nil?

          pattern.match?(/[*?\[{]/)
        end

        # Normalize path separators for current OS
        # @param path [String] Path to normalize
        # @return [String] Normalized path
        def normalize_separators(path)
          return nil if path.nil?

          path.gsub(/[\\\/]+/, File::SEPARATOR)
        end

        # Convert glob pattern to regex
        # @param pattern [String] Glob pattern
        # @return [Regexp] Regular expression equivalent
        def to_regex(pattern)
          return nil if pattern.nil?

          # Escape special regex characters except glob ones
          escaped = pattern.gsub(/[.+^$()|\[\]{}\\]/) { |m| "\\#{m}" }

          # Convert glob patterns to regex
          regex_pattern = escaped
            .gsub("**/", ".*/")      # ** matches any depth
            .gsub("*", "[^/]*")       # * matches within directory
            .tr("?", ".")           # ? matches single character

          Regexp.new("^#{regex_pattern}$")
        end
      end
    end
  end
end
