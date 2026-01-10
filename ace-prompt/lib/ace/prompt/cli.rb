# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
# Commands
require_relative "commands/process"
require_relative "commands/setup"
# Organisms (needed for command logic)
require_relative "organisms/prompt_processor"
require_relative "organisms/prompt_initializer"

module Ace
  module Prompt
    # dry-cli based CLI registry for ace-prompt
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry
      extend Ace::Core::CLI::DryCli::DefaultRouting

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[process setup].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      # Using Set for O(1) lookup performance
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "process"

      # Register the process command (default)
      register "process", Commands::Process.new

      # Register the setup command
      register "setup", Commands::Setup.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-prompt",
        version: Ace::Prompt::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
