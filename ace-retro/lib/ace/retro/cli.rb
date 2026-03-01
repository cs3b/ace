# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../retro/version"
require_relative "cli/commands/create"
require_relative "cli/commands/show"
require_relative "cli/commands/list"
require_relative "cli/commands/move"
require_relative "cli/commands/update"

module Ace
  module Retro
    # Flat CLI registry for ace-retro (retrospective management).
    #
    # Provides the flat `ace-retro <command>` invocation pattern.
    module RetroCLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-retro"

      REGISTERED_COMMANDS = [
        ["create", "Create a new retro"],
        ["show",   "Show retro details"],
        ["list",   "List retros"],
        ["move",   "Move retro to a different folder"],
        ["update", "Update retro metadata"]
      ].freeze

      HELP_EXAMPLES = [
        'ace-retro create "Sprint Review" --type standard --tags sprint,team',
        "ace-retro show q7w",
        "ace-retro list --in archive --status active",
        "ace-retro move q7w --to archive",
        "ace-retro update q7w --set status=done --add tags=reviewed"
      ].freeze

      register "create", CLI::Commands::Create
      register "show",   CLI::Commands::Show
      register "list",   CLI::Commands::List
      register "move",   CLI::Commands::Move
      register "update", CLI::Commands::Update

      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-retro",
        version: Ace::Retro::VERSION
      )
      register "version",   version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Retro::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help",   help_cmd
      register "--help", help_cmd
      register "-h",     help_cmd

      # Entry point for CLI invocation
      # @param args [Array<String>] Command-line arguments
      def self.start(args)
        Dry::CLI.new(self).call(arguments: args)
      end
    end
  end
end
