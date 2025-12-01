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
              begin
              require "ace/git/diff/atoms/command_executor"
            rescue LoadError
              # Try alternative path for local development
              require "ace/git_diff/atoms/command_executor"
            end

              # Ensure all arguments are strings
              string_args = args.map(&:to_s)

              # Execute via ace-git-diff's CommandExecutor for safety
              # Note: CommandExecutor doesn't support timeout parameter
              result = Ace::GitDiff::Atoms::CommandExecutor.execute("git", *string_args)

              # Normalize result format
              {
                success: result[:success],
                output: result[:output].to_s,
                error: result[:error].to_s,
                exit_code: result[:exit_code] || 0
              }
            rescue LoadError
              # Fallback if ace-git-diff is not available - use system git directly
              begin
                require "open3"
                stdout, stderr, status = Open3.capture3("git", *string_args)
                {
                  success: status.success?,
                  output: stdout,
                  error: stderr,
                  exit_code: status.exitstatus
                }
              rescue StandardError => e
                {
                  success: false,
                  output: "",
                  error: "Failed to execute git command: #{e.message}",
                  exit_code: 1
                }
              end
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

            # Get current git branch name or commit SHA if in detached HEAD state
            #
            # @return [String, nil] Current branch name, commit SHA (if detached), or nil on error
            def current_branch
              result = execute("branch", "--show-current", timeout: 5)
              return nil unless result[:success]

              branch = result[:output].strip
              return branch unless branch.empty?

              # Detached HEAD - return commit SHA
              sha_result = execute("rev-parse", "HEAD", timeout: 5)
              return nil unless sha_result[:success]

              sha = sha_result[:output].strip
              sha.empty? ? nil : sha
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