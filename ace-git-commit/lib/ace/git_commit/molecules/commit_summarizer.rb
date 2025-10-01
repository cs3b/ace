# frozen_string_literal: true

module Ace
  module GitCommit
    module Molecules
      # CommitSummarizer generates human-readable commit summaries
      # using git's native formatting commands
      class CommitSummarizer
        def initialize(git_executor)
          @git = git_executor
        end

        # Generate a formatted summary for a commit
        # @param commit_sha [String] The commit SHA to summarize (e.g., "HEAD", "abc123")
        # @return [String] Formatted commit summary with hash, message, and file stats
        def summarize(commit_sha)
          # Get commit info: hash (refs) message
          commit_line = @git.execute("log", "--oneline", commit_sha, "-1").strip

          # Get file stats
          stats = get_commit_stats(commit_sha)

          # Combine with newline
          "#{commit_line}\n#{stats}"
        end

        private

        # Get file statistics for a commit
        # Handles both regular commits and first commits (no parent)
        # @param commit_sha [String] The commit SHA
        # @return [String] File statistics from git diff --stat
        def get_commit_stats(commit_sha)
          # Try diff against parent first (normal case)
          @git.execute("diff", "--stat", "#{commit_sha}~1", commit_sha, capture_stderr: true)
        rescue GitError
          # If no parent (first commit), use git show
          @git.execute("show", "--stat", "--format=", commit_sha)
        end
      end
    end
  end
end
