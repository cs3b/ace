# frozen_string_literal: true

require_relative '../atoms/file_reader'
require_relative '../atoms/glob_expander'
require_relative 'project_root_finder'

module Ace
  module Core
    module Molecules
      # Aggregates file contents from multiple sources using atoms
      class FileAggregator
        def initialize(options = {})
          @max_size = options[:max_size] || Atoms::FileReader::MAX_FILE_SIZE
          @base_dir = options[:base_dir] || ProjectRootFinder.find_or_current
          @exclude_patterns = options[:exclude] || []
        end

        # Aggregate files from patterns
        # @param patterns [Array<String>] File patterns to aggregate
        # @return [Hash] {files: Array, errors: Array, stats: Hash}
        def aggregate(patterns)
          result = {
            files: [],
            errors: [],
            stats: {
              total_size: 0,
              file_count: 0,
              error_count: 0,
              skipped_count: 0
            }
          }

          patterns = Array(patterns).compact
          return result if patterns.empty?

          # Expand all patterns
          all_files = expand_patterns(patterns)

          # Apply exclusions
          filtered_files = filter_exclusions(all_files)

          # Track skipped files
          skipped_count = all_files.size - filtered_files.size
          result[:stats][:skipped_count] = skipped_count

          # Read each file
          filtered_files.each do |file_path|
            process_file(file_path, result)
          end

          result
        end

        # Aggregate specific files (no pattern expansion)
        # @param file_paths [Array<String>] Direct file paths
        # @return [Hash] {files: Array, errors: Array, stats: Hash}
        def aggregate_files(file_paths)
          result = {
            files: [],
            errors: [],
            stats: {
              total_size: 0,
              file_count: 0,
              error_count: 0,
              skipped_count: 0
            }
          }

          file_paths = Array(file_paths).compact
          return result if file_paths.empty?

          file_paths.each do |file_path|
            # Apply exclusions even to direct paths
            if excluded?(file_path)
              result[:stats][:skipped_count] += 1
              next
            end

            process_file(file_path, result)
          end

          result
        end

        # Find and aggregate files by name pattern
        # @param pattern [String] File name pattern
        # @param max_depth [Integer] Maximum directory depth
        # @return [Hash] {files: Array, errors: Array, stats: Hash}
        def find_and_aggregate(pattern, max_depth: nil)
          files = Atoms::GlobExpander.find_files(
            pattern,
            base_dir: @base_dir,
            max_depth: max_depth
          )

          aggregate_files(files)
        end

        private

        # Expand patterns to file paths
        # @param patterns [Array<String>] Patterns to expand
        # @return [Array<String>] Expanded file paths
        def expand_patterns(patterns)
          Atoms::GlobExpander.expand_multiple(
            patterns,
            base_dir: @base_dir
          )
        end

        # Filter out excluded files
        # @param files [Array<String>] Files to filter
        # @return [Array<String>] Filtered files
        def filter_exclusions(files)
          return files if @exclude_patterns.empty?

          Atoms::GlobExpander.filter_excluded(
            files,
            @exclude_patterns
          )
        end

        # Check if file is excluded
        # @param file_path [String] File path to check
        # @return [Boolean] true if excluded
        def excluded?(file_path)
          return false if @exclude_patterns.empty?

          Atoms::GlobExpander.matches?(
            file_path,
            @exclude_patterns
          )
        end

        # Process a single file
        # @param file_path [String] File path
        # @param result [Hash] Result hash to update
        def process_file(file_path, result)
          # Resolve file path relative to base directory if not absolute
          resolved_path = File.absolute_path?(file_path) ? file_path : File.join(@base_dir, file_path)

          # Make path relative to base directory for display
          display_path = make_relative_path(resolved_path)

          # Check if file is readable
          unless Atoms::FileReader.readable?(resolved_path)
            result[:errors] << "File not readable: #{display_path}"
            result[:stats][:error_count] += 1
            return
          end

          # Check if file is binary
          if Atoms::FileReader.binary?(resolved_path)
            result[:errors] << "Binary file skipped: #{display_path}"
            result[:stats][:skipped_count] += 1
            return
          end

          # Read file content
          read_result = Atoms::FileReader.read(resolved_path, max_size: @max_size)

          if read_result[:success]
            result[:files] << {
              path: display_path,
              absolute_path: File.expand_path(resolved_path),
              content: read_result[:content],
              size: read_result[:size]
            }

            result[:stats][:file_count] += 1
            result[:stats][:total_size] += read_result[:size]
          else
            result[:errors] << "Failed to read #{display_path}: #{read_result[:error]}"
            result[:stats][:error_count] += 1
          end
        end

        # Make path relative to base directory
        # @param path [String] Path to make relative
        # @return [String] Relative path if possible
        def make_relative_path(path)
          absolute = File.expand_path(path)
          base_absolute = File.expand_path(@base_dir)

          if absolute.start_with?(base_absolute)
            Pathname.new(absolute).relative_path_from(Pathname.new(base_absolute)).to_s
          else
            path
          end
        rescue
          path
        end
      end
    end
  end
end