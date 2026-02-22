# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../secrets"
# Business logic command objects
require_relative "commands/scan_command"
require_relative "commands/rewrite_command"
require_relative "commands/revoke_command"
require_relative "commands/check_release_command"
# dry-cli command wrappers (Hanami pattern: CLI::Commands::)
require_relative "cli/commands/scan"
require_relative "cli/commands/rewrite"
require_relative "cli/commands/revoke"
require_relative "cli/commands/check_release"
require_relative "version"

module Ace
  module Git
    module Secrets
      # dry-cli based CLI registry for ace-git-secrets
      #
      # This replaces the Thor-based CLI with dry-cli while maintaining
      # complete command parity and user-facing behavior.
      module CLI
        extend Dry::CLI::Registry

        # Application commands registered in this CLI (single source of truth)
        REGISTERED_COMMANDS = %w[scan rewrite-history revoke check-release].freeze

        # dry-cli built-in commands (standard across all CLI gems)
        BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

        # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
        # Using Set for O(1) lookup performance
        KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

        # Default command to use when first argument is not a known command
        DEFAULT_COMMAND = "scan"

        # Start the CLI with default command routing and config preloading
        #
        # This preloads config before dry-cli dispatches to ensure thread safety.
        # The config method uses mutex synchronization, but has a potential TOCTOU
        # (time-of-check-to-time-of-use) issue if config is first accessed during
        # parallel operations.
        #
        # @param args [Array<String>] Command-line arguments
        # @return [Integer, nil] Exit code from command (nil treated as 0 by exe wrapper)
        #
        # @example From shell
        #   Ace::Git::Secrets::CLI.start(ARGV)
        #
        # @example From tests
        #   result = Ace::Git::Secrets::CLI.start(["scan", "--verbose"])
        def self.start(args = ARGV)
          # Handle help explicitly (dry-cli doesn't handle registry-level help)
          if args.first && %w[help --help -h].include?(args.first)
            puts Dry::CLI::Usage.call(get([]), registry: self)
            return 0
          end

          # Preload config before dry-cli dispatches to commands
          Ace::Git::Secrets.config

          # If args is empty OR first arg isn't a known command,
          # prepend the default command. This maintains Thor's default_task parity.
          if args.empty? || !KNOWN_COMMANDS.include?(args.first)
            args = [DEFAULT_COMMAND] + args
          end

          Dry::CLI.new(self).call(arguments: args)
        end

        # Check if argument is a known command
        #
        # @param arg [String] First argument to check
        # @return [Boolean] true if it's a command, false if it's an argument
        def self.known_command?(arg)
          return false if arg.nil?

          KNOWN_COMMANDS.include?(arg)
        end

        # Register the scan command (default) - Hanami pattern: CLI::Commands::
        register "scan", CLI::Commands::Scan.new

        # Register the rewrite-history command
        register "rewrite-history", CLI::Commands::Rewrite.new

        # Register the revoke command
        register "revoke", CLI::Commands::Revoke.new

        # Register the check-release command
        register "check-release", CLI::Commands::CheckRelease.new

        # Register version command
        version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
          gem_name: "ace-git-secrets",
          version: Ace::Git::Secrets::VERSION
        )
        register "version", version_cmd
        register "--version", version_cmd
      end
    end
  end
end
