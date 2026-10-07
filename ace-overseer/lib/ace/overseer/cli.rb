# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "cli/commands/work_on"
require_relative "cli/commands/status"
require_relative "cli/commands/prune"
require_relative "cli/commands/projects"
require_relative "cli/commands/agents"
require_relative "cli/commands/prompt"
require_relative "cli/commands/review"
require_relative "cli/commands/stop"

module Ace
  module Overseer
    module CLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-overseer"

      REGISTERED_COMMANDS = [
        ["work-on", "Start local task work or one retained protected launch"],
        ["status", "Show status of task worktrees"],
        ["prune", "Remove stale task worktrees"],
        ["projects", "List visible public projects"],
        ["agents", "List visible public project agents"],
        ["prompt", "Prompt an exact protected attempt or inspect original prompt status"],
        ["review", "Review an exact protected candidate under its original capability"],
        ["stop", "Request proof-authenticated stop of an exact protected attempt"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-overseer work-on 148              # Launch task in worktree",
        "ace-overseer status                   # All active worktrees",
        "ace-overseer prune                    # Clean up finished tasks"
      ].freeze

      register "work-on", Commands::WorkOn
      register "status", Commands::Status
      register "prune", Commands::Prune
      register "projects", Commands::Projects
      register "agents", Commands::Agents
      register "prompt", Commands::Prompt
      register "review", Commands::Review
      register "stop", Commands::Stop

      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-overseer",
        version: Ace::Overseer::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Support::Cli::HelpCommand.build(
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
