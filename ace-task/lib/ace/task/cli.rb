# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "version"
require_relative "cli/commands/create"
require_relative "cli/commands/show"
require_relative "cli/commands/list"
require_relative "cli/commands/update"
require_relative "cli/commands/doctor"
require_relative "cli/commands/status"
require_relative "cli/commands/plan"
require_relative "cli/commands/github_sync"

module Ace
  module Task
    # Flat CLI registry for ace-task (task management).
    module TaskCLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-task"

      REGISTERED_COMMANDS = [
        ["create", "Create a new task"],
        ["show", "Show task details"],
        ["list", "List tasks"],
        ["update", "Update task metadata (fields, move, reparent)"],
        ["doctor", "Run health checks on tasks"],
        ["status", "Show task status overview"],
        ["plan", "Resolve or generate implementation plan"],
        ["github-sync", "Sync linked GitHub issues for task(s)"]
      ].freeze

      HELP_EXAMPLES = [
        'ace-task create "Fix login bug"',
        'ace-task create "Fix auth" --priority high --tags auth,security',
        "ace-task show q7w",
        "ace-task show q7w --tree",
        "ace-task list --status pending",
        "ace-task list --in maybe",
        "ace-task update q7w --set status=done --move-to archive",
        "ace-task update q7w --set status=done --set priority=high",
        "ace-task update q7w --move-to next",
        "ace-task doctor",
        "ace-task doctor --auto-fix --dry-run",
        "ace-task status",
        "ace-task status --up-next-limit 5",
        "ace-task plan q7w",
        "ace-task plan q7w --refresh",
        "ace-task plan q7w --content",
        "ace-task github-sync q7w",
        "ace-task github-sync --all"
      ].freeze

      register "create", CLI::Commands::Create
      register "show", CLI::Commands::Show
      register "list", CLI::Commands::List
      register "update", CLI::Commands::Update
      register "doctor", CLI::Commands::Doctor
      register "status", CLI::Commands::Status
      register "plan", CLI::Commands::Plan
      register "github-sync", CLI::Commands::GithubSync

      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-task",
        version: Ace::Task::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Support::Cli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Task::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd

      # Entry point for CLI invocation
      # @param args [Array<String>] Command-line arguments
      def self.start(args)
        Ace::Support::Cli::Runner.new(self).call(args: args)
      end
    end
  end
end
