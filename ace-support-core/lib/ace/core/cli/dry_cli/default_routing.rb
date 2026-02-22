# frozen_string_literal: true

require "dry/cli"
require "set"
require_relative "help_router"

module Ace
  module Core
    module CLI
      module DryCli
        # Shared default routing logic for dry-cli based CLIs.
        #
        # This module provides the standard pattern for default command routing
        # used across ACE CLI gems. It implements the Thor default_task parity:
        #
        # - When args are empty or first arg is not a known command, prepend default
        # - Flags (starting with -) route to default command
        # - Built-in commands (--help, --version) are recognized and not routed to default
        #
        # @example Usage in CLI module
        #   require "ace/core/cli/dry_cli/default_routing"
        #
        #   module MyGem
        #     module CLI
        #       extend Dry::CLI::Registry
        #       extend Ace::Core::CLI::DryCli::DefaultRouting
        #
        #       # Define constants
        #       REGISTERED_COMMANDS = %w[status update].freeze
        #       BUILTIN_COMMANDS = %w[version help --help -h --version].freeze
        #       KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze
        #       DEFAULT_COMMAND = "status"
        #
        #       # Use the start method from DefaultRouting
        #       register "status", Commands::Status
        #       register "update", Commands::Update
        #     end
        #   end
        module DefaultRouting
          # Standard dry-cli built-in commands (should be included in BUILTIN_COMMANDS)
          STANDARD_BUILTINS = %w[version help --help -h --version].freeze

          # Help flags that should trigger usage output
          HELP_FLAGS = %w[help --help -h].freeze

          # Full help flags (show complete reference with ALL-CAPS sections)
          FULL_HELP_FLAGS = %w[help --help].freeze

          # Concise help flags (show compact scannable output)
          CONCISE_HELP_FLAGS = %w[-h].freeze

          # Start the CLI with default command routing.
          #
          # Two-tier help:
          # - `-h` renders concise, scannable output
          # - `--help` / `help` renders full reference with ALL-CAPS sections
          #
          # @param args [Array<String>] Command-line arguments
          # @return [Integer] Exit code (0 for success, non-zero for failure)
          #
          # @raise [NotImplementedError] if KNOWN_COMMANDS or DEFAULT_COMMAND are not defined
          def start(args)
            # Ensure required constants are defined
            validate_routing_constants!

            # Handle help explicitly (dry-cli doesn't handle registry-level help)
            # Without this, --help returns exit code 1 because dry-cli's spell_checker
            # is invoked when the registry can't find the command
            return 0 if HelpRouter.handle(args, self)

            # If args is empty OR first arg isn't a known command,
            # prepend the default command. This maintains Thor's default_task parity.
            #
            # Note: Flags will route to default command because they are not in KNOWN_COMMANDS.
            # Built-in flags like --help, --version are in KNOWN_COMMANDS (via BUILTIN_COMMANDS)
            # and won't get default prepended.
            if args.empty? || !known_command?(args.first)
              args = [const_get(:DEFAULT_COMMAND)] + args
            end

            Dry::CLI.new(self).call(arguments: args)
          end

          # Check if an argument is a known command.
          #
          # Known commands include:
          # - Registered application commands
          # - Built-in dry-cli commands (--help, --version, etc.)
          #
          # @param arg [String, nil] First argument from command line
          # @return [Boolean] true if arg is a known command
          def known_command?(arg)
            # nil is never a known command (will trigger default routing)
            return false if arg.nil?

            # Access KNOWN_COMMANDS from the extending module's context
            const_get(:KNOWN_COMMANDS).include?(arg)
          end

          private

          # Validate that required routing constants are defined.
          #
          # @raise [NotImplementedError] if KNOWN_COMMANDS or DEFAULT_COMMAND are missing
          def validate_routing_constants!
            unless const_defined?(:KNOWN_COMMANDS)
              raise NotImplementedError, "CLI must define KNOWN_COMMANDS constant (Set of registered + built-in commands)"
            end

            unless const_defined?(:DEFAULT_COMMAND)
              raise NotImplementedError, "CLI must define DEFAULT_COMMAND constant (default command name as string)"
            end
          end
        end
      end
    end
  end
end
