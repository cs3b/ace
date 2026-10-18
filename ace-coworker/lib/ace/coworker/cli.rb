# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "cli/commands/start"
require_relative "cli/commands/status"

module Ace
  module Coworker
    module CLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-coworker"

      REGISTERED_COMMANDS = [
        ["start", "Validate prepared run config and render the executor brief"],
        ["status", "Show readiness, identity, and assignment progress"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-coworker start                    # Read .ace-local/coworker/config.yml",
        "ace-coworker start --config PATH      # Use an explicit config",
        "ace-coworker status --format json     # Readiness + assignment verdict"
      ].freeze

      register "start", Commands::Start
      register "status", Commands::Status

      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-coworker",
        version: Ace::Coworker::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Support::Cli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Coworker::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
