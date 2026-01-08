# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../search"
# Commands
require_relative "commands/search"
# Atoms
require_relative "atoms/search_path_resolver"
require_relative "atoms/debug_logger"
require_relative "atoms/tool_checker"
require_relative "atoms/ripgrep_executor"
require_relative "atoms/fd_executor"
require_relative "atoms/result_parser"
require_relative "atoms/pattern_analyzer"
# Molecules
require_relative "molecules/fzf_integrator"
require_relative "molecules/preset_manager"
require_relative "molecules/time_filter"
require_relative "molecules/dwim_analyzer"
# Organisms
require_relative "organisms/unified_searcher"
require_relative "organisms/result_formatter"

module Ace
  module Search
    # dry-cli based CLI registry for ace-search
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[search].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      # Using Set for O(1) lookup performance
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "search"

      # Start the CLI with default command routing
      #
      # This method handles the default task routing that was previously
      # in the exe/ace-search wrapper. Moving it here makes the routing
      # logic testable and ensures consistent behavior for all consumers
      # (shell, tests, internal Ruby calls).
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      #
      # @example From shell
      #   Ace::Search::CLI.start(ARGV)
      #
      # @example From tests
      #   result = Ace::Search::CLI.start(["pattern", "--max-results", "10"])
      def self.start(args)
        # If first argument isn't a known command and args aren't empty,
        # prepend the default command. This maintains Thor's default_task parity.
        #
        # Edge case: If first arg looks like a path (contains / or .), treat it
        # as a search pattern even if it happens to match a command name.
        # Example: ace-search ./version should search for ./version, not show version
        if args.any? && !known_command?(args.first)
          args = [DEFAULT_COMMAND] + args
        end

        Dry::CLI.new(self).call(arguments: args)
      end

      # Check if argument is a known command, considering path edge cases
      #
      # @param arg [String] First argument to check
      # @return [Boolean] true if it's a command, false if it's likely a pattern/path
      def self.known_command?(arg)
        return false if arg.nil?

        # If it looks like a path (contains / or .), treat as pattern not command
        return false if arg.include?("/") || arg.start_with?(".")

        KNOWN_COMMANDS.include?(arg)
      end

      # Register the search command
      register "search", Commands::Search.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-search",
        version: Ace::Search::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
