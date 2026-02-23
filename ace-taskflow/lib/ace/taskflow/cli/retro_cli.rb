# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../version"

# Reuse existing command classes
require_relative "commands/retro"
require_relative "commands/retros"
require_relative "commands/create_retro"

module Ace
  module Taskflow
    # Flat CLI registry for ace-retro (retrospective management).
    #
    # Replaces the nested `ace-taskflow retro/retros` pattern with
    # flat `ace-retro <command>` invocations.
    module RetroCLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-retro"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["list", "List retrospective reflection notes"],
        ["create", "Create a new retrospective reflection note"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-retro list",
        'ace-retro create "Session learnings"',
        "ace-retro create my-topic --release v.0.9.0"
      ].freeze

      # Register flat commands (reusing existing command classes)
      register "list", CLI::Commands::Retros
      register "create", CLI::Commands::CreateRetro

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-retro",
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
