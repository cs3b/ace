# frozen_string_literal: true

require "open3"

module Ace
  module GitCommit
    module Atoms
      # GitExecutor handles low-level git command execution
      class GitExecutor
        # Execute a git command and return output
        # @param args [Array<String>] Git command arguments
        # @param capture_stderr [Boolean] Whether to capture stderr
        # @return [String] Command output
        # @raise [GitError] If command fails
        def execute(*args, capture_stderr: false)
          cmd = ["git"] + args

          if capture_stderr
            output, error, status = Open3.capture3(*cmd)
            unless status.success?
              raise GitError, "Git command failed: #{cmd.join(' ')}\nError: #{error}"
            end
            output + error
          else
            output, status = Open3.capture2(*cmd)
            unless status.success?
              raise GitError, "Git command failed: #{cmd.join(' ')}"
            end
            output
          end
        end

        # Check if we're in a git repository
        # @return [Boolean] True if in a git repo
        def in_repository?
          execute("rev-parse", "--git-dir")
          true
        rescue GitError
          false
        end

        # Get repository root
        # @return [String] Repository root path
        def repository_root
          execute("rev-parse", "--show-toplevel").strip
        end

        # Check if there are any changes
        # @return [Boolean] True if there are changes
        def has_changes?
          !execute("status", "--porcelain").strip.empty?
        end

        # Check if there are staged changes
        # @return [Boolean] True if there are staged changes
        def has_staged_changes?
          !execute("diff", "--cached", "--name-only").strip.empty?
        end
      end
    end
  end
end