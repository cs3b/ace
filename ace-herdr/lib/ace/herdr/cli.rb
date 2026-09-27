# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../herdr"
require_relative "cli/commands/deliver"
require_relative "cli/commands/dispatch"
require_relative "cli/commands/wait"
require_relative "cli/commands/close"

module Ace
  module Herdr
    # ace-support-cli based CLI registry for ace-herdr
    module CLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-herdr"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["deliver", "Push an answer to an agent pane (ace-hitl delivery contract)"],
        ["dispatch", "Start an agent in one command: tab + agent + prompt"],
        ["wait", "Wait for an agent to reach a state"],
        ["close", "Rename and/or close a finished agent pane"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-herdr deliver --session ws-1 --pane p5 --event-id evt-1 --answer-file answer.md",
        "echo 'the answer' | ace-herdr deliver --pane p5",
        "ace-herdr dispatch --label 8wm.t.vs0 --kind pi --prompt-file prompt.md",
        "ace-herdr wait --pane p5 --until done --timeout 120",
        "ace-herdr close --pane p5 --rename done"
      ].freeze

      # Start the CLI
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      def self.start(args)
        Ace::Support::Cli::Runner.new(self).call(args: args)
      end

      # Register commands
      register "deliver", CLI::Commands::Deliver.new
      register "dispatch", CLI::Commands::Dispatch.new
      register "wait", CLI::Commands::Wait.new
      register "close", CLI::Commands::Close.new

      # Register version command
      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-herdr",
        version: Ace::Herdr::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Support::Cli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Herdr::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
