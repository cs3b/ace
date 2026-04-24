# frozen_string_literal: true

require "ace/b36ts"
require "ace/support/cli"
require "stringio"
require "ace/support/cli"

module Ace
  module Test
    module EndToEndRunner
      module CLI
        module Commands
          # CLI command for running E2E test suite across all packages
          #
          # Discovers all E2E tests in the monorepo and executes them
          # with optional parallel execution and affected package filtering.
          class RunSuite < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base

            desc <<~DESC.strip
              Run E2E test suite across all packages

              Discovers and executes TS-* test scenarios from all packages
              in the monorepo. Tests run sequentially by default or in parallel
              with --parallel flag. Use --affected to only test changed packages.
              Use --only-failures to re-run only previously failed scenarios.
              Full unfiltered suite runs retry failed scenarios once by default.
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
              "--only-failures               # Re-run failed scenarios from cache",
              "--affected --only-failures    # Re-run failed scenarios in affected packages",
              "--no-retry-failures-once      # Disable default retry for a full suite run",
              "--prune-artifacts             # Remove stale .ace-local/test-e2e artifacts before running",
              "--tags smoke,happy-path       # Include scenarios by tag",
              "--exclude-tags deep           # Exclude scenarios by tag",
              "--cli-args dangerously-skip-permissions  # Pass args to provider"
            ]

            option :parallel, type: :string, default: Molecules::ConfigLoader.default_parallel.to_s,
              desc: "Number of parallel workers (0 = sequential)"
            option :affected, type: :boolean, desc: "Only test affected packages"
            option :only_failures, type: :boolean,
              desc: "Re-run only previously failed scenarios"
            option :retry_failures_once, type: :boolean,
              desc: "Retry failed scenarios once after a full unfiltered suite run"
            option :cli_args, type: :string,
              desc: "Extra args for CLI-based LLM providers"
            option :provider, type: :string, default: Molecules::ConfigLoader.default_provider,
              desc: "LLM provider:model (e.g., claude:sonnet, gemini:flash)"
            option :timeout, type: :string, default: Molecules::ConfigLoader.default_timeout.to_s,
              desc: "Timeout per test in seconds"
            option :tags, type: :string, desc: "Comma-separated scenario tags to include"
            option :exclude_tags, type: :string, desc: "Comma-separated scenario tags to exclude"
            option :progress, type: :boolean, desc: "Enable live animated display"
            option :verify, type: :boolean,
              desc: "Run independent verifier pass for each scenario"
            option :prune_artifacts, type: :boolean,
              desc: "Remove stale .ace-local/test-e2e artifacts before running (preserves suite reports and runtime-cache)"
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

            def call(packages: nil, **options)
              options = coerce_types(options, parallel: :integer, timeout: :integer)

              parallel = options[:parallel]
              affected = !!options[:affected]
              only_failures = !!options[:only_failures]
              prune_artifacts = !!options[:prune_artifacts]
              tags = parse_csv_list(options[:tags])
              exclude_tags = parse_csv_list(options[:exclude_tags])
              if only_failures && prune_artifacts
                raise Ace::Support::Cli::Error.new(
                  "--prune-artifacts cannot be used with --only-failures"
                )
              end
              retry_failures_once = resolve_retry_failures_once(
                requested: options[:retry_failures_once],
                packages: packages,
                affected: affected,
                only_failures: only_failures,
                tags: tags,
                exclude_tags: exclude_tags
              )

              output = quiet?(options) ? StringIO.new : $stdout
              progress = options[:progress] && !quiet?(options)
              prune_artifacts_if_requested(output: output, prune_artifacts: prune_artifacts, quiet: quiet?(options))

              orchestrator = build_orchestrator(
                max_parallel: [parallel, 1].max,
                output: output,
                progress: progress
              )

              run_options = {
                parallel: parallel > 0,
                affected: affected,
                only_failures: only_failures,
                packages: packages,
                cli_args: options[:cli_args],
                provider: options[:provider],
                timeout: options[:timeout],
                tags: tags,
                exclude_tags: exclude_tags,
                verify: options[:verify]
              }

              results = run_suite_with_retry(
                orchestrator,
                run_options: run_options,
                output: output,
                retry_failures_once: retry_failures_once
              )

              if results[:total].zero?
                if only_failures
                  raise Ace::Support::Cli::Error.new(
                    "No failed test scenarios found in cache"
                  )
                else
                  raise Ace::Support::Cli::Error.new("No tests found to run")
                end
              end

              # Exit with error if any test failed
              if results[:failed] > 0 || results[:errors] > 0
                failed_count = results[:failed] + results[:errors]
                raise Ace::Support::Cli::Error.new(
                  results[:retry_attempted] ? "#{failed_count} test(s) failed or errored after retry" : "#{failed_count} test(s) failed or errored"
                )
              end

              results
            end

            private

            def build_orchestrator(max_parallel:, output:, progress:)
              Organisms::SuiteOrchestrator.new(
                max_parallel: max_parallel,
                output: output,
                progress: progress
              )
            end

            def build_retry_report_writer
              Molecules::SuiteReportWriter.new(config: Molecules::ConfigLoader.load)
            end

            def build_artifact_pruner
              Molecules::ArtifactPruner.new
            end

            def prune_artifacts_if_requested(output:, prune_artifacts:, quiet:)
              return unless prune_artifacts

              result = build_artifact_pruner.prune(base_dir: Dir.pwd)
              return if quiet

              output.puts(
                "Pruned #{result[:deleted_count]} artifact(s) from #{result[:root_display]} (preserved suite reports and runtime-cache)"
              )
            end

            def run_suite_with_retry(orchestrator, run_options:, output:, retry_failures_once:)
              initial_results = orchestrator.run(run_options)
              annotated = annotate_results(
                initial_results,
                retry_attempted: false,
                attempts: 1,
                flaky_scenarios: [],
                remaining_failures: failure_scenarios(initial_results),
                initial_report_path: initial_results[:report_path],
                retry_report_path: nil,
                report_path: initial_results[:report_path]
              )
              return annotated unless retry_failures_once && suite_failed?(initial_results)

              output.puts "Retrying failed scenarios once..."
              retry_results = orchestrator.run(run_options.merge(only_failures: true))
              if retry_results[:total].zero?
                raise Ace::Support::Cli::Error.new(
                  "Retry pass found no failed test scenarios from attempt 1; aborting instead of silently passing"
                )
              end

              flaky_scenarios = recovered_flaky_scenarios(initial_results, retry_results)
              remaining_failures = failure_scenarios(retry_results)
              final_report_path = write_retry_summary_report(initial_results, retry_results)
              output.puts "Final Report: #{final_report_path}" if final_report_path

              if remaining_failures.empty?
                output.puts "#{flaky_scenarios.length} scenario(s) recovered on retry and were marked flaky"
              else
                output.puts "#{remaining_failures.length} scenario(s) still failing after retry"
              end

              annotate_results(
                retry_results,
                retry_attempted: true,
                attempts: 2,
                flaky_scenarios: flaky_scenarios,
                remaining_failures: remaining_failures,
                initial_report_path: initial_results[:report_path],
                retry_report_path: retry_results[:report_path],
                report_path: final_report_path || retry_results[:report_path]
              )
            end

            def write_retry_summary_report(initial_results, retry_results)
              build_retry_report_writer.write_retry_summary(
                initial_results: initial_results,
                retry_results: retry_results,
                timestamp: Ace::B36ts.encode(Time.now.utc, format: :"50ms"),
                base_dir: Dir.pwd
              )
            rescue => e
              warn "Warning: Failed to write retry summary report: #{e.message}" if ENV["DEBUG"]
              nil
            end

            def annotate_results(results, **extra)
              results.merge(extra)
            end

            def suite_failed?(results)
              results[:failed].to_i > 0 || results[:errors].to_i > 0
            end

            def failure_scenarios(results)
              scenario_result_index(results)
                .values
                .select { |result| result[:status] != "pass" }
                .map { |result| result[:test_id] }
                .sort
            end

            def recovered_flaky_scenarios(initial_results, retry_results)
              initial_by_test = scenario_result_index(initial_results)
              retry_by_test = scenario_result_index(retry_results)

              initial_by_test.each_with_object([]) do |(test_id, initial), flaky|
                next if initial[:status] == "pass"

                retry_result = retry_by_test[test_id]
                next unless retry_result && retry_result[:status] == "pass"

                flaky << {
                  "test_id" => test_id,
                  "initial_status" => initial[:status],
                  "retry_status" => retry_result[:status]
                }
              end.sort_by { |entry| entry["test_id"] }
            end

            def scenario_result_index(results)
              results.fetch(:packages, {}).values.flatten.each_with_object({}) do |result, index|
                test_name = result[:test_name] || result[:test_id] || ""
                test_id = test_name[/\A(TS-[A-Z0-9]+-\d+[a-z]*)/i, 1]&.upcase || test_name
                next if test_id.empty?

                index[test_id] = {
                  test_id: test_id,
                  status: result[:status],
                  summary: result[:summary],
                  error: result[:error]
                }
              end
            end

            def resolve_retry_failures_once(requested:, packages:, affected:, only_failures:, tags:, exclude_tags:)
              scoped = scoped_suite_run?(
                packages: packages,
                affected: affected,
                only_failures: only_failures,
                tags: tags,
                exclude_tags: exclude_tags
              )
              if requested == true && scoped
                raise Ace::Support::Cli::Error.new(
                  "--retry-failures-once is only supported for full unfiltered suite runs"
                )
              end

              return requested unless requested.nil?

              !scoped
            end

            def scoped_suite_run?(packages:, affected:, only_failures:, tags:, exclude_tags:)
              [packages, affected, only_failures].any? ||
                !tags.empty? ||
                !exclude_tags.empty?
            end

            def parse_csv_list(raw)
              return [] if raw.nil? || raw.strip.empty?

              raw.split(",").map(&:strip).reject(&:empty?).map(&:downcase)
            end
          end
        end
      end
    end
  end
end
