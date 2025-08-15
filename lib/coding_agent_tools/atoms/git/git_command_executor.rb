# frozen_string_literal: true

require "open3"
require "timeout"
require "shellwords"
require_relative "../project_root_detector"

module CodingAgentTools
  module Atoms
    module Git
      class GitCommandError < StandardError
        attr_reader :command, :exit_status, :stderr_output

        def initialize(message, command: nil, exit_status: nil, stderr_output: nil)
          super(message)
          @command = command
          @exit_status = exit_status
          @stderr_output = stderr_output
        end
      end

      class GitCommandExecutor
        def self.execute(command, repository_path: nil, capture_output: true)
          new(repository_path: repository_path).execute(command, capture_output: capture_output)
        end

        def initialize(repository_path: nil)
          @repository_path = repository_path
        end

        def execute(command, capture_output: true)
          full_command = build_command(command)

          if capture_output
            execute_with_capture(full_command)
          else
            execute_without_capture(full_command)
          end
        end

        private

        attr_reader :repository_path

        def build_command(command)
          if repository_path
            resolved_path = resolve_repository_path(repository_path)
            "git -C #{Shellwords.escape(resolved_path)} #{command}"
          else
            # When no repository path specified, always use project root
            project_root = ProjectRootDetector.find_project_root
            "git -C #{Shellwords.escape(project_root)} #{command}"
          end
        end

        def resolve_repository_path(path)
          # Always resolve relative to project root for consistency
          project_root = ProjectRootDetector.find_project_root
          
          # Special case for "." - use project root
          return project_root if path == "."
          
          # If path is already absolute, use it as-is
          return path if File.absolute_path?(path)

          # Always resolve relative to project root
          absolute_path = File.join(project_root, path)

          # Verify the resolved path exists
          unless File.exist?(absolute_path) && File.directory?(absolute_path)
            raise GitCommandError.new(
              "Repository path not found: #{path} (tried local: #{File.expand_path(path)}, global: #{absolute_path})"
            )
          end

          absolute_path
        end

        def execute_with_capture(full_command)
          # Add timeout to prevent hanging indefinitely (e.g., interactive editors)
          timeout_seconds = 30

          begin
            stdout_str, stderr_str, status = Timeout.timeout(timeout_seconds) do
              Open3.capture3(full_command)
            end
          rescue Timeout::Error
            raise GitCommandError.new(
              "Git command timed out after #{timeout_seconds} seconds: #{format_command_for_display(full_command)}",
              command: full_command,
              exit_status: 124, # Standard timeout exit code
              stderr_output: "Command timed out"
            )
          end

          unless status.success?
            raise GitCommandError.new(
              "Git command failed: #{format_command_for_display(full_command)}",
              command: full_command,
              exit_status: status.exitstatus,
              stderr_output: stderr_str.strip
            )
          end

          {
            success: true,
            stdout: stdout_str,
            stderr: stderr_str,
            exit_status: status.exitstatus
          }
        end

        def execute_without_capture(full_command)
          success = system(full_command)

          unless success
            exit_status = $?.exitstatus
            raise GitCommandError.new(
              "Git command failed: #{format_command_for_display(full_command)}",
              command: full_command,
              exit_status: exit_status
            )
          end

          {
            success: true,
            exit_status: 0
          }
        end

        # Format command for display by unescaping shell-escaped sequences
        # to make error messages more readable
        def format_command_for_display(command)
          # Use a simple approach to make the command more readable:
          # Replace common shell escapes with their original characters
          command
            .gsub(/\\(.)/m, '\1')  # Unescape any escaped character
            .gsub(/\s+/, " ")      # Normalize whitespace
            .strip
        end
      end
    end
  end
end
