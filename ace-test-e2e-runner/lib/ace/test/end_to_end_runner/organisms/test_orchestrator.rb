# frozen_string_literal: true

require "fileutils"
require "thread"
require "date"
require "yaml"
require "ace/support/timestamp"

module Ace
  module Test
    module EndToEndRunner
      module Organisms
        # Orchestrates E2E test discovery, execution, and reporting
        #
        # Handles both single test and package-wide test execution flows.
        # Coordinates between test discovery, scenario parsing, LLM execution,
        # and report writing.
        #
        # For CLI providers: agents write their own reports via workflow/skill,
        # so the orchestrator skips ReportWriter and looks for agent-written
        # report directories on disk.
        #
        # For API providers: orchestrator writes reports as before.
        class TestOrchestrator
          # @param provider [String] LLM provider:model string
          # @param timeout [Integer] Request timeout per test in seconds
          # @param parallel [Integer] Number of tests to run in parallel
          # @param base_dir [String] Base directory for test discovery
          # @param timestamp_generator [#call] Callable that returns a timestamp string
          # @param executor [#execute] Injectable test executor (for testing)
          # @param progress [Boolean] Enable animated progress display
          def initialize(provider: nil, timeout: nil, parallel: nil, base_dir: nil, timestamp_generator: nil, executor: nil, progress: false)
            config = Molecules::ConfigLoader.load
            @provider = provider || config.dig("execution", "provider") || "claude:sonnet"
            @timeout = timeout || config.dig("execution", "timeout") || 300
            @parallel = parallel || config.dig("execution", "parallel") || 3
            @base_dir = base_dir || Dir.pwd
            @timestamp_generator = timestamp_generator || method(:default_timestamp)
            @progress = progress
            @discoverer = Molecules::TestDiscoverer.new
            @parser = Molecules::ScenarioParser.new
            @executor = executor || Molecules::TestExecutor.new(provider: @provider, timeout: @timeout, config: config)
            @report_writer = Molecules::ReportWriter.new
            @suite_report_writer = Molecules::SuiteReportWriter.new(config: config)
          end

          # Run E2E tests for a package, optionally filtering by test ID
          #
          # @param package [String] Package name (e.g., "ace-lint")
          # @param test_id [String, nil] Optional test ID to run specific test
          # @param cli_args [String, nil] Extra args for CLI providers
          # @param output [IO] Output stream for progress messages (default: $stdout)
          # @return [Array<Models::TestResult>] List of test results
          def run(package:, test_id: nil, cli_args: nil, run_id: nil, output: $stdout)
            # Discover tests
            files = @discoverer.find_tests(
              package: package,
              test_id: test_id,
              base_dir: @base_dir
            )

            if files.empty?
              output.puts "No E2E tests found in #{package}" +
                          (test_id ? " matching #{test_id}" : "")
              return []
            end

            # Generate timestamp for this run (use external run_id when provided)
            timestamp = run_id || generate_timestamp

            if files.size == 1
              run_single_test(files.first, timestamp, cli_args, output)
            else
              run_package_tests(files, package, timestamp, cli_args, output)
            end
          end

          private

          # Check if the current provider is a CLI provider
          # @return [Boolean]
          def cli_provider?
            Atoms::SkillPromptBuilder.cli_provider?(@provider)
          end

          # Run a single test
          # @return [Array<Models::TestResult>] Single-element result array
          def run_single_test(file, timestamp, cli_args, output)
            scenario = @parser.parse(file)
            display = build_display_manager([scenario], output)

            output.puts "Running E2E test: #{scenario.test_id} (#{scenario.package})"
            output.puts "Executing via #{@provider}#{cli_provider? ? " (skill mode)" : ""}..."

            run_id = cli_provider? ? timestamp : nil
            result = @executor.execute(scenario, cli_args: cli_args, run_id: run_id)

            report_dir = report_dir_for(scenario, timestamp)

            if cli_provider?
              # CLI providers write reports via workflow — use expected path, fallback to glob
              expected_dir = report_dir_for(scenario, timestamp)
              agent_dir = Dir.exist?(expected_dir) ? expected_dir : find_agent_report_dir(scenario)
              if agent_dir
                result = read_agent_result(scenario, agent_dir, result)
              else
                result = result.with_report_dir(expected_dir)
              end
            else
              # API providers: write reports via ReportWriter
              report_paths = @report_writer.write(result, scenario, report_dir: report_dir)
              result = result.with_report_dir(report_dir)
            end

            display.show_single_result(result)
            output.puts "Report: #{result.report_dir}" if result.report_dir

            [result]
          end

          # Run all tests in a package
          # @return [Array<Models::TestResult>] Results for all tests
          def run_package_tests(files, package, timestamp, cli_args, output)
            # Parse scenarios upfront for titles and report generation
            scenarios = files.map { |f| @parser.parse(f) }

            display = build_display_manager(scenarios, output)
            display.initialize_display

            # Generate unique timestamps per test for CLI providers (deterministic report paths)
            run_ids = cli_provider? ? generate_timestamps(scenarios.size) : Array.new(scenarios.size)

            queue = Queue.new
            scenarios.each_with_index { |scenario, index| queue << [index, scenario, run_ids[index]] }

            results = Array.new(files.size)
            mutex = Mutex.new
            completed = 0

            thread_count = [@parallel, files.size].min
            done = false

            refresh_thread = if @progress
              Thread.new do
                until done
                  sleep REFRESH_INTERVAL
                  mutex.synchronize { display.refresh }
                end
              end
            end

            threads = thread_count.times.map do
              Thread.new do
                while (item = begin; queue.pop(true); rescue ThreadError; nil; end)
                  index, scenario, run_id = item

                  mutex.synchronize do
                    display.test_started(scenario)
                  end

                  result = @executor.execute(scenario, cli_args: cli_args, run_id: run_id)

                  report_dir = report_dir_for(scenario, run_id || timestamp)

                  if cli_provider?
                    expected_dir = report_dir_for(scenario, run_id)
                    agent_dir = Dir.exist?(expected_dir) ? expected_dir : find_agent_report_dir(scenario)
                    if agent_dir
                      result = read_agent_result(scenario, agent_dir, result)
                    else
                      result = result.with_report_dir(expected_dir)
                    end
                  else
                    @report_writer.write(result, scenario, report_dir: report_dir)
                    result = result.with_report_dir(report_dir)
                  end

                  mutex.synchronize do
                    results[index] = result
                    completed += 1
                    display.test_completed(scenario, result, completed, files.size)
                  end
                end
              end
            end

            threads.each(&:join)
            done = true
            refresh_thread&.join

            # Write suite report
            report_path = @suite_report_writer.write(
              results, scenarios,
              package: package, timestamp: timestamp, base_dir: @base_dir
            )

            display.show_summary(results, report_path)

            results
          end

          # Build the appropriate display manager for this run
          # @param scenarios [Array<Models::TestScenario>]
          # @param output [IO]
          # @return [Molecules::SimpleDisplayManager, Molecules::ProgressDisplayManager]
          def build_display_manager(scenarios, output)
            if @progress
              Molecules::ProgressDisplayManager.new(scenarios, output: output, parallel: @parallel)
            else
              Molecules::SimpleDisplayManager.new(scenarios, output: output, parallel: @parallel)
            end
          end

          # Build report directory path for a scenario
          # @return [String] Absolute path to reports directory
          def report_dir_for(scenario, timestamp)
            cache_dir = File.join(@base_dir, ".cache", "ace-test-e2e")
            File.join(cache_dir, "#{scenario.dir_name(timestamp)}-reports")
          end

          # Find an agent-written report directory on disk
          #
          # Agents create report dirs matching the pattern:
          #   .cache/ace-test-e2e/{timestamp}-{short-pkg}-{short-id}-reports/
          # Look for the most recent one matching this scenario.
          #
          # @param scenario [Models::TestScenario] The test scenario
          # @return [String, nil] Path to found report dir, or nil
          def find_agent_report_dir(scenario)
            cache_dir = File.join(@base_dir, ".cache", "ace-test-e2e")
            return nil unless Dir.exist?(cache_dir)

            pattern = "*-#{scenario.short_package}-#{scenario.short_id}-reports"
            matches = Dir.glob(File.join(cache_dir, pattern)).sort
            matches.last # Most recent by timestamp
          end

          # Generate a timestamp ID via injected generator
          # @return [String] 7-char timestamp ID
          def generate_timestamp
            @timestamp_generator.call
          end

          # Generate N unique timestamps for batch test runs
          #
          # Uses Ace::Support::Timestamp library to encode unique IDs with 50ms precision,
          # ensuring distinct timestamps for parallel test runs.
          #
          # @param count [Integer] Number of unique timestamps needed
          # @return [Array<String>] Array of unique timestamp strings
          def generate_timestamps(count)
            count.times.map do |i|
              time = Time.now.utc + (i * 0.05) # 50ms offset per ID
              Ace::Support::Timestamp.encode(time, format: :"50ms")
            end
          end

          # Read the agent-written metadata.yml to determine authoritative test status
          #
          # When CLI providers run tests, they write metadata.yml with the real
          # pass/fail status. The orchestrator's parsed response text may not
          # match, so we trust metadata.yml when present.
          #
          # @param scenario [Models::TestScenario] The test scenario
          # @param agent_dir [String] Path to agent report directory
          # @param fallback_result [Models::TestResult] Result to use if metadata unreadable
          # @return [Models::TestResult] Result with authoritative status
          def read_agent_result(scenario, agent_dir, fallback_result)
            metadata_path = File.join(agent_dir, "metadata.yml")
            return fallback_result.with_report_dir(agent_dir) unless File.exist?(metadata_path)

            metadata = YAML.safe_load_file(metadata_path, permitted_classes: [Date])
            status = metadata["status"] || fallback_result.status
            passed = metadata.dig("results", "passed") || 0
            failed = metadata.dig("results", "failed") || 0
            total = metadata.dig("results", "total") || 0

            # Build synthetic test cases from counts
            test_cases = []
            passed.times { |i| test_cases << { id: "TC-#{format("%03d", i + 1)}", description: "", status: "pass", actual: "", notes: "" } }
            failed.times { |i| test_cases << { id: "TC-#{format("%03d", passed + i + 1)}", description: "", status: "fail", actual: "", notes: "" } }

            Models::TestResult.new(
              test_id: scenario.test_id,
              status: status,
              test_cases: test_cases,
              summary: "#{passed}/#{total} passed",
              started_at: fallback_result.started_at,
              completed_at: fallback_result.completed_at,
              report_dir: agent_dir
            )
          rescue => e
            fallback_result.with_report_dir(agent_dir)
          end

          # Default timestamp generator using Ace::Support::Timestamp library
          # @return [String] 7-char timestamp ID
          def default_timestamp
            Ace::Support::Timestamp.encode(Time.now.utc, format: :"50ms")
          end
        end
      end
    end
  end
end
