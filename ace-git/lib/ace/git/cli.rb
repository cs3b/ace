# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../git"
# Commands
require_relative "cli/commands/diff"
require_relative "cli/commands/status"
require_relative "cli/commands/branch"
require_relative "cli/commands/pr"

module Ace
  module Git
    # dry-cli based CLI registry for ace-git
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior, including:
    # - Default command (diff)
    # - Magic git range routing (HEAD~5..HEAD -> diff)
    # - All command options and behaviors
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[diff status branch pr].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      # Using Set for O(1) lookup performance
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "diff"

      # Start the CLI with default command routing and git range magic routing
      #
      # This method handles:
      # 1. Default task routing (diff when no command specified)
      # 2. Magic git range routing (HEAD~5..HEAD -> diff HEAD~5..HEAD)
      # 3. Standard command dispatch
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      #
      # @example From shell (default command)
      #   ace-git                          # Runs diff with no args
      #   ace-git HEAD~5..HEAD             # Runs diff HEAD~5..HEAD (magic routing)
      #
      # @example From shell (explicit command)
      #   ace-git status                   # Runs status command
      #   ace-git branch                   # Runs branch command
      def self.start(args)
        # Handle special routing for git ranges
        # If args is empty, route to default command
        if args.empty?
          args = [DEFAULT_COMMAND] + args
        # If first arg looks like a git range, route to diff
        elsif git_range_pattern?(args.first)
          args = [DEFAULT_COMMAND] + args
        # If first arg isn't a known command, use default
        elsif !known_command?(args.first)
          args = [DEFAULT_COMMAND] + args
        end

        Dry::CLI.new(self).call(arguments: args)
      end

      # Check if argument is a known command
      #
      # @param arg [String] First argument to check
      # @return [Boolean] true if it's a command, false if it should be routed to default
      def self.known_command?(arg)
        return false if arg.nil?

        KNOWN_COMMANDS.include?(arg)
      end

      # Check if a string looks like a git range or ref
      # This enables "magic routing" where users can type:
      #   ace-git HEAD~5..HEAD
      # instead of:
      #   ace-git diff HEAD~5..HEAD
      #
      # @param str [String] String to check
      # @return [Boolean] True if it looks like a git range
      def self.git_range_pattern?(str)
        return false if str.nil?

        # Must match one of these specific patterns:
        # 1. Contains range operators (.., ...)
        # 2. Contains ref modifiers (~, ^) with optional number
        # 3. Is exactly "HEAD"
        # 4. Contains @{} reflog syntax
        return true if str.match?(/\.\.\.?/)           # Range operators: .. or ...
        return true if str.match?(/[~^]\d*/)           # Ref modifiers: ~, ~2, ^, ^2
        return true if str == "HEAD"                   # Exact HEAD match
        return true if str.match?(/@\{/)               # Reflog: @{1}, @{yesterday}

        false
      end

      # Register the diff command (default)
      register "diff", Commands::Diff.new

      # Register the status command
      register "status", Commands::Status.new

      # Register the branch command
      register "branch", Commands::Branch.new

      # Register the pr command
      register "pr", Commands::Pr.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-git",
        version: Ace::Git::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
