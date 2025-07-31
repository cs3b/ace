# frozen_string_literal: true

require "pathname"

module CodingAgentTools
  module Atoms
    module TaskflowManagement
      # DirectoryNavigator provides utilities for finding and navigating release directories
      # This is an atom - it has no dependencies on other parts of this gem
      class DirectoryNavigator
        # Default paths for task management
        DEFAULT_BASE_PATH = "dev-taskflow"
        DEFAULT_CURRENT_PATH = "dev-taskflow/current"
        DEFAULT_BACKLOG_PATH = "dev-taskflow/backlog"
        DEFAULT_TASKS_SUBDIR = "tasks"

        # Release directory pattern: v.X.Y.Z-codename
        RELEASE_DIR_PATTERN = /^v\.\d+\.\d+\.\d+/
        VERSION_EXTRACTION_REGEX = /^(v\.\d+\.\d+\.\d+)/

        # Find release directory by version
        # @param version [String] Version string (e.g., "v.0.3.0")
        # @param search_paths [Array<String>] Paths to search in (default: current, then backlog)
        # @param base_path [String] Base path for relative paths (default: current directory)
        # @return [Hash, nil] Hash with :path and :version keys, or nil if not found
        def self.find_release_directory(version, search_paths: nil, base_path: ".")
          # Check for nil first, then string type
          raise ArgumentError, "version cannot be nil or empty" if version.nil? || version.to_s.empty?
          raise ArgumentError, "version must be a string" unless version.is_a?(String)

          search_paths ||= [
            File.join(base_path, DEFAULT_CURRENT_PATH),
            File.join(base_path, DEFAULT_BACKLOG_PATH)
          ]

          search_paths.each do |search_path|
            next unless File.exist?(search_path) && File.directory?(search_path)

            matching_dirs = find_matching_directories(search_path, version)
            next if matching_dirs.empty?

            if matching_dirs.size > 1
              log_warning("Multiple release directories found for version '#{version}' in #{search_path}: #{matching_dirs.map { |d| File.basename(d) }.join(", ")}. Using the first one.")
            end

            return {
              path: matching_dirs.first,
              version: version
            }
          end

          nil
        end

        # Get current release directory
        # @param base_path [String] Base path for relative paths (default: current directory)
        # @return [Hash, nil] Hash with :path and :version keys, or nil if not found
        def self.get_current_release_directory(base_path: ".")
          current_path = File.join(base_path, DEFAULT_CURRENT_PATH)

          unless File.exist?(current_path) && File.directory?(current_path)
            return nil
          end

          subdirs = Dir.entries(current_path).select do |entry|
            next false if entry == "." || entry == ".."
            next false unless File.directory?(File.join(current_path, entry))
            # Only include directories that match the version pattern
            !extract_version_from_directory_name(entry).nil?
          end

          case subdirs.size
          when 0
            nil
          when 1
            dir_path = File.join(current_path, subdirs.first)
            version = extract_version_from_directory_name(subdirs.first)

            if version
              {
                path: dir_path,
                version: version
              }
            end
          else
            log_warning("Multiple release directories found in #{current_path}: #{subdirs.join(", ")}. Using the first one.")
            dir_path = File.join(current_path, subdirs.first)
            version = extract_version_from_directory_name(subdirs.first)

            if version
              {
                path: dir_path,
                version: version
              }
            end
          end
        end

        # Find tasks directory within a release directory
        # @param release_path [String] Path to release directory
        # @param tasks_subdir [String] Name of tasks subdirectory (default: "tasks")
        # @return [String, nil] Path to tasks directory, or nil if not found
        def self.find_tasks_directory(release_path, tasks_subdir: DEFAULT_TASKS_SUBDIR)
          raise ArgumentError, "release_path cannot be nil or empty" if release_path.nil? || release_path.empty?

          tasks_path = File.join(release_path, tasks_subdir)

          if File.exist?(tasks_path) && File.directory?(tasks_path)
            tasks_path
          end
        end

        # List all release directories in a given path
        # @param search_path [String] Path to search for release directories
        # @return [Array<Hash>] Array of hashes with :path and :version keys
        def self.list_release_directories(search_path)
          raise ArgumentError, "search_path cannot be nil or empty" if search_path.nil? || search_path.empty?

          unless File.exist?(search_path) && File.directory?(search_path)
            return []
          end

          directories = []

          begin
            Dir.entries(search_path).each do |entry|
              next if entry == "." || entry == ".."

              full_path = File.join(search_path, entry)
              next unless File.directory?(full_path)

              version = extract_version_from_directory_name(entry)
              next unless version

              directories << {
                path: full_path,
                version: version,
                name: entry
              }
            end
          rescue Errno::EACCES
            # Handle permission denied errors gracefully by returning empty array
            return []
          end

          # Sort by version
          directories.sort do |a, b|
            compare_versions(a[:version], b[:version])
          end
        end

        # Validate directory path safety
        # @param path [String] Path to validate
        # @return [Boolean] True if path appears safe
        def self.safe_directory_path?(path)
          return false unless path.is_a?(String)
          return false if path.nil? || path.empty?
          return false if path.include?("\0")
          return false if path.match?(/[\x00-\x1f\x7f]/)

          # Check for obvious traversal attempts
          return false if path.include?("../")
          return false if path.include?("..\\")

          # Check for excessively long paths
          return false if path.length > 4096

          true
        end

        # Create directory if it doesn't exist
        # @param path [String] Directory path to create
        # @param recursive [Boolean] Whether to create parent directories (default: true)
        # @return [Boolean] True if directory was created or already exists
        # @raise [ArgumentError] If path is invalid
        # @raise [SecurityError] If path is unsafe
        def self.ensure_directory_exists(path, recursive: true)
          raise ArgumentError, "path cannot be nil or empty" if path.nil? || path.empty?
          raise SecurityError, "path failed safety validation" unless safe_directory_path?(path)

          return true if File.exist?(path) && File.directory?(path)

          begin
            if recursive
              FileUtils.mkdir_p(path)
            else
              Dir.mkdir(path)
            end
            true
          rescue SystemCallError => e
            raise SecurityError, "Failed to create directory: #{e.message}"
          end
        end

        # Get relative path from base to target
        # @param target_path [String] Target path
        # @param base_path [String] Base path to make relative from
        # @return [String] Relative path
        def self.relative_path(target_path, base_path)
          raise ArgumentError, "target_path cannot be nil or empty" if target_path.nil? || target_path.empty?
          raise ArgumentError, "base_path cannot be nil or empty" if base_path.nil? || base_path.empty?

          Pathname.new(target_path).relative_path_from(Pathname.new(base_path)).to_s
        end

        # Class variable to control warning output (for testing)
        @suppress_warnings = false

        class << self
          attr_accessor :suppress_warnings

          private

          # Log warning message (can be suppressed for testing)
          # @param message [String] Warning message to log
          def log_warning(message)
            warn("Warning: #{message}") unless suppress_warnings
          end

          # Find directories matching version prefix
          # @param search_path [String] Path to search in
          # @param version [String] Version to match
          # @return [Array<String>] Array of matching directory paths
          def find_matching_directories(search_path, version)
            matching_dirs = []

            Dir.entries(search_path).each do |entry|
              next if entry == "." || entry == ".."

              full_path = File.join(search_path, entry)
              next unless File.directory?(full_path)

              if entry.start_with?(version)
                matching_dirs << full_path
              end
            end

            matching_dirs
          end

          # Extract version from directory name
          # @param directory_name [String] Directory name (e.g., "v.0.3.0-migration")
          # @return [String, nil] Version string or nil if not found
          def extract_version_from_directory_name(directory_name)
            match = directory_name.match(VERSION_EXTRACTION_REGEX)
            match ? match[1] : nil
          end

          # Compare two version strings
          # @param version_a [String] First version
          # @param version_b [String] Second version
          # @return [Integer] -1, 0, or 1
          def compare_versions(version_a, version_b)
            return 0 if version_a == version_b

            # Extract numeric parts
            parts_a = version_a.gsub(/^v\./, "").split(".").map(&:to_i)
            parts_b = version_b.gsub(/^v\./, "").split(".").map(&:to_i)

            # Compare each part
            [parts_a.length, parts_b.length].max.times do |i|
              part_a = parts_a[i] || 0
              part_b = parts_b[i] || 0

              comparison = part_a <=> part_b
              return comparison if comparison != 0
            end

            0
          end
        end
      end
    end
  end
end
