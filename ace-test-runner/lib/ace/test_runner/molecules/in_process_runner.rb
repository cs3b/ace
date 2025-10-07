# frozen_string_literal: true

require "stringio"
require "ostruct"
require "minitest"

module Ace
  module TestRunner
    module Molecules
      # Runs tests directly in the current Ruby process without spawning subprocesses
      # This provides significantly faster execution for unit tests that don't need isolation
      class InProcessRunner
        def initialize(timeout: nil)
          @timeout = timeout
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
          original_mt_no_autorun = ENV['MT_NO_AUTORUN']

          begin
            $stdout = stdout_io
            $stderr = stderr_io
            $VERBOSE = nil if options[:suppress_warnings]

            # Prevent Minitest from auto-running
            ENV['MT_NO_AUTORUN'] = '1'

            # Add test directory to load path if not already there
            test_dir = File.expand_path('test')
            lib_dir = File.expand_path('lib')
            $LOAD_PATH.unshift(test_dir) unless $LOAD_PATH.include?(test_dir)
            $LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

            # Only require minitest/autorun if not already loaded
            # This prevents double runs when ace/test_support is loaded
            unless defined?(Minitest.autorun)
              require "minitest/autorun"
            end

            # First pass: check for line numbers and resolve test names
            # This must be done before loading files
            test_names_to_run = []
            files_to_load = []

            files.each do |file|
              # Check if file has line number (file:line format)
              if file =~ /^(.+):(\d+)$/
                actual_file = $1
                line_number = $2.to_i

                # Resolve line number to test name
                require_relative "../atoms/line_number_resolver"
                test_name = Ace::TestRunner::Atoms::LineNumberResolver.resolve_test_at_line(actual_file, line_number)
                test_names_to_run << test_name if test_name

                files_to_load << actual_file
              else
                files_to_load << file
              end
            end

            # Store test names in options to pass to run_minitest_with_args
            options = options.merge(test_names_filter: test_names_to_run) if test_names_to_run.any?

            # Setup Minitest::Reporters BEFORE loading test files
            # This ensures the reporter is configured before Minitest initializes
            require 'minitest/reporters'
            Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new(io: $stdout)

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

            # Run Minitest with captured output
            # Suppress Minitest's own output by using null reporter
            exit_code = if @timeout
              Timeout.timeout(@timeout) do
                run_minitest_silent(options)
              end
            else
              run_minitest_silent(options)
            end

            success = exit_code == true || exit_code == 0

          rescue Timeout::Error
            stderr_io.puts "Test execution timed out after #{@timeout} seconds"
            success = false
            exit_code = 124
          rescue LoadError => e
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

            # Restore original MT_NO_AUTORUN value
            if original_mt_no_autorun
              ENV['MT_NO_AUTORUN'] = original_mt_no_autorun
            else
              ENV.delete('MT_NO_AUTORUN')
            end
          end

          end_time = Time.now

          {
            stdout: stdout_io.string,
            stderr: stderr_io.string,
            status: OpenStruct.new(success?: success, exitstatus: exit_code.is_a?(Integer) ? exit_code : (success ? 0 : 1)),
            command: "in-process:#{files.join(',')}",
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
            yield({ type: :stdout, content: result[:stdout] })
          end

          # Simulate progress callbacks for compatibility
          if block_given?
            files.each { |file| yield({ type: :start, file: file }) }
            files.each { |file| yield({ type: :complete, file: file, success: result[:success], duration: result[:duration] / files.size }) }
          end

          result
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

        def run_minitest_with_args(options)
          # Build Minitest arguments
          args = []
          args << "--seed" << options[:seed].to_s if options[:seed]
          args << "--verbose" if options[:verbose]

          # Add test name filter if line numbers were provided
          if options[:test_names_filter] && options[:test_names_filter].any?
            pattern = options[:test_names_filter].map { |name| Regexp.escape(name) }.join("|")
            args << "--name" << "/#{pattern}/"
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
          if options[:test_names_filter] && options[:test_names_filter].any?
            pattern = options[:test_names_filter].map { |name| Regexp.escape(name) }.join("|")
            args << "--name" << "/#{pattern}/"
          end

          # Reporter already set up before loading test files
          # Run Minitest
          Minitest.run(args)
        end
      end
    end
  end
end