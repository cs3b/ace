# frozen_string_literal: true

require "pathname"
require "find"

module CodingAgentTools
  module Atoms
    module TaskflowManagement
      # FileSystemScanner provides secure directory scanning utilities
      # This is an atom - it has no dependencies on other parts of this gem
      class FileSystemScanner
        # Scan a directory for files matching glob patterns
        # @param base_path [String] Directory to scan
        # @param patterns [Array<String>] Glob patterns to match (default: ["*"])
        # @param recursive [Boolean] Whether to scan recursively (default: false)
        # @param max_depth [Integer] Maximum recursion depth (default: 10)
        # @param max_files [Integer] Maximum number of files to return (default: 1000)
        # @return [Array<String>] Array of matching file paths
        # @raise [ArgumentError] If base_path is invalid
        # @raise [SecurityError] If path validation fails
        def self.scan_directory(base_path, patterns: ["*"], recursive: false, max_depth: 10, max_files: 1000)
          raise ArgumentError, "base_path cannot be nil or empty" if base_path.nil? || base_path.empty?
          raise ArgumentError, "patterns must be an array" unless patterns.is_a?(Array)
          raise ArgumentError, "max_depth must be positive" if max_depth <= 0
          raise ArgumentError, "max_files must be positive" if max_files <= 0

          # Basic path validation
          validate_path_safety(base_path)

          # Convert to absolute path for consistency
          abs_base_path = File.expand_path(base_path)

          # Ensure directory exists
          raise ArgumentError, "Directory does not exist: #{abs_base_path}" unless File.directory?(abs_base_path)

          matching_files = if recursive
            scan_recursive(abs_base_path, patterns, max_depth, max_files)
          else
            scan_flat(abs_base_path, patterns, max_files)
          end

          # Return relative paths for consistency
          matching_files.map { |file| make_relative_path(file, abs_base_path) }
        end

        # Find files by exact name
        # @param base_path [String] Directory to search
        # @param filename [String] Exact filename to find
        # @param recursive [Boolean] Whether to search recursively (default: true)
        # @param max_depth [Integer] Maximum recursion depth (default: 10)
        # @return [Array<String>] Array of matching file paths
        def self.find_files_by_name(base_path, filename, recursive: true, max_depth: 10)
          raise ArgumentError, "filename cannot be nil or empty" if filename.nil? || filename.empty?

          scan_directory(base_path, patterns: [filename], recursive: recursive, max_depth: max_depth)
        end

        # Find files by extension
        # @param base_path [String] Directory to search
        # @param extension [String] File extension (with or without dot)
        # @param recursive [Boolean] Whether to search recursively (default: true)
        # @param max_depth [Integer] Maximum recursion depth (default: 10)
        # @return [Array<String>] Array of matching file paths
        def self.find_files_by_extension(base_path, extension, recursive: true, max_depth: 10)
          raise ArgumentError, "extension cannot be nil or empty" if extension.nil? || extension.empty?

          # Normalize extension (ensure it starts with a dot)
          ext = extension.start_with?(".") ? extension : ".#{extension}"
          pattern = "*#{ext}"

          scan_directory(base_path, patterns: [pattern], recursive: recursive, max_depth: max_depth)
        end

        # Check if a path is safe for scanning (basic validation)
        # @param path [String] Path to validate
        # @return [Boolean] True if path appears safe
        def self.safe_path?(path)
          return false if path.nil? || path.empty?
          return false if path.include?("\0")
          return false if path.match?(/[\x00-\x1f\x7f]/)

          # Check for obvious traversal attempts
          return false if path.include?("../")
          return false if path.include?("..\\")

          true
        end

        # Find files matching a pattern (glob or directory path)
        # @param base_path [String] Directory to search from
        # @param pattern [String] Pattern to match (can be a directory path or glob pattern)
        # @param recursive [Boolean] Whether to search recursively (default: true)
        # @param max_depth [Integer] Maximum recursion depth (default: 10)
        # @param max_files [Integer] Maximum number of files to return (default: 1000)
        # @return [Hash] {files: Array<String>, success: Boolean, error: String}
        def self.find_files_with_pattern(base_path, pattern, recursive: true, max_depth: 10, max_files: 1000)
          raise ArgumentError, "base_path cannot be nil or empty" if base_path.nil? || base_path.empty?
          raise ArgumentError, "pattern cannot be nil or empty" if pattern.nil? || pattern.empty?

          # Basic path validation
          validate_path_safety(base_path)

          # Convert base_path to absolute path
          abs_base_path = File.expand_path(base_path)

          # Ensure base directory exists
          unless File.directory?(abs_base_path)
            return {
              files: [],
              success: false,
              error: "Base directory does not exist: #{abs_base_path}"
            }
          end

          # Determine if pattern is a directory path or glob pattern
          if pattern.include?("*") || pattern.include?("?") || pattern.include?("[")
            # Handle as glob pattern
            find_files_by_glob_pattern(abs_base_path, pattern, recursive, max_depth, max_files)
          else
            # Handle as directory path - expand to find all files within
            find_files_in_directory_path(abs_base_path, pattern, recursive, max_depth, max_files)
          end
        rescue SecurityError => e
          {
            files: [],
            success: false,
            error: e.message
          }
        rescue => e
          {
            files: [],
            success: false,
            error: "Unexpected error: #{e.message}"
          }
        end

        # Get directory statistics
        # @param base_path [String] Directory to analyze
        # @param max_depth [Integer] Maximum depth to scan (default: 5)
        # @return [Hash] Statistics about the directory
        def self.directory_stats(base_path, max_depth: 5)
          raise ArgumentError, "base_path cannot be nil or empty" if base_path.nil? || base_path.empty?

          validate_path_safety(base_path)

          abs_base_path = File.expand_path(base_path)

          raise ArgumentError, "Directory does not exist: #{abs_base_path}" unless File.directory?(abs_base_path)

          stats = {
            total_files: 0,
            total_directories: 0,
            total_size: 0,
            max_depth_reached: 0,
            file_types: Hash.new(0)
          }

          scan_for_stats(abs_base_path, stats, 0, max_depth)

          stats
        end

        class << self
          private

          # Validate path safety (basic checks)
          # @param path [String] Path to validate
          # @raise [SecurityError] If path is unsafe
          def validate_path_safety(path)
            raise SecurityError, "Path failed safety validation: #{path}" unless safe_path?(path)

            # Additional length check
            return unless path.length > 4096

            raise SecurityError, "Path too long: #{path.length} characters"
          end

          # Scan directory recursively
          # @param base_path [String] Base directory
          # @param patterns [Array<String>] Glob patterns
          # @param max_depth [Integer] Maximum recursion depth
          # @param max_files [Integer] Maximum files to return
          # @return [Array<String>] Matching file paths
          def scan_recursive(base_path, patterns, max_depth, max_files)
            matching_files = []

            Find.find(base_path) do |path|
              # Skip if we've reached max files
              break if matching_files.length >= max_files

              # Check depth
              relative_path = Pathname.new(path).relative_path_from(Pathname.new(base_path))
              depth = relative_path.to_s.count("/")

              if depth > max_depth
                Find.prune if File.directory?(path)
                next
              end

              # Skip directories
              next if File.directory?(path)

              # Check if file matches any pattern
              filename = File.basename(path)
              matching_files << path if patterns.any? { |pattern| File.fnmatch(pattern, filename, File::FNM_CASEFOLD) }
            end

            matching_files
          rescue Errno::ENOENT, Errno::EACCES => e
            raise SecurityError, "Directory access error: #{e.message}"
          end

          # Scan directory flat (non-recursive)
          # @param base_path [String] Base directory
          # @param patterns [Array<String>] Glob patterns
          # @param max_files [Integer] Maximum files to return
          # @return [Array<String>] Matching file paths
          def scan_flat(base_path, patterns, max_files)
            matching_files = []

            Dir.entries(base_path).each do |entry|
              break if matching_files.length >= max_files

              # Skip . and .. and directories
              next if [".", ".."].include?(entry)

              full_path = File.join(base_path, entry)
              next if File.directory?(full_path)

              # Check if file matches any pattern
              if patterns.any? { |pattern| File.fnmatch(pattern, entry, File::FNM_CASEFOLD) }
                matching_files << full_path
              end
            end

            matching_files
          rescue Errno::ENOENT, Errno::EACCES => e
            raise SecurityError, "Directory access error: #{e.message}"
          end

          # Convert absolute path to relative path
          # @param abs_path [String] Absolute path
          # @param base_path [String] Base path to make relative from
          # @return [String] Relative path
          def make_relative_path(abs_path, base_path)
            Pathname.new(abs_path).relative_path_from(Pathname.new(base_path)).to_s
          end

          # Find files using glob pattern
          # @param base_path [String] Base directory
          # @param pattern [String] Glob pattern
          # @param recursive [Boolean] Whether to search recursively
          # @param max_depth [Integer] Maximum recursion depth
          # @param max_files [Integer] Maximum files to return
          # @return [Hash] {files: Array, success: Boolean, error: String}
          def find_files_by_glob_pattern(base_path, pattern, recursive, max_depth, max_files)
            # Convert pattern to absolute path if it's relative
            full_pattern = if Pathname.new(pattern).absolute?
              pattern
            else
              File.join(base_path, pattern)
            end

            # Use Ruby's Dir.glob for glob patterns
            matching_files = Dir.glob(full_pattern).select do |path|
              File.file?(path)
            end.take(max_files)

            # Filter by depth if recursive is false or max_depth is specified
            if !recursive || max_depth < Float::INFINITY
              matching_files = filter_by_depth(matching_files, base_path, recursive, max_depth)
            end

            {
              files: matching_files.map { |f| make_relative_path(f, base_path) },
              success: true,
              error: nil
            }
          rescue => e
            {
              files: [],
              success: false,
              error: "Glob pattern error: #{e.message}"
            }
          end

          # Find files in a directory path (treating pattern as directory)
          # @param base_path [String] Base directory
          # @param dir_pattern [String] Directory path pattern
          # @param recursive [Boolean] Whether to search recursively
          # @param max_depth [Integer] Maximum recursion depth
          # @param max_files [Integer] Maximum files to return
          # @return [Hash] {files: Array, success: Boolean, error: String}
          def find_files_in_directory_path(base_path, dir_pattern, recursive, max_depth, max_files)
            # Resolve the target directory path
            target_path = if Pathname.new(dir_pattern).absolute?
              dir_pattern
            else
              File.join(base_path, dir_pattern)
            end

            # Ensure target directory exists
            unless File.directory?(target_path)
              return {
                files: [],
                success: false,
                error: "Directory does not exist: #{target_path}"
              }
            end

            # Use existing scan_directory method to find all files
            patterns = ["*"] # Match all files
            matching_files = scan_directory(target_path, patterns: patterns, recursive: recursive,
              max_depth: max_depth, max_files: max_files)

            # Convert to absolute paths and then back to relative from base_path
            abs_matching_files = matching_files.map { |relative_file| File.join(target_path, relative_file) }

            {
              files: abs_matching_files.map { |f| make_relative_path(f, base_path) },
              success: true,
              error: nil
            }
          rescue => e
            {
              files: [],
              success: false,
              error: "Directory scanning error: #{e.message}"
            }
          end

          # Filter files by depth constraints
          # @param files [Array<String>] File paths to filter
          # @param base_path [String] Base path for depth calculation
          # @param recursive [Boolean] Whether recursive search is enabled
          # @param max_depth [Integer] Maximum depth allowed
          # @return [Array<String>] Filtered file paths
          def filter_by_depth(files, base_path, recursive, max_depth)
            return [] unless recursive

            files.select do |file|
              relative_path = Pathname.new(file).relative_path_from(Pathname.new(base_path))
              depth = relative_path.to_s.count("/")
              depth <= max_depth
            end
          end

          # Scan directory for statistics
          # @param path [String] Current path
          # @param stats [Hash] Statistics accumulator
          # @param current_depth [Integer] Current recursion depth
          # @param max_depth [Integer] Maximum depth
          def scan_for_stats(path, stats, current_depth, max_depth)
            stats[:max_depth_reached] = [stats[:max_depth_reached], current_depth].max

            return if current_depth >= max_depth

            Dir.entries(path).each do |entry|
              next if [".", ".."].include?(entry)

              full_path = File.join(path, entry)

              begin
                if File.directory?(full_path)
                  stats[:total_directories] += 1
                  scan_for_stats(full_path, stats, current_depth + 1, max_depth)
                else
                  stats[:total_files] += 1

                  # Add file size if accessible
                  begin
                    stats[:total_size] += File.size(full_path)
                  rescue
                    # Skip if we can't get file size
                  end

                  # Track file extension
                  ext = File.extname(entry).downcase
                  ext = "[no extension]" if ext.empty?
                  stats[:file_types][ext] += 1
                end
              rescue Errno::ENOENT, Errno::EACCES
                # Skip files/directories we can't access
              end
            end
          end
        end
      end
    end
  end
end
