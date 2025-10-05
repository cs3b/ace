# frozen_string_literal: true

require "open3"

module Ace
  module Review
    module Atoms
      # Pure functions for extracting git information
      module GitExtractor
        module_function

        # Execute a git diff command
        def git_diff(range_or_target)
          execute_git_command("git diff #{range_or_target}")
        end

        # Get git log for a range
        def git_log(range, format: "--oneline")
          execute_git_command("git log #{range} #{format}")
        end

        # Get staged changes
        def staged_diff
          execute_git_command("git diff --cached")
        end

        # Get working directory changes
        def working_diff
          execute_git_command("git diff")
        end

        # Get list of changed files
        def changed_files(range_or_target)
          output = execute_git_command("git diff --name-only #{range_or_target}")
          return [] unless output[:success]

          output[:output].split("\n").map(&:strip).reject(&:empty?)
        end

        # Check if we're in a git repository
        def in_git_repo?
          result = execute_git_command("git rev-parse --git-dir")
          result[:success]
        end

        # Get current branch name
        def current_branch
          result = execute_git_command("git rev-parse --abbrev-ref HEAD")
          result[:success] ? result[:output].strip : nil
        end

        # Get remote tracking branch
        def tracking_branch
          result = execute_git_command("git rev-parse --abbrev-ref --symbolic-full-name @{u}")
          result[:success] ? result[:output].strip : nil
        end

        private

        def execute_git_command(command)
          stdout, stderr, status = Open3.capture3(command)

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
            error: e.message,
            exit_code: -1
          }
        end
      end
    end
  end
end