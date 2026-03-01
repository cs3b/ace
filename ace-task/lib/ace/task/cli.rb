# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "version"
require_relative "cli/commands/create"
require_relative "cli/commands/show"
require_relative "cli/commands/list"
require_relative "cli/commands/move"
require_relative "cli/commands/update"
require_relative "cli/commands/doctor"

module Ace
  module Task
    # Flat CLI registry for ace-task (task management).
    module TaskCLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-task"

      REGISTERED_COMMANDS = [
        ["create", "Create a new task"],
        ["show",   "Show task details"],
        ["list",   "List tasks"],
        ["move",   "Move a task to a different folder"],
        ["update", "Update task metadata"],
        ["doctor", "Run health checks on tasks"]
      ].freeze

      HELP_EXAMPLES = [
        'ace-task create "Fix login bug"',
        'ace-task create "Fix auth" --priority high --tags auth,security',
        "ace-task show q7w",
        "ace-task show q7w --tree",
        "ace-task list --status pending",
        "ace-task list --in maybe",
        "ace-task move q7w --to archive",
        "ace-task update q7w --set status=done --set priority=high",
        "ace-task doctor",
        "ace-task doctor --auto-fix --dry-run"
      ].freeze

      register "create", CLI::Commands::Create
      register "show",   CLI::Commands::Show
      register "list",   CLI::Commands::List
      register "move",   CLI::Commands::Move
      register "update", CLI::Commands::Update
      register "doctor", CLI::Commands::Doctor

      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-task",
        version: Ace::Task::VERSION
      )
      register "version",   version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Task::VERSION,
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
