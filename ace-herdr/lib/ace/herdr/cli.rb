# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../herdr"
require_relative "cli/commands/deliver"
require_relative "cli/commands/inbox"
require_relative "cli/commands/dispatch"
require_relative "cli/commands/wait"
require_relative "cli/commands/close"
require_relative "cli/commands/tidy"
require_relative "cli/commands/list"
require_relative "cli/commands/send"
require_relative "cli/commands/capture"
require_relative "cli/commands/workspace"
require_relative "cli/commands/tab"
require_relative "cli/commands/list_presets"
require_relative "cli/commands/native_source"

module Ace
  module Herdr
    # ace-support-cli based CLI registry for ace-herdr
    module CLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-herdr"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["deliver", "Push an answer to an agent pane (ace-hitl delivery contract)"],
        ["inbox", "Durable agent message queue and reconciliation"],
        ["dispatch", "Start an agent in one command: tab + agent + prompt"],
        ["native-source", "Describe, build, or verify the packaged guarded native source"],
        ["list", "List live panes, tabs, or workspaces as one JSON line"],
        ["send", "Send a command, raw text, or named keys to a pane"],
        ["capture", "Print recent pane output as raw text"],
        ["wait", "Wait for an agent state or matching pane output"],
        ["close", "Rename and/or close a finished agent pane"],
        ["tidy", "Report cleanable panes/delivery records; close and archive with --apply"],
        ["workspace", "Create a workspace from a preset"],
        ["tab", "Create a tab from a preset"],
        ["--list-presets", "List available workspace/tab presets"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-herdr deliver --session ws-1 --pane p5 --event-id evt-1 --answer-file answer.md",
        "ace-herdr inbox enqueue --event evt-1 --attempt att-1 --ref ref.json --file prompt.txt",
        "echo 'the answer' | ace-herdr deliver --pane p5",
        "ace-herdr dispatch --label 8wm.t.vs0 --kind pi --prompt-file prompt.md",
        "ace-herdr list --workspace w1",
        "ace-herdr send --pane p5 --cmd 'bundle exec rake test'",
        "ace-herdr send --pane p5 --msg 'continue' --key Enter",
        "ace-herdr capture --pane p5 --lines 40",
        "ace-herdr wait --pane p5 --for output --pattern done --timeout 30",
        "ace-herdr workspace development",
        "ace-herdr tab agent --workspace w1",
        "ace-herdr --list-presets",
        "ace-herdr close --pane p5 --rename done",
        "ace-herdr tidy --apply"
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
      register "inbox", CLI::Commands::Inbox.new
      register "dispatch", CLI::Commands::Dispatch.new
      register "native-source", CLI::Commands::NativeSource.new
      register "list", CLI::Commands::List.new
      register "send", CLI::Commands::Send.new
      register "capture", CLI::Commands::Capture.new
      register "wait", CLI::Commands::Wait.new
      register "close", CLI::Commands::Close.new
      register "tidy", CLI::Commands::Tidy.new
      register "workspace", CLI::Commands::Workspace.new
      register "tab", CLI::Commands::Tab.new
      register "--list-presets", CLI::Commands::ListPresets.new

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
