# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Atoms
        # Git command execution atom
        #
        # Provides a thin wrapper around ace-git's CommandExecutor
        # for safe git command execution with proper error handling.
        # This adapter maintains backward compatibility with the original API
        # while delegating to the consolidated ace-git package.
        #
        # @example Execute a git worktree command
        #   GitCommand.execute("worktree", "add", "/path/to/worktree", "-b", "feature-branch")
        #
        # @example Handle command failures
        #   result = GitCommand.execute("worktree", "add", "/invalid/path")
        #   unless result[:success]
        #     puts "Error: #{result[:error]}"
        #   end
        class GitCommand
          # Fallback timeout for git commands (30 seconds)
          # Used only when config is unavailable
          FALLBACK_TIMEOUT = 30

          class << self
            # Get default timeout from config or fallback
            # @return [Integer] Timeout in seconds
            def default_timeout
              Ace::Git::Worktree.default_timeout
            rescue
              FALLBACK_TIMEOUT
            end

            # Execute a git command safely using ace-git's CommandExecutor
            #
            # @param args [Array<String>] Command arguments (command and its arguments)
            # @param timeout [Integer, nil] Timeout in seconds (uses config default if nil)
            # @return [Hash] Result hash with :success, :output, :error, :exit_code keys
            #
            # @example
            #   result = GitCommand.execute("worktree", "list")
            #   # => { success: true, output: "/path/to/worktree abc123 [branch-name]\n", error: "", exit_code: 0 }
            def execute(*args, timeout: nil)
              timeout ||= default_timeout
              # Ensure all arguments are strings
              string_args = args.map(&:to_s)

              # Delegate to ace-git's CommandExecutor
              # Note: CommandExecutor expects "git" as first argument
              result = Ace::Git::Atoms::CommandExecutor.execute("git", *string_args, timeout:)

              # Normalize ace-git result keys for legacy compatibility
              {
                success: result[:success],
                output: result[:output].to_s,
                error: result[:error].to_s,
                exit_code: result[:exit_code] || 0
              }
            rescue => e
              # Handle unexpected exceptions from ace-git to maintain defensive behavior
              {
                success: false,
                output: "",
                error: "Unexpected error: #{e.message}",
                exit_code: 1
              }
            end

            # Execute a git worktree command
            #
            # @param args [Array<String>] Worktree subcommand arguments
            # @param timeout [Integer, nil] Timeout in seconds (uses config default if nil)
            # @return [Hash] Result hash with command execution details
            #
            # @example
            #   result = GitCommand.worktree("add", "/path/to/worktree", "-b", "feature-branch")
            def worktree(*args, timeout: nil)
              execute("worktree", *args, timeout: timeout)
            end

            # Check if git repository exists
            #
            # @return [Boolean] true if current directory is a git repository
            def git_repository?
              Ace::Git::Atoms::CommandExecutor.in_git_repo?
            end

            # Get current git branch name or commit SHA if in detached HEAD state
            #
            # @return [String, nil] Current branch name, commit SHA (if detached), or nil on error
            def current_branch
              # ace-git's current_branch now handles detached HEAD state
              # and returns SHA directly when detached
              Ace::Git::Atoms::CommandExecutor.current_branch
            end

            # Check if a git ref (branch, tag, commit SHA) exists
            #
            # @param ref [String] Git ref to validate
            # @return [Boolean] true if ref exists
            def ref_exists?(ref)
              result = execute("rev-parse", "--verify", "--quiet", ref, timeout: 5)
              result[:success]
            end

            # Get git repository root directory
            #
            # Delegates to ace-git's CommandExecutor for repository root detection
            #
            # @return [String, nil] Path to git repository root or nil if not in a git repo
            def git_root
              Ace::Git::Atoms::CommandExecutor.repo_root
            end
          end
        end
      end
    end
  end
end
