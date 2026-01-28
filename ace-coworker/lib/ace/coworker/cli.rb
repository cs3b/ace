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
require_relative "atoms/number_generator"
require_relative "atoms/step_file_parser"
require_relative "atoms/step_sorter"

# Molecules
require_relative "molecules/session_manager"
require_relative "molecules/queue_scanner"
require_relative "molecules/step_writer"

# Organisms
require_relative "organisms/workflow_executor"

# Commands
require_relative "cli/commands/start"
require_relative "cli/commands/status"
require_relative "cli/commands/report"
require_relative "cli/commands/fail"
require_relative "cli/commands/add"
require_relative "cli/commands/retry_cmd"

module Ace
  module Coworker
    # dry-cli based CLI registry for ace-coworker
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[start status report fail add retry].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "status"

      # Start the CLI with default command routing
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      def self.start(args)
        # If first argument isn't a known command and args aren't empty,
        # prepend the default command.
        if args.empty? || !known_command?(args.first)
          args = [DEFAULT_COMMAND] + args
        end

        Dry::CLI.new(self).call(arguments: args)
      end

      # Check if argument is a known command
      #
      # @param arg [String] First argument to check
      # @return [Boolean] true if it's a command
      def self.known_command?(arg)
        return false if arg.nil?

        KNOWN_COMMANDS.include?(arg)
      end

      # Register commands
      register "start", Commands::Start
      register "status", Commands::Status
      register "report", Commands::Report
      register "fail", Commands::Fail
      register "add", Commands::Add
      register "retry", Commands::RetryCmd

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
