# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../retro/version"
require_relative "cli/commands/create"
require_relative "cli/commands/show"
require_relative "cli/commands/list"
require_relative "cli/commands/update"
require_relative "cli/commands/doctor"

module Ace
  module Retro
    # Flat CLI registry for ace-retro (retrospective management).
    #
    # Provides the flat `ace-retro <command>` invocation pattern.
    module RetroCLI
      extend Ace::Core::CLI::RegistryDsl

      PROGRAM_NAME = "ace-retro"

      REGISTERED_COMMANDS = [
        ["create", "Create a new retro"],
        ["show",   "Show retro details"],
        ["list",   "List retros"],
        ["update", "Update retro metadata (fields and move)"],
        ["doctor", "Run health checks on retros"]
      ].freeze

      HELP_EXAMPLES = [
        'ace-retro create "Sprint Review" --type standard --tags sprint,team',
        "ace-retro show q7w",
        "ace-retro list --in archive --status active",
        "ace-retro update q7w --set status=done --move-to archive",
        "ace-retro update q7w --set status=done --add tags=reviewed",
        "ace-retro update q7w --move-to next",
        "ace-retro doctor --verbose"
      ].freeze

      register "create", CLI::Commands::Create
      register "show",   CLI::Commands::Show
      register "list",   CLI::Commands::List
      register "update", CLI::Commands::Update
      register "doctor", CLI::Commands::Doctor

      version_cmd = Ace::Core::CLI::VersionCommand.build(
        gem_name: "ace-retro",
        version: Ace::Retro::VERSION
      )
      register "version",   version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Core::CLI::HelpCommand.build(
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
        Ace::Support::Cli::Runner.new(self).call(args: args)
      end
    end
  end
end
