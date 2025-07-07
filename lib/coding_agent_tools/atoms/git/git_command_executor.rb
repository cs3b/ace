# frozen_string_literal: true

require "open3"

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
          if repository_path && repository_path != "."
            "git -C #{Shellwords.escape(repository_path)} #{command}"
          else
            "git #{command}"
          end
        end

        def execute_with_capture(full_command)
          stdout_str, stderr_str, status = Open3.capture3(full_command)
          
          unless status.success?
            raise GitCommandError.new(
              "Git command failed: #{full_command}",
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
              "Git command failed: #{full_command}",
              command: full_command,
              exit_status: exit_status
            )
          end

          {
            success: true,
            exit_status: 0
          }
        end
      end
    end
  end
end