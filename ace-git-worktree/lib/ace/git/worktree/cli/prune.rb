# frozen_string_literal: true

require "dry/cli"
require_relative "shared_helpers"
require_relative "../commands/prune_command"

module Ace
  module Git
    module Worktree
      module CLI
        class Prune < Dry::CLI::Command
          include SharedHelpers

          desc "Clean up deleted worktrees from git metadata"

          example [
            "                        # Prune deleted worktrees",
            "--dry-run              # Preview what would be pruned",
            "--cleanup-directories  # Also remove orphaned directories"
          ]

          option :dry_run, desc: "Show what would be pruned", type: :boolean, aliases: ["--dry-run"]
          option :cleanup_directories, desc: "Remove orphaned worktree directories", type: :boolean, aliases: ["--cleanup-directories"]
          option :force, desc: "Force cleanup", type: :boolean, aliases: []
          option :verbose, desc: "Show detailed information", type: :boolean, aliases: ["-v"]
          option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress config summary output"
          option :debug, type: :boolean, aliases: ["-d"], desc: "Debug output"

          def call(**options)
            display_config_summary("prune", options)

            # Convert dry-cli options to args array format
            args = options_to_args(options)

            Commands::PruneCommand.new.run(args)
          end
        end
      end
    end
  end
end
