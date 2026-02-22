# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../version"

# Reuse existing command classes
require_relative "commands/idea"
require_relative "commands/ideas"
require_relative "commands/idea/create"
require_relative "commands/idea/done"
require_relative "commands/idea/park"
require_relative "commands/idea/unpark"
require_relative "commands/idea/reschedule"

module Ace
  module Taskflow
    # Flat CLI registry for ace-idea (idea management).
    #
    # Replaces the nested `ace-taskflow idea <subcommand>` pattern with
    # flat `ace-idea <command>` invocations.
    module IdeaCLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-idea"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["list", "List ideas in current release"],
        ["show", "Show idea details"],
        ["create", "Create a new idea"],
        ["done", "Mark idea as complete"],
        ["park", "Park an idea for later"],
        ["unpark", "Restore a parked idea"],
        ["reschedule", "Reschedule idea to different release"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-idea list",
        "ace-idea show 42",
        "ace-idea create \"New feature concept\"",
        "ace-idea done 42",
        "ace-idea park 42"
      ].freeze

      # Register flat commands (reusing existing command classes)
      register "list", CLI::Commands::Ideas
      register "show", CLI::Commands::Idea
      register "create", CLI::Commands::IdeaSubcommands::Create
      register "done", CLI::Commands::IdeaSubcommands::Done
      register "park", CLI::Commands::IdeaSubcommands::Park
      register "unpark", CLI::Commands::IdeaSubcommands::Unpark
      register "reschedule", CLI::Commands::IdeaSubcommands::Reschedule

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-idea",
        version: Ace::Taskflow::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Taskflow::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd

      # Entry point for CLI invocation (used by tests and exe/)
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for errors)
      def self.start(args)
        Dry::CLI.new(self).call(arguments: args)
      end
    end
  end
end
