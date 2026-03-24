# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../version"

# Reuse existing feedback command classes
require_relative "commands/feedback/create"
require_relative "commands/feedback/list"
require_relative "commands/feedback/show"
require_relative "commands/feedback/verify"
require_relative "commands/feedback/skip"
require_relative "commands/feedback/resolve"

module Ace
  module Review
    # Flat CLI registry for ace-review-feedback (review feedback management).
    #
    # Replaces the nested `ace-review feedback <subcommand>` pattern with
    # flat `ace-review-feedback <command>` invocations.
    module FeedbackCLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-review-feedback"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["list", "List feedback items from a review"],
        ["create", "Create feedback from review output"],
        ["show", "Show feedback details"],
        ["verify", "Verify feedback as valid or invalid"],
        ["skip", "Skip a feedback item"],
        ["resolve", "Resolve a feedback item"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-review-feedback create                        # From latest review session",
        "ace-review-feedback list --status pending          # Unresolved items",
        "ace-review-feedback verify 42 --valid              # Confirm finding",
        "ace-review-feedback resolve 42                     # Mark as resolved"
      ].freeze

      # Register flat commands (reusing existing command classes)
      register "list", CLI::Commands::FeedbackSubcommands::List
      register "create", CLI::Commands::FeedbackSubcommands::Create
      register "show", CLI::Commands::FeedbackSubcommands::Show
      register "verify", CLI::Commands::FeedbackSubcommands::Verify
      register "skip", CLI::Commands::FeedbackSubcommands::Skip
      register "resolve", CLI::Commands::FeedbackSubcommands::Resolve

      # Register version command
      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-review-feedback",
        version: Ace::Review::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Support::Cli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Review::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
