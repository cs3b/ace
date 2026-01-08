# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../nav"
# Commands
require_relative "commands/resolve"
require_relative "commands/list"
require_relative "commands/create"
require_relative "commands/sources"

module Ace
  module Nav
    # dry-cli based CLI registry for ace-nav
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[resolve list create sources].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      # Using Set for O(1) lookup performance
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "resolve"

      # Start the CLI with default command routing
      #
      # This method handles the default task routing that was previously
      # in the exe/ace-nav wrapper. Moving it here makes the routing
      # logic testable and ensures consistent behavior for all consumers
      # (shell, tests, internal Ruby calls).
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      #
      # @example From shell
      #   Ace::Nav::CLI.start(ARGV)
      #
      # @example From tests
      #   result = Ace::Nav::CLI.start(["wfi://setup"])
      def self.start(args)
        # Handle backward compatibility flags
        # --sources was a flag that triggered the sources command
        if args.include?("--sources")
          return Dry::CLI.new(self).call(arguments: ["sources"])
        end

        # --create URI was a flag that triggered create with URI argument
        if args.include?("--create")
          create_index = args.index("--create")
          uri = args[create_index + 1]
          target = args[create_index + 2]
          new_args = ["create"]
          new_args << uri if uri && !uri.start_with?("-")
          new_args << target if target && !target.start_with?("-")
          # Add any other flags
          new_args.concat(args.reject { |a| a == "--create" || a == uri || a == target })
          return Dry::CLI.new(self).call(arguments: new_args)
        end

        # If first argument isn't a known command and args aren't empty,
        # prepend the default command. This maintains Thor's default_task parity.
        if args.any? && !known_command?(args.first)
          args = [DEFAULT_COMMAND] + args
        end

        Dry::CLI.new(self).call(arguments: args)
      end

      # Check if argument is a known command
      #
      # @param arg [String] First argument to check
      # @return [Boolean] true if it's a command, false if it's likely a URI pattern
      def self.known_command?(arg)
        return false if arg.nil?

        KNOWN_COMMANDS.include?(arg)
      end

      # Register the resolve command (default)
      register "resolve", Commands::Resolve.new

      # Register the list command
      register "list", Commands::List.new

      # Register the create command
      register "create", Commands::Create.new

      # Register the sources command
      register "sources", Commands::Sources.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-nav",
        version: Ace::Nav::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
