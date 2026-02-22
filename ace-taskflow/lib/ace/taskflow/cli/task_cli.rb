# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../version"
require_relative "../molecules/task_loader"
require_relative "../molecules/release_resolver"

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
      extend Ace::Core::CLI::DryCli::DefaultRouting

      PROGRAM_NAME = "ace-task"

      REGISTERED_COMMANDS = %w[
        list show create start done undone defer undefer move update
        add-dependency remove-dependency
      ].freeze

      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      DEFAULT_COMMAND = "list"

      HELP_EXAMPLES = [
        ["List pending tasks", "ace-task"],
        ["Show a specific task", "ace-task show 148"],
        ["Create a new task", "ace-task create \"Add caching layer\""],
        ["Mark task as done", "ace-task done 114"],
        ["Start working on a task", "ace-task start 148"],
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

      # Clear caches before each invocation
      def self.start(args)
        Ace::Taskflow::Molecules::TaskLoader.clear_cache!
        Ace::Taskflow::Molecules::ReleaseResolver.clear_cache!
        super
      end
    end
  end
end
