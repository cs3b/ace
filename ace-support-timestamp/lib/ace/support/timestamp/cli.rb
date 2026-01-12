# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "cli/encode"
require_relative "cli/decode"
require_relative "cli/config"
require_relative "version"

module Ace
  module Support
    module Timestamp
    # CLI interface for ace-timestamp using dry-cli
    #
    # @example Encode a timestamp
    #   $ ace-timestamp encode "2025-01-06 12:30:00"
    #   i50jj3
    #
    # @example Decode a compact ID
    #   $ ace-timestamp decode i50jj3
    #   2025-01-06 12:30:00 UTC
    #
    # @example Show configuration
    #   $ ace-timestamp config
    #   year_zero: 2000
    #   alphabet: 0123456789abcdefghijklmnopqrstuvwxyz
    #
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[encode decode config].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      DEFAULT_COMMAND = "encode"

      # Testable start method with default command routing
      def self.start(args)
        if args.empty? || !KNOWN_COMMANDS.include?(args.first)
          args = [DEFAULT_COMMAND] + args
        end
        Dry::CLI.new(self).call(arguments: args)
      end

      register "encode", Commands::Encode
      register "decode", Commands::Decode
      register "config", Commands::Config

      # Version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-support-timestamp",
        version: Ace::Support::Timestamp::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
  end
end
