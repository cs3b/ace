# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../lab"

module Ace
  module Lab
    # ace-support-cli based CLI registry for ace-lab
    module CLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-lab"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [].freeze

      HELP_EXAMPLES = [
        "ace-lab projects --format json",
        "ace-lab agents --project atlas --format json",
        "ace-lab resolve --id atlas-planner --format json",
        "ace-lab route --project atlas --capability search --format json"
      ].freeze

      # Start the CLI
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      def self.start(args)
        Ace::Support::Cli::Runner.new(self).call(args: args)
      end

      # Register version command
      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-lab",
        version: Ace::Lab::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Support::Cli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Lab::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
