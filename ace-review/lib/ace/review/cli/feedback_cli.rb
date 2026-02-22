# frozen_string_literal: true

require "dry/cli"
require "set"
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
      extend Dry::CLI::Registry
      extend Ace::Core::CLI::DryCli::DefaultRouting

      PROGRAM_NAME = "ace-review-feedback"

      REGISTERED_COMMANDS = %w[list create show verify skip resolve].freeze

      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      DEFAULT_COMMAND = "list"

      HELP_EXAMPLES = [
        ["List feedback items", "ace-review-feedback"],
        ["Create feedback from review", "ace-review-feedback create"],
        ["Show feedback details", "ace-review-feedback show abc123"],
        ["Verify feedback as valid", "ace-review-feedback verify abc123 --valid"],
        ["Resolve feedback item", "ace-review-feedback resolve abc123 --resolution 'Fixed in PR #42'"],
      ].freeze

      # Register flat commands (reusing existing command classes)
      register "list", CLI::Commands::FeedbackSubcommands::List
      register "create", CLI::Commands::FeedbackSubcommands::Create
      register "show", CLI::Commands::FeedbackSubcommands::Show
      register "verify", CLI::Commands::FeedbackSubcommands::Verify
      register "skip", CLI::Commands::FeedbackSubcommands::Skip
      register "resolve", CLI::Commands::FeedbackSubcommands::Resolve

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-review-feedback",
        version: Ace::Review::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
