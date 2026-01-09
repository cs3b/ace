# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../taskflow"
# Molecules
require_relative "molecules/command_router"
# Command wrapper classes
require_relative "cli/task"
require_relative "cli/tasks"
require_relative "cli/idea"
require_relative "cli/ideas"
require_relative "cli/release"
require_relative "cli/releases"
require_relative "cli/retro"
require_relative "cli/retros"
require_relative "cli/status"
require_relative "cli/doctor"
require_relative "cli/migrate"
require_relative "cli/config"
# Nested task subcommands
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
    # dry-cli based CLI registry for ace-taskflow
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[
        task tasks idea ideas
        release releases retro retros
        status doctor migrate config
      ].freeze

      # Task subcommands (for routing disambiguation)
      # These are the known subcommands under "task" namespace
      TASK_SUBCOMMANDS = %w[
        create show start done undone defer undefer move update
        add-dependency remove-dependency
      ].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Command aliases for backward compatibility
      # - context: alias for status (historical CLI naming)
      # - migrate-paths: alias for migrate (Thor CLI naming)
      COMMAND_ALIASES = %w[context migrate-paths].freeze

      # Auto-derived from REGISTERED + BUILTIN + ALIASES (no manual maintenance needed)
      # Using Set for O(1) lookup performance
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS + COMMAND_ALIASES).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "task"

      # Start the CLI with default command routing and cache clearing
      #
      # This method handles:
      # 1. Cache clearing at start of each CLI invocation (from Thor version)
      # 2. Default command routing for unknown commands (e.g., "150" -> "task 150")
      # 3. Task subcommand routing disambiguation (e.g., "task create" vs "task 114")
      # 4. Testable entry point for consistent behavior
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      def self.start(args)
        # Clear per-command caches at the start of each CLI invocation
        clear_caches!

        # Apply routing rules via CommandRouter molecule
        args = Molecules::CommandRouter.route(
          args,
          default: DEFAULT_COMMAND,
          known_commands: KNOWN_COMMANDS,
          task_subcommands: TASK_SUBCOMMANDS
        )

        Dry::CLI.new(self).call(arguments: args)
      end

      # @deprecated Use Molecules::CommandRouter.route_task_subcommand instead
      # Retained for backward compatibility with existing tests
      def self.route_task_subcommand(args)
        Molecules::CommandRouter.route_task_subcommand(
          args,
          task_subcommands: TASK_SUBCOMMANDS
        )
      end

      # Check if argument is a known command
      #
      # @param arg [String] First argument to check
      # @return [Boolean] true if it's a known command
      def self.known_command?(arg)
        return false if arg.nil?
        KNOWN_COMMANDS.include?(arg)
      end

      # Clear per-command caches in loaders
      # Called at the start of each CLI invocation to ensure fresh data
      def self.clear_caches!
        Ace::Taskflow::Molecules::TaskLoader.clear_cache!
        Ace::Taskflow::Molecules::ReleaseResolver.clear_cache!
      end

      # Register task commands
      register "task", CLI::Task.new
      register "task create", Commands::Task::Create
      register "task show", Commands::Task::Show
      register "task start", Commands::Task::Start
      register "task done", Commands::Task::Done
      register "task undone", Commands::Task::Undone
      register "task defer", Commands::Task::Defer
      register "task undefer", Commands::Task::Undefer
      register "task move", Commands::Task::Move
      register "task update", Commands::Task::Update
      register "task add-dependency", Commands::Task::AddDependency
      register "task remove-dependency", Commands::Task::RemoveDependency
      register "tasks", CLI::Tasks.new

      # Register idea commands
      register "idea", CLI::Idea.new
      register "ideas", CLI::Ideas.new

      # Register release commands
      register "release", CLI::Release.new
      register "releases", CLI::Releases.new

      # Register retro commands
      register "retro", CLI::Retro.new
      register "retros", CLI::Retros.new

      # Register status command with alias
      register "status", CLI::Status.new, aliases: ["context"]

      # Register utility commands
      register "doctor", CLI::Doctor.new
      register "migrate", CLI::Migrate.new, aliases: ["migrate-paths"]
      register "config", CLI::Config.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-taskflow",
        version: Ace::Taskflow::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
