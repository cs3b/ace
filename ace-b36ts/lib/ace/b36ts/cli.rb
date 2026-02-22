# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "cli/commands/encode"
require_relative "cli/commands/decode"
require_relative "cli/commands/config"
require_relative "version"

module Ace
  module B36ts
    # CLI interface for ace-b36ts using dry-cli
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
        extend Dry::CLI::Registry
        extend Ace::Core::CLI::DryCli::DefaultRouting

        PROGRAM_NAME = "ace-b36ts"

        # Application commands registered in this CLI (single source of truth)
        REGISTERED_COMMANDS = %w[encode decode config].freeze

        # dry-cli built-in commands (standard across all CLI gems)
        BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

        # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
        KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

        DEFAULT_COMMAND = "encode"

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
      end
    end
  end

