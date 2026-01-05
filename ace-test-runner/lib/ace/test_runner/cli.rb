# frozen_string_literal: true

require "ace/core/cli/base"

module Ace
  module TestRunner
    class CLI < Ace::Core::CLI::Base
      # class_options :quiet, :verbose, :debug inherited from Base

      default_task :test

      # Override help to add test layer targets section
      def self.help(shell, subcommand = false)
        super
        shell.say ""
        shell.say "Test Layer Targets:"
        shell.say "  atoms       -> Pure function tests (no side effects)"
        shell.say "  molecules   -> Composed operation tests"
        shell.say "  organisms   -> Business logic tests"
        shell.say "  unit        -> All unit tests (atoms+molecules+organisms)"
        shell.say ""
        shell.say "Examples:"
        shell.say "  ace-test                             # All tests in current package"
        shell.say "  ace-test atoms                       # Atom tests only"
        shell.say "  ace-test ace-context molecules       # Package + target"
      end

      desc "test [PACKAGE] [TARGET] [options] [files...]", "Run tests"
      long_desc <<~DESC
        Run tests with flexible package, target, and file selection.

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

        EXAMPLES:

          # Run all tests (default)
          $ ace-test

          # Run only atom tests
          $ ace-test atoms

          # Run tests in specific package
          $ ace-test ace-context

          # Run atom tests in specific package
          $ ace-test ace-context atoms

          # Run specific test file
          $ ace-test test/foo_test.rb

          # Run with progress output
          $ ace-test --format progress

          # Profile slowest tests
          $ ace-test --profile 10

          # Stop on first failure
          $ ace-test --fail-fast

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
          - atoms       → Pure functions (no side effects)
          - molecules   → Composed operations (controlled side effects)
          - organisms   → Business logic (complex coordination)
          - models      → Data structures (no behavior)
          - integration → Cross-component testing
          - system      → End-to-end workflows
      DESC
      option :format, type: :string, aliases: "-f", desc: "Output format: progress (default), progress-file, json"
      option :report_dir, type: :string, aliases: "-d", desc: "Report storage directory (default: test-reports/)"
      option :save_reports, type: :boolean, desc: "Skip saving detailed reports"
      option :fail_fast, type: :boolean, desc: "Stop execution on first failure"
      option :fix_deprecations, type: :boolean, desc: "Auto-fix deprecated test patterns"
      option :filter, type: :string, desc: "Run only tests matching pattern"
      option :group, type: :string, aliases: "-g", desc: "Run specific test group (unit, integration, system, all)"
      option :color, type: :boolean, desc: "Enable/disable colored output (default: enabled)"
      option :config_path, type: :string, aliases: "-c", desc: "Configuration file path (default: .ace/test-runner.yml)"
      option :timeout, type: :numeric, desc: "Timeout for test execution in seconds"
      option :parallel, type: :boolean, desc: "Run tests in parallel (experimental)"
      option :per_file, type: :boolean, desc: "Execute each test file separately (slower, for debugging)"
      option :direct, type: :boolean, desc: "Force in-process execution (faster, less isolation)"
      option :subprocess, type: :boolean, desc: "Force subprocess execution (slower, full isolation)"
      option :max_display, type: :numeric, desc: "Maximum failures to display (default: 7)"
      option :profile, type: :numeric, desc: "Show N slowest tests (default: 10)"
      option :set_default_rake, type: :boolean, desc: "Set ace-test as default rake test runner"
      option :unset_default_rake, type: :boolean, desc: "Remove ace-test as default rake test runner"
      option :check_rake_status, type: :boolean, desc: "Check if ace-test is set as default rake test runner"
      option :cleanup_reports, type: :boolean, desc: "Clean up old test reports (keeps last 10)"
      option :cleanup_keep, type: :numeric, desc: "Number of reports to keep when cleaning (default: 10)"
      option :cleanup_age, type: :numeric, desc: "Delete reports older than DAYS (default: 30)"
      def test(*args)
        # Handle --help/-h passed as first argument
        if args.first == "--help" || args.first == "-h"
          invoke :help, ["test"]
          return 0
        end
        require_relative "commands/test_command"
        Commands::TestCommand.new(args, options).execute
      end

      desc "version", "Show version"
      long_desc <<~DESC
        Display the current version of ace-test-runner.

        EXAMPLES:

          $ ace-test version
          $ ace-test --version
      DESC
      def version
        puts "ace-test-runner #{Ace::TestRunner::VERSION}"
        0
      end
      map "--version" => :version

      # Handle unknown commands as arguments to the default 'test' command
      # This allows: ace-test [package] [target] without requiring the explicit 'test' command
      def method_missing(command, *args)
        # Delegate unknown commands to the 'test' command
        # Prepend the unknown command as the first argument to 'test'
        test(command.to_s, *args)
      end
      # respond_to_missing? inherited from Ace::Core::CLI::Base
    end
  end
end
