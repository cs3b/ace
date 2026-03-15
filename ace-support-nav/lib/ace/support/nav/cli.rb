# frozen_string_literal: true

require "ace/support/cli"
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
      # ace-support-cli based CLI registry for ace-nav
      module CLI
        extend Ace::Core::CLI::RegistryDsl

        PROGRAM_NAME = "ace-nav"

        REGISTERED_COMMANDS = [
          ["resolve", "Resolve resource path or content"],
          ["list", "List matching resources"],
          ["create", "Create resource from template"],
          ["sources", "Show available sources"]
        ].freeze

        HELP_EXAMPLES = [
          "ace-nav resolve wfi://task/work       # Get workflow file path",
          "ace-nav list 'wfi://*'               # Browse all workflows",
          "ace-nav sources                       # Show registered sources"
        ].freeze

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

        help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
          program_name: PROGRAM_NAME,
          version: Ace::Support::Nav::VERSION,
          commands: REGISTERED_COMMANDS,
          examples: HELP_EXAMPLES
        )
        register "help", help_cmd
        register "--help", help_cmd
        register "-h", help_cmd
      end
    end
  end
end
