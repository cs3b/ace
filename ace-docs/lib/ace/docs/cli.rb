# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../docs"
# CLI Commands
require_relative "cli/status_command"
require_relative "cli/discover_command"
require_relative "cli/update_command"
require_relative "cli/analyze_command"
require_relative "cli/validate_command"
require_relative "cli/analyze_consistency_command"

module Ace
  module Docs
    # dry-cli based CLI registry for ace-docs
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry
      extend Ace::Core::CLI::DryCli::DefaultRouting

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[status discover update analyze validate analyze-consistency].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      # Using Set for O(1) lookup performance
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "status"

      # Register all commands
      register "status", StatusCommand.new
      register "discover", DiscoverCommand.new
      register "update", UpdateCommand.new
      register "analyze", AnalyzeCommand.new
      register "validate", ValidateCommand.new
      register "analyze-consistency", AnalyzeConsistencyCommand.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-docs",
        version: Ace::Docs::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
