# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "cli/commands/work_on"
require_relative "cli/commands/status"
require_relative "cli/commands/prune"

module Ace
  module Overseer
    module CLI
      extend Dry::CLI::Registry

      REGISTERED_COMMANDS = %w[work-on status prune].freeze
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      def self.start(args)
        if args.first && %w[help --help -h].include?(args.first)
          puts Dry::CLI::Usage.call(get([]))
          return 0
        end

        if args.empty?
          puts Dry::CLI::Usage.call(get([]))
          return 0
        end

        Dry::CLI.new(self).call(arguments: args)
      end

      def self.known_command?(arg)
        return false if arg.nil?

        KNOWN_COMMANDS.include?(arg)
      end

      register "work-on", Commands::WorkOn
      register "status", Commands::Status
      register "prune", Commands::Prune

      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-overseer",
        version: Ace::Overseer::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
