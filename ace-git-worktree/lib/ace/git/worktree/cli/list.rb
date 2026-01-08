# frozen_string_literal: true

require "dry/cli"
require_relative "shared_helpers"
require_relative "../commands/list_command"

module Ace
  module Git
    module Worktree
      module CLI
        class List < Dry::CLI::Command
          include SharedHelpers

          desc "List all worktrees with optional filtering"

          example [
            "                          # List all worktrees",
            "--show-tasks              # Include task associations",
            "--format json             # JSON output",
            "--search auth             # Filter by branch pattern"
          ]

          option :format, desc: "Output format: table, json, simple", aliases: [], default: "table"
          option :show_tasks, desc: "Include task associations", type: :boolean, aliases: ["--show-tasks"]
          option :task_associated, desc: "Show only task-associated worktrees", type: :boolean, aliases: ["--task-associated"]
          option :no_task_associated, desc: "Show only non-task worktrees", type: :boolean, aliases: ["--no-task-associated"]
          option :usable, desc: "Show only usable worktrees", type: :boolean, aliases: ["--usable"]
          option :no_usable, desc: "Show only unusable worktrees", type: :boolean, aliases: ["--no-usable"]
          option :search, desc: "Filter by branch name pattern", aliases: []
          option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress config summary output"
          option :verbose, type: :boolean, aliases: ["-v"], desc: "Verbose output"
          option :debug, type: :boolean, aliases: ["-d"], desc: "Debug output"

          def call(**options)
            display_config_summary("list", options)

            # Convert dry-cli options to args array format
            args = options_to_args(options)

            Commands::ListCommand.new.run(args)
          end
        end
      end
    end
  end
end
