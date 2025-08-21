# frozen_string_literal: true

require "open3"

module CodingAgentTools
  module Organisms
    module System
      # Executes system commands and captures output
      class CommandExecutor
        # Result object for command execution
        CommandResult = Struct.new(:stdout, :stderr, :exit_status, :success?) do
          def success?
            exit_status.zero?
          end
        end

        # Execute a command and return structured result
        def execute(command, *args)
          # Build the full command
          full_command = build_command(command, args)
          
          # Execute and capture output
          stdout, stderr, status = Open3.capture3(full_command)
          
          # Return structured result
          CommandResult.new(stdout, stderr, status.exitstatus, status.success?)
        rescue => e
          # Return error result for execution failures
          CommandResult.new("", e.message, 1, false)
        end

        # Execute a command with stdin input
        def execute_with_input(command, input, *args)
          full_command = build_command(command, args)
          
          # Execute with stdin
          stdout, stderr, status = Open3.capture3(full_command, stdin_data: input)
          
          CommandResult.new(stdout, stderr, status.exitstatus, status.success?)
        rescue => e
          CommandResult.new("", e.message, 1, false)
        end

        # Execute and stream output in real-time
        def execute_streaming(command, *args, &block)
          full_command = build_command(command, args)
          
          exit_status = nil
          output_lines = []
          error_lines = []
          
          Open3.popen3(full_command) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            
            # Read both stdout and stderr
            threads = []
            
            threads << Thread.new do
              stdout.each_line do |line|
                output_lines << line
                yield(:stdout, line) if block_given?
              end
            end
            
            threads << Thread.new do
              stderr.each_line do |line|
                error_lines << line
                yield(:stderr, line) if block_given?
              end
            end
            
            threads.each(&:join)
            exit_status = wait_thr.value.exitstatus
          end
          
          CommandResult.new(
            output_lines.join,
            error_lines.join,
            exit_status,
            exit_status.zero?
          )
        rescue => e
          CommandResult.new("", e.message, 1, false)
        end

        private

        def build_command(command, args)
          # Handle both string and array arguments
          command_parts = [command]
          
          args.each do |arg|
            if arg.is_a?(Array)
              command_parts.concat(arg)
            else
              command_parts << arg.to_s
            end
          end
          
          # Join with proper quoting for shell execution
          command_parts.map { |part| shell_escape(part) }.join(" ")
        end

        def shell_escape(str)
          # Simple shell escaping - wrap in quotes if contains spaces or special chars
          if str =~ /[\s'"\\$`;|<>&]/
            "'#{str.gsub("'", "'\\''")}'"
          else
            str
          end
        end
      end
    end
  end
end