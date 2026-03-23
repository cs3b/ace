# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Pure functions for parsing diff output
      # Migrated from ace-git-diff
      module DiffParser
        class << self
          # Estimate the size of a diff in lines
          # @param diff [String] The diff content
          # @return [Integer] Number of lines
          def count_lines(diff)
            return 0 if diff.nil? || diff.empty?

            diff.count("\n") + 1
          end

          # Count significant changes (additions and deletions)
          # @param diff [String] The diff content
          # @return [Hash] Statistics about the diff
          def count_changes(diff)
            return {additions: 0, deletions: 0, files: 0, total_changes: 0} if diff.nil? || diff.empty?

            additions = 0
            deletions = 0
            files = 0

            diff.split("\n").each do |line|
              if file_header_line?(line)
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

          # Check if diff exceeds a size limit
          # @param diff [String] The diff content
          # @param max_lines [Integer] Maximum allowed lines
          # @return [Boolean] True if diff exceeds limit
          def exceeds_limit?(diff, max_lines)
            count_lines(diff) > max_lines
          end

          # Extract list of files from diff
          # @param diff [String] The diff content
          # @return [Array<String>] List of file paths
          def extract_files(diff)
            return [] if diff.nil? || diff.empty?

            files = []
            diff.split("\n").each do |line|
              if line.start_with?("diff --git")
                # Extract file path from "diff --git a/path b/path"
                if line =~ /^diff --git a\/(.+) b\/(.+)$/
                  files << Regexp.last_match(2) # Use 'b/' path (new file)
                end
              end
            end

            files.uniq
          end

          # Parse diff into structured data
          # @param diff [String] The diff content
          # @return [Hash] Parsed diff data
          def parse(diff)
            {
              content: diff,
              stats: count_changes(diff),
              files: extract_files(diff),
              line_count: count_lines(diff),
              empty: diff.nil? || diff.strip.empty?
            }
          end

          # Check if diff contains any actual changes
          # @param diff [String] The diff content
          # @return [Boolean] True if diff has changes
          def has_changes?(diff)
            return false if diff.nil? || diff.strip.empty?

            # Check for addition or deletion lines
            diff.split("\n").any? do |line|
              (line.start_with?("+") && !line.start_with?("+++")) ||
                (line.start_with?("-") && !line.start_with?("---"))
            end
          end

          private

          # Check if a line is a file header (starts a new file in diff)
          def file_header_line?(line)
            line.start_with?("diff --git")
          end
        end
      end
    end
  end
end
