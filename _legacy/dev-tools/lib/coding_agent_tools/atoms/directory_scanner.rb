# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    # DirectoryScanner - Atom for scanning directory contents
    #
    # Responsibilities:
    # - Scan directories for files matching patterns
    # - Apply exclusion patterns
    # - Return file paths in a consistent format
    class DirectoryScanner
      # Scans a directory for files matching the given pattern
      #
      # @param directory [String] Directory path to scan
      # @param pattern [String] File pattern to match (shell glob)
      # @param exclude_patterns [Array<String>] Patterns to exclude
      # @return [Array<String>] Array of file paths
      def self.scan_files(directory, pattern: "*", exclude_patterns: [])
        raise ArgumentError, "Directory does not exist: #{directory}" unless File.directory?(directory)

        # Get all files matching the pattern
        search_pattern = File.join(directory, pattern)
        matching_files = Dir.glob(search_pattern)

        # Filter out directories and excluded patterns
        matching_files.select do |file_path|
          next false unless File.file?(file_path)
          next false unless File.executable?(file_path)

          file_name = File.basename(file_path)

          # Check against exclusion patterns
          exclude_patterns.none? do |exclude_pattern|
            if exclude_pattern.include?("*")
              # Use shell glob pattern matching, not regex
              File.fnmatch(exclude_pattern, file_name)
            else
              file_name == exclude_pattern
            end
          end
        end.sort
      end

      # Scans a directory and returns basic file information
      #
      # @param directory [String] Directory path to scan
      # @param pattern [String] File pattern to match
      # @return [Array<Hash>] Array of file info hashes
      def self.scan_with_info(directory, pattern: "*")
        files = scan_files(directory, pattern: pattern)

        files.map do |file_path|
          stat = File.stat(file_path)
          {
            name: File.basename(file_path),
            path: file_path,
            size: stat.size,
            modified: stat.mtime,
            executable: File.executable?(file_path)
          }
        end
      end
    end
  end
end
