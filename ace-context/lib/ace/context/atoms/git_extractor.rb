# frozen_string_literal: true

require "open3"
require "ace/git_diff"

module Ace
  module Context
    module Atoms
      # Pure functions for extracting git information
      # Delegates diff operations to ace-git-diff for consistency
      module GitExtractor
        class << self
          # Execute a git diff command
          # Delegates to ace-git-diff for consistent filtering and configuration
          def git_diff(range_or_target = "origin/main...HEAD")
            result = Ace::GitDiff::Organisms::DiffOrchestrator.generate(
              ranges: [range_or_target]
            )
            result.content
          rescue StandardError => e
            warn "ace-git-diff failed: #{e.message}" if ENV["DEBUG"]
            ""
          end

          # Get git log for a range
          def git_log(range = "origin/main..HEAD", format: "--oneline")
            result = execute_git_command("git", "log", range, format)
            result[:success] ? result[:output] : ""
          end

          # Get staged changes
          # Delegates to ace-git-diff for consistent filtering
          def staged_diff
            result = Ace::GitDiff::Organisms::DiffOrchestrator.staged
            result.content
          rescue StandardError => e
            warn "ace-git-diff staged failed: #{e.message}" if ENV["DEBUG"]
            ""
          end

          # Get working directory changes
          # Delegates to ace-git-diff for consistent filtering
          def working_diff
            result = Ace::GitDiff::Organisms::DiffOrchestrator.working
            result.content
          rescue StandardError => e
            warn "ace-git-diff working failed: #{e.message}" if ENV["DEBUG"]
            ""
          end

          # Get list of changed files
          def changed_files(range_or_target = "origin/main...HEAD")
            result = execute_git_command("git", "diff", "--name-only", range_or_target)
            return [] unless result[:success]

            result[:output].split("\n").map(&:strip).reject(&:empty?)
          end

          # Check if we're in a git repository
          def in_git_repo?
            result = execute_git_command("git", "rev-parse", "--git-dir")
            result[:success]
          end

          # Get current branch name
          def current_branch
            result = execute_git_command("git", "rev-parse", "--abbrev-ref", "HEAD")
            result[:success] ? result[:output].strip : nil
          end

          # Get remote tracking branch
          def tracking_branch
            result = execute_git_command("git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")
            result[:success] ? result[:output].strip : nil
          end

          # Get commit count between two refs
          def commit_count(from_ref, to_ref)
            result = execute_git_command("git", "rev-list", "--count", "#{from_ref}..#{to_ref}")
            result[:success] ? result[:output].strip.to_i : 0
          end

          # Get repository root path
          def repo_root
            result = execute_git_command("git", "rev-parse", "--show-toplevel")
            result[:success] ? result[:output].strip : nil
          end

          # Extract diff with detailed result information
          # Uses direct git command for detailed error reporting
          # Note: This method provides raw error details, unlike other diff methods
          # which delegate to ace-git-diff and handle errors gracefully
          def extract_diff(range_or_target)
            result = execute_git_command("git", "diff", range_or_target)
            {
              success: result[:success],
              output: result[:output],
              error: result[:error],
              range: range_or_target
            }
          end

        private

          # Execute a git command safely using array arguments to prevent command injection
          # @param command_parts [Array<String>] Command parts to execute
          # @return [Hash] Result with output, error, and success status
          def execute_git_command(*command_parts)
            stdout, stderr, status = Open3.capture3(*command_parts)

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
end
