# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../assign"

# Models
require_relative "models/assignment"
require_relative "models/phase"
require_relative "models/queue_state"
require_relative "models/assignment_info"

# Atoms
require_relative "atoms/phase_numbering"
require_relative "atoms/number_generator"
require_relative "atoms/preset_expander"
require_relative "atoms/phase_file_parser"
require_relative "atoms/phase_sorter"
require_relative "atoms/catalog_loader"
require_relative "atoms/composition_rules"
require_relative "atoms/assign_frontmatter_parser"
require_relative "atoms/tree_formatter"

# Molecules
require_relative "molecules/assignment_manager"
require_relative "molecules/assignment_discoverer"
require_relative "molecules/queue_scanner"
require_relative "molecules/phase_writer"
require_relative "molecules/phase_renumberer"
require_relative "molecules/skill_assign_source_resolver"
require_relative "molecules/fork_session_launcher"

# Organisms
require_relative "organisms/assignment_executor"

# Commands
require_relative "cli/commands/create"
require_relative "cli/commands/assignment_target"
require_relative "cli/commands/status"
require_relative "cli/commands/start"
require_relative "cli/commands/finish"
require_relative "cli/commands/fail"
require_relative "cli/commands/add"
require_relative "cli/commands/retry_cmd"
require_relative "cli/commands/list"
require_relative "cli/commands/select"
require_relative "cli/commands/fork_run"

module Ace
  module Assign
    # ace-support-cli based CLI registry for ace-assign
    module CLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-assign"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["create", "Create assignment from preset or YAML"],
        ["status", "Show assignment status"],
        ["start", "Start next workable phase"],
        ["finish", "Complete current phase with report"],
        ["fail", "Mark phase as failed"],
        ["add", "Add phase to assignment"],
        ["retry", "Retry failed phase"],
        ["list", "List all assignments"],
        ["select", "Select active assignment"],
        ["fork-run", "Run subtree in forked process"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-assign create --preset review     # Start review assignment",
        "ace-assign status                     # Current phase progress",
        "ace-assign start                      # Start next workable phase",
        "ace-assign finish --message done.md    # Complete active phase",
        "cat report.md | ace-assign finish     # Complete phase via stdin",
        "ace-assign fork-run 010.01            # Run subtree in subprocess"
      ].freeze

      # Captured command exit code from last run
      @captured_exit_code = nil

      # Start the CLI
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      def self.start(args)
        @captured_exit_code = nil
        Ace::Support::Cli::Runner.new(self).call(args: args)
        @captured_exit_code || 0
      end

      # Wrap a command to capture its exit code
      #
      # @param command_class [Class] The command class to wrap
      # @return [Class] Wrapped command class
      def self.wrap_command(command_class)
        wrapped = Class.new(Ace::Support::Cli::Command) do
          define_method(:call) do |**kwargs|
            result = command_class.new.call(**kwargs)
            Ace::Assign::CLI.instance_variable_set(:@captured_exit_code, result) if result.is_a?(Integer)
            result
          end
        end
        # Copy metadata from original class
        command_class.instance_variables.each do |ivar|
          wrapped.instance_variable_set(ivar, command_class.instance_variable_get(ivar))
        end
        wrapped
      end

      # Register commands (wrapped to capture exit codes)
      register "create", wrap_command(Commands::Create)
      register "status", wrap_command(Commands::Status)
      register "start", wrap_command(Commands::Start)
      register "finish", wrap_command(Commands::Finish)
      register "fail", wrap_command(Commands::Fail)
      register "add", wrap_command(Commands::Add)
      register "retry", wrap_command(Commands::RetryCmd)
      register "list", wrap_command(Commands::List)
      register "select", wrap_command(Commands::Select)
      register "fork-run", wrap_command(Commands::ForkRun)

      # Register version command
      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-assign",
        version: Ace::Assign::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Support::Cli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Assign::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
