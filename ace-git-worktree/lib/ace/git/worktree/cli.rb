# frozen_string_literal: true

require "dry/cli"

require_relative "version"
require_relative "cli/commands/create"
require_relative "cli/commands/list"
require_relative "cli/commands/switch"
require_relative "cli/commands/remove"
require_relative "cli/commands/prune"
require_relative "cli/commands/config"
require "ace/core"
require "ace/core/cli/dry_cli/base"

module Ace
  module Git
    module Worktree
      # dry-cli based CLI registry for ace-git-worktree
      #
      # This follows the Hanami pattern with all commands in CLI::Commands:: namespace.
      module CLI
        extend Dry::CLI::Registry

        PROGRAM_NAME = "ace-git-worktree"

        REGISTERED_COMMANDS = [
          ["create", "Create a new worktree for task, PR, or branch"],
          ["list", "List active worktrees with optional task metadata"],
          ["switch", "Resolve a worktree path for cd navigation"],
          ["remove", "Remove a worktree by task, branch, or path"],
          ["prune", "Prune stale/deleted worktree references"],
          ["config", "Show and validate configuration"]
        ].freeze

        HELP_EXAMPLES = [
          "ace-git-worktree create --task 148    # Isolated worktree for task",
          "ace-git-worktree list --show-tasks    # Worktrees with task context",
          "ace-git-worktree switch 148           # Get path for cd",
          "ace-git-worktree prune --dry-run      # Preview stale cleanup"
        ].freeze

        # Captured command exit code from last run.
        @captured_exit_code = nil

        # Start the CLI.
        #
        # @param args [Array<String>] Command-line arguments
        # @return [Integer] Exit code (0 for success, non-zero for failure)
        def self.start(args)
          @captured_exit_code = nil
          Dry::CLI.new(self).call(arguments: args)
          @captured_exit_code || 0
        end

        # Wrap a command to capture its exit code.
        #
        # @param command_class [Class] The command class to wrap
        # @return [Class] Wrapped command class
        def self.wrap_command(command_class)
          wrapped = Class.new(Dry::CLI::Command) do
            define_method(:call) do |**kwargs|
              result = command_class.new.call(**kwargs)
              Ace::Git::Worktree::CLI.instance_variable_set(:@captured_exit_code, result) if result.is_a?(Integer)
              result
            end
          end

          command_class.instance_variables.each do |ivar|
            wrapped.instance_variable_set(ivar, command_class.instance_variable_get(ivar))
          end

          wrapped
        end

        # Register commands (Hanami pattern: CLI::Commands::*)
        register "create", wrap_command(CLI::Commands::Create), aliases: []
        register "list", wrap_command(CLI::Commands::List), aliases: ["ls"]
        register "switch", wrap_command(CLI::Commands::Switch), aliases: ["cd"]
        register "remove", wrap_command(CLI::Commands::Remove), aliases: ["rm"]
        register "prune", wrap_command(CLI::Commands::Prune), aliases: []
        register "config", wrap_command(CLI::Commands::Config), aliases: []

        # Version command
        version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
          gem_name: "ace-git-worktree",
          version: Ace::Git::Worktree::VERSION
        )
        register "version", version_cmd
        register "--version", version_cmd

        help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
          program_name: PROGRAM_NAME,
          version: Ace::Git::Worktree::VERSION,
          commands: REGISTERED_COMMANDS,
          examples: HELP_EXAMPLES
        )
        register "help", help_cmd
        register "--help", help_cmd
        register "-h", help_cmd
      end
    end
  end
end
