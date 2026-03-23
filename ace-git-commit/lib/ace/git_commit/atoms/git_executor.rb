# frozen_string_literal: true

require "ace/git"

module Ace
  module GitCommit
    module Atoms
      # GitExecutor handles low-level git command execution
      # Delegates to ace-git for command execution
      class GitExecutor
        # Execute a git command and return output
        # @param args [Array<String>] Git command arguments
        # @param capture_stderr [Boolean] Whether to capture stderr (ignored, always captured)
        # @return [String] Command output
        # @raise [GitError] If command fails
        def execute(*args, capture_stderr: false)
          cmd = ["git"] + args
          result = Ace::Git::Atoms::CommandExecutor.execute(*cmd)

          unless result[:success]
            error_msg = "Git command failed: #{cmd.join(" ")}"
            error_msg += "\nError: #{result[:error]}" if result[:error] && !result[:error].empty?
            raise GitError, error_msg
          end

          # Combine output and error if capture_stderr is true
          if capture_stderr && result[:error] && !result[:error].empty?
            result[:output] + result[:error]
          else
            result[:output]
          end
        end

        # Check if we're in a git repository
        # @return [Boolean] True if in a git repo
        def in_repository?
          Ace::Git::Atoms::CommandExecutor.in_git_repo?
        end

        # Get repository root
        # @return [String] Repository root path
        def repository_root
          Ace::Git::Atoms::CommandExecutor.repo_root
        end

        # Check if there are any changes
        # @return [Boolean] True if there are changes
        def has_changes?
          Ace::Git::Atoms::CommandExecutor.has_unstaged_changes? ||
            Ace::Git::Atoms::CommandExecutor.has_staged_changes? ||
            Ace::Git::Atoms::CommandExecutor.has_untracked_changes?
        end

        # Check if there are staged changes
        # @return [Boolean] True if there are staged changes
        def has_staged_changes?
          Ace::Git::Atoms::CommandExecutor.has_staged_changes?
        end
      end
    end
  end
end
