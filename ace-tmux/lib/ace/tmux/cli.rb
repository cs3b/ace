# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../tmux"
require_relative "cli/commands/start"
require_relative "cli/commands/window"
require_relative "cli/commands/list"

module Ace
  module Tmux
    # dry-cli based CLI registry for ace-tmux
    module CLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-tmux"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["start", "Start tmux session from preset"],
        ["window", "Add window to existing session"],
        ["list", "List available presets"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-tmux start dev",
        "ace-tmux window cc --root /path/to/project",
        "ace-tmux list"
      ].freeze

      # Start the CLI
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      def self.start(args)
        Dry::CLI.new(self).call(arguments: args)
      end

      # Register commands
      register "start", CLI::Commands::Start.new
      register "window", CLI::Commands::Window.new
      register "list", CLI::Commands::List.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-tmux",
        version: Ace::Tmux::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
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
