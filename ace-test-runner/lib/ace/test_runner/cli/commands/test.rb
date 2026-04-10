# frozen_string_literal: true

require "ace/support/cli"
require_relative "../../version"

module Ace
  module TestRunner
    module CLI
      module Commands
        # ace-support-cli Command class for the test command
        #
        # This command runs tests with flexible package, target, and file selection.
        # All business logic is inline in this single command class.
        class Test < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc <<~DESC.strip
            Run tests with flexible package, target, and file selection

            SYNTAX:
              ace-test [PACKAGE] [TARGET] [options] [files...]

            PACKAGE (optional):
              ace-*         Run tests in specified package (e.g., ace-bundle, ace-nav)
              ./path        Run tests in package at relative path
              /path         Run tests in package at absolute path

            TARGETS:
              atoms       Run atom tests only
              molecules   Run molecule tests only
              organisms   Run organism tests only
              models      Run model tests only
              unit        Run all unit tests (default)
              integration Run integration tests
              int         Alias for integration
              all         Run unit + edge + integration
              quick       Run quick tests (atoms + molecules)

            CONFIGURATION:
              Global config:  ~/.ace/test-runner/config.yml
              Project config: .ace/test-runner/config.yml
              Example:        ace-test-runner/.ace-defaults/test-runner/config.yml

              Can also use .ace/test-runner.yml for project-level config

            OUTPUT:
              By default, shows progress bar with summary
              Use --format json for structured output
              Reports saved to .ace-local/test/reports/<package>/ by default
              Exit codes: 0 (pass), 1 (fail), 2 (error)

            TEST HIERARCHY:
              ATOM Architecture Test Layers:
              - atoms       -> Pure functions (no side effects)
              - molecules   -> Composed operations (controlled side effects)
              - organisms   -> Business logic (complex coordination)
              - models      -> Data structures (no behavior)
              - integration -> Cross-component testing
          DESC

          # Examples shown in help output
          example [
            "                                    # All tests in current package",
            "atoms                               # Atom tests only",
            "ace-bundle molecules                # Package + target",
            "test/foo_test.rb                    # Specific test file",
            "--format progress                   # Run with progress output",
            "--profile 10                        # Profile slowest tests",
            "--fail-fast                         # Stop on first failure"
          ]

          # Output format options
          option :format, type: :string, aliases: %w[-f], desc: "Output format: progress (default), progress-file, json"
          option :report_dir, type: :string, aliases: %w[-d], desc: "Report root directory (default: .ace-local/test/reports)"
          option :save_reports, type: :boolean, desc: "Skip saving detailed reports"

          # Test execution options
          option :fail_fast, type: :boolean, desc: "Stop execution on first failure"
          option :fix_deprecations, type: :boolean, desc: "Auto-fix deprecated test patterns"
          option :filter, type: :string, desc: "Run only tests matching pattern"
          option :group, type: :string, aliases: %w[-g], desc: "Run specific test group (unit, integration/int, all)"
          option :color, type: :boolean, desc: "Enable/disable colored output (default: enabled)"
          option :config_path, type: :string, aliases: %w[-c], desc: "Configuration file path (default: .ace/test-runner.yml)"

          # Type conversion options (ace-support-cli returns strings, need to convert to integers)
          option :timeout, type: :string, desc: "Timeout for test execution in seconds"
          option :max_display, type: :string, desc: "Maximum failures to display (default: 7)"
          option :profile, type: :string, desc: "Show N slowest tests (default: 10)"

          # Execution mode options
          option :parallel, type: :boolean, desc: "Run tests in parallel (experimental)"
          option :per_file, type: :boolean, desc: "Execute each test file separately (slower, for debugging)"
          option :direct, type: :boolean, desc: "Force in-process execution (faster, less isolation)"
          option :subprocess, type: :boolean, desc: "Force subprocess execution (slower, full isolation)"
          option :run_in_sequence, type: :boolean, aliases: %w[--ris], desc: "Run test groups sequentially (default)"
          option :run_in_single_batch, type: :boolean, aliases: %w[--risb], desc: "Run all tests together in single batch"

          # Rake integration options
          option :set_default_rake, type: :boolean, desc: "Set ace-test as default rake test runner"
          option :unset_default_rake, type: :boolean, desc: "Remove ace-test as default rake test runner"
          option :check_rake_status, type: :boolean, desc: "Check if ace-test is set as default rake test runner"

          # Cleanup options
          option :cleanup_reports, type: :boolean, desc: "Clean up old test reports (keeps last 10)"
          option :cleanup_keep, type: :string, desc: "Number of reports to keep when cleaning (default: 10)"
          option :cleanup_age, type: :string, desc: "Delete reports older than DAYS (default: 30)"

          # Standard options (inherited from Base but need explicit definition for ace-support-cli)
          option :version, type: :boolean, desc: "Show version information"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(args: [], **options)
            if options[:version]
              puts "ace-test #{Ace::TestRunner::VERSION}"
              return 0
            end

            # Type-convert numeric options (ace-support-cli returns strings, Thor converted to integers)
            # This maintains parity with the Thor implementation
            numeric_options = %i[timeout max_display profile cleanup_keep cleanup_age]
            numeric_options.each do |key|
              options[key] = options[key].to_i if options[key]
            end

            # Build test options with defaults
            test_options = build_test_options(options)

            # Display config summary
            display_config_summary(test_options)

            # Handle special modes first
            result = handle_special_modes(args, test_options)
            return result if result

            # Parse CLI arguments using CliArgumentParser
            begin
              arg_parser = Molecules::CliArgumentParser.new(args)
              parsed_args = arg_parser.parse
              test_options.merge!(parsed_args)
            rescue ArgumentError => e
              raise Ace::Support::Cli::Error.new(e.message)
            end

            # Run tests with special exit! handling for Minitest compatibility
            run_tests_with_exit_handling(test_options)
          rescue Ace::TestRunner::Error => e
            raise Ace::Support::Cli::Error.new(e.message)
          rescue Interrupt
            raise Ace::Support::Cli::Error.new("Test execution interrupted", exit_code: 130)
          rescue => e
            raise Ace::Support::Cli::Error.new("Unexpected error: #{e.message}")
          end

          private

          def build_test_options(cli_options)
            # Thor returns HashWithIndifferentAccess with string keys internally.
            # Transform to symbol keys for consistent access patterns throughout the codebase.
            symbolized_options = cli_options.transform_keys(&:to_sym)

            # Handle mutually exclusive run mode options
            # --run-in-sequence sets run_in_single_batch to false (default behavior)
            # --run-in-single-batch sets run_in_single_batch to true
            if symbolized_options[:run_in_sequence]
              symbolized_options[:run_in_single_batch] = false
            end
            # Remove the run_in_sequence key as it's only used to set run_in_single_batch
            symbolized_options.delete(:run_in_sequence)

            # Default options - symbolized_options will override these for any explicit values
            {
              format: "progress",
              save_reports: true,
              verbose: false,
              fail_fast: false,
              fix_deprecations: false,
              color: true,
              per_file: false,
              run_in_single_batch: false
            }.merge(symbolized_options)
          end

          def handle_special_modes(args, options)
            # Handle cleanup reports mode
            if options[:cleanup_reports]
              return handle_cleanup_reports(options)
            end

            # Handle rake integration modes
            if options[:set_default_rake] || options[:unset_default_rake] || options[:check_rake_status]
              return handle_rake_integration(options)
            end

            # Handle deprecation fixing mode
            if options[:fix_deprecations]
              return handle_fix_deprecations
            end

            nil # Continue to normal test execution
          end

          def handle_cleanup_reports(options)
            require "ace/test_runner/molecules/report_storage"
            require "ace/test_runner/atoms/timestamp_generator"
            require "ace/test_runner/molecules/config_loader"

            # Load config from cascade (ADR-022 pattern)
            config_loader = Molecules::ConfigLoader.new
            config_data = config_loader.load(options[:config_path])
            config = config_loader.merge_with_options(config_data, options)

            timestamp_generator = Atoms::TimestampGenerator.new
            storage = Molecules::ReportStorage.new(
              base_dir: config[:defaults][:report_dir] || ".ace-local/test/reports",
              timestamp_generator: timestamp_generator
            )

            keep = options[:cleanup_keep] || 10
            age = options[:cleanup_age] || 30

            puts "Cleaning up test reports..."
            puts "  Keeping last #{keep} reports"
            puts "  Deleting reports older than #{age} days"

            deleted = storage.cleanup_old_reports(keep: keep, max_age_days: age)

            if deleted.empty?
              puts "No reports to clean up."
            else
              puts "Deleted #{deleted.size} old reports:"
              deleted.each { |path| puts "  - #{File.basename(path)}" }
            end
          end

          def handle_rake_integration(options)
            require "ace/test_runner/molecules/rake_integration"

            integration = Molecules::RakeIntegration.new

            if options[:set_default_rake]
              result = integration.set_default
              puts result[:message]
              raise Ace::Support::Cli::Error.new(result[:message]) unless result[:success]
              nil
            elsif options[:unset_default_rake]
              result = integration.unset_default
              puts result[:message]
              raise Ace::Support::Cli::Error.new(result[:message]) unless result[:success]
              nil
            elsif options[:check_rake_status]
              status = integration.check_status
              puts "Rake Test Integration Status:"
              puts "  Rakefile exists: #{status[:rakefile_exists]}"
              puts "  ace-test integrated: #{status[:integrated]}"
              puts "  Message: #{status[:message]}"
              puts "  Backup exists: #{status[:backup_exists]}" if status[:backup_exists]
              puts "  Has test task: #{status[:has_test_task]}" if status.key?(:has_test_task)
              nil
            end
          end

          def handle_fix_deprecations
            require "ace/test_runner/molecules/deprecation_fixer"

            puts "Scanning for deprecated test patterns..."

            detector = Atoms::TestDetector.new
            fixer = Molecules::DeprecationFixer.new

            test_files = detector.find_test_files
            fixed_count = 0

            test_files.each do |file|
              result = fixer.fix_file(file, dry_run: false)
              if result[:success] && result[:changes] > 0
                puts "  Fixed #{result[:changes]} deprecations in #{file}"
                fixed_count += result[:changes]
              end
            end

            if fixed_count == 0
              puts "No deprecations found to fix."
            else
              puts "Fixed #{fixed_count} deprecations total."
            end
          end

          def run_tests_with_exit_handling(options)
            exit_code = Ace::TestRunner.run(options)

            # Flush IO buffers before exit! (which skips at_exit handlers including finalizers)
            $stdout.flush
            $stderr.flush

            # IMPORTANT: Use exit! (not exit) to skip Ruby's at_exit handlers.
            # This prevents Minitest from auto-running again via its at_exit hook.
            # When ace-test uses in-process (direct) execution, test files are loaded
            # into the current process. Minitest registers an at_exit handler that would
            # re-run all tests on normal exit. Using exit! bypasses this.
            # See guide://testable-code-patterns for details on this pattern.

            # Note: We cannot use exit! here and return the exit code instead.
            # The exe file wrapper will handle the exit! call.
            exit_code
          end

          def display_config_summary(options)
            return if options[:quiet]

            require "ace/core"
            Ace::Core::Atoms::ConfigSummary.display(
              command: "test",
              config: options,
              defaults: {},
              options: options,
              quiet: false
            )
          end
        end
      end
    end
  end
end
