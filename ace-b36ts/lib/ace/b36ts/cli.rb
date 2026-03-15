# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "cli/commands/encode"
require_relative "cli/commands/decode"
require_relative "cli/commands/config"
require_relative "version"

module Ace
  module B36ts
    # CLI interface for ace-b36ts using ace-support-cli
    #
    # This follows the Hanami pattern with all commands in CLI::Commands:: namespace.
    #
    # @example Encode a timestamp
    #   $ ace-b36ts encode "2025-01-06 12:30:00"
    #   i50jj3
    #
    # @example Decode a compact ID
    #   $ ace-b36ts decode i50jj3
    #   2025-01-06 12:30:00 UTC
    #
    # @example Show configuration
    #   $ ace-b36ts config
    #   year_zero: 2000
    #   alphabet: 0123456789abcdefghijklmnopqrstuvwxyz
    #
    module CLI
      extend Ace::Core::CLI::RegistryDsl

      PROGRAM_NAME = "ace-b36ts"

      REGISTERED_COMMANDS = [
        ["encode", "Encode timestamp to compact ID"],
        ["decode", "Decode compact ID to timestamp"],
        ["config", "Show current configuration"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-b36ts encode                          # Generate ID from now",
        "ace-b36ts encode 2024-01-15T10:30:00Z     # Encode specific time",
        "ace-b36ts decode abc123                   # Decode ID to timestamp"
      ].freeze

      # Register commands (Hanami pattern: CLI::Commands::*)
      register "encode", Commands::Encode
      register "decode", Commands::Decode
      register "config", Commands::Config

      # Version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-b36ts",
        version: Ace::B36ts::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Help command
      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::B36ts::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end

