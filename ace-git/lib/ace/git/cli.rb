# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../git"
require_relative "cli/commands/diff"
require_relative "cli/commands/status"
require_relative "cli/commands/branch"
require_relative "cli/commands/pr"

module Ace
  module Git
    # dry-cli command registry for ace-git.
    module CLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-git"

      REGISTERED_COMMANDS = [
        ["diff", "Show filtered git diff output"],
        ["status", "Show repository status and PR context"],
        ["branch", "Show current branch information"],
        ["pr", "Show pull request information"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-git diff HEAD~5..HEAD",
        "ace-git status",
        "ace-git branch",
        "ace-git pr"
      ].freeze

      register "diff", Commands::Diff.new
      register "status", Commands::Status.new
      register "branch", Commands::Branch.new
      register "pr", Commands::Pr.new

      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-git",
        version: Ace::Git::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Git::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
