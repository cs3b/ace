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
              "ace-lint --provider glite     # Use API provider (predict mode)"
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
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress detailed output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(package:, test_id: nil, **options)
              options = convert_types(options, timeout: :integer, parallel: :integer)

              orchestrator = Organisms::TestOrchestrator.new(
                provider: options[:provider],
                timeout: options[:timeout],
                parallel: options[:parallel],
                progress: options[:progress]
              )

              results = orchestrator.run(
                package: package,
                test_id: test_id,
                cli_args: options[:cli_args],
                output: quiet?(options) ? StringIO.new : $stdout
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
          end
        end
      end
    end
  end
end
