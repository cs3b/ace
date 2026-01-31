# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../lint"

module Ace
  module Lint
    # dry-cli based CLI registry for ace-lint
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[lint doctor].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      # Using Set for O(1) lookup performance
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "lint"

      # Start the CLI with default command routing
      #
      # This method handles the default task routing that was previously
      # in the Thor CLI.start override. Moving it here makes the routing
      # logic testable and ensures consistent behavior for all consumers
      # (shell, tests, internal Ruby calls).
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      #
      # @example From shell
      #   Ace::Lint::CLI.start(ARGV)
      #
      # @example From tests
      #   result = Ace::Lint::CLI.start(["README.md", "--fix"])
      def self.start(args)
        # Handle help explicitly (dry-cli doesn't handle registry-level help)
        if args.first && %w[help --help -h].include?(args.first)
          puts Dry::CLI::Usage.call(get([]))
          return 0
        end

        # If first argument isn't a known command and args aren't empty,
        # prepend the default command. This maintains Thor's default_task parity.
        #
        # Edge case: If first arg looks like a file path (contains . or /),
        # treat it as a file path even if it happens to match a command name.
        # Example: ace-lint ./version should lint ./version, not show version
        if args.any? && !known_command?(args.first)
          args = [DEFAULT_COMMAND] + args
        end

        Dry::CLI.new(self).call(arguments: args)
      end

      # Check if argument is a known command, considering path edge cases
      #
      # @param arg [String] First argument to check
      # @return [Boolean] true if it's a command, false if it's likely a file path
      def self.known_command?(arg)
        return false if arg.nil?

        # If it looks like a path (contains / or starts with .), treat as file path not command
        return false if arg.include?("/") || arg.start_with?(".")

        KNOWN_COMMANDS.include?(arg)
      end

      # Register the lint command
      register "lint", Commands::Lint.new

      # Register the doctor command
      register "doctor", Commands::Doctor.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-lint",
        version: Ace::Lint::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
