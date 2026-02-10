# frozen_string_literal: true

require "dry/cli"
require "stringio"
require "ace/core/cli/dry_cli/base"

module Ace
  module Test
    module EndToEndRunner
      module CLI
        module Commands
          # CLI command for running E2E test suite across all packages
          #
          # Discovers all E2E tests in the monorepo and executes them
          # with optional parallel execution and affected package filtering.
          class RunSuite < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Run E2E test suite across all packages

              Discovers and executes *.mt.md test scenarios from all packages
              in the monorepo. Tests run sequentially by default or in parallel
              with --parallel flag. Use --affected to only test changed packages.
              Use --only-failures to re-run only previously failed test cases.
              Optionally filter to specific packages with a comma-separated list.

              Output:
                Exit codes: 0 (all pass), 1 (any fail/error)
            DESC

            argument :packages, required: false,
                     desc: "Comma-separated package names (e.g., ace-bundle,ace-lint)"

            example [
              "                              # Run all tests sequentially",
              "ace-bundle,ace-lint           # Run only specified packages",
              "--parallel 4                  # Run with 4 parallel workers",
              "--affected                    # Only test changed packages",
              "--affected --parallel 8       # Parallel affected tests only",
              "--only-failures               # Re-run only failed tests",
              "--affected --only-failures    # Re-run failures in affected packages",
              "--cli-args dangerously-skip-permissions  # Pass args to provider"
            ]

            option :parallel, type: :string, default: "0",
                   desc: "Number of parallel workers (0 = sequential)"
            option :affected, type: :boolean, desc: "Only test affected packages"
            option :only_failures, type: :boolean,
                   desc: "Re-run only previously failed test cases"
            option :cli_args, type: :string,
                   desc: "Extra args for CLI-based LLM providers"
            option :provider, type: :string, default: Molecules::ConfigLoader.default_provider,
                   desc: "LLM provider:model (e.g., claude:sonnet, gemini:flash)"
            option :timeout, type: :string, default: Molecules::ConfigLoader.default_timeout.to_s,
                   desc: "Timeout per test in seconds"
            option :progress, type: :boolean, desc: "Enable live animated display"
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress detailed output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(packages: nil, **options)
              options = convert_types(options, parallel: :integer, timeout: :integer)

              parallel = options[:parallel]
              affected = options[:affected]
              only_failures = options[:only_failures]

              output = quiet?(options) ? StringIO.new : $stdout
              progress = options[:progress] && !quiet?(options)

              orchestrator = Organisms::SuiteOrchestrator.new(
                max_parallel: [parallel, 1].max,
                output: output,
                progress: progress
              )

              results = orchestrator.run(
                parallel: parallel > 0,
                affected: affected,
                only_failures: only_failures,
                packages: packages,
                cli_args: options[:cli_args],
                provider: options[:provider],
                timeout: options[:timeout]
              )

              if results[:total].zero?
                if only_failures
                  raise Ace::Core::CLI::Error.new(
                    "No failed test cases found in cache"
                  )
                else
                  raise Ace::Core::CLI::Error.new("No tests found to run")
                end
              end

              # Exit with error if any test failed
              if results[:failed] > 0 || results[:errors] > 0
                failed_count = results[:failed] + results[:errors]
                raise Ace::Core::CLI::Error.new(
                  "#{failed_count} test(s) failed or errored"
                )
              end
            end
          end
        end
      end
    end
  end
end
