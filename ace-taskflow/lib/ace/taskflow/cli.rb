# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../taskflow"
# Molecules
require_relative "molecules/command_router"

# CLI Commands (Hanami pattern)
require_relative "cli/commands/task"
require_relative "cli/commands/tasks"
require_relative "cli/commands/idea"
require_relative "cli/commands/ideas"
require_relative "cli/commands/release"
require_relative "cli/commands/releases"
require_relative "cli/commands/retro"
require_relative "cli/commands/retros"
require_relative "cli/commands/status"
require_relative "cli/commands/doctor"
require_relative "cli/commands/migrate"
require_relative "cli/commands/config"
# Nested task subcommands (migrated to CLI::Commands:: namespace)
require_relative "cli/commands/task/create"
require_relative "cli/commands/task/show"
require_relative "cli/commands/task/start"
require_relative "cli/commands/task/done"
require_relative "cli/commands/task/undone"
require_relative "cli/commands/task/defer"
require_relative "cli/commands/task/undefer"
require_relative "cli/commands/task/move"
require_relative "cli/commands/task/update"
require_relative "cli/commands/task/add_dependency"
require_relative "cli/commands/task/remove_dependency"
# Nested idea subcommands (migrated to CLI::Commands:: namespace)
require_relative "cli/commands/idea/create"
require_relative "cli/commands/idea/done"
require_relative "cli/commands/idea/park"
require_relative "cli/commands/idea/unpark"
require_relative "cli/commands/idea/reschedule"

module Ace
  module Taskflow
    # dry-cli based CLI registry for ace-taskflow
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    #
    # Uses the Hanami pattern: CLI::Commands::* namespace for all commands.
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[
        task tasks idea ideas
        release releases retro retros
        status doctor migrate config
      ].freeze

      # Task subcommands (for routing disambiguation)
      TASK_SUBCOMMANDS = %w[
        create show start done undone defer undefer move update
        add-dependency remove-dependency
      ].freeze

      # Idea subcommands (for routing disambiguation)
      IDEA_SUBCOMMANDS = %w[
        create done park unpark reschedule
      ].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Command aliases for backward compatibility
      COMMAND_ALIASES = %w[context migrate-paths].freeze

      # Auto-derived from REGISTERED + BUILTIN + ALIASES
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS + COMMAND_ALIASES).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "task"

      # Start the CLI with default command routing and cache clearing
      def self.start(args)
        clear_caches!

        # Handle help explicitly (dry-cli doesn't handle registry-level help)
        if args.first && %w[help --help -h].include?(args.first)
          puts Dry::CLI::Usage.call(get([]))
          return 0
        end

        args = Molecules::CommandRouter.route(
          args,
          default: DEFAULT_COMMAND,
          known_commands: KNOWN_COMMANDS,
          task_subcommands: TASK_SUBCOMMANDS,
          idea_subcommands: IDEA_SUBCOMMANDS
        )

        Dry::CLI.new(self).call(arguments: args)
      end

      def self.known_command?(arg)
        return false if arg.nil?
        KNOWN_COMMANDS.include?(arg)
      end

      def self.clear_caches!
        Ace::Taskflow::Molecules::TaskLoader.clear_cache!
        Ace::Taskflow::Molecules::ReleaseResolver.clear_cache!
      end

      # Register task commands
      register "task", CLI::Commands::Task
      register "task create", CLI::Commands::TaskSubcommands::Create
      register "task show", CLI::Commands::TaskSubcommands::Show
      register "task start", CLI::Commands::TaskSubcommands::Start
      register "task done", CLI::Commands::TaskSubcommands::Done
      register "task undone", CLI::Commands::TaskSubcommands::Undone
      register "task defer", CLI::Commands::TaskSubcommands::Defer
      register "task undefer", CLI::Commands::TaskSubcommands::Undefer
      register "task move", CLI::Commands::TaskSubcommands::Move
      register "task update", CLI::Commands::TaskSubcommands::Update
      register "task add-dependency", CLI::Commands::TaskSubcommands::AddDependency
      register "task remove-dependency", CLI::Commands::TaskSubcommands::RemoveDependency
      register "tasks", CLI::Commands::Tasks

      # Register idea commands
      register "idea", CLI::Commands::Idea
      register "idea create", CLI::Commands::IdeaSubcommands::Create
      register "idea done", CLI::Commands::IdeaSubcommands::Done
      register "idea park", CLI::Commands::IdeaSubcommands::Park
      register "idea unpark", CLI::Commands::IdeaSubcommands::Unpark
      register "idea reschedule", CLI::Commands::IdeaSubcommands::Reschedule
      register "ideas", CLI::Commands::Ideas

      # Register release commands (CLI::Commands::*)
      register "release", CLI::Commands::Release
      register "releases", CLI::Commands::Releases

      # Register retro commands (CLI::Commands::*)
      register "retro", CLI::Commands::Retro
      register "retros", CLI::Commands::Retros

      # Register status command with alias (CLI::Commands::*)
      register "status", CLI::Commands::Status, aliases: ["context"]

      # Register utility commands (CLI::Commands::*)
      register "doctor", CLI::Commands::Doctor
      register "migrate", CLI::Commands::Migrate, aliases: ["migrate-paths"]
      register "config", CLI::Commands::Config

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
