# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "version"
# Commands
require_relative "cli/commands/test"

module Ace
  module TestRunner
    # dry-cli based CLI registry for ace-test-runner
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry
      extend Ace::Core::CLI::DryCli::DefaultRouting

      PROGRAM_NAME = "ace-test"

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[test].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "test"

      # Register the test command (Hanami pattern: CLI::Commands::)
      register "test", Commands::Test.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-test-runner",
        version: Ace::TestRunner::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
