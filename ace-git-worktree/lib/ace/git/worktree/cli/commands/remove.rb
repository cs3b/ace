# frozen_string_literal: true

require "ace/support/cli"
require_relative "shared_helpers"
require_relative "../../commands/remove_command"

module Ace
  module Git
    module Worktree
      module CLI
        module Commands
          class Remove < Ace::Support::Cli::Command
            include SharedHelpers

            desc "Remove a git worktree with safety checks"

            example [
              "--task 081           # Remove task worktree",
              "feature-branch       # Remove by branch name",
              "--task 081 --force   # Force removal with changes"
            ]

            argument :identifier, required: false, desc: "Worktree identifier (task ID, branch, directory, or path)"

            option :task, desc: "Remove worktree for specific task", aliases: []
            option :force, desc: "Force removal even with uncommitted changes", type: :boolean, aliases: []
            option :keep_directory, desc: "Keep the worktree directory", type: :boolean, aliases: ["--keep-directory"]
            option :delete_branch, desc: "Also delete the associated branch", type: :boolean, aliases: ["-db"]
            option :dry_run, desc: "Show what would be removed", type: :boolean, aliases: ["--dry-run"]
            option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress non-essential output"
            option :verbose, type: :boolean, aliases: ["-v"], desc: "Show verbose output"
            option :debug, type: :boolean, aliases: ["-d"], desc: "Show debug output"

            def call(identifier: nil, **options)
              display_config_summary("remove", options)

              # Convert ace-support-cli options to args array format
              args = options_to_args(options)
              args << identifier if identifier

              Ace::Git::Worktree::Commands::RemoveCommand.new.run(args)
            end
          end
        end
      end
    end
  end
end
