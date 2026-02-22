# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../llm"
# Commands
require_relative "cli/commands/query"
require_relative "cli/commands/list_providers"

module Ace
  module LLM
    # dry-cli based CLI registry for ace-llm
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry
      extend Ace::Core::CLI::DryCli::DefaultRouting

      PROGRAM_NAME = "ace-llm"

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[query list-providers --list-providers].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "query"

      # Register the query command (default)
      register "query", Commands::Query.new

      # Register list-providers command
      register "list-providers", Commands::ListProviders.new
      register "--list-providers", Commands::ListProviders.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: PROGRAM_NAME,
        version: Ace::LLM::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
