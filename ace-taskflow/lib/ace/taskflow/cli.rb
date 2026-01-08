# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../taskflow"
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
      # 3. Testable entry point for consistent behavior
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      def self.start(args)
        # Clear per-command caches at the start of each CLI invocation
        # This ensures fresh data for each command execution
        clear_caches!

        # Prepend default command when:
        # - args is empty (user ran `ace-taskflow` with no arguments)
        # - first argument isn't a known command (user ran `ace-taskflow 150`)
        # This maintains Thor's default_task parity.
        if args.empty? || !known_command?(args.first)
          args = [DEFAULT_COMMAND] + args
        end

        Dry::CLI.new(self).call(arguments: args)
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
