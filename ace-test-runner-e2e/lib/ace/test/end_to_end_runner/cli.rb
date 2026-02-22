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
        REGISTERED_COMMANDS = %w[run suite setup].freeze

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
          # Handle help explicitly (dry-cli doesn't handle registry-level help)
          return 0 if Ace::Core::CLI::DryCli::HelpRouter.handle(args, self)

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

        # Register the setup command
        register "setup", Commands::Setup

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
