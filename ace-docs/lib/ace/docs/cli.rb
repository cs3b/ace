# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../docs"
# CLI Commands (Hanami pattern)
require_relative "cli/commands/status"
require_relative "cli/commands/discover"
require_relative "cli/commands/update"
require_relative "cli/commands/analyze"
require_relative "cli/commands/validate"
require_relative "cli/commands/analyze_consistency"

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
    end
  end
end
