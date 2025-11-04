# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Atoms
        # Git command execution atom
        #
        # Provides a thin wrapper around ace-git-diff's CommandExecutor
        # for safe git command execution with proper error handling.
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
          # Default timeout for git commands (30 seconds)
          DEFAULT_TIMEOUT = 30

          class << self
            # Execute a git command safely using ace-git-diff's CommandExecutor
            #
            # @param args [Array<String>] Command arguments (command and its arguments)
            # @param timeout [Integer] Timeout in seconds (default: 30)
            # @return [Hash] Result hash with :success, :output, :error, :exit_code keys
            #
            # @example
            #   result = GitCommand.execute("worktree", "list")
            #   # => { success: true, output: "/path/to/worktree abc123 [branch-name]\n", error: "", exit_code: 0 }
            def execute(*args, timeout: DEFAULT_TIMEOUT)
              require "ace/git/diff/atoms/command_executor"

              # Ensure all arguments are strings
              string_args = args.map(&:to_s)

              # Execute via ace-git-diff's CommandExecutor for safety
              result = Ace::GitDiff::Atoms::CommandExecutor.execute("git", *string_args, timeout: timeout)

              # Normalize result format
              {
                success: result[:success],
                output: result[:output].to_s,
                error: result[:error].to_s,
                exit_code: result[:exit_code] || 0
              }
            rescue LoadError
              # Fallback if ace-git-diff is not available
              {
                success: false,
                output: "",
                error: "ace-git-diff gem not available for git command execution",
                exit_code: 1
              }
            rescue StandardError => e
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
            # @param timeout [Integer] Timeout in seconds
            # @return [Hash] Result hash with command execution details
            #
            # @example
            #   result = GitCommand.worktree("add", "/path/to/worktree", "-b", "feature-branch")
            def worktree(*args, timeout: DEFAULT_TIMEOUT)
              execute("worktree", *args, timeout: timeout)
            end

            # Check if git repository exists
            #
            # @return [Boolean] true if current directory is a git repository
            def git_repository?
              result = execute("rev-parse", "--git-dir", timeout: 5)
              result[:success] && !result[:output].strip.empty?
            end

            # Get current git branch name
            #
            # @return [String, nil] Current branch name or nil if not on a branch
            def current_branch
              result = execute("branch", "--show-current", timeout: 5)
              return nil unless result[:success]

              branch = result[:output].strip
              branch.empty? ? nil : branch
            end

            # Get git repository root directory
            #
            # @return [String, nil] Path to git repository root or nil if not in a git repo
            def git_root
              result = execute("rev-parse", "--show-toplevel", timeout: 5)
              return nil unless result[:success]

              root = result[:output].strip
              root.empty? ? nil : root
            end
          end
        end
      end
    end
  end
end