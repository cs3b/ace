# frozen_string_literal: true

require "dry/cli"
require "ace/core"

module Ace
  module Docs
    # dry-cli based CLI registry for ace-docs
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-docs"

      REGISTERED_COMMANDS = [
        ["status", "Show documentation status"],
        ["discover", "Discover undocumented items"],
        ["update", "Update documentation metadata"],
        ["analyze", "Analyze documentation quality"],
        ["validate", "Validate documentation structure"],
        ["analyze-consistency", "Check documentation consistency"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-docs status",
        "ace-docs discover",
        "ace-docs update docs/architecture.md",
        "ace-docs analyze",
        "ace-docs validate",
        "ace-docs analyze-consistency"
      ].freeze

      # Register all commands (Hanami pattern: CLI::Commands::*)
      register "status", Commands::Status.new
      register "discover", Commands::Discover.new
      register "update", Commands::Update.new
      register "analyze", Commands::Analyze.new
      register "validate", Commands::Validate.new
      register "analyze-consistency", Commands::AnalyzeConsistency.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-docs",
        version: Ace::Docs::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Docs::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
