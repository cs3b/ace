# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../runtime"
require_relative "cli/commands/send"

module Ace
  module Runtime
    # ace-support-cli based CLI registry for ace-runtime. The contract
    # ships exactly one agent-facing command: the neutral send
    # passthrough (Fork Callback Rule decision, 2026-09-27).
    module CLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-runtime"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["send", "Send a submitted command, text chunks, or named keys to a pane via the resolved terminal runtime"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-runtime send --pane %1 --cmd 'bundle exec rake test'                  # Submit a command",
        "ace-runtime send --pane %1 --msg 'Reply with exactly: pong' --key Enter   # Callback form: submits exactly once",
        "ace-runtime send --runtime herdr --pane w1:p1 --msg 'hello'               # Explicit runtime selection",
        "ace-runtime send --pane %1 --key C-c                                      # Keys-only send"
      ].freeze

      # Start the CLI
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      def self.start(args)
        Ace::Support::Cli::Runner.new(self).call(args: args)
      end

      # Register commands
      register "send", CLI::Commands::Send.new

      # Register version command
      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-runtime",
        version: Ace::Runtime::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Support::Cli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Runtime::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
