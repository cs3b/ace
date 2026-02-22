# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../bundle"
# Commands
require_relative "cli/commands/load"
require_relative "cli/commands/list"

module Ace
  module Bundle
    # dry-cli based CLI registry for ace-bundle
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry
      extend Ace::Core::CLI::DryCli::DefaultRouting

      PROGRAM_NAME = "ace-bundle"

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[load list].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "load"

      # Register the load command (Hanami pattern: CLI::Commands::)
      register "load", Commands::Load.new

      # Register the list command (Hanami pattern: CLI::Commands::)
      register "list", Commands::List.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-bundle",
        version: Ace::Bundle::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
