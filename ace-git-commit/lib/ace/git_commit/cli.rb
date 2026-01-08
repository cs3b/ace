# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../git_commit"
# Commands
require_relative "commands/commit"

module Ace
  module GitCommit
    # dry-cli based CLI registry for ace-git-commit
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[commit].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      # Using Set for O(1) lookup performance
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "commit"

      # Start the CLI with default command routing
      #
      # This method handles the default task routing that was previously
      # in the exe/ace-git-commit wrapper. Moving it here makes the routing
      # logic testable and ensures consistent behavior for all consumers
      # (shell, tests, internal Ruby calls).
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      #
      # @example From shell
      #   Ace::GitCommit::CLI.start(ARGV)
      #
      # @example From tests
      #   result = Ace::GitCommit::CLI.start(["file.rb", "--dry-run"])
      def self.start(args)
        # If args is empty OR first arg isn't a known command (and not a flag),
        # prepend the default command. This maintains Thor's default_task parity.
        #
        # Edge case: If first arg looks like a flag (starts with -), let dry-cli
        # handle it normally for --help, --version, etc.
        if args.empty? || (!known_command?(args.first) && !args.first.start_with?("-"))
          args = [DEFAULT_COMMAND] + args
        end

        Dry::CLI.new(self).call(arguments: args)
      end

      # Check if argument is a known command
      #
      # @param arg [String] First argument to check
      # @return [Boolean] true if it's a command, false if it's a file argument
      def self.known_command?(arg)
        return false if arg.nil?

        KNOWN_COMMANDS.include?(arg)
      end

      # Register the commit command (default)
      register "commit", Commands::Commit.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-git-commit",
        version: Ace::GitCommit::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
