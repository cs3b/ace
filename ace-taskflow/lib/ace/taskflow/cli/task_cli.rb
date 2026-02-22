# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../version"

# Reuse existing command classes
require_relative "commands/task"
require_relative "commands/tasks"
require_relative "commands/task/create"
require_relative "commands/task/show"
require_relative "commands/task/start"
require_relative "commands/task/done"
require_relative "commands/task/undone"
require_relative "commands/task/defer"
require_relative "commands/task/undefer"
require_relative "commands/task/move"
require_relative "commands/task/update"
require_relative "commands/task/add_dependency"
require_relative "commands/task/remove_dependency"

module Ace
  module Taskflow
    # Flat CLI registry for ace-task (task management).
    #
    # Replaces the nested `ace-taskflow task <subcommand>` pattern with
    # flat `ace-task <command>` invocations.
    module TaskCLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-task"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["list", "List tasks in current release"],
        ["show", "Show task details"],
        ["create", "Create a new task"],
        ["start", "Mark task as in-progress"],
        ["done", "Mark task as complete"],
        ["undone", "Reopen completed task"],
        ["defer", "Defer task to future release"],
        ["undefer", "Restore deferred task"],
        ["move", "Move or reorganize task"],
        ["update", "Update task metadata"],
        ["add-dependency", "Add dependency to task"],
        ["remove-dependency", "Remove dependency from task"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-task list",
        "ace-task show 148",
        "ace-task create \"Fix login bug\"",
        "ace-task start 148",
        "ace-task done 148",
        "ace-task move 148 --child-of 100",
        "ace-task add-dependency 148 --on 147"
      ].freeze

      # Register flat commands (reusing existing command classes)
      register "list", CLI::Commands::Tasks
      register "show", CLI::Commands::Task
      register "create", CLI::Commands::TaskSubcommands::Create
      register "start", CLI::Commands::TaskSubcommands::Start
      register "done", CLI::Commands::TaskSubcommands::Done
      register "undone", CLI::Commands::TaskSubcommands::Undone
      register "defer", CLI::Commands::TaskSubcommands::Defer
      register "undefer", CLI::Commands::TaskSubcommands::Undefer
      register "move", CLI::Commands::TaskSubcommands::Move
      register "update", CLI::Commands::TaskSubcommands::Update
      register "add-dependency", CLI::Commands::TaskSubcommands::AddDependency
      register "remove-dependency", CLI::Commands::TaskSubcommands::RemoveDependency

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-task",
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
