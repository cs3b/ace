# frozen_string_literal: true

module Ace
  module Git
    module Molecules
      # Generate diffs using git commands with configuration options
      # Migrated from ace-git-diff
      class DiffGenerator
        class << self
          # Generate diff based on configuration
          # @param config [Models::DiffConfig] Diff configuration
          # @param executor [Module] Command executor (default: Atoms::CommandExecutor)
          # @return [String] Raw diff output
          def generate(config, executor: Atoms::CommandExecutor)
            # Handle special cases first
            return executor.staged_diff if config.format == :staged
            return executor.working_diff if config.format == :working

            # Determine what to diff
            range = determine_range(config, executor)

            # Build git diff command
            cmd_parts = build_command(range, config)

            # Execute with configured timeout
            result = executor.execute(*cmd_parts, timeout: config.timeout)
            handle_result(result, cmd_parts)
          end

          # Generate diff for a specific range
          # @param range [String] Git range (e.g., "HEAD~5..HEAD", "origin/main...HEAD")
          # @param config [Models::DiffConfig] Configuration options
          # @param executor [Module] Command executor
          # @return [String] Diff output
          def generate_for_range(range, config, executor: Atoms::CommandExecutor)
            cmd_parts = build_command(range, config)
            result = executor.execute(*cmd_parts, timeout: config.timeout)
            handle_result(result, cmd_parts)
          end

          # Generate diff since a date or commit
          # @param since [String] Date or commit reference
          # @param config [Models::DiffConfig] Configuration options
          # @param executor [Module] Command executor
          # @return [String] Diff output
          def generate_since(since, config, executor: Atoms::CommandExecutor)
            # Resolve since to commit
            since_ref = Atoms::DateResolver.resolve_since_to_commit(since, executor: executor)
            range = "#{since_ref}..HEAD"

            generate_for_range(range, config, executor: executor)
          end

          # Get staged diff with configuration
          # @param config [Models::DiffConfig] Configuration options
          # @param executor [Module] Command executor
          # @return [String] Staged diff output
          def staged(config, executor: Atoms::CommandExecutor)
            cmd_parts = build_command("--cached", config)
            result = executor.execute(*cmd_parts, timeout: config.timeout)
            handle_result(result, cmd_parts)
          end

          # Get working directory diff with configuration
          # @param config [Models::DiffConfig] Configuration options
          # @param executor [Module] Command executor
          # @return [String] Working diff output
          def working(config, executor: Atoms::CommandExecutor)
            cmd_parts = build_command(nil, config)
            result = executor.execute(*cmd_parts, timeout: config.timeout)
            handle_result(result, cmd_parts)
          end

          private

          # Handle command execution result, raising error on failure
          # @param result [Hash] Command execution result with :success, :output, :error keys
          # @param cmd_parts [Array<String>] Command that was executed (for error messages)
          # @return [String] Command output on success
          # @raise [Ace::Git::GitError] When command fails
          def handle_result(result, cmd_parts = nil)
            if result[:success]
              result[:output]
            else
              error_msg = result[:error].to_s.strip
              error_msg = "Unknown git error" if error_msg.empty?
              # Include the failed command for easier debugging
              cmd_str = cmd_parts ? " (#{cmd_parts.join(' ')})" : ""
              raise Ace::Git::GitError, "Git command failed#{cmd_str}: #{error_msg}"
            end
          end

          # Determine what range to diff based on configuration and git state
          def determine_range(config, executor)
            # If ranges specified in config, use first one
            return config.ranges.first if config.ranges.any?

            # If since specified, convert to range
            if config.since
              since_ref = Atoms::DateResolver.resolve_since_to_commit(config.since, executor: executor)
              return "#{since_ref}..HEAD"
            end

            # Smart default: check if there are unstaged or staged changes
            return nil if executor.has_unstaged_changes?
            return "--cached" if executor.has_staged_changes?

            # Default: branch diff against origin/main or tracking branch
            tracking = executor.tracking_branch
            if tracking
              return "#{tracking}...HEAD"
            end

            # Fallback: diff against origin/main
            "origin/main...HEAD"
          end

          # Build git diff command with configuration options
          def build_command(range, config)
            cmd_parts = ["git", "diff"]

            # Add flags from config
            cmd_parts.concat(config.git_flags)

            # Add range if specified
            cmd_parts << range if range

            # Add path filters if specified
            if config.paths.any?
              cmd_parts << "--"
              cmd_parts.concat(config.paths)
            end

            cmd_parts
          end
        end
      end
    end
  end
end
