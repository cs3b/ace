# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../taskflow"

# CLI Commands (Hanami pattern)
require_relative "cli/commands/status"
require_relative "cli/commands/doctor"
require_relative "cli/commands/config"
require_relative "cli/commands/review_next_phase"

module Ace
  module Taskflow
    # dry-cli based CLI registry for ace-taskflow
    #
    # After the split, ace-taskflow only handles utility commands.
    # Task/idea/release/retro management moved to dedicated CLIs:
    #   ace-task, ace-idea, ace-release, ace-retro
    module CLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-taskflow"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["status", "Show taskflow status"],
        ["doctor", "Run health checks"],
        ["config", "Show configuration"],
        ["review-next-phase", "Run next-phase simulation and persist cache artifacts"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-taskflow status                   # Current task and release overview",
        "ace-taskflow doctor --auto-fix        # Fix safe issues automatically",
        "ace-taskflow config                   # Show resolved configuration",
        "ace-taskflow review-next-phase --source 285.01 --modes plan --dry-run"
      ].freeze

      # Register utility commands
      register "status", CLI::Commands::Status, aliases: ["context"]
      register "doctor", CLI::Commands::Doctor
      register "config", CLI::Commands::Config
      register "review-next-phase", CLI::Commands::ReviewNextPhase

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-taskflow",
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
