# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "cli/commands/list"
require_relative "cli/commands/run"
require_relative "cli/commands/emit"
require_relative "cli/commands/status"
require_relative "cli/commands/cron"
require_relative "version"

module Ace
  module Scheduler
    # CLI interface for ace-scheduler
    module CLI
      extend Dry::CLI::Registry

      REGISTERED_COMMANDS = %w[list run emit status cron].freeze
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze
      DEFAULT_COMMAND = "help"

      def self.start(args)
        if args.first && %w[help --help -h].include?(args.first)
          puts Dry::CLI::Usage.call(get([]))
          return 0
        end

        if args.empty? || !KNOWN_COMMANDS.include?(args.first)
          args = [DEFAULT_COMMAND] + args
        end
        Dry::CLI.new(self).call(arguments: args)
      end

      # Command registrations
      register "list", CLI::Commands::List
      register "run", CLI::Commands::Run
      register "emit", CLI::Commands::Emit
      register "status", CLI::Commands::Status
      register "cron", CLI::Commands::Cron

      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-scheduler",
        version: Ace::Scheduler::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
