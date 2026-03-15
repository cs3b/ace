# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"

require_relative "../handbook"
require_relative "cli/commands/sync"
require_relative "cli/commands/status"

module Ace
  module Handbook
    module CLI
      extend Ace::Core::CLI::RegistryDsl

      PROGRAM_NAME = "ace-handbook"

      REGISTERED_COMMANDS = [
        ["sync", "Project canonical skills into provider-native folders"],
        ["status", "Show handbook provider integration status"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-handbook sync                    # Sync all enabled providers",
        "ace-handbook sync --provider pi      # Sync only Pi",
        "ace-handbook status                  # Show provider status",
        "ace-handbook status --provider pi    # Show Pi status"
      ].freeze

      register "sync", Commands::Sync
      register "status", Commands::Status

      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-handbook",
        version: Ace::Handbook::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Handbook::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
