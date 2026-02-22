# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../version"

# Reuse existing command classes
require_relative "commands/retro"
require_relative "commands/retros"

module Ace
  module Taskflow
    # Flat CLI registry for ace-retro (retrospective management).
    #
    # Replaces the nested `ace-taskflow retro/retros` pattern with
    # flat `ace-retro <command>` invocations.
    module RetroCLI
      extend Dry::CLI::Registry
      extend Ace::Core::CLI::DryCli::DefaultRouting

      PROGRAM_NAME = "ace-retro"

      REGISTERED_COMMANDS = %w[list create].freeze

      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      DEFAULT_COMMAND = "list"

      HELP_EXAMPLES = [
        ["List retrospectives", "ace-retro"],
        ["Create a retrospective for a task", "ace-retro create 148"],
      ].freeze

      # Register flat commands (reusing existing command classes)
      register "list", CLI::Commands::Retros
      register "create", CLI::Commands::Retro

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-retro",
        version: Ace::Taskflow::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
