# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../end_to_end_runner"

module Ace
  module Test
    module EndToEndRunner
      # dry-cli based CLI registry for ace-test-e2e
      module CLI
        extend Dry::CLI::Registry

        # Application commands registered in this CLI
        REGISTERED_COMMANDS = %w[run suite].freeze

        # dry-cli built-in commands
        BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

        # All known commands for default routing
        KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

        # Default command when first argument is not a known command
        DEFAULT_COMMAND = "run"

        # Start the CLI with default command routing
        #
        # @param args [Array<String>] Command-line arguments
        # @return [Integer] Exit code
        def self.start(args)
          # Handle --version explicitly
          if args.first && args.first == "--version"
            puts "ace-test-e2e #{Ace::Test::EndToEndRunner::VERSION}"
            return 0
          end

          # Handle help explicitly
          if args.first && %w[help --help -h].include?(args.first)
            puts "ace-test-e2e - Run E2E tests via LLM execution"
            puts ""
            puts "Usage:"
            puts "  ace-test-e2e PACKAGE [TEST_ID] [OPTIONS]"
            puts ""
            puts "Examples:"
            puts "  ace-test-e2e ace-lint MT-LINT-001"
            puts "  ace-test-e2e ace-lint"
            puts "  ace-test-e2e ace-lint --provider claude:sonnet"
            puts ""
            puts "Options:"
            puts "  --provider    LLM provider:model (default: #{Molecules::ConfigLoader.default_provider})"
            puts "  --cli-args    Extra args for CLI providers"
            puts "  --timeout     Timeout per test in seconds (default: 300)"
            puts "  --progress    Enable live animated display"
            puts "  --quiet/-q    Suppress detailed output"
            puts "  --verbose/-v  Enable verbose output"
            puts "  --debug/-d    Enable debug output"
            puts "  --version     Show version"
            return 0
          end

          # If first argument isn't a known command, prepend default
          if args.any? && !known_command?(args.first)
            args = [DEFAULT_COMMAND] + args
          end

          Dry::CLI.new(self).call(arguments: args)
        end

        # Check if argument is a known command
        #
        # @param arg [String] First argument to check
        # @return [Boolean]
        def self.known_command?(arg)
          return false if arg.nil?
          return false if arg.include?("/") || arg.start_with?(".")
          return false if arg.start_with?("-")

          KNOWN_COMMANDS.include?(arg)
        end

        # Register the run command
        register "run", Commands::RunTest

        # Register the suite command
        register "suite", Commands::RunSuite

        # Register version command
        version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
          gem_name: "ace-test-e2e",
          version: Ace::Test::EndToEndRunner::VERSION
        )
        register "version", version_cmd
        register "--version", version_cmd
      end
    end
  end
end
