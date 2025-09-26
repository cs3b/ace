# frozen_string_literal: true

module Ace
  module GitCommit
    module Molecules
      # DiffAnalyzer analyzes git diffs and extracts information for commit message generation
      class DiffAnalyzer
        def initialize(git_executor)
          @git = git_executor
        end

        # Get the diff for staged changes
        # @param files [Array<String>, nil] Specific files to diff
        # @return [String] The diff output
        def get_staged_diff(files = nil)
          args = ["diff", "--cached"]
          args += ["--"] + files if files && !files.empty?
          @git.execute(*args)
        end

        # Get the diff for all changes (staged and unstaged)
        # @param files [Array<String>, nil] Specific files to diff
        # @return [String] The diff output
        def get_all_diff(files = nil)
          args = ["diff", "HEAD"]
          args += ["--"] + files if files && !files.empty?
          @git.execute(*args)
        rescue GitError
          # If HEAD doesn't exist (new repo), get all changes
          get_unstaged_diff(files)
        end

        # Get the diff for unstaged changes
        # @param files [Array<String>, nil] Specific files to diff
        # @return [String] The diff output
        def get_unstaged_diff(files = nil)
          args = ["diff"]
          args += ["--"] + files if files && !files.empty?
          @git.execute(*args)
        end

        # Get list of changed files
        # @param staged_only [Boolean] Only staged files
        # @return [Array<String>] List of file paths
        def changed_files(staged_only: false)
          if staged_only
            @git.execute("diff", "--cached", "--name-only").strip.split("\n")
          else
            # Get all changed files (staged, unstaged, and untracked)
            staged = @git.execute("diff", "--cached", "--name-only").strip.split("\n")
            unstaged = @git.execute("diff", "--name-only").strip.split("\n")
            untracked = @git.execute("ls-files", "--others", "--exclude-standard").strip.split("\n")
            (staged + unstaged + untracked).uniq
          end
        end

        # Analyze diff to extract summary information
        # @param diff [String] The diff to analyze
        # @return [Hash] Summary with :files_changed, :insertions, :deletions
        def analyze_diff(diff)
          files = []
          insertions = 0
          deletions = 0

          diff.lines.each do |line|
            if line.start_with?("+++")
              # Extract file path from +++ line
              file = line.sub(/^\+\+\+ b\//, "").strip
              files << file unless file == "/dev/null"
            elsif line.start_with?("+") && !line.start_with?("+++")
              insertions += 1
            elsif line.start_with?("-") && !line.start_with?("---")
              deletions += 1
            end
          end

          {
            files_changed: files.uniq,
            insertions: insertions,
            deletions: deletions
          }
        end

        # Detect the scope from changed files
        # @param files [Array<String>] List of file paths
        # @return [String, nil] Detected scope or nil
        def detect_scope(files)
          return nil if files.empty?

          # Check if all files are in a specific directory/component
          if files.all? { |f| f.start_with?("ace-") }
            # All files in a specific ace gem
            gem = files.first.split("/").first
            return gem
          end

          # Check common patterns
          if files.all? { |f| f.match?(%r{(^|/)test/}) || f.match?(%r{(^|/)spec/}) }
            return "test"
          elsif files.all? { |f| f.end_with?(".md") }
            return "docs"
          elsif files.all? { |f| f.include?("config") }
            return "config"
          end

          nil
        end
      end
    end
  end
end