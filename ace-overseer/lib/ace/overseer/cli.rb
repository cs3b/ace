# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "cli/commands/work_on"
require_relative "cli/commands/status"
require_relative "cli/commands/prune"

module Ace
  module Overseer
    module CLI
      extend Ace::Core::CLI::RegistryDsl

      PROGRAM_NAME = "ace-overseer"

      REGISTERED_COMMANDS = [
        ["work-on", "Work on a task in isolated worktree"],
        ["status", "Show status of task worktrees"],
        ["prune", "Remove stale task worktrees"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-overseer work-on 148              # Launch task in worktree",
        "ace-overseer status                   # All active worktrees",
        "ace-overseer prune                    # Clean up finished tasks"
      ].freeze

      register "work-on", Commands::WorkOn
      register "status", Commands::Status
      register "prune", Commands::Prune

      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-overseer",
        version: Ace::Overseer::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Overseer::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
