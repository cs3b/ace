# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../nav"
# Commands (Hanami pattern: CLI::Commands::)
require_relative "cli/commands/resolve"
require_relative "cli/commands/list"
require_relative "cli/commands/create"
require_relative "cli/commands/sources"

module Ace
  module Support
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
        # Per ADR-023, this method returns nil. Exit codes are handled via
        # Ace::Core::CLI::Error exceptions caught in the exe wrapper.
        #
        # @param args [Array<String>] Command-line arguments
        # @return [nil] Returns nil (exit codes via exceptions)
        #
        # @example From shell
        #   Ace::Support::Nav::CLI.start(ARGV)
        #
        # @example From tests
        #   # No exception = success (exit 0)
        #   Ace::Support::Nav::CLI.start(["wfi://setup"])
        def self.start(args)
          # Handle help explicitly (dry-cli doesn't handle registry-level help)
          if args.first && %w[help --help -h].include?(args.first)
            puts Dry::CLI::Usage.call(get([]))
            return 0
          end

          # Handle backward compatibility flags
          # --sources was a flag that triggered the sources command
          if args.include?("--sources")
            Dry::CLI.new(self).call(arguments: ["sources"])
            return
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
            Dry::CLI.new(self).call(arguments: new_args)
            return
          end

          # If first argument isn't a known command and args aren't empty,
          # prepend the default command. This maintains Thor's default_task parity.
          if args.any? && !known_command?(args.first)
            args = [DEFAULT_COMMAND] + args
          end

          Dry::CLI.new(self).call(arguments: args)
          # Returns nil - exit codes handled via Ace::Core::CLI::Error
        end

        # Check if argument is a known command
        #
        # @param arg [String] First argument to check
        # @return [Boolean] true if it's a command, false if it's likely a URI pattern
        def self.known_command?(arg)
          return false if arg.nil?

          KNOWN_COMMANDS.include?(arg)
        end

        # Register the resolve command (default) - Hanami pattern: CLI::Commands::
        register "resolve", CLI::Commands::Resolve.new

        # Register the list command
        register "list", CLI::Commands::List.new

        # Register the create command
        register "create", CLI::Commands::Create.new

        # Register the sources command
        register "sources", CLI::Commands::Sources.new

        # Register version command
        version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
          gem_name: "ace-support-nav",
          version: Ace::Support::Nav::VERSION
        )
        register "version", version_cmd
        register "--version", version_cmd
      end
    end
  end
end
