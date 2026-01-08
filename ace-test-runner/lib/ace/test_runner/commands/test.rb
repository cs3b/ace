# frozen_string_literal: true

require "dry/cli"
require_relative "../version"
require_relative "test_command"

module Ace
  module TestRunner
    module Commands
      # dry-cli Command class for the test command
      #
      # This wraps the existing TestCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class Test < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Run tests with flexible package, target, and file selection

          SYNTAX:
            ace-test [PACKAGE] [TARGET] [options] [files...]

          PACKAGE (optional):
            ace-*         Run tests in specified package (e.g., ace-context, ace-nav)
            ./path        Run tests in package at relative path
            /path         Run tests in package at absolute path

          TARGETS:
            atoms       Run atom tests only
            molecules   Run molecule tests only
            organisms   Run organism tests only
            models      Run model tests only
            unit        Run all unit tests (atoms + molecules + organisms + models)
            integration Run integration tests
            system      Run system tests
            all         Run all tests (default)
            quick       Run quick tests (atoms + molecules)

          CONFIGURATION:
            Global config:  ~/.ace/test-runner/config.yml
            Project config: .ace/test-runner/config.yml
            Example:        ace-test-runner/.ace-defaults/test-runner/config.yml

            Can also use .ace/test-runner.yml for project-level config

          OUTPUT:
            By default, shows progress bar with summary
            Use --format json for structured output
            Reports saved to test-reports/ by default
            Exit codes: 0 (pass), 1 (fail), 2 (error)

          TEST HIERARCHY:
            ATOM Architecture Test Layers:
            - atoms       -> Pure functions (no side effects)
            - molecules   -> Composed operations (controlled side effects)
            - organisms   -> Business logic (complex coordination)
            - models      -> Data structures (no behavior)
            - integration -> Cross-component testing
            - system      -> End-to-end workflows
        DESC

        # Examples shown in help output
        example [
          "ace-test                             # All tests in current package",
          "ace-test atoms                       # Atom tests only",
          "ace-test ace-context molecules       # Package + target",
          "ace-test test/foo_test.rb            # Specific test file",
          "ace-test --format progress           # Run with progress output",
          "ace-test --profile 10                # Profile slowest tests",
          "ace-test --fail-fast                 # Stop on first failure"
        ]

        # Output format options
        option :format, type: :string, aliases: %w[-f], desc: "Output format: progress (default), progress-file, json"
        option :report_dir, type: :string, aliases: %w[-d], desc: "Report storage directory (default: test-reports/)"
        option :save_reports, type: :boolean, desc: "Skip saving detailed reports"

        # Test execution options
        option :fail_fast, type: :boolean, desc: "Stop execution on first failure"
        option :fix_deprecations, type: :boolean, desc: "Auto-fix deprecated test patterns"
        option :filter, type: :string, desc: "Run only tests matching pattern"
        option :group, type: :string, aliases: %w[-g], desc: "Run specific test group (unit, integration, system, all)"
        option :color, type: :boolean, desc: "Enable/disable colored output (default: enabled)"
        option :config_path, type: :string, aliases: %w[-c], desc: "Configuration file path (default: .ace/test-runner.yml)"

        # Type conversion options (dry-cli returns strings, need to convert to integers)
        option :timeout, type: :string, desc: "Timeout for test execution in seconds"
        option :max_display, type: :string, desc: "Maximum failures to display (default: 7)"
        option :profile, type: :string, desc: "Show N slowest tests (default: 10)"

        # Execution mode options
        option :parallel, type: :boolean, desc: "Run tests in parallel (experimental)"
        option :per_file, type: :boolean, desc: "Execute each test file separately (slower, for debugging)"
        option :direct, type: :boolean, desc: "Force in-process execution (faster, less isolation)"
        option :subprocess, type: :boolean, desc: "Force subprocess execution (slower, full isolation)"

        # Rake integration options
        option :set_default_rake, type: :boolean, desc: "Set ace-test as default rake test runner"
        option :unset_default_rake, type: :boolean, desc: "Remove ace-test as default rake test runner"
        option :check_rake_status, type: :boolean, desc: "Check if ace-test is set as default rake test runner"

        # Cleanup options
        option :cleanup_reports, type: :boolean, desc: "Clean up old test reports (keeps last 10)"
        option :cleanup_keep, type: :string, desc: "Number of reports to keep when cleaning (default: 10)"
        option :cleanup_age, type: :string, desc: "Delete reports older than DAYS (default: 30)"

        # Standard options (inherited from Base but need explicit definition for dry-cli)
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(args: [], **options)
          # Type-convert numeric options (dry-cli returns strings, Thor converted to integers)
          # This maintains parity with the Thor implementation
          numeric_options = %i[timeout max_display profile cleanup_keep cleanup_age]
          numeric_options.each do |key|
            options[key] = options[key].to_i if options[key]
          end

          # Use the existing TestCommand logic
          # args contains leftover positional arguments (package, target, files)
          command = TestCommand.new(args, options)
          command.execute
        end
      end
    end
  end
end
