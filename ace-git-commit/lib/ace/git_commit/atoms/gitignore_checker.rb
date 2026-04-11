# frozen_string_literal: true

module Ace
  module GitCommit
    module Atoms
      # GitignoreChecker detects files that match gitignore patterns
      # Uses git check-ignore to determine if paths are ignored
      class GitignoreChecker
        # Check if a single file/path is gitignored
        # @param path [String] File or directory path to check
        # @param git_executor [GitExecutor] Git executor instance
        # @return [Boolean] True if path is gitignored
        def ignored?(path, git_executor)
          result = check_ignore(path, git_executor)
          result[:ignored]
        end

        # Check if a file is tracked in git (exists in the index)
        # @param path [String] File path to check
        # @param git_executor [GitExecutor] Git executor instance
        # @return [Boolean] True if file is tracked
        def tracked?(path, git_executor)
          # git ls-files returns the path if it's tracked, empty if not
          result = git_executor.execute("ls-files", "--error-unmatch", path)
          !result.nil? && !result.strip.empty?
        rescue GitError
          false
        end

        # Categorize paths into: valid (not gitignored), force_add (gitignored but tracked), skipped (gitignored and untracked)
        # @param paths [Array<String>] Paths to check
        # @param git_executor [GitExecutor] Git executor instance
        # @return [Hash] {:valid => [...], :force_add => [...], :skipped => [...]}
        #   - :valid - paths that are NOT gitignored
        #   - :force_add - paths that ARE gitignored but are tracked in git (use git add -f)
        #   - :skipped - paths that ARE gitignored and NOT tracked (skip these)
        def categorize_paths(paths, git_executor)
          return {valid: [], force_add: [], skipped: []} if paths.nil? || paths.empty?

          valid = []
          force_add = []
          skipped = []

          paths.each do |path|
            result = check_ignore(path, git_executor)
            if result[:ignored]
              # Path matches gitignore - check if it's tracked
              if tracked?(path, git_executor)
                # Tracked file in gitignored location - force add it
                force_add << {path: path, pattern: result[:pattern]}
              else
                # Untracked and gitignored - skip it
                skipped << {path: path, pattern: result[:pattern]}
              end
            else
              valid << path
            end
          end

          {valid: valid, force_add: force_add, skipped: skipped}
        end

        # Legacy method for backward compatibility
        # @param paths [Array<String>] Paths to check
        # @param git_executor [GitExecutor] Git executor instance
        # @return [Hash] {:valid => [...], :ignored => [...]}
        def filter_ignored(paths, git_executor)
          result = categorize_paths(paths, git_executor)
          {
            valid: result[:valid] + result[:force_add].map { |f| f[:path] },
            ignored: result[:skipped]
          }
        end

        private

        # Check a single path with git check-ignore
        # @param path [String] Path to check
        # @param git_executor [GitExecutor] Git executor instance
        # @return [Hash] {:ignored => Boolean, :pattern => String|nil}
        def check_ignore(path, git_executor)
          # git check-ignore returns:
          # - exit 0 and the matching pattern if path IS ignored
          # - exit 1 (non-zero) if path is NOT ignored
          # Use -v to get verbose output including the pattern that matched
          cmd = ["check-ignore", "-v", path]

          begin
            output = git_executor.execute(*cmd)
            # If we get here, the file IS ignored
            # Output format: "<pattern>:<line>:<source>:<path>"
            pattern = extract_pattern(output)
            {ignored: true, pattern: pattern}
          rescue GitError
            # If command fails (exit 1), file is NOT ignored
            {ignored: false, pattern: nil}
          end
        end

        # Extract the gitignore pattern from check-ignore -v output
        # @param output [String] Output from git check-ignore -v
        # @return [String, nil] The pattern that matched, or nil
        def extract_pattern(output)
          return nil if output.nil? || output.strip.empty?

          # Format: ".gitignore:3:.ace-task/**/reviews/    .ace-task/v.0.9.0/reviews/review-report-gpro.md"
          # We want the third field (the pattern)
          parts = output.strip.split("\t")
          if parts.length >= 2
            # Pattern is in the third colon-separated field of the first part
            source_parts = parts[0].split(":")
            source_parts[2] if source_parts.length >= 3
          end
        end
      end
    end
  end
end
