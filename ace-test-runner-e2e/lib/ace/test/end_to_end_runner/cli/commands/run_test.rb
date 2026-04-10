# frozen_string_literal: true

require "ace/support/cli"
require "stringio"
require "ace/support/cli"

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
          class RunTest < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base

            desc <<~DESC.strip
              Run E2E tests via LLM execution

              Discovers and executes deterministic integration tests from test/integration
              before TS-* agent scenarios from test/e2e. Tests are sent to an LLM provider
              which executes the scenario steps and returns structured results.

              Output:
                Exit codes: 0 (all pass), 1 (any fail/error)
                Reports written to: .ace-local/test-e2e/{timestamp}-{pkg}-{id}-reports/
            DESC

            example [
              "ace-lint TS-LINT-001          # Run specific test",
              "ace-lint                      # Run all tests in package",
              "ace-lint --provider gemini:flash  # Use specific provider",
              "ace-lint --provider glite     # Use API provider (predict mode)",
              "ace-lint --tags smoke         # Run only smoke-tagged scenarios",
              "ace-lint TS-LINT-003 --dry-run  # Preview integration and scenario phases"
            ]

            argument :package, required: true, desc: "Package name (e.g., ace-lint)"
            argument :test_id, required: false, desc: "Test ID (e.g., TS-LINT-001)"

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
            option :report_dir, type: :string,
              desc: "Explicit report directory path (overrides computed path)"
            option :dry_run, type: :boolean,
              desc: "Preview which integration tests and scenarios would run without executing"
            option :tags, type: :string,
              desc: "Comma-separated scenario tags to include"
            option :verify, type: :boolean,
              desc: "Run independent verifier pass after runner execution"
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

            def call(package:, test_id: nil, **options)
              options = coerce_types(options, timeout: :integer, parallel: :integer)
              output = quiet?(options) ? StringIO.new : $stdout

              # Handle dry-run mode
              if options[:dry_run]
                return handle_dry_run(package, test_id, output, tags: parse_tags(options[:tags]))
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
                verify: options[:verify],
                tags: parse_tags(options[:tags]),
                cli_args: options[:cli_args],
                run_id: options[:run_id],
                report_dir: options[:report_dir],
                output: output
              )

              if results.empty?
                raise Ace::Support::Cli::Error.new(
                  "No tests found for package '#{package}'" +
                  (test_id ? " with ID '#{test_id}'" : "")
                )
              end

              # Exit with error if any test failed (excluding skips)
              if results.any?(&:failed?)
                failed = results.select(&:failed?)
                failed_ids = failed.map(&:test_id).join(", ")
                raise Ace::Support::Cli::Error.new(
                  "#{failed.size} test(s) failed: #{failed_ids}"
                )
              end
            end

            private

            # Handle dry-run mode: preview which integration tests and scenarios would run
            #
            # @param package [String] Package name
            # @param test_id [String, nil] Test ID
            # @param output [IO] Output stream
            def handle_dry_run(package, test_id, output, tags: [])
              discoverer = Molecules::TestDiscoverer.new
              loader = Molecules::ScenarioLoader.new

              files = discoverer.find_tests(
                package: package,
                test_id: test_id,
                tags: tags,
                base_dir: Dir.pwd
              )
              integration_files = discoverer.find_integration_tests(package: package, base_dir: Dir.pwd)
              if files.empty? && integration_files.empty?
                raise Ace::Support::Cli::Error.new(
                  "No tests found for package '#{package}'" +
                  (test_id ? " with ID '#{test_id}'" : "")
                )
              end

              output.puts "Dry run: preview of execution phases"
              output.puts ""
              output.puts "Phase 1: integration"
              if integration_files.empty?
                output.puts "  (none)"
              else
                integration_files.each do |file|
                  output.puts "  [integration] #{file}"
                end
              end
              output.puts ""
              output.puts "Phase 2: scenarios"
              output.puts "  (none)" if files.empty?
              output.puts "" unless files.empty?

              files.each do |file|
                scenario = loader.load(File.dirname(file))
                output.puts "#{scenario.test_id}: #{scenario.title}"
                output.puts "  [run] full scenario (#{scenario.test_case_ids.size} test cases)"
                output.puts ""
              end
            end

            def parse_tags(raw)
              return [] if raw.nil? || raw.strip.empty?

              raw.split(",").map(&:strip).reject(&:empty?).map(&:downcase)
            end
          end
        end
      end
    end
  end
end
