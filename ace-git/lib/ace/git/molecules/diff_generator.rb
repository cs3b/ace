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

          # Generate `git diff --numstat` output for structured file statistics.
          # Uses the same range/path/flags logic as the main diff generation path.
          # @param config [Models::DiffConfig] Diff configuration
          # @param executor [Module] Command executor (default: Atoms::CommandExecutor)
          # @return [String] Numstat output
          def generate_numstat(config, executor: Atoms::CommandExecutor)
            range = determine_range(config, executor)
            cmd_parts = build_numstat_command(range, config)
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
            # If ranges specified in config, use first non-empty one
            # Empty/blank ranges are treated as "no range" (working tree diff)
            non_empty_ranges = config.ranges.reject { |r| r.nil? || r.strip.empty? }
            return non_empty_ranges.first if non_empty_ranges.any?

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
              return "#{tracking}...HEAD" if executor.respond_to?(:ref_exists?) && executor.ref_exists?(tracking)
            end

            return "origin/main...HEAD" if executor.respond_to?(:ref_exists?) && executor.ref_exists?("origin/main")
            return "HEAD~1..HEAD" if executor.respond_to?(:ref_exists?) && executor.ref_exists?("HEAD~1")

            nil
          end

          # Build git diff command with configuration options
          def build_command(range, config)
            build_git_diff_command(range, config)
          end

          def build_numstat_command(range, config)
            build_git_diff_command(range, config, "--numstat")
          end

          def build_git_diff_command(range, config, *extra_flags)
            cmd_parts = ["git", "diff"]
            cmd_parts.concat(extra_flags)
            cmd_parts.concat(config.git_flags)
            cmd_parts << range if range

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
