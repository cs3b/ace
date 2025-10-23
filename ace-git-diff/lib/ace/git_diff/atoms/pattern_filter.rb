# frozen_string_literal: true

module Ace
  module GitDiff
    module Atoms
      # Pure functions for pattern matching and filtering
      # Extracted from ace-docs DiffFilterer but made configurable (no hardcoded patterns)
      module PatternFilter
        class << self
          # Convert glob patterns to regex patterns
          # @param glob_patterns [Array<String>] Glob patterns like "test/**/*"
          # @return [Array<Regexp>] Regex patterns for matching
          def glob_to_regex(glob_patterns)
            return [] if glob_patterns.nil? || glob_patterns.empty?

            glob_patterns.map do |pattern|
              # Escape special regex characters except glob wildcards
              regex_str = Regexp.escape(pattern)

              # Convert escaped glob patterns to regex
              regex_str = regex_str
                .gsub('\\*\\*/', '.*')     # **/ → .* (zero or more segments)
                .gsub('\\*\\*', '.*')       # ** → .* (zero or more segments)
                .gsub('\\*', '[^/]*')       # * → [^/]* (within segment)
                .gsub('\\?', '.')           # ? → . (single char)

              # Anchor to start of path
              Regexp.new("^#{regex_str}")
            end
          end

          # Check if a file path should be excluded based on patterns
          # @param file_path [String] Path to check
          # @param patterns [Array<Regexp>] Regex patterns to match against
          # @return [Boolean] True if path matches any exclude pattern
          def should_exclude?(file_path, patterns)
            return false if file_path.nil? || file_path.empty?
            return false if patterns.nil? || patterns.empty?

            patterns.any? { |pattern| file_path.match?(pattern) }
          end

          # Check if a line is a file header in git diff format
          # @param line [String] Line to check
          # @return [Boolean] True if line is a file header
          def file_header?(line)
            return false if line.nil? || line.empty?

            line.start_with?("diff --git", "+++", "---") ||
              line.match?(/^index [a-f0-9]+\.\.[a-f0-9]+/)
          end

          # Extract file path from diff header line
          # @param line [String] Diff header line
          # @return [String] Extracted file path or empty string
          def extract_file_path(line)
            return "" if line.nil? || line.empty?

            case line
            when /^diff --git a\/(.+) b\/(.+)$/
              Regexp.last_match(2) # Use the 'b/' path (new file path)
            when /^\+\+\+ b\/(.+)$/
              Regexp.last_match(1)
            when /^--- a\/(.+)$/
              Regexp.last_match(1)
            else
              ""
            end
          end

          # Filter paths from diff output based on exclude patterns
          # @param diff [String] The diff content
          # @param exclude_patterns [Array<Regexp>] Patterns to exclude
          # @return [String] Filtered diff content
          def filter_diff_by_patterns(diff, exclude_patterns)
            return "" if diff.nil? || diff.empty?
            return diff if exclude_patterns.nil? || exclude_patterns.empty?

            lines = diff.split("\n")
            filtered_lines = []
            skip_until_next_file = false

            lines.each do |line|
              # Check if this is a file header
              if file_header?(line)
                file_path = extract_file_path(line)
                if should_exclude?(file_path, exclude_patterns)
                  skip_until_next_file = true
                else
                  skip_until_next_file = false
                  filtered_lines << line
                end
              elsif !skip_until_next_file
                filtered_lines << line
              end
            end

            filtered_lines.join("\n")
          end

          # Match a path against include patterns (glob)
          # @param file_path [String] Path to check
          # @param include_patterns [Array<String>] Glob patterns to include
          # @return [Boolean] True if path matches any include pattern
          def matches_include?(file_path, include_patterns)
            return true if include_patterns.nil? || include_patterns.empty?
            return false if file_path.nil? || file_path.empty?

            regex_patterns = glob_to_regex(include_patterns)
            regex_patterns.any? { |pattern| file_path.match?(pattern) }
          end
        end
      end
    end
  end
end
