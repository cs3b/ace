# frozen_string_literal: true

require "open3"
require "timeout"

module Ace
  module GitDiff
    module Atoms
      # Pure functions for executing git commands safely
      # Extracted from ace-context GitExtractor
      module CommandExecutor
        class << self
          # Execute a git command safely using array arguments to prevent command injection
          # @param command_parts [Array<String>] Command parts to execute
          # @return [Hash] Result with output, error, and success status
          def execute(*command_parts)
            # Using Timeout to prevent hanging on network issues or stuck git operations
            # Git operations should typically complete within 30 seconds for most repositories
            Timeout.timeout(30) do
              # Using Open3.capture3 to avoid shell injection
              # Arguments are passed directly as array elements, not through shell
              stdout, stderr, status = Open3.capture3(*command_parts)

              {
                success: status.success?,
                output: stdout,
                error: stderr,
                exit_code: status.exitstatus
              }
            end
          rescue Timeout::Error
            {
              success: false,
              output: "",
              error: "Command timed out after 30 seconds: #{command_parts.join(' ')}",
              exit_code: -1
            }
          rescue StandardError => e
            {
              success: false,
              output: "",
              error: e.message,
              exit_code: -1
            }
          end

          # Execute git diff command
          # @param args [Array<String>] Arguments to pass to git diff
          # @return [String] Diff output or empty string on error
          def git_diff(*args)
            result = execute("git", "diff", *args)
            result[:success] ? result[:output] : ""
          end

          # Get staged changes
          # @return [String] Diff of staged changes
          def staged_diff
            result = execute("git", "diff", "--cached")
            result[:success] ? result[:output] : ""
          end

          # Get working directory changes
          # @return [String] Diff of working directory changes
          def working_diff
            result = execute("git", "diff")
            result[:success] ? result[:output] : ""
          end

          # Check if we're in a git repository
          # @return [Boolean] True if in a git repository
          def in_git_repo?
            result = execute("git", "rev-parse", "--git-dir")
            result[:success]
          end

          # Get current branch name
          # @return [String, nil] Current branch name or nil on error
          def current_branch
            result = execute("git", "rev-parse", "--abbrev-ref", "HEAD")
            result[:success] ? result[:output].strip : nil
          end

          # Get repository root path
          # @return [String, nil] Repository root path or nil on error
          def repo_root
            result = execute("git", "rev-parse", "--show-toplevel")
            result[:success] ? result[:output].strip : nil
          end

          # Get remote tracking branch
          # @return [String, nil] Remote tracking branch or nil
          def tracking_branch
            result = execute("git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")
            result[:success] ? result[:output].strip : nil
          end

          # Get list of changed files
          # @param range [String] Git range to check
          # @return [Array<String>] List of changed file paths
          def changed_files(range = "origin/main...HEAD")
            result = execute("git", "diff", "--name-only", range)
            return [] unless result[:success]

            result[:output].split("\n").map(&:strip).reject(&:empty?)
          end

          # Check if there are unstaged changes
          # @return [Boolean] True if there are unstaged changes
          def has_unstaged_changes?
            !working_diff.strip.empty?
          end

          # Check if there are staged changes
          # @return [Boolean] True if there are staged changes
          def has_staged_changes?
            !staged_diff.strip.empty?
          end
        end
      end
    end
  end
end
