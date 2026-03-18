# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../tmux"
require_relative "cli/commands/start"
require_relative "cli/commands/window"
require_relative "cli/commands/list"

module Ace
  module Tmux
    # ace-support-cli based CLI registry for ace-tmux
    module CLI
      extend Ace::Core::CLI::RegistryDsl

      PROGRAM_NAME = "ace-tmux"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["start", "Start tmux session from preset"],
        ["window", "Add window to existing session"],
        ["list", "List available presets"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-tmux start dev                    # Launch dev session preset",
        "ace-tmux window cc --root ~/project   # Add window to session",
        "ace-tmux list                         # Available presets"
      ].freeze

      # Start the CLI
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      def self.start(args)
        Ace::Support::Cli::Runner.new(self).call(args: args)
      end

      # Register commands
      register "start", CLI::Commands::Start.new
      register "window", CLI::Commands::Window.new
      register "list", CLI::Commands::List.new

      # Register version command
      version_cmd = Ace::Core::CLI::VersionCommand.build(
        gem_name: "ace-tmux",
        version: Ace::Tmux::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Core::CLI::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Tmux::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
