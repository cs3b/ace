# frozen_string_literal: true

require "stringio"
require "timeout"
require "ostruct"
require "minitest"

module Ace
  module TestRunner
    module Molecules
      # Runs tests directly in the current Ruby process without spawning subprocesses
      # This provides significantly faster execution for unit tests that don't need isolation
      class InProcessRunner
        # Minitest converts ordinary timeout exceptions into completed test
        # errors. Its pass-through SystemExit boundary preserves execution
        # deadlines; this owner catches the private control-flow exception.
        class ExecutionTimeout < SystemExit
          def initialize(*)
            super(124)
          end
        end
        private_constant :ExecutionTimeout

        def initialize(timeout: nil, launch_env:)
          @timeout = timeout
          @launch_env = launch_env  # Hermetic fixture environment applied for the test run
          @saved_env = nil
        end

        def execute_tests(files, options = {})
          return empty_result if files.empty?

          start_time = Time.now

          # Capture stdout/stderr
          original_stdout = $stdout
          original_stderr = $stderr
          stdout_io = StringIO.new
          stderr_io = StringIO.new

          # Store original verbose setting
          original_verbose = $VERBOSE

          begin
            $stdout = stdout_io
            $stderr = stderr_io
            $VERBOSE = nil if options[:suppress_warnings]

            # Apply the hermetic fixture environment for the duration of the run:
            # test code reads sanitized, fixture-owned environment state, and any
            # subprocess the tests spawn inherits the same hermetic environment.
            apply_launch_env

            # Add test directory to load path if not already there
            test_dir = File.expand_path("test")
            lib_dir = File.expand_path("lib")
            $LOAD_PATH.unshift(test_dir) unless $LOAD_PATH.include?(test_dir)
            $LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

            # Only require minitest/autorun if not already loaded
            # This prevents double runs when ace/test_support is loaded
            unless defined?(Minitest.autorun)
              require "minitest/autorun"
            end

            require_relative "selection_resolver"
            require_relative "selection_verifier"
            selection = options[:selection_plan] || SelectionResolver.resolve(files)
            SelectionVerifier.verify_sources!(selection)
            files_to_load = selection.files

            # Clear previously loaded test classes to avoid accumulation between groups
            # This is crucial for in-process execution where tests from previous groups
            # would otherwise be re-run in subsequent groups
            Minitest::Runnable.runnables.clear

            # Setup Minitest::Reporters BEFORE loading test files
            # For in-process mode, we need to handle reporter state carefully
            # because Minitest::Reporters.use! only works properly on first call
            require "minitest/reporters"

            # Create a fresh reporter for this group
            reporter = Minitest::Reporters::DefaultReporter.new(io: $stdout)

            # If this isn't the first group, we need to replace the existing reporter
            if Minitest.reporter && Minitest.reporter.reporters
              $stdout.flush
              Minitest.reporter.reporters.clear
              Minitest.reporter.reporters << reporter
              # Reset reporter state for the new group
              reporter.start_time = nil
              # NOTE: Known limitation - progress dots don't show for subsequent groups
              # in in-process mode. This appears to be a Minitest::Reporters limitation
              # where some internal state prevents proper output after the first run.
              # Test counts and results are still accurate.
            else
              # First group - use the standard setup
              Minitest::Reporters.use! reporter
            end

            # Load the test files
            files_to_load.uniq.each do |file|
              file_path = File.expand_path(file)
              begin
                load file_path
              rescue LoadError => e
                stderr_io.puts "Failed to load #{file}: #{e.message}"
                # Re-raise to fail the entire test run
                raise
              end
            end

            if selection.qualified?
              options = options.merge(selection_pattern: SelectionVerifier.verify_loaded!(selection))
            end

            # Run Minitest with captured output
            # Suppress Minitest's own output by using null reporter
            execution = lambda do
              if @timeout
                Timeout.timeout(@timeout, ExecutionTimeout) { run_minitest_silent(options) }
              else
                run_minitest_silent(options)
              end
            end
            exit_code = if selection.qualified?
              SelectionVerifier.verify_execution!(selection, &execution)
            else
              execution.call
            end

            success = exit_code == true || exit_code == 0
          rescue ExecutionTimeout, Timeout::Error
            stderr_io.puts "Test execution timed out after #{@timeout} seconds"
            success = false
            exit_code = 124
          rescue LoadError
            # LoadError already logged in the loop above
            stderr_io.puts "Test run aborted due to load error"
            success = false
            exit_code = 1
          rescue => e
            stderr_io.puts "Error running tests: #{e.message}"
            stderr_io.puts e.backtrace.join("\n") if options[:verbose]
            success = false
            exit_code = 1
          ensure
            $stdout = original_stdout
            $stderr = original_stderr
            $VERBOSE = original_verbose

            # Restore the exact parent environment, including keys removed or
            # added by test code during the run
            restore_launch_env
          end

          end_time = Time.now

          {
            stdout: stdout_io.string,
            stderr: stderr_io.string,
            status: OpenStruct.new(success?: success, exitstatus: if exit_code.is_a?(Integer)
                                                                    exit_code
                                                                  else
                                                                    (success ? 0 : 1)
                                                                  end),
            command: "in-process:#{files.join(",")}",
            start_time: start_time,
            end_time: end_time,
            duration: end_time - start_time,
            success: success
          }
        end

        def execute_single_file(file, options = {})
          execute_tests([file], options)
        end

        def execute_with_progress(files, options = {}, &block)
          # For in-process execution, we run all tests together for best performance
          result = execute_tests(files, options)

          # Send stdout event for per-test progress parsing
          if block_given? && result[:stdout]
            yield({type: :stdout, content: result[:stdout]})
          end

          # Simulate progress callbacks for compatibility
          if block_given?
            files.each { |file| yield({type: :start, file: file}) }
            files.each { |file| yield({type: :complete, file: file, success: result[:success], duration: result[:duration] / files.size}) }
          end

          result
        end

        private

        # Swap the process environment to the hermetic fixture environment.
        # Keys absent from the fixture environment (ambient configuration,
        # credentials) are removed for the duration of the run.
        def apply_launch_env
          @saved_env = ENV.to_h
          @launch_env.each { |key, value| ENV[key] = value }
          (@saved_env.keys - @launch_env.keys).each { |key| ENV.delete(key) }
        end

        def restore_launch_env
          return unless @saved_env

          ENV.clear
          @saved_env.each { |key, value| ENV[key] = value }
          @saved_env = nil
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

        def run_minitest_with_args(options)
          # Build Minitest arguments
          args = []
          args << "--seed" << options[:seed].to_s if options[:seed]
          args << "--verbose" if options[:verbose]

          # Add test name filter if line numbers were provided
          if options[:selection_pattern]
            args << "--name" << "/#{options[:selection_pattern]}/"
          end

          # Run Minitest
          # Returns true on success, false on failure
          Minitest.run(args)
        end

        def run_minitest_silent(options)
          # Minitest uses reporters that can bypass $stdout redirection
          # We need to suppress Minitest's own output completely

          # Build Minitest arguments
          args = []
          args << "--seed" << options[:seed].to_s if options[:seed]

          # Add test name filter if line numbers were provided
          if options[:selection_pattern]
            args << "--name" << "/#{options[:selection_pattern]}/"
          end

          # Minitest swallows Interrupt and returns a normal failure. Preserve
          # operator SIGINT as interruption so the owner never writes a completed
          # report for this invocation.
          interrupted = false
          previous_handler = Signal.trap("INT") do
            interrupted = true
            raise Interrupt
          end
          begin
            result = Minitest.run(args)
            raise Interrupt if interrupted
            result
          ensure
            Signal.trap("INT", previous_handler)
          end
        end
      end
    end
  end
end
