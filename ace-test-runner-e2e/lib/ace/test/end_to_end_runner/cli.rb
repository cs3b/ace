# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../end_to_end_runner"

module Ace
  module Test
    module EndToEndRunner
      # dry-cli based CLI registry for ace-test-e2e
      module CLI
        extend Dry::CLI::Registry

        PROGRAM_NAME = "ace-test-e2e"

        REGISTERED_COMMANDS = [
          ["run", "Run E2E test scenario"],
          ["suite", "Run all E2E test suites"],
          ["setup", "Setup E2E test sandbox"]
        ].freeze

        HELP_EXAMPLES = [
          "ace-test-e2e run ace-lint TS-LINT-001",
          "ace-test-e2e run ace-lint TS-LINT-001 --dry-run",
          "ace-test-e2e run ace-lint TS-LINT-001 --test-cases TC-001",
          "ace-test-e2e suite",
          "ace-test-e2e setup ace-lint TS-LINT-001"
        ].freeze

        # Register the run command
        register "run", Commands::RunTest

        # Register the suite command
        register "suite", Commands::RunSuite

        # Register the setup command
        register "setup", Commands::Setup

        # Register version command
        version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
          gem_name: "ace-test-e2e",
          version: Ace::Test::EndToEndRunner::VERSION
        )
        register "version", version_cmd
        register "--version", version_cmd

        # Register help command
        help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
          program_name: PROGRAM_NAME,
          version: Ace::Test::EndToEndRunner::VERSION,
          commands: REGISTERED_COMMANDS,
          examples: HELP_EXAMPLES
        )
        register "help", help_cmd
        register "--help", help_cmd
        register "-h", help_cmd
      end
    end
  end
end
