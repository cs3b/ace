# frozen_string_literal: true

require_relative "../taskflow_management/shell_command_executor"

module CodingAgentTools
  module Atoms
    module Code
      # Executes git commands and returns output
      # This is an atom - it depends only on another atom (ShellCommandExecutor)
      class GitCommandExecutor
        def initialize
          @shell_executor = Atoms::TaskflowManagement::ShellCommandExecutor
        end

        # Execute a git command with arguments
        # @param command [String] git subcommand (e.g., 'diff', 'log', 'status')
        # @param args [Array<String>] command arguments
        # @return [Hash] {output: String, success: Boolean, error: String}
        def execute(command, args = [])
          full_command = ["git", command] + args
          result = @shell_executor.execute(full_command.join(" "))
          
          {
            output: result.stdout,
            success: result.success?,
            error: result.stderr
          }
        end

        # Execute git diff with options
        # @param target [String] diff target (range, 'staged', 'unstaged', etc.)
        # @param options [Array<String>] additional options
        # @return [Hash] {output: String, success: Boolean, error: String}
        def diff(target, options = [])
          args = build_diff_args(target, options)
          execute("diff", args)
        end

        # Check if git is available
        # @return [Boolean] true if git command is available
        def available?
          result = @shell_executor.execute("which git")
          result.success? && !result.stdout.strip.empty?
        end

        # Get git version
        # @return [String, nil] git version string or nil if unavailable
        def version
          result = execute("--version")
          result[:success] ? result[:output].strip : nil
        end

        private

        # Build arguments for git diff based on target type
        # @param target [String] diff target
        # @param options [Array<String>] additional options
        # @return [Array<String>] command arguments
        def build_diff_args(target, options)
          base_args = ["--no-color"] + options
          
          case target
          when "staged"
            ["--staged"] + base_args
          when "unstaged"
            base_args
          when "working"
            ["HEAD"] + base_args
          when /\.\./
            # Commit range
            [target] + base_args
          else
            # Assume it's a ref or file
            [target] + base_args
          end
        end
      end
    end
  end
end