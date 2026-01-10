# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../llm"
# Commands
require_relative "commands/query"
require_relative "commands/list_providers"

module Ace
  module LLM
    # dry-cli based CLI registry for ace-llm
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[query list-providers --list-providers].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      # Using Set for O(1) lookup performance
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "query"

      # Start the CLI with default command routing
      #
      # This method handles the default task routing that was previously
      # in the exe/ace-llm-query wrapper. Moving it here makes the routing
      # logic testable and ensures consistent behavior for all consumers
      # (shell, tests, internal Ruby calls).
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      #
      # @example From shell
      #   Ace::LLM::CLI.start(ARGV)
      #
      # @example From tests
      #   result = Ace::LLM::CLI.start(["google:gemini-2.5-flash", "What is Ruby?"])
      def self.start(args)
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
      # @return [Boolean] true if it's a known command
      def self.known_command?(arg)
        return false if arg.nil?

        KNOWN_COMMANDS.include?(arg)
      end

      # Register the query command (default)
      register "query", Commands::Query.new

      # Register list-providers command
      register "list-providers", Commands::ListProviders.new
      register "--list-providers", Commands::ListProviders.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-llm-query",
        version: Ace::LLM::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
