# frozen_string_literal: true

require "ace/support/cli"
require_relative "shared_helpers"
require_relative "../../commands/create_command"

module Ace
  module Git
    module Worktree
      module CLI
        module Commands
          class Create < Ace::Support::Cli::Command
            include SharedHelpers

            desc <<~DESC.strip
              Create a new worktree

              Supports task-aware, PR, and traditional worktree creation.

              Task-Aware:
                ace-git-worktree --task 081
                ace-git-worktree --task 081 --dry-run

              PR-Aware:
                ace-git-worktree --pr 123

              Traditional:
                ace-git-worktree feature-branch
                ace-git-worktree create --from origin/feature
            DESC

            example [
              "--task 081          # Create worktree for task",
              "--pr 123            # Create worktree for PR",
              "--from origin/feature   # Create from remote branch",
              "feature/new-auth    # Create with branch name"
            ]

            argument :branch, required: false, desc: "Branch name for traditional creation"

            option :task, desc: "Task ID for task-aware worktree", aliases: []
            option :pr, desc: "PR number for PR-aware worktree", aliases: ["--pull-request"]
            option :from, desc: "Create from specific branch (local or remote)", aliases: ["-b"]
            option :path, desc: "Custom worktree path", aliases: []
            option :source, desc: "Git ref to use as start-point", aliases: []
            option :dry_run, desc: "Show what would be created", type: :boolean, aliases: ["--dry-run"]
            option :no_status_update, desc: "Skip marking task as in-progress", type: :boolean, aliases: ["--no-status-update"]
            option :no_commit, desc: "Skip committing task changes", type: :boolean, aliases: ["--no-commit"]
            option :no_push, desc: "Skip pushing task changes", type: :boolean, aliases: ["--no-push"]
            option :no_upstream, desc: "Skip pushing with upstream tracking", type: :boolean, aliases: ["--no-upstream"]
            option :no_pr, desc: "Skip creating draft PR", type: :boolean, aliases: ["--no-pr"]
            option :push_remote, desc: "Remote to push to", aliases: []
            option :no_auto_navigate, desc: "Stay in current directory", type: :boolean, aliases: ["--no-auto-navigate"]
            option :commit_message, desc: "Custom commit message", aliases: []
            option :target_branch, desc: "Override PR target branch (default: auto-detect from parent)", aliases: []
            option :force, desc: "Create even if worktree exists", type: :boolean, aliases: []
            option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress non-essential output"
            option :verbose, type: :boolean, aliases: ["-v"], desc: "Show verbose output"
            option :debug, type: :boolean, aliases: ["-d"], desc: "Show debug output"

            def call(branch: nil, **options)
              display_config_summary("create", options)

              # Convert --from to --source for the underlying command
              if options[:from]
                options[:source] = options.delete(:from)
              end

              # Convert ace-support-cli options hash to args array format
              args = options_to_args(options)
              args << branch if branch

              Ace::Git::Worktree::Commands::CreateCommand.new.run(args)
            end
          end
        end
      end
    end
  end
end
