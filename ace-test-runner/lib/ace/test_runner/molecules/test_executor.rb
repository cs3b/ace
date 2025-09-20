# frozen_string_literal: true

require "open3"
require "timeout"
require "ostruct"

module Ace
  module TestRunner
    module Molecules
      # Executes test commands and captures output
      class TestExecutor
        def initialize(command_builder: nil, timeout: nil)
          @command_builder = command_builder || Atoms::CommandBuilder.new
          @timeout = timeout  # In seconds, nil = no timeout
        end

        def execute_tests(files, options = {})
          return empty_result if files.empty?

          command = @command_builder.build_test_command(files, options)
          execute_command(command)
        end

        def execute_single_file(file, options = {})
          command = @command_builder.build_single_file_command(file, options)
          execute_command(command)
        end

        def execute_command(command)
          start_time = Time.now
          stdout = ""
          stderr = ""
          status = nil

          # Set environment to prevent Minitest autorun at_exit hook
          env = { "MT_NO_AUTORUN" => "1" }

          # Remove MT_NO_AUTORUN=1 from command if it's there
          command = command.sub(/^MT_NO_AUTORUN=1\s+/, '')

          begin
            if @timeout
              Timeout.timeout(@timeout) do
                stdout, stderr, status = Open3.capture3(env, command)
              end
            else
              stdout, stderr, status = Open3.capture3(env, command)
            end
          rescue Timeout::Error
            stderr = "Test execution timed out after #{@timeout} seconds"
            status = OpenStruct.new(success?: false, exitstatus: 124)
          end

          end_time = Time.now


          {
            stdout: stdout,
            stderr: stderr,
            status: status,
            command: command,
            start_time: start_time,
            end_time: end_time,
            duration: end_time - start_time,
            success: status.success?
          }
        end

        def execute_with_progress(files, options = {}, &block)
          # For performance, execute all files together unless explicitly disabled
          if options[:per_file] == true
            execute_per_file_with_progress(files, options, &block)
          else
            # Execute all files in a single Ruby process for performance
            result = execute_tests(files, options)

            # Simulate progress callbacks for compatibility
            if block_given?
              files.each { |file| yield({ type: :start, file: file }) }
              files.each { |file| yield({ type: :complete, file: file, success: result[:success], duration: result[:duration] / files.size }) }
            end

            result
          end
        end

        def execute_per_file_with_progress(files, options = {}, &block)
          results = []

          files.each do |file|
            yield({ type: :start, file: file }) if block_given?

            result = execute_single_file(file, options)
            results << result

            if block_given?
              yield({
                type: :complete,
                file: file,
                success: result[:success],
                duration: result[:duration]
              })
            end

            # Stop on first failure if fail_fast is set
            break if options[:fail_fast] && !result[:success]
          end

          merge_results(results)
        end

        private

        def empty_result
          {
            stdout: "",
            stderr: "No test files found",
            status: OpenStruct.new(success?: true, exitstatus: 0),
            command: "",
            start_time: Time.now,
            end_time: Time.now,
            duration: 0.0,
            success: true
          }
        end

        def merge_results(results)
          return empty_result if results.empty?

          merged = {
            stdout: results.map { |r| r[:stdout] }.join("\n"),
            stderr: results.map { |r| r[:stderr] }.join("\n"),
            commands: results.map { |r| r[:command] },
            start_time: results.first[:start_time],
            end_time: results.last[:end_time],
            duration: results.sum { |r| r[:duration] },
            success: results.all? { |r| r[:success] }
          }

          # Create a synthetic status
          merged[:status] = OpenStruct.new(
            success?: merged[:success],
            exitstatus: merged[:success] ? 0 : 1
          )

          merged
        end
      end
    end
  end
end