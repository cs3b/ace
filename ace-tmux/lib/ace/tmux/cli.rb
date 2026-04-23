# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../tmux"
require_relative "cli/commands/start"
require_relative "cli/commands/window"
require_relative "cli/commands/list"
require_relative "cli/commands/list_presets"
require_relative "cli/commands/send"
require_relative "cli/commands/capture"
require_relative "cli/commands/wait"
require_relative "cli/commands/attach"
require_relative "cli/commands/detach"

module Ace
  module Tmux
    # ace-support-cli based CLI registry for ace-tmux
    module CLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-tmux"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["start", "Start tmux session from preset"],
        ["window", "Add window to existing session"],
        ["list", "List live tmux sessions, windows, or panes"],
        ["--list-presets", "List available tmux presets"],
        ["send", "Send submitted commands, raw text, or named keys to a pane"],
        ["capture", "Capture recent output from a pane"],
        ["wait", "Wait for a bounded tmux condition"],
        ["attach", "Attach to a tmux session"],
        ["detach", "Detach clients from a tmux session"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-tmux start dev                    # Launch dev session preset",
        "ace-tmux window cc --root ~/project   # Add window to session",
        "ace-tmux --list-presets windows       # Available window presets",
        "ace-tmux list                         # Panes in the current window",
        "ace-tmux list --windows               # Windows in the current session",
        "ace-tmux send --pane %1 --cmd 'bundle exec rake test'      # Send command",
        "ace-tmux send --pane .1 --msg 'echo ready' --key Enter     # Current-window pane shortcut",
        "ace-tmux wait --session dev --for window-active --window work-fs # Wait for window",
        "ace-tmux capture --pane %1 --lines 40 # Capture pane output",
        "ace-tmux detach --session dev         # Detach session clients"
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
      register "--list-presets", CLI::Commands::ListPresets.new
      register "send", CLI::Commands::Send.new
      register "capture", CLI::Commands::Capture.new
      register "wait", CLI::Commands::Wait.new
      register "attach", CLI::Commands::Attach.new
      register "detach", CLI::Commands::Detach.new

      # Register version command
      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-tmux",
        version: Ace::Tmux::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Support::Cli::HelpCommand.build(
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
