# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "version"
# Commands
require_relative "cli/commands/test"

module Ace
  module TestRunner
    # dry-cli based CLI registry for ace-test-runner
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[test].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      # Using Set for O(1) lookup performance
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "test"

      # Start the CLI with default command routing
      #
      # This method handles the default task routing that was previously
      # in the exe/ace-test wrapper. Moving it here makes the routing
      # logic testable and ensures consistent behavior for all consumers
      # (shell, tests, internal Ruby calls).
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      #
      # @example From shell
      #   Ace::TestRunner::CLI.start(ARGV)
      #
      # @example From tests
      #   result = Ace::TestRunner::CLI.start(["atoms", "--verbose"])
      def self.start(args)
        # Handle help explicitly (dry-cli doesn't handle registry-level help)
        if args.first && %w[help --help -h].include?(args.first)
          puts Dry::CLI::Usage.call(get([]))
          return 0
        end

        # If args is empty OR first argument isn't a known command,
        # prepend the default command. This maintains Thor's default_task parity.
        if args.empty? || !known_command?(args.first)
          args = [DEFAULT_COMMAND] + args
        end

        Dry::CLI.new(self).call(arguments: args)
      end

      # Check if argument is a known command
      #
      # @param arg [String] First argument to check
      # @return [Boolean] true if it's a command, false if it's likely a test argument
      def self.known_command?(arg)
        return false if arg.nil?

        KNOWN_COMMANDS.include?(arg)
      end

      # Register the test command (Hanami pattern: CLI::Commands::)
      register "test", Commands::Test.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-test-runner",
        version: Ace::TestRunner::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
