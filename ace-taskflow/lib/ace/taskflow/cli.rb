# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../taskflow"

# CLI Commands (Hanami pattern)
require_relative "cli/commands/status"
require_relative "cli/commands/doctor"
require_relative "cli/commands/config"

module Ace
  module Taskflow
    # dry-cli based CLI registry for ace-taskflow
    #
    # After the split, ace-taskflow only handles utility commands.
    # Task/idea/release/retro management moved to dedicated CLIs:
    #   ace-task, ace-idea, ace-release, ace-retro
    module CLI
      extend Dry::CLI::Registry
      extend Ace::Core::CLI::DryCli::DefaultRouting

      PROGRAM_NAME = "ace-taskflow"

      REGISTERED_COMMANDS = %w[status doctor config].freeze

      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      DEFAULT_COMMAND = "status"

      HELP_EXAMPLES = [
        ["Show taskflow status", "ace-taskflow"],
        ["Run health check", "ace-taskflow doctor"],
        ["Show configuration", "ace-taskflow config"],
      ].freeze

      # Register utility commands
      register "status", CLI::Commands::Status, aliases: ["context"]
      register "doctor", CLI::Commands::Doctor
      register "config", CLI::Commands::Config

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-taskflow",
        version: Ace::Taskflow::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Clear caches before each invocation
      def self.start(args)
        Ace::Taskflow::Molecules::TaskLoader.clear_cache!
        Ace::Taskflow::Molecules::ReleaseResolver.clear_cache!
        super
      end
    end
  end
end
