# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../git_commit"
# Commands
require_relative "commands/commit"

module Ace
  module GitCommit
    # dry-cli based CLI registry for ace-git-commit
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry
      extend Ace::Core::CLI::DryCli::DefaultRouting

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[commit].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      # Using Set for O(1) lookup performance
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "commit"

      # Register the commit command (default)
      register "commit", Commands::Commit.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-git-commit",
        version: Ace::GitCommit::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
