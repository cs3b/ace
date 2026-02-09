# frozen_string_literal: true

require "dry/cli"
require "stringio"
require "ace/core/cli/dry_cli/base"

module Ace
  module Test
    module EndToEndRunner
      module CLI
        module Commands
          # CLI command for running E2E tests
          #
          # Supports running a single test by ID or all tests in a package.
          # Tests are executed via LLM and results are written to standard
          # report locations.
          class RunTest < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Run E2E tests via LLM execution

              Discovers and executes *.mt.md test scenarios in a package's test/e2e/ directory.
              Tests are sent to an LLM provider which executes the test steps and returns
              structured results.

              Output:
                Exit codes: 0 (all pass), 1 (any fail/error)
                Reports written to: .cache/ace-test-e2e/{timestamp}-{pkg}-{id}-reports/
            DESC

            example [
              "ace-lint MT-LINT-001          # Run specific test",
              "ace-lint                      # Run all tests in package",
              "ace-lint --provider gemini:flash  # Use specific provider",
              "ace-lint --provider glite     # Use API provider (predict mode)",
              "ace-lint MT-LINT-003 --test-cases tc-001,002  # Run specific test cases",
              "ace-lint MT-LINT-003 --test-cases TC-001 --dry-run  # Preview test cases"
            ]

            argument :package, required: true, desc: "Package name (e.g., ace-lint)"
            argument :test_id, required: false, desc: "Test ID (e.g., MT-LINT-001)"

            option :provider, type: :string, default: Molecules::ConfigLoader.default_provider,
                   desc: "LLM provider:model (e.g., claude:sonnet, gemini:flash)"
            option :cli_args, type: :string,
                   desc: "Extra args for CLI-based LLM providers"
            option :timeout, type: :string, default: Molecules::ConfigLoader.default_timeout.to_s,
                   desc: "Timeout per test in seconds"
            option :parallel, type: :string, default: Molecules::ConfigLoader.default_parallel.to_s,
                   desc: "Number of tests to run in parallel (1 = sequential)"
            option :progress, type: :boolean, desc: "Enable live animated display"
            option :run_id, type: :string,
                   desc: "Pre-generated run ID for deterministic report paths"
            option :test_cases, type: :string,
                   desc: "Comma-separated test case IDs to run (e.g., tc-001,002,TC-3)"
            option :dry_run, type: :boolean,
                   desc: "Preview which test cases would run without executing"
            option :only_failures, type: :boolean,
                   desc: "Re-run only previously failed test cases"
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress detailed output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(package:, test_id: nil, **options)
              options = convert_types(options, timeout: :integer, parallel: :integer)
              output = quiet?(options) ? StringIO.new : $stdout

              # Validate mutually exclusive flags
              validate_exclusive_flags!(options)

              # Parse and normalize test case IDs if provided
              test_cases = parse_test_cases(options[:test_cases])

              # Handle dry-run mode
              if options[:dry_run]
                return handle_dry_run(package, test_id, test_cases, output)
              end

              orchestrator = Organisms::TestOrchestrator.new(
                provider: options[:provider],
                timeout: options[:timeout],
                parallel: options[:parallel],
                progress: options[:progress]
              )

              results = orchestrator.run(
                package: package,
                test_id: test_id,
                test_cases: test_cases,
                cli_args: options[:cli_args],
                run_id: options[:run_id],
                output: output
              )

              if results.empty?
                raise Ace::Core::CLI::Error.new(
                  "No tests found for package '#{package}'" +
                  (test_id ? " with ID '#{test_id}'" : "")
                )
              end

              # Exit with error if any test failed
              if results.any?(&:failed?)
                failed = results.select(&:failed?)
                failed_ids = failed.map(&:test_id).join(", ")
                raise Ace::Core::CLI::Error.new(
                  "#{failed.size} test(s) failed: #{failed_ids}"
                )
              end
            end

            private

            # Validate that mutually exclusive flags are not combined
            #
            # @param options [Hash] CLI options
            # @raise [Ace::Core::CLI::Error] If conflicting flags are used together
            def validate_exclusive_flags!(options)
              if options[:test_cases] && options[:only_failures]
                raise Ace::Core::CLI::Error.new(
                  "--test-cases and --only-failures are mutually exclusive. " \
                  "Use one or the other."
                )
              end
            end

            # Parse comma-separated test case IDs into normalized format
            #
            # @param raw [String, nil] Raw test cases string from CLI
            # @return [Array<String>, nil] Normalized test case IDs or nil
            def parse_test_cases(raw)
              return nil if raw.nil? || raw.strip.empty?

              Atoms::TestCaseParser.parse(raw)
            rescue ArgumentError => e
              raise Ace::Core::CLI::Error.new("Invalid test cases: #{e.message}")
            end

            # Handle dry-run mode: preview which test cases would run
            #
            # @param package [String] Package name
            # @param test_id [String, nil] Test ID
            # @param test_cases [Array<String>, nil] Normalized test case IDs
            # @param output [IO] Output stream
            def handle_dry_run(package, test_id, test_cases, output)
              discoverer = Molecules::TestDiscoverer.new
              parser = Molecules::ScenarioParser.new

              files = discoverer.find_tests(package: package, test_id: test_id, base_dir: Dir.pwd)
              if files.empty?
                raise Ace::Core::CLI::Error.new(
                  "No tests found for package '#{package}'" +
                  (test_id ? " with ID '#{test_id}'" : "")
                )
              end

              output.puts "Dry run: preview of test cases to execute"
              output.puts ""

              files.each do |file|
                scenario = parser.parse(file)
                available_ids = scenario.test_case_ids
                output.puts "#{scenario.test_id}: #{scenario.title}"

                if test_cases
                  # Validate and show filtered test cases
                  begin
                    Atoms::TestCaseParser.validate_against_available(test_cases, available_ids)
                    test_cases.each { |tc| output.puts "  [run] #{tc}" }
                    skipped = available_ids - test_cases
                    skipped.each { |tc| output.puts "  [skip] #{tc}" }
                  rescue ArgumentError => e
                    output.puts "  Error: #{e.message}"
                  end
                else
                  # Show all test cases
                  available_ids.each { |tc| output.puts "  [run] #{tc}" }
                end

                output.puts ""
              end
            end
          end
        end
      end
    end
  end
end
