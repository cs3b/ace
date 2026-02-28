# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "cli/commands/run"

module Ace
  module Sim
    module CLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-sim"

      REGISTERED_COMMANDS = [
        ["run", "Run a preset simulation"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-sim run --preset validate-idea --source path/to/source.md --provider codex:mini --dry-run",
        "ace-sim run --preset validate-idea --source path/to/source.md --provider codex:mini --provider google:gflash --repeat 2",
        "ace-sim run --preset validate-idea --source path/to/source.md --provider glite --synthesis-workflow wfi://task/review --synthesis-provider claude:haiku"
      ].freeze

      def self.start(args)
        Dry::CLI.new(self).call(arguments: args)
      end

      register "run", Commands::Run

      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-sim",
        version: Ace::Sim::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Sim::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
