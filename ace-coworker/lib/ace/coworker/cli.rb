# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "cli/commands/start"
require_relative "cli/commands/status"
require_relative "cli/commands/report"
require_relative "cli/commands/resume"
require_relative "cli/commands/prepare"

module Ace
  module Coworker
    module CLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-coworker"

      REGISTERED_COMMANDS = [
        ["start", "Validate prepared run config and render the executor brief"],
        ["status", "Show readiness, identity, and assignment progress"],
        ["report", "Record the assignment outcome and report it through ace-hitl"],
        ["resume", "Assess interrupted work in this worktree and resume it"],
        ["prepare", "Accept a preparation commission and ensure the task worktree"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-coworker start                    # Read .ace-local/coworker/config.yml",
        "ace-coworker start --config PATH      # Use an explicit config",
        "ace-coworker status --format json     # Readiness + assignment verdict",
        "ace-coworker report                   # Record outcome + HITL report",
        "ace-coworker report --result error --message 'cause'",
        "ace-coworker resume                   # Resume interrupted work",
        "ace-coworker resume --dry-run         # Plan only, no redelivery",
        "ace-coworker prepare --task 148 --roles worker,reviewer",
        "ace-coworker prepare --task 148 --roles worker --dry-run"
      ].freeze

      register "start", Commands::Start
      register "status", Commands::Status
      register "report", Commands::Report
      register "resume", Commands::Resume
      register "prepare", Commands::Prepare

      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-coworker",
        version: Ace::Coworker::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Support::Cli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Coworker::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
