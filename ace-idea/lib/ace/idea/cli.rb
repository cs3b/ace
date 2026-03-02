# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../idea/version"
require_relative "cli/commands/create"
require_relative "cli/commands/show"
require_relative "cli/commands/list"
require_relative "cli/commands/move"
require_relative "cli/commands/update"
require_relative "cli/commands/doctor"
require_relative "cli/commands/status"

module Ace
  module Idea
    # Flat CLI registry for ace-idea (idea management).
    #
    # Provides the flat `ace-idea <command>` invocation pattern.
    module IdeaCLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-idea"

      REGISTERED_COMMANDS = [
        ["create", "Create a new idea"],
        ["show",   "Show idea details"],
        ["list",   "List ideas"],
        ["move",   "Move idea to a different folder"],
        ["update", "Update idea metadata"],
        ["doctor", "Run health checks on ideas"],
        ["status", "Show idea status overview"]
      ].freeze

      HELP_EXAMPLES = [
        'ace-idea create "Dark mode" --tags ux,design --move-to next',
        "ace-idea show q7w",
        "ace-idea list --in maybe --status pending",
        "ace-idea move q7w --to archive",
        "ace-idea update q7w --set status=done --add tags=shipped",
        "ace-idea doctor --auto-fix",
        "ace-idea status",
        "ace-idea status --up-next-limit 5"
      ].freeze

      register "create", CLI::Commands::Create
      register "show",   CLI::Commands::Show
      register "list",   CLI::Commands::List
      register "move",   CLI::Commands::Move
      register "update", CLI::Commands::Update
      register "doctor", CLI::Commands::Doctor
      register "status", CLI::Commands::Status

      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-idea",
        version: Ace::Idea::VERSION
      )
      register "version",   version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Idea::VERSION,
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
