# frozen_string_literal: true

require "open3"
require "fileutils"
require "yaml"
require "ace/support/timestamp"

module Ace
  module Test
    module EndToEndRunner
      module Organisms
        # Orchestrates E2E test execution across multiple packages
        #
        # Discovers all E2E tests across the monorepo and executes them
        # either sequentially or in parallel using subprocess isolation.
        # Supports filtering to affected packages based on git diff.
        class SuiteOrchestrator
          attr_reader :max_parallel, :base_dir

          # @param max_parallel [Integer] Number of parallel workers
          # @param base_dir [String] Base directory for test discovery
          # @param discoverer [#find_tests, #list_packages] Test discoverer (injectable)
          # @param affected_detector [#detect] Affected package detector (injectable)
          # @param failure_finder [#find_failures_by_package] Failure finder (injectable)
          # @param output [IO] Output stream for progress messages
          # @param use_color [Boolean] Enable ANSI color output (default: auto-detect TTY)
          # @param progress [Boolean] Enable animated progress display
          # @param suite_report_writer Suite report writer (injectable)
          # @param scenario_parser Scenario parser (injectable)
          # @param timestamp_generator Timestamp generator (injectable)
          def initialize(max_parallel: 4, base_dir: nil, discoverer: nil, affected_detector: nil,
                         failure_finder: nil, output: $stdout, use_color: nil, progress: false,
                         suite_report_writer: nil, scenario_parser: nil, timestamp_generator: nil)
            @max_parallel = max_parallel
            @base_dir = base_dir || Dir.pwd
            @discoverer = discoverer || Molecules::TestDiscoverer.new
            @affected_detector = affected_detector || Molecules::AffectedDetector.new
            @failure_finder = failure_finder || Molecules::FailureFinder.new
            @output = output
            @use_color = use_color.nil? ? output.respond_to?(:tty?) && output.tty? : use_color
            @progress = progress
            config = Molecules::ConfigLoader.load
            @suite_report_writer = suite_report_writer || Molecules::SuiteReportWriter.new(config: config)
            @parser = scenario_parser || Molecules::ScenarioParser.new
            @timestamp_generator = timestamp_generator || method(:default_timestamp)
          end

          # Run E2E tests across all packages
          #
          # @param options [Hash] Execution options
          # @option options [Boolean] :parallel Enable parallel execution
          # @option options [Boolean] :affected Only test affected packages
          # @option options [Boolean] :only_failures Re-run only failed test cases
          # @option options [String] :packages Comma-separated package names to filter
          # @option options [String] :cli_args Extra args for CLI providers
          # @option options [String] :provider LLM provider:model
          # @option options [Integer] :timeout Timeout per test in seconds
          # @return [Hash] Summary of results
          def run(options = {})
            packages = @discoverer.list_packages(base_dir: @base_dir)

            if packages.empty?
              @output.puts "No packages with E2E tests found"
              return { total: 0, passed: 0, failed: 0, errors: 0, packages: {} }
            end

            # Filter to specific packages if requested
            if options[:packages]
              requested = options[:packages].split(",").map(&:strip)
              packages = packages & requested

              if packages.empty?
                @output.puts "No matching packages with E2E tests found"
                return { total: 0, passed: 0, failed: 0, errors: 0, packages: {} }
              end
            end

            # Filter to affected packages if requested
            if options[:affected]
              affected = @affected_detector.detect(base_dir: @base_dir)
              packages = packages & affected

              if packages.empty?
                @output.puts "No affected packages with E2E tests"
                return { total: 0, passed: 0, failed: 0, errors: 0, packages: {} }
              end

              @output.puts "Affected packages: #{packages.join(", ")}"
            end

            # Collect failures by package if --only-failures requested
            package_failures = nil
            if options[:only_failures]
              package_failures = @failure_finder.find_failures_by_package(
                packages: packages, base_dir: @base_dir
              )

              if package_failures.empty?
                @output.puts "No failed test cases found in cache"
                return { total: 0, passed: 0, failed: 0, errors: 0, packages: {} }
              end

              # Filter packages to only those with failures
              packages = packages & package_failures.keys
              @output.puts "Packages with failures: #{packages.join(", ")}"
              packages.each do |pkg|
                @output.puts "  #{pkg}: #{package_failures[pkg].join(", ")}"
              end
            end

            # Store package failures for use in test command building
            @package_failures = package_failures

            # Discover tests in each package
            package_tests = discover_package_tests(packages)

            total_tests = package_tests.values.flatten.size
            pkg_count = package_tests.keys.size

            # Pre-compute column widths for aligned output
            compute_column_widths(package_tests)

            # Build display manager
            test_queue = build_test_queue(package_tests)
            @display = build_display_manager(test_queue)

            # Print suite header
            @display.show_header(total_tests, pkg_count)

            # Execute tests
            if options[:parallel]
              run_parallel(package_tests, options)
            else
              run_sequential(package_tests, options)
            end
          end

          private

          # Build the appropriate display manager based on progress flag
          #
          # @param test_queue [Array<Hash>] flat list of test items
          # @return [Molecules::SuiteSimpleDisplayManager, Molecules::SuiteProgressDisplayManager]
          def build_display_manager(test_queue)
            if @progress
              Molecules::SuiteProgressDisplayManager.new(
                test_queue, output: @output, use_color: @use_color,
                pkg_width: @pkg_width, name_width: @name_width
              )
            else
              Molecules::SuiteSimpleDisplayManager.new(
                test_queue, output: @output, use_color: @use_color,
                pkg_width: @pkg_width, name_width: @name_width
              )
            end
          end

          # Discover all tests in each package
          #
          # @param packages [Array<String>] List of package names
          # @return [Hash] Package name to list of test files
          def discover_package_tests(packages)
            package_tests = {}
            packages.each do |package|
              tests = @discoverer.find_tests(package: package, base_dir: @base_dir)
              package_tests[package] = tests unless tests.empty?
            end
            package_tests
          end

          # Pre-compute column widths for aligned output
          #
          # @param package_tests [Hash] Package to tests mapping
          def compute_column_widths(package_tests)
            @pkg_width = package_tests.keys.map(&:length).max || 10
            @name_width = package_tests.values.flatten.map { |f| extract_test_name(f).length }.max || 20
          end

          # Extract human-readable test name from file path
          #
          # @param test_file [String] Path to test file
          # @return [String] e.g. "MT-BUNDLE-001-section-workflow"
          def extract_test_name(test_file)
            File.basename(test_file, ".mt.md")
          end

          # Run tests sequentially
          #
          # @param package_tests [Hash] Package to tests mapping
          # @param options [Hash] Execution options
          # @return [Hash] Summary of results
          def run_sequential(package_tests, options)
            results = { total: 0, passed: 0, failed: 0, errors: 0, packages: {} }
            start_time = Time.now

            # Pre-generate unique run IDs for all tests
            all_tests = package_tests.flat_map { |pkg, tests| tests.map { |t| [pkg, t] } }
            run_ids = generate_run_ids(all_tests.size)
            run_id_map = all_tests.zip(run_ids).to_h

            display_mutex = Mutex.new
            done = false
            refresh_thread = if @progress
              Thread.new do
                until done
                  sleep REFRESH_INTERVAL
                  display_mutex.synchronize { @display.refresh }
                end
              end
            end

            package_tests.each do |package, tests|
              package_results = []

              tests.each do |test_file|
                display_mutex.synchronize { @display.test_started(package, test_file) }

                test_start = Time.now
                run_id = run_id_map[[package, test_file]]
                result = run_single_test(package, test_file, options, run_id: run_id)
                elapsed = Time.now - test_start
                package_results << result

                # Update totals
                results[:total] += 1
                case result[:status]
                when "pass"
                  results[:passed] += 1
                when "fail"
                  results[:failed] += 1
                when "error"
                  results[:errors] += 1
                end

                # Show columnar progress line
                display_mutex.synchronize { @display.test_completed(result, package, test_file, elapsed) }
              end

              results[:packages][package] = package_results
            end

            done = true
            refresh_thread&.join

            finalize_run(results, package_tests, start_time)
          end

          # Run tests in parallel using subprocesses
          #
          # @param package_tests [Hash] Package to tests mapping
          # @param options [Hash] Execution options
          # @return [Hash] Summary of results
          def run_parallel(package_tests, options)
            results = { total: 0, passed: 0, failed: 0, errors: 0, packages: {} }
            queue = build_test_queue(package_tests)
            run_ids = generate_run_ids(queue.size)
            queue.each_with_index { |item, i| item[:run_id] = run_ids[i] }
            start_time = Time.now

            running = {}

            while !queue.empty? || !running.empty?
              # Start new processes up to max_parallel
              while running.size < @max_parallel && !queue.empty?
                test_item = queue.shift
                @display.test_started(test_item[:package], test_item[:test_file])
                process = spawn_test_process(test_item, options)
                running[process[:pid]] = process.merge(started_at: Time.now)
              end

              # Check for completed processes
              sleep 0.1
              @display.refresh
              check_running_processes(running, results)
            end

            finalize_run(results, package_tests, start_time)
          end

          # Build a flat queue of test items
          #
          # @param package_tests [Hash] Package to tests mapping
          # @return [Array<Hash>] Queue of test items
          def build_test_queue(package_tests)
            queue = []
            package_tests.each do |package, tests|
              tests.each do |test_file|
                queue << { package: package, test_file: test_file }
              end
            end
            queue
          end

          # Spawn a subprocess for a single test
          #
          # @param test_item [Hash] Test item with package and test_file
          # @param options [Hash] Execution options
          # @return [Hash] Process info
          def spawn_test_process(test_item, options)
            package = test_item[:package]
            test_file = test_item[:test_file]
            run_id = test_item[:run_id]

            # Build command as array for safe execution
            cmd_array = build_test_command(package, test_file, options, run_id: run_id)

            # Spawn process with array form (no shell invocation)
            stdin, stdout, stderr, thread = Open3.popen3(*cmd_array, chdir: @base_dir)

            { pid: thread.pid, thread: thread, stdout: stdout, stderr: stderr,
              stdin: stdin, package: package, test_file: test_file, output: String.new }
          end

          # Build the command to run a single test
          #
          # @param package [String] Package name
          # @param test_file [String] Path to test file
          # @param options [Hash] Execution options
          # @return [Array<String>] Command array for safe execution
          def build_test_command(package, test_file, options, run_id: nil)
            # Extract test_id from filename
            test_id = extract_test_id(test_file)

            cmd_parts = ["ace-test-e2e", package, test_id]

            # Add provider if specified
            if options[:provider]
              cmd_parts.concat(["--provider", options[:provider]])
            end

            # Add timeout if specified
            if options[:timeout]
              cmd_parts.concat(["--timeout", options[:timeout].to_s])
            end

            # Add CLI args if specified - passed as a single string argument
            if options[:cli_args]
              cmd_parts.concat(["--cli-args", options[:cli_args]])
            end

            # Add pre-generated run ID for deterministic report paths
            if run_id
              cmd_parts.concat(["--run-id", run_id])
            end

            # Add --test-cases for only-failures mode (package-level filtering)
            if @package_failures && @package_failures[package]
              cmd_parts.concat(["--test-cases", @package_failures[package].join(",")])
            end

            # Add parallel=1 for subprocess isolation
            cmd_parts.concat(["--parallel", "1"])

            cmd_parts
          end

          # Extract test ID from file path
          #
          # @param test_file [String] Path to test file
          # @return [String] Test ID
          def extract_test_id(test_file)
            basename = File.basename(test_file, ".mt.md")
            # Handle various filename patterns
            if basename =~ /MT-[\w-]+/
              basename.match(/MT-[\w-]+/)[0]
            else
              basename
            end
          end

          # Check running processes for completion
          #
          # @param running [Hash] Running processes
          # @param results [Hash] Results accumulator
          def check_running_processes(running, results)
            running.dup.each do |pid, process|
              thread = process[:thread]

              # Read available output from both stdout and stderr
              begin
                readable, = IO.select([process[:stdout], process[:stderr]], nil, nil, 0)
                readable&.each do |stream|
                  chunk = stream.read_nonblock(4096)
                  process[:output] << chunk
                end
              rescue IO::WaitReadable, EOFError
                # No data or stream closed
              end

              # Check if completed
              unless thread.alive?
                # Get remaining output from both streams
                [process[:stdout], process[:stderr]].each do |stream|
                  begin
                    process[:output] << stream.read
                  rescue IOError
                    # Stream already closed
                  end
                end

                # Close streams
                process[:stdout].close rescue nil
                process[:stderr].close rescue nil
                process[:stdin].close rescue nil

                # Parse result
                result = parse_subprocess_result(process)

                # Update results
                results[:total] += 1
                results[:packages][process[:package]] ||= []
                results[:packages][process[:package]] << result

                case result[:status]
                when "pass"
                  results[:passed] += 1
                when "fail"
                  results[:failed] += 1
                when "error"
                  results[:errors] += 1
                end

                # Show columnar progress line
                elapsed = Time.now - process[:started_at]
                @display.test_completed(result, process[:package], process[:test_file], elapsed)

                # Remove from running
                running.delete(pid)
              end
            end
          end

          # Parse result from subprocess output
          #
          # @param process [Hash] Process info with output
          # @return [Hash] Parsed result with :passed_cases and :total_cases
          def parse_subprocess_result(process)
            parse_test_output(process[:output], process[:thread].value.exitstatus, extract_test_name(process[:test_file]))
          rescue => e
            { status: "error", error: "Failed to parse result: #{e.message}" }
          end

          # Shared helper to parse test output from combined stdout/stderr
          #
          # @param output [String] Combined test output
          # @param exit_status [Integer] Process exit status
          # @param test_name [String] Test name for result
          # @return [Hash] Parsed result with :status, :passed_cases, :total_cases, etc.
          def parse_test_output(output, exit_status, test_name)
            # Try to find report directory in output
            report_dir = output.match(/Report: (.+?)$/m)&.captures&.first&.strip

            # Extract test case counts from "Result: ... N/M cases" line
            cases_match = output.match(/(\d+)\/(\d+) cases/)
            passed_cases = cases_match ? cases_match[1].to_i : nil
            total_cases = cases_match ? cases_match[2].to_i : nil

            base = { report_dir: report_dir, passed_cases: passed_cases, total_cases: total_cases,
                     test_name: test_name }

            if exit_status == 0
              base.merge(status: "pass", summary: "Test passed")
            elsif output.include?("ERROR") || output.include?("Error:")
              error_msg = output.match(/Error: (.+?)$/m)&.captures&.first || "Unknown error"
              base.merge(status: "error", error: error_msg)
            else
              summary = output.match(/(\d+)\/(\d+) passed/)&.captures&.join("/") || "Test failed"
              base.merge(status: "fail", summary: summary)
            end
          rescue => e
            { status: "error", error: "Failed to parse result: #{e.message}" }
          end

          # Finalize a test run: show summary, generate report, return results
          #
          # @param results [Hash] Accumulated results
          # @param package_tests [Hash] Package to test files mapping
          # @param start_time [Time] When the run started
          # @return [Hash] Results with optional :report_path
          def finalize_run(results, package_tests, start_time)
            @display.show_summary(results, Time.now - start_time)

            report_path = generate_suite_report(results, package_tests)
            if report_path
              @output.puts "Report: #{report_path}"
              results[:report_path] = report_path
            end

            results
          end

          # Generate a suite-level final report from results
          #
          # @param results [Hash] Suite results with :packages hash
          # @param package_tests [Hash] Package to test files mapping
          # @return [String, nil] Path to the report file, or nil on failure
          def generate_suite_report(results, package_tests)
            timestamp = @timestamp_generator.call

            all_results = []
            all_scenarios = []

            package_tests.each do |package, test_files|
              pkg_results = results[:packages][package] || []
              results_by_name = pkg_results.each_with_object({}) { |r, h| h[r[:test_name]] = r }

              test_files.each do |test_file|
                test_name = extract_test_name(test_file)
                result_hash = results_by_name[test_name]
                next unless result_hash

                all_results << build_test_result(result_hash)
                all_scenarios << parse_scenario(package, test_file)
              end
            end

            if all_results.empty?
              warn "Warning: Suite report skipped — no results matched test files" if ENV["DEBUG"]
              return nil
            end

            @suite_report_writer.write(
              all_results, all_scenarios,
              package: "suite",
              timestamp: timestamp,
              base_dir: @base_dir
            )
          rescue => e
            warn "Warning: Suite report generation failed (#{e.class}: #{e.message})"
            warn e.backtrace.first(5).join("\n") if ENV["DEBUG"]
            nil
          end

          # Convert a result hash (from subprocess output) into a Models::TestResult
          #
          # @param result_hash [Hash] Raw result hash with :status, :passed_cases, etc.
          # @return [Models::TestResult]
          def build_test_result(result_hash)
            passed = result_hash[:passed_cases] || 0
            total = result_hash[:total_cases] || 0
            failed = [total - passed, 0].max

            test_cases = []
            passed.times { |i| test_cases << { id: "TC-#{format("%03d", i + 1)}", description: "", status: "pass" } }
            failed.times { |i| test_cases << { id: "TC-#{format("%03d", passed + i + 1)}", description: "", status: "fail" } }

            Models::TestResult.new(
              test_id: result_hash[:test_name] || "unknown",
              status: result_hash[:status] || "error",
              test_cases: test_cases,
              summary: result_hash[:summary] || result_hash[:error] || "",
              report_dir: result_hash[:report_dir]
            )
          end

          # Parse a .mt.md file into a Models::TestScenario, with fallback
          #
          # @param package [String] Package name
          # @param test_file [String] Path to the test file
          # @return [Models::TestScenario]
          def parse_scenario(package, test_file)
            @parser.parse(test_file)
          rescue => _e
            Models::TestScenario.new(
              test_id: extract_test_id(test_file),
              title: extract_test_name(test_file),
              area: package.sub(/\Aace-/, ""),
              package: package,
              file_path: test_file,
              content: ""
            )
          end

          # Generate N unique run IDs for batch test runs
          #
          # Uses Ace::Support::Timestamp library to encode unique IDs with 50ms precision,
          # ensuring distinct timestamps for coordinated sandbox/report paths.
          #
          # @param count [Integer] Number of unique run IDs needed
          # @return [Array<String>] Array of unique run ID strings
          def generate_run_ids(count)
            count.times.map do |i|
              time = Time.now.utc + (i * 0.05)
              Ace::Support::Timestamp.encode(time, format: :"50ms")
            end
          end

          # Generate a timestamp for report naming
          # @return [String] Compact Base36 timestamp ID
          def default_timestamp
            Ace::Support::Timestamp.encode(Time.now.utc, format: :"50ms")
          end

          # Run a single test (sequential mode)
          #
          # @param package [String] Package name
          # @param test_file [String] Path to test file
          # @param options [Hash] Execution options
          # @return [Hash] Test result
          def run_single_test(package, test_file, options, run_id: nil)
            cmd_array = build_test_command(package, test_file, options, run_id: run_id)
            output, stderr, status = Open3.capture3(*cmd_array, chdir: @base_dir)

            # Combine stdout and stderr for parsing
            combined_output = output + stderr
            parse_test_output(combined_output, status.exitstatus, extract_test_name(test_file))
          rescue => e
            { status: "error", error: e.message }
          end
        end
      end
    end
  end
end
