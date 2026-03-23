# frozen_string_literal: true

require_relative "../atoms/git_command"

module Ace
  module Git
    module Worktree
      module Molecules
        # Task pusher molecule
        #
        # Pushes task changes to remote repository after commits.
        # Used by TaskWorktreeOrchestrator to ensure task status updates
        # are visible in PRs.
        #
        # @example Push to default remote
        #   pusher = TaskPusher.new
        #   result = pusher.push
        #
        # @example Push to specific remote and branch
        #   result = pusher.push(remote: "upstream", branch: "feature-branch")
        class TaskPusher
          # Default timeout for git push commands
          DEFAULT_TIMEOUT = 60

          # Initialize a new TaskPusher
          #
          # @param timeout [Integer] Command timeout in seconds
          def initialize(timeout: DEFAULT_TIMEOUT)
            @timeout = timeout
          end

          # Push current branch to remote
          #
          # @param remote [String] Remote name (default: "origin")
          # @param branch [String, nil] Branch name (default: current branch)
          # @param set_upstream [Boolean] Set upstream tracking (default: true)
          # @return [Hash] Result with :success, :output, :error
          #
          # @example
          #   pusher = TaskPusher.new
          #   result = pusher.push(remote: "origin")
          #   result[:success] # => true
          def push(remote: "origin", branch: nil, set_upstream: true)
            branch ||= current_branch
            return failure_result("Could not determine current branch") unless branch

            args = ["push"]
            args << "-u" if set_upstream
            args << remote
            args << branch

            result = Atoms::GitCommand.execute(*args, timeout: @timeout)

            {
              success: result[:success],
              output: result[:output],
              error: result[:error],
              remote: remote,
              branch: branch
            }
          end

          # Check if remote exists
          #
          # @param remote [String] Remote name to check
          # @return [Boolean] true if remote exists
          #
          # @example
          #   pusher.remote_exists?("origin") # => true
          def remote_exists?(remote)
            result = Atoms::GitCommand.execute("remote", "get-url", remote, timeout: 5)
            result[:success]
          end

          # Get current branch name
          #
          # @return [String, nil] Current branch name or nil if detached
          #
          # @example
          #   pusher.current_branch # => "feature-branch"
          def current_branch
            result = Atoms::GitCommand.execute("branch", "--show-current", timeout: 5)
            return nil unless result[:success]

            branch = result[:output]&.strip
            branch.empty? ? nil : branch
          end

          # Check if branch has upstream tracking
          #
          # @param branch [String, nil] Branch to check (default: current)
          # @return [Boolean] true if branch has upstream
          #
          # @example
          #   pusher.has_upstream? # => true
          def has_upstream?(branch = nil)
            branch ||= current_branch
            return false unless branch

            result = Atoms::GitCommand.execute(
              "rev-parse", "--abbrev-ref", "#{branch}@{upstream}",
              timeout: 5
            )
            result[:success]
          end

          # Set upstream tracking for a branch
          #
          # Uses `git branch --set-upstream-to` to configure tracking without pushing.
          # Useful when the remote branch already exists or push is not desired.
          #
          # @param branch [String, nil] Branch to configure (default: current)
          # @param remote [String] Remote name (default: "origin")
          # @return [Hash] Result with :success, :output, :error, :remote, :branch
          #
          # @example
          #   pusher.set_upstream(branch: "feature", remote: "origin")
          #   # => { success: true, branch: "feature", remote: "origin", ... }
          def set_upstream(branch: nil, remote: "origin")
            branch ||= current_branch
            return failure_result("Could not determine current branch") unless branch

            result = Atoms::GitCommand.execute(
              "branch", "--set-upstream-to=#{remote}/#{branch}", branch,
              timeout: @timeout
            )

            {
              success: result[:success],
              output: result[:output],
              error: result[:error],
              remote: remote,
              branch: branch
            }
          end

          # Get the upstream remote/branch for current branch
          #
          # @param branch [String, nil] Branch to check (default: current)
          # @return [Hash, nil] Hash with :remote and :branch keys, or nil
          #
          # @example
          #   pusher.get_upstream # => { remote: "origin", branch: "main" }
          def get_upstream(branch = nil)
            branch ||= current_branch
            return nil unless branch

            result = Atoms::GitCommand.execute(
              "rev-parse", "--abbrev-ref", "#{branch}@{upstream}",
              timeout: 5
            )
            return nil unless result[:success]

            upstream = result[:output]&.strip
            return nil if upstream.nil? || upstream.empty?

            # Parse "origin/branch-name" format
            parts = upstream.split("/", 2)
            return nil if parts.length < 2

            {remote: parts[0], branch: parts[1]}
          end

          private

          # Create a failure result hash
          #
          # @param message [String] Error message
          # @return [Hash] Failure result
          def failure_result(message)
            {
              success: false,
              output: "",
              error: message,
              remote: nil,
              branch: nil
            }
          end
        end
      end
    end
  end
end
