# frozen_string_literal: true

require_relative "test_executor"
require_relative "in_process_runner"
require_relative "../atoms/test_type_detector"

module Ace
  module TestRunner
    module Molecules
      # Intelligently chooses between subprocess and in-process execution based on test type
      class SmartTestExecutor
        def initialize(command_builder: nil, timeout: nil, force_mode: nil)
          @subprocess_executor = TestExecutor.new(command_builder: command_builder, timeout: timeout)
          @in_process_runner = InProcessRunner.new(timeout: timeout)
          @test_type_detector = Atoms::TestTypeDetector.new
          @force_mode = force_mode  # :subprocess, :direct, or nil for auto
        end

        def execute_tests(files, options = {})
          return empty_result if files.empty?

          # Determine execution mode
          mode = determine_execution_mode(files, options)

          # Execute with appropriate runner
          if mode == :direct
            @in_process_runner.execute_tests(files, options)
          else
            @subprocess_executor.execute_tests(files, options)
          end
        end

        def execute_single_file(file, options = {})
          mode = determine_execution_mode([file], options)

          if mode == :direct
            @in_process_runner.execute_single_file(file, options)
          else
            @subprocess_executor.execute_single_file(file, options)
          end
        end

        def execute_command(command)
          # Direct command execution always uses subprocess
          @subprocess_executor.execute_command(command)
        end

        def execute_with_progress(files, options = {}, &block)
          mode = determine_execution_mode(files, options)

          # Add mode information to progress callback
          yield({ type: :execution_mode, mode: mode }) if block_given?

          if mode == :direct
            @in_process_runner.execute_with_progress(files, options, &block)
          else
            @subprocess_executor.execute_with_progress(files, options, &block)
          end
        end

        private

        def determine_execution_mode(files, options)
          # Check for forced mode from options or initialization
          return :subprocess if options[:subprocess] || @force_mode == :subprocess
          return :direct if options[:direct] || @force_mode == :direct

          # Check sequential_groups_mode config for sequential group execution
          # This ensures correct group header ordering
          if options[:sequential_groups_mode] == "subprocess"
            return :subprocess
          end

          # Use subprocess for line number filtering (file:line format)
          # This provides cleaner output without Minitest reporter duplication
          if files.any? { |f| f.match?(/:\d+$/) }
            return :subprocess
          end

          # Auto-detect based on test content
          needs_subprocess = files.any? { |file| @test_type_detector.needs_subprocess?(file) }

          # Also use subprocess if running tests from multiple packages (different directories)
          if files.size > 1
            dirs = files.map { |f| File.dirname(f) }.uniq
            needs_subprocess ||= dirs.size > 3  # Multiple directories suggest different packages
          end

          needs_subprocess ? :subprocess : :direct
        end

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
      end
    end
  end
end