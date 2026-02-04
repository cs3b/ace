# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "version"

module Ace
  module E2eRunner
    # CLI interface for ace-e2e-test and ace-e2e-test-suite
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = [].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      DEFAULT_COMMAND = "help"

      # Testable start method with default command routing
      def self.start(args)
        # Handle help explicitly (dry-cli doesn't handle registry-level help)
        if args.first && %w[help --help -h].include?(args.first)
          puts Dry::CLI::Usage.call(get([]))
          return 0
        end

        if args.empty? || !KNOWN_COMMANDS.include?(args.first)
          args = [DEFAULT_COMMAND] + args
        end
        Dry::CLI.new(self).call(arguments: args)
      end

      # Version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-test-e2e-runner-cli",
        version: Ace::E2eRunner::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
