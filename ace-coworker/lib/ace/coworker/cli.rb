# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../coworker"

# Models
require_relative "models/session"
require_relative "models/step"
require_relative "models/queue_state"

# Atoms
require_relative "atoms/job_numbering"
require_relative "atoms/number_generator"
require_relative "atoms/step_file_parser"
require_relative "atoms/step_sorter"

# Molecules
require_relative "molecules/session_manager"
require_relative "molecules/queue_scanner"
require_relative "molecules/step_writer"
require_relative "molecules/job_renumberer"

# Organisms
require_relative "organisms/workflow_executor"

# Commands
require_relative "cli/commands/create"
require_relative "cli/commands/status"
require_relative "cli/commands/report"
require_relative "cli/commands/fail"
require_relative "cli/commands/add"
require_relative "cli/commands/retry_cmd"
require_relative "cli/commands/prepare"

module Ace
  module Coworker
    # dry-cli based CLI registry for ace-coworker
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[create status report fail add retry prepare].freeze

      # Deprecated commands and their replacements
      DEPRECATED_COMMANDS = {
        "start" => "create"
      }.freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "status"

      # Captured command exit code from last run
      @captured_exit_code = nil

      # Start the CLI with default command routing
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      def self.start(args)
        # Reset captured exit code
        @captured_exit_code = nil

        # Handle help explicitly (dry-cli doesn't handle registry-level help)
        if args.first && %w[help --help -h].include?(args.first)
          puts Dry::CLI::Usage.call(get([]))
          return 0
        end

        # Check for deprecated commands
        if args.first && DEPRECATED_COMMANDS.key?(args.first)
          old_cmd = args.first
          new_cmd = DEPRECATED_COMMANDS[old_cmd]
          $stderr.puts "Warning: '#{old_cmd}' is deprecated. Use '#{new_cmd}' instead."
          args = [new_cmd] + args[1..]
        end

        # If first argument isn't a known command and args aren't empty,
        # prepend the default command.
        if args.empty? || !known_command?(args.first)
          args = [DEFAULT_COMMAND] + args
        end

        Dry::CLI.new(self).call(arguments: args)
        @captured_exit_code || 0
      end

      # Wrap a command to capture its exit code
      #
      # @param command_class [Class] The command class to wrap
      # @return [Class] Wrapped command class
      def self.wrap_command(command_class)
        wrapped = Class.new(Dry::CLI::Command) do
          define_method(:call) do |**kwargs|
            result = command_class.new.call(**kwargs)
            Ace::Coworker::CLI.instance_variable_set(:@captured_exit_code, result) if result.is_a?(Integer)
            result
          end
        end
        # Copy metadata from original class
        command_class.instance_variables.each do |ivar|
          wrapped.instance_variable_set(ivar, command_class.instance_variable_get(ivar))
        end
        wrapped
      end

      # Check if argument is a known command
      #
      # @param arg [String] First argument to check
      # @return [Boolean] true if it's a command
      def self.known_command?(arg)
        return false if arg.nil?

        KNOWN_COMMANDS.include?(arg)
      end

      # Register commands (wrapped to capture exit codes)
      register "create", wrap_command(Commands::Create)
      register "status", wrap_command(Commands::Status)
      register "report", wrap_command(Commands::Report)
      register "fail", wrap_command(Commands::Fail)
      register "add", wrap_command(Commands::Add)
      register "retry", wrap_command(Commands::RetryCmd)
      register "prepare", wrap_command(Commands::Prepare)

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-coworker",
        version: Ace::Coworker::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
