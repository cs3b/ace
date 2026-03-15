# frozen_string_literal: true

require "ace/support/cli"
require_relative "shared_helpers"
require_relative "../../commands/prune_command"

module Ace
  module Git
    module Worktree
      module CLI
        module Commands
          class Prune < Ace::Support::Cli::Command
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
            option :verbose, desc: "Show verbose output", type: :boolean, aliases: ["-v"]
            option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress non-essential output"
            option :debug, type: :boolean, aliases: ["-d"], desc: "Show debug output"

            def call(**options)
              display_config_summary("prune", options)

              # Convert ace-support-cli options to args array format
              args = options_to_args(options)

              Ace::Git::Worktree::Commands::PruneCommand.new.run(args)
            end
          end
        end
      end
    end
  end
end
