# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../lint"

module Ace
  module Lint
    # dry-cli based CLI registry for ace-lint
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-lint"

      REGISTERED_COMMANDS = [
        ["lint", "Lint markdown, YAML, Ruby, and frontmatter files"],
        ["doctor", "Diagnose lint configuration and validator health"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-lint lint docs/architecture.md",
        "ace-lint lint docs/**/*.md --fix",
        "ace-lint lint .claude/skills/ace-git-commit/SKILL.md",
        "ace-lint doctor"
      ].freeze

      # Register the lint command
      register "lint", Commands::Lint.new

      # Register the doctor command
      register "doctor", Commands::Doctor.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-lint",
        version: Ace::Lint::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Lint::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
