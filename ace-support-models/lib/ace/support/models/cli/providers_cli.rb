# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../version"

# Reuse existing provider command classes
require_relative "commands/providers/list"
require_relative "commands/providers/show"
require_relative "commands/providers/sync"

module Ace
  module Support
    module Models
      # Flat CLI registry for ace-llm-providers (LLM provider management).
      #
      # Replaces the nested `ace-models providers <subcommand>` pattern with
      # flat `ace-llm-providers <command>` invocations.
      module ProvidersCLI
        extend Dry::CLI::Registry
        extend Ace::Core::CLI::DryCli::DefaultRouting

        PROGRAM_NAME = "ace-llm-providers"

        REGISTERED_COMMANDS = %w[list show sync].freeze

        BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

        KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

        DEFAULT_COMMAND = "list"

        HELP_EXAMPLES = [
          ["List all providers", "ace-llm-providers"],
          ["Show provider details", "ace-llm-providers show openai"],
          ["Sync provider configs", "ace-llm-providers sync --apply"],
          ["Sync specific provider", "ace-llm-providers sync -p anthropic"],
        ].freeze

        # Register flat commands (reusing existing command classes)
        register "list", CLI::Commands::Providers::List
        register "show", CLI::Commands::Providers::Show
        register "sync", CLI::Commands::Providers::Sync

        # Register version command
        version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
          gem_name: "ace-llm-providers",
          version: VERSION
        )
        register "version", version_cmd
        register "--version", version_cmd
      end
    end
  end
end
