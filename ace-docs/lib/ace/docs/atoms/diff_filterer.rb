# frozen_string_literal: true

module Ace
  module Docs
    module Atoms
      # Pure functions for filtering diff content
      class DiffFilterer
        class << self
          # Default patterns to exclude from diffs
          DEFAULT_EXCLUDE_PATTERNS = [
            %r{^test/},
            %r{^spec/},
            %r{\.test\.},
            %r{\.spec\.},
            %r{^coverage/},
            %r{^tmp/},
            %r{^vendor/},
            %r{^node_modules/},
            %r{^\.git/},
            %r{Gemfile\.lock$},
            %r{package-lock\.json$},
            %r{yarn\.lock$}
          ].freeze

          # Filter paths from diff output
          # @param diff [String] The diff content
          # @param exclude_patterns [Array<Regexp>] Patterns to exclude
          # @return [String] Filtered diff content
          def filter_paths(diff, exclude_patterns = DEFAULT_EXCLUDE_PATTERNS)
            return "" if diff.nil? || diff.empty?

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

          # Estimate the size of a diff in lines
          # @param diff [String] The diff content
          # @return [Integer] Number of lines
          def estimate_size(diff)
            return 0 if diff.nil? || diff.empty?

            diff.count("\n") + 1
          end

          # Count significant changes (additions and deletions)
          # @param diff [String] The diff content
          # @return [Hash] Statistics about the diff
          def count_changes(diff)
            return {additions: 0, deletions: 0, files: 0} if diff.nil? || diff.empty?

            additions = 0
            deletions = 0
            files = 0

            diff.split("\n").each do |line|
              if file_header?(line)
                files += 1
              elsif line.start_with?("+") && !line.start_with?("+++")
                additions += 1
              elsif line.start_with?("-") && !line.start_with?("---")
                deletions += 1
              end
            end

            {
              additions: additions,
              deletions: deletions,
              files: files,
              total_changes: additions + deletions
            }
          end

          # Check if diff is too large for processing
          # @param diff [String] The diff content
          # @param max_lines [Integer] Maximum allowed lines
          # @return [Boolean] True if diff exceeds limit
          def exceeds_limit?(diff, max_lines = 100_000)
            estimate_size(diff) > max_lines
          end

          private

          # Check if a line is a file header in git diff format
          def file_header?(line)
            line.start_with?("diff --git", "+++", "---") ||
              line.match?(/^index [a-f0-9]+\.\.[a-f0-9]+/)
          end

          # Extract file path from diff header line
          def extract_file_path(line)
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

          # Check if a file path should be excluded
          def should_exclude?(file_path, patterns)
            return false if file_path.empty?

            patterns.any? { |pattern| file_path.match?(pattern) }
          end
        end
      end
    end
  end
end
