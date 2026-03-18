# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Docs
    # ace-support-cli based CLI registry for ace-docs
    #
    # This replaces the Thor-based CLI with ace-support-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Ace::Core::CLI::RegistryDsl

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
        "ace-docs status --needs-update        # Docs due for refresh",
        "ace-docs update docs/architecture.md  # Refresh metadata",
        "ace-docs analyze-consistency          # Cross-doc link check"
      ].freeze

      # Register all commands (Hanami pattern: CLI::Commands::*)
      register "status", Commands::Status.new
      register "discover", Commands::Discover.new
      register "update", Commands::Update.new
      register "analyze", Commands::Analyze.new
      register "validate", Commands::Validate.new
      register "analyze-consistency", Commands::AnalyzeConsistency.new

      # Register version command
      version_cmd = Ace::Core::CLI::VersionCommand.build(
        gem_name: "ace-docs",
        version: Ace::Docs::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Core::CLI::HelpCommand.build(
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
