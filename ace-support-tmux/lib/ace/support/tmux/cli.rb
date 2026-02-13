# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../tmux"
require_relative "cli/commands/start"
require_relative "cli/commands/window"
require_relative "cli/commands/list"

module Ace
  module Support
    module Tmux
      # dry-cli based CLI registry for ace-tmux
      module CLI
        extend Dry::CLI::Registry

        # Application commands registered in this CLI
        REGISTERED_COMMANDS = %w[start window list].freeze

        # dry-cli built-in commands
        BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

        # Auto-derived known commands set (O(1) lookup)
        KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

        # Default command when first argument is not a known command
        DEFAULT_COMMAND = "start"

        # Start the CLI with default command routing
        #
        # Per ADR-023, returns nil. Exit codes via Ace::Core::CLI::Error exceptions.
        #
        # @param args [Array<String>] Command-line arguments
        # @return [nil]
        def self.start(args)
          # Handle help explicitly
          if args.first && %w[help --help -h].include?(args.first)
            puts Dry::CLI::Usage.call(get([]))
            return 0
          end

          # If first argument isn't a known command and args aren't empty,
          # prepend the default command (so `ace-tmux dev` = `ace-tmux start dev`)
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

          KNOWN_COMMANDS.include?(arg)
        end

        # Register commands
        register "start", CLI::Commands::Start.new
        register "window", CLI::Commands::Window.new
        register "list", CLI::Commands::List.new

        # Register version command
        version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
          gem_name: "ace-support-tmux",
          version: Ace::Support::Tmux::VERSION
        )
        register "version", version_cmd
        register "--version", version_cmd
      end
    end
  end
end
