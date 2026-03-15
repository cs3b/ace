# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../secrets"
# Business logic command objects
require_relative "commands/scan_command"
require_relative "commands/rewrite_command"
require_relative "commands/revoke_command"
require_relative "commands/check_release_command"
# ace-support-cli command wrappers (Hanami pattern: CLI::Commands::)
require_relative "cli/commands/scan"
require_relative "cli/commands/rewrite"
require_relative "cli/commands/revoke"
require_relative "cli/commands/check_release"
require_relative "version"

module Ace
  module Git
    module Secrets
      # ace-support-cli based CLI registry for ace-git-secrets
      #
      # This replaces the Thor-based CLI with ace-support-cli while maintaining
      # complete command parity and user-facing behavior.
      module CLI
        extend Ace::Core::CLI::RegistryDsl

        PROGRAM_NAME = "ace-git-secrets"

        REGISTERED_COMMANDS = [
          ["scan", "Scan Git history for authentication tokens"],
          ["rewrite-history", "Rewrite Git history to remove leaked tokens"],
          ["revoke", "Revoke leaked tokens via provider APIs"],
          ["check-release", "Check repository readiness for release"]
        ].freeze

        HELP_EXAMPLES = [
          "ace-git-secrets scan --staged         # Pre-commit check",
          "ace-git-secrets check-release         # Verify before publish",
          "ace-git-secrets revoke --token TOKEN  # Revoke leaked credential"
        ].freeze

        # Register the scan command (default) - Hanami pattern: CLI::Commands::
        register "scan", CLI::Commands::Scan.new

        # Register the rewrite-history command
        register "rewrite-history", CLI::Commands::Rewrite.new

        # Register the revoke command
        register "revoke", CLI::Commands::Revoke.new

        # Register the check-release command
        register "check-release", CLI::Commands::CheckRelease.new

        # Register version command
        version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
          gem_name: "ace-git-secrets",
          version: Ace::Git::Secrets::VERSION
        )
        register "version", version_cmd
        register "--version", version_cmd

        help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
          program_name: PROGRAM_NAME,
          version: Ace::Git::Secrets::VERSION,
          commands: REGISTERED_COMMANDS,
          examples: HELP_EXAMPLES
        )
        register "help", help_cmd
        register "--help", help_cmd
        register "-h", help_cmd
      end
    end
  end
end
