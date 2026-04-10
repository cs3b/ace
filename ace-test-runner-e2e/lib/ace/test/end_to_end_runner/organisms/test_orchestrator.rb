# frozen_string_literal: true

require "fileutils"
require "date"
require "yaml"
require "ace/b36ts"
require "ace/test_support/sandbox_package_copy"
require "ace/test/end_to_end_runner/molecules/integration_runner"

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
            @provider = provider || config.dig("execution", "runner_provider") ||
              config.dig("execution", "provider") || "claude:sonnet"
            @timeout = timeout || config.dig("execution", "timeout") || 300
            @parallel = parallel || config.dig("execution", "parallel") || 3
            @base_dir = base_dir || Dir.pwd
            @timestamp_generator = timestamp_generator || method(:default_timestamp)
            @progress = progress
            @discoverer = Molecules::TestDiscoverer.new
            @integration_runner = Molecules::IntegrationRunner.new(base_dir: @base_dir)
            @loader = Molecules::ScenarioLoader.new
            @executor = executor || Molecules::TestExecutor.new(provider: @provider, timeout: @timeout, config: config)
            @report_writer = Molecules::ReportWriter.new
            @suite_report_writer = Molecules::SuiteReportWriter.new(config: config)
          end

          # Run E2E tests for a package, optionally filtering by test ID
          #
          # @param package [String] Package name (e.g., "ace-lint")
          # @param test_id [String, nil] Optional test ID to run specific test
          # @param test_cases [Array<String>, nil] Optional normalized test case IDs to filter
          # @param tags [Array<String>, nil] Optional scenario tags for discovery filtering
          # @param cli_args [String, nil] Extra args for CLI providers
          # @param output [IO] Output stream for progress messages (default: $stdout)
          # @return [Array<Models::TestResult>] List of test results
          def run(package:, test_id: nil, test_cases: nil, verify: false, tags: nil,
            cli_args: nil, run_id: nil, report_dir: nil, output: $stdout)
            integration_files = @discoverer.find_integration_tests(
              package: package,
              base_dir: @base_dir
            )

            # Discover tests
            files = @discoverer.find_tests(
              package: package,
              test_id: test_id,
              tags: tags,
              base_dir: @base_dir
            )

            if files.empty? && integration_files.empty?
              output.puts "No E2E tests found in #{package}" +
                (test_id ? " matching #{test_id}" : "")
              return []
            end

            # Generate timestamp for this run (use external run_id when provided)
            timestamp = run_id || generate_timestamp

            if files.size == 1 && integration_files.empty?
              run_single_test(
                files.first,
                timestamp,
                cli_args,
                output,
                test_cases: test_cases,
                verify: verify,
                report_dir: report_dir
              )
            else
              run_package_tests(
                files,
                package,
                timestamp,
                cli_args,
                output,
                test_cases: test_cases,
                verify: verify,
                integration_files: integration_files
              )
            end
          end

          private

          # Check if the current provider is a CLI provider
          # @return [Boolean]
          def cli_provider?
            Atoms::CliProviderAdapter.cli_provider?(@provider)
          end

          # Run deterministic setup in Ruby before handing off to LLM
          #
          # For scenarios with setup steps and CLI providers, creates
          # a sandbox and runs SetupExecutor so the LLM only does TC execution.
          #
          # @param scenario [Models::TestScenario] The test scenario
          # @param timestamp [String] Timestamp for sandbox directory naming
          # @param output [IO] Output stream for progress messages
          # @return [Array(String, Hash, SetupExecutor)] [sandbox_path, env_vars, setup_executor] or [nil, nil, nil]
          def setup_sandbox_if_ts(scenario, timestamp, output)
            return [nil, nil, nil] unless cli_provider? && scenario.setup_steps.any?

            sandbox_dir = File.join(@base_dir, ".ace-local", "test-e2e", scenario.dir_name(timestamp))
            package_copy = Ace::TestSupport::SandboxPackageCopy.new(source_root: @base_dir)
            package_source = File.join(@base_dir, scenario.package.to_s)
            package_copy_result = if File.directory?(package_source)
              package_copy.prepare(
                package_name: scenario.package,
                sandbox_root: sandbox_dir
              )
            else
              {
                env: {
                  "PROJECT_ROOT_PATH" => File.expand_path(sandbox_dir),
                  "ACE_E2E_SOURCE_ROOT" => File.expand_path(@base_dir)
                }
              }
            end
            setup_executor = Molecules::SetupExecutor.new
            result = setup_executor.execute(
              setup_steps: scenario.setup_steps,
              sandbox_dir: sandbox_dir,
              fixture_source: scenario.fixture_path,
              scenario_name: scenario.test_id,
              run_id: timestamp,
              initial_env: package_copy_result[:env]
            )

            unless result[:success]
              output.puts "Warning: sandbox setup failed: #{result[:error]}"
              setup_executor.teardown
              return [nil, nil, nil]
            end

            env = result[:env]
            if env["PROJECT_ROOT_PATH"] && !env["PROJECT_ROOT_PATH"].start_with?("/")
              env["PROJECT_ROOT_PATH"] = File.expand_path(env["PROJECT_ROOT_PATH"], sandbox_dir)
            end

            [File.expand_path(sandbox_dir), env, setup_executor]
          end

          # Run a single test
          # @param test_cases [Array<String>, nil] Optional test case IDs to filter
          # @param report_dir [String, nil] Explicit report directory path (overrides computed path)
          # @return [Array<Models::TestResult>] Single-element result array
          def run_single_test(file, timestamp, cli_args, output, test_cases: nil, verify: false, report_dir: nil)
            scenario = @loader.load(File.dirname(file))
            display = build_display_manager([scenario], output)
            setup_executor = nil

            output.puts "Running E2E test: #{scenario.test_id} (#{scenario.package})"
            if test_cases
              output.puts "Filtering test cases: #{test_cases.join(", ")}"
            end
            output.puts "Executing via #{@provider}#{" (pipeline mode: runner+verifier)" if cli_provider?}..."

            run_id = cli_provider? ? timestamp : nil
            # When report_dir is provided, derive sandbox path from it (strip -reports suffix)
            if report_dir
              sandbox_path = report_dir.sub(/-reports\z/, "")
              sandbox_path, env_vars, setup_executor = setup_sandbox_if_ts(scenario, timestamp, output) unless Dir.exist?(sandbox_path)
            else
              sandbox_path, env_vars, setup_executor = setup_sandbox_if_ts(scenario, timestamp, output)
            end
            result = execute_scenario(
              scenario,
              cli_args: cli_args,
              run_id: run_id,
              test_cases: test_cases,
              sandbox_path: sandbox_path,
              env_vars: env_vars,
              report_dir: report_dir,
              verify: verify
            )

            # Use explicit report_dir when provided, otherwise compute from scenario
            expected_dir = report_dir || report_dir_for(scenario, timestamp)

            if cli_provider?
              # CLI providers write reports via workflow at a deterministic path.
              # Do not fall back to older report directories from other runs.
              result = if Dir.exist?(expected_dir)
                verify ? result.with_report_dir(expected_dir) : read_agent_result(scenario, expected_dir, result)
              else
                missing_agent_report_result(scenario, expected_dir, result)
              end
            else
              # API providers: write reports via ReportWriter
              @report_writer.write(result, scenario, report_dir: expected_dir)
              result = result.with_report_dir(expected_dir)
            end

            display.show_single_result(result)
            output.puts "Report: #{result.report_dir}" if result.report_dir

            [result]
          ensure
            setup_executor&.teardown
          end

          # Run all tests in a package
          # @param test_cases [Array<String>, nil] Optional test case IDs to filter
          # @return [Array<Models::TestResult>] Results for all tests
          def run_package_tests(files, package, timestamp, cli_args, output, test_cases: nil, verify: false,
            integration_files: [])
            integration_result = @integration_runner.run(
              package: package,
              files: integration_files,
              timestamp: timestamp,
              output: output
            )
            if integration_result && %w[fail error].include?(integration_result.status)
              output.puts integration_result.summary
              return [integration_result]
            end

            if files.empty?
              return integration_result ? [integration_result] : []
            end

            # Load scenarios upfront for titles and report generation
            scenarios = files.map { |f| @loader.load(File.dirname(f)) }

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

                  # Intersect test_cases with scenario's available IDs to avoid
                  # workflow validation errors when filtering across multiple scenarios
                  scenario_test_cases = if test_cases
                    available = scenario.test_case_ids
                    filtered = test_cases & available
                    filtered.empty? ? nil : filtered
                  end

                  # Skip scenario entirely when filtering is active but no test cases match
                  setup_executor = nil
                  if test_cases && scenario_test_cases.nil?
                    result = Models::TestResult.new(
                      test_id: scenario.test_id,
                      status: "skip",
                      test_cases: [],
                      summary: "Skipped: no matching test cases"
                    )
                  else
                    begin
                      sandbox_path, env_vars, setup_executor = setup_sandbox_if_ts(scenario, run_id || timestamp, output)
                      result = execute_scenario(
                        scenario,
                        cli_args: cli_args,
                        run_id: run_id,
                        test_cases: scenario_test_cases,
                        sandbox_path: sandbox_path,
                        env_vars: env_vars,
                        verify: verify
                      )
                    ensure
                      setup_executor&.teardown
                    end
                  end

                  report_dir = report_dir_for(scenario, run_id || timestamp)

                  if cli_provider?
                    expected_dir = report_dir_for(scenario, run_id || timestamp)
                    result = if Dir.exist?(expected_dir)
                      verify ? result.with_report_dir(expected_dir) : read_agent_result(scenario, expected_dir, result)
                    else
                      missing_agent_report_result(scenario, expected_dir, result)
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

            combined_results = integration_result ? [integration_result] + results : results

            # Write suite report
            report_path = @suite_report_writer.write(
              combined_results, scenarios,
              package: package, timestamp: timestamp, base_dir: @base_dir
            )

            display.show_summary(combined_results, report_path)

            combined_results
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
            cache_dir = File.join(@base_dir, ".ace-local", "test-e2e")
            File.join(cache_dir, "#{scenario.dir_name(timestamp)}-reports")
          end

          # Generate a timestamp ID via injected generator
          # @return [String] 7-char timestamp ID
          def generate_timestamp
            @timestamp_generator.call
          end

          # Generate N unique timestamps for batch test runs
          #
          # Uses Ace::B36ts library to encode unique IDs with 50ms precision,
          # ensuring distinct timestamps for parallel test runs.
          #
          # @param count [Integer] Number of unique timestamps needed
          # @return [Array<String>] Array of unique timestamp strings
          def generate_timestamps(count)
            count.times.map do |i|
              time = Time.now.utc + (i * 0.05) # 50ms offset per ID
              Ace::B36ts.encode(time, format: :"50ms")
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
            passed = metadata["tcs-passed"] || metadata.dig("results", "passed") || 0
            failed = metadata["tcs-failed"] || metadata.dig("results", "failed") || 0
            total = metadata["tcs-total"] || metadata.dig("results", "total") || 0

            # Reconcile: if all cases passed, status should be "pass"
            if passed == total && total > 0 && status != "pass"
              status = "pass"
            end

            # Build synthetic test cases from counts
            test_cases = []
            passed.times { |i| test_cases << {id: "TC-#{format("%03d", i + 1)}", description: "", status: "pass", actual: "", notes: ""} }
            failed.times { |i| test_cases << {id: "TC-#{format("%03d", passed + i + 1)}", description: "", status: "fail", actual: "", notes: ""} }

            Models::TestResult.new(
              test_id: scenario.test_id,
              status: status,
              test_cases: test_cases,
              summary: "#{passed}/#{total} passed",
              started_at: fallback_result.started_at,
              completed_at: fallback_result.completed_at,
              report_dir: agent_dir
            )
          rescue
            fallback_result.with_report_dir(agent_dir)
          end

          # Build a deterministic infrastructure error when the expected report
          # directory for a CLI-provider run is missing.
          #
          # @param scenario [Models::TestScenario]
          # @param expected_dir [String] Deterministic report directory path
          # @param fallback_result [Models::TestResult]
          # @return [Models::TestResult]
          def missing_agent_report_result(scenario, expected_dir, fallback_result)
            return fallback_result.with_report_dir(expected_dir) if fallback_result.status == "skip"

            Models::TestResult.new(
              test_id: scenario.test_id,
              status: "error",
              test_cases: fallback_result.test_cases,
              summary: "Missing CLI report directory",
              error: "Expected report directory was not created: #{expected_dir}",
              started_at: fallback_result.started_at,
              completed_at: fallback_result.completed_at,
              report_dir: expected_dir
            )
          end

          # Default timestamp generator using Ace::B36ts library
          # @return [String] 7-char timestamp ID
          def default_timestamp
            Ace::B36ts.encode(Time.now.utc, format: :"50ms")
          end

          # Execute a scenario while preserving compatibility with legacy executor
          # doubles that do not accept the newer :verify keyword.
          def execute_scenario(scenario, cli_args:, run_id:, test_cases:, sandbox_path:, env_vars:, report_dir: nil, verify: false)
            kwargs = {
              cli_args: cli_args,
              run_id: run_id,
              test_cases: test_cases,
              sandbox_path: sandbox_path,
              env_vars: env_vars,
              report_dir: report_dir
            }

            supports_timeout = @executor.method(:execute).parameters.any? do |type, name|
              type == :keyrest || (%i[key keyreq].include?(type) && name == :timeout)
            end
            supports_verify = @executor.method(:execute).parameters.any? do |type, name|
              type == :keyrest || (%i[key keyreq].include?(type) && name == :verify)
            end
            kwargs[:timeout] = (scenario.timeout || @timeout) if supports_timeout
            kwargs[:verify] = verify if supports_verify

            @executor.execute(scenario, **kwargs)
          end
        end
      end
    end
  end
end
