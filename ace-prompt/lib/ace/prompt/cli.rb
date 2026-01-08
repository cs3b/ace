# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
# Commands
require_relative "commands/process"
require_relative "commands/setup"
# Organisms (needed for command logic)
require_relative "organisms/prompt_processor"
require_relative "organisms/prompt_initializer"

module Ace
  module Prompt
    # dry-cli based CLI registry for ace-prompt
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[process setup].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      # Using Set for O(1) lookup performance
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "process"

      # Start the CLI with default command routing
      #
      # This method handles the default task routing that was previously
      # in the Thor CLI. Moving it here makes the routing logic testable
      # and ensures consistent behavior for all consumers.
      #
      # Default Command Routing:
      #   Unknown commands are auto-routed to 'process' - the default command:
      #     ace-prompt file.md                  → ace-prompt process file.md
      #   No need to type 'process' explicitly
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      #
      # @example From shell
      #   Ace::Prompt::CLI.start(ARGV)
      #
      # @example From tests
      #   result = Ace::Prompt::CLI.start(["--setup"])
      def self.start(args)
        # If args is empty OR first arg isn't a known command (and not a flag),
        # prepend the default command. This maintains Thor's default_task parity.
        #
        # Edge case: If first arg looks like a flag (starts with -), don't route
        # to default command - let dry-cli handle it (likely --help or --version).
        if args.empty? || (!known_command?(args.first) && !args.first.start_with?("-"))
          args = [DEFAULT_COMMAND] + args
        end

        Dry::CLI.new(self).call(arguments: args)
      end

      # Check if argument is a known command
      #
      # @param arg [String] First argument to check
      # @return [Boolean] true if it's a command, false if it should route to default
      def self.known_command?(arg)
        return false if arg.nil?

        KNOWN_COMMANDS.include?(arg)
      end

      # Register the process command (default)
      register "process", Commands::Process.new

      # Register the setup command
      register "setup", Commands::Setup.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-prompt",
        version: Ace::Prompt::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
