# frozen_string_literal: true

module Ace
  module GitDiff
    module Molecules
      # Apply filtering to diff output based on configuration
      class DiffFilter
        class << self
          # Filter diff content based on configuration
          # @param diff [String] Raw diff content
          # @param config [Models::DiffConfig] Diff configuration
          # @return [String] Filtered diff content
          def filter(diff, config)
            return "" if diff.nil? || diff.empty?
            return diff if config.exclude_patterns.empty?

            # Convert glob patterns to regex
            regex_patterns = Atoms::PatternFilter.glob_to_regex(config.exclude_patterns)

            # Apply pattern filtering
            filtered = Atoms::PatternFilter.filter_diff_by_patterns(diff, regex_patterns)

            # Check if exceeds max lines
            if config.max_lines && Atoms::DiffParser.exceeds_limit?(filtered, config.max_lines)
              truncate(filtered, config.max_lines)
            else
              filtered
            end
          end

          # Apply only path-based filtering (no size limits)
          # @param diff [String] Raw diff content
          # @param exclude_patterns [Array<String>] Glob patterns to exclude
          # @return [String] Filtered diff content
          def filter_by_patterns(diff, exclude_patterns)
            return diff if diff.nil? || diff.empty? || exclude_patterns.empty?

            regex_patterns = Atoms::PatternFilter.glob_to_regex(exclude_patterns)
            Atoms::PatternFilter.filter_diff_by_patterns(diff, regex_patterns)
          end

          # Apply include patterns (only show matching files)
          # @param diff [String] Raw diff content
          # @param include_patterns [Array<String>] Glob patterns to include
          # @return [String] Filtered diff content
          def filter_by_includes(diff, include_patterns)
            return diff if diff.nil? || diff.empty? || include_patterns.empty?

            # Get all files in diff
            files = Atoms::DiffParser.extract_files(diff)

            # Filter to only included files
            included_files = files.select do |file|
              Atoms::PatternFilter.matches_include?(file, include_patterns)
            end

            # If no files match, return empty
            return "" if included_files.empty?

            # Filter diff to only included files
            # (This is a simplified implementation - could be enhanced)
            diff
          end

          # Truncate diff to maximum number of lines
          # @param diff [String] Diff content
          # @param max_lines [Integer] Maximum lines to keep
          # @return [String] Truncated diff with note
          def truncate(diff, max_lines)
            return diff if diff.nil? || diff.empty?

            lines = diff.split("\n")
            return diff if lines.length <= max_lines

            truncated = lines[0...max_lines].join("\n")
            truncated + "\n\n... (diff truncated at #{max_lines} lines)"
          end

          # Get filtering statistics
          # @param original [String] Original diff
          # @param filtered [String] Filtered diff
          # @return [Hash] Statistics about filtering
          def stats(original, filtered)
            original_stats = Atoms::DiffParser.count_changes(original)
            filtered_stats = Atoms::DiffParser.count_changes(filtered)

            {
              original: original_stats,
              filtered: filtered_stats,
              files_removed: original_stats[:files] - filtered_stats[:files],
              lines_removed: Atoms::DiffParser.count_lines(original) - Atoms::DiffParser.count_lines(filtered)
            }
          end
        end
      end
    end
  end
end
