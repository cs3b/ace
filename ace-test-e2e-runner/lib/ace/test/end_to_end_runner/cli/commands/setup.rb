# frozen_string_literal: true

require "dry/cli"
require "stringio"
require "ace/core/cli/dry_cli/base"
require "ace/support/timestamp"

module Ace
  module Test
    module EndToEndRunner
      module CLI
        module Commands
          # CLI command for creating a populated sandbox from a scenario
          #
          # Loads a TS-format scenario directory, executes setup steps
          # deterministically, and prints the sandbox path for inspection.
          class Setup < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Create a populated sandbox for a test scenario

              Loads scenario.yml and executes setup steps (git-init, copy-fixtures,
              run, write-file, env) to create a ready-to-test sandbox directory.
              Useful for debugging test setup without running the actual test cases.

              Output:
                Prints sandbox path to stdout
                Exit codes: 0 (success), 1 (failure)
            DESC

            example [
              "ace-lint TS-LINT-001            # Create sandbox for scenario",
              "ace-lint TS-LINT-001 --verbose   # With verbose output"
            ]

            argument :package, required: true,
                     desc: "Package name (e.g., ace-lint)"
            argument :scenario_id, required: true,
                     desc: "Scenario ID (e.g., TS-LINT-001)"

            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress detailed output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(package:, scenario_id:, **options)
              output = quiet?(options) ? StringIO.new : $stdout

              scenario_dir = find_scenario_dir(package, scenario_id)
              loader = Molecules::ScenarioLoader.new
              scenario = loader.load(scenario_dir)

              timestamp = generate_timestamp
              sandbox_dir = File.join(
                ".cache", "ace-test-e2e",
                "#{timestamp}-#{scenario.short_package}-#{scenario.short_id}"
              )

              output.puts "Setting up sandbox for #{scenario.test_id}..." if options[:verbose]

              executor = Molecules::SetupExecutor.new
              result = executor.execute(
                setup_steps: scenario.setup_steps,
                sandbox_dir: sandbox_dir,
                fixture_source: scenario.fixture_path
              )

              unless result[:success]
                raise Ace::Core::CLI::Error.new(
                  "Setup failed: #{result[:error]}"
                )
              end

              output.puts "Setup complete (#{result[:steps_completed]} steps)" if options[:verbose]
              puts File.expand_path(sandbox_dir)
            end

            private

            # Find the scenario directory for a given package and scenario ID
            #
            # @param package [String] Package name
            # @param scenario_id [String] Scenario ID (e.g., "TS-LINT-001")
            # @return [String] Path to the scenario directory
            # @raise [Ace::Core::CLI::Error] If scenario not found
            def find_scenario_dir(package, scenario_id, base_dir: Dir.pwd)
              e2e_dir = File.join(base_dir, package, "test", "e2e")
              unless Dir.exist?(e2e_dir)
                raise Ace::Core::CLI::Error.new(
                  "E2E test directory not found: #{e2e_dir}"
                )
              end

              # Find matching TS-* directory (exact match first, then prefix-slug match)
              exact = File.join(e2e_dir, scenario_id)
              return exact if Dir.exist?(exact)

              pattern = File.join(e2e_dir, "#{scenario_id}-*")
              matches = Dir.glob(pattern).select { |p| File.directory?(p) }

              if matches.empty?
                raise Ace::Core::CLI::Error.new(
                  "Scenario not found: #{scenario_id} in #{e2e_dir}"
                )
              end

              if matches.size > 1
                warn "Warning: Multiple directories match #{scenario_id}: #{matches.map { |m| File.basename(m) }.join(', ')}. Using #{File.basename(matches.first)}."
              end

              matches.first
            end

            # Generate a timestamp for the sandbox directory name
            # @return [String] Base36 timestamp ID
            def generate_timestamp
              Ace::Support::Timestamp.encode(Time.now.utc, format: :"50ms")
            end
          end
        end
      end
    end
  end
end
