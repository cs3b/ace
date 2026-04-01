# frozen_string_literal: true

require "ace/support/cli"
require_relative "shared_helpers"
require_relative "../../commands/list_command"

module Ace
  module Git
    module Worktree
      module CLI
        module Commands
          class List < Ace::Support::Cli::Command
            include SharedHelpers

            desc "List all worktrees with optional filtering"

            example [
              "                          # List all worktrees",
              "--show-tasks              # Include task associations",
              "--format json             # JSON output",
              "--search auth             # Filter by branch pattern"
            ]

            option :format, desc: "Output format: table, json, simple", aliases: [], default: "table"
            option :show_tasks, desc: "Include task associations", type: :boolean
            option :task_associated, desc: "Show only task-associated worktrees", type: :boolean
            option :usable, desc: "Show only usable worktrees", type: :boolean
            option :search, desc: "Filter by branch name pattern", aliases: []
            option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress non-essential output"
            option :verbose, type: :boolean, aliases: ["-v"], desc: "Show verbose output"
            option :debug, type: :boolean, aliases: ["-d"], desc: "Show debug output"

            def call(**options)
              display_config_summary("list", options) unless options[:format] == "json"

              # Keep explicit false values as --no-* flags so legacy parser receives filters.
              args = list_options_to_args(options)

              Ace::Git::Worktree::Commands::ListCommand.new.run(args)
            end

            private

            def list_options_to_args(options)
              args = []
              args.concat(format_arg(options))
              args << "--show-tasks" if options[:show_tasks]

              unless options[:task_associated].nil?
                args << (options[:task_associated] ? "--task-associated" : "--no-task-associated")
              end

              unless options[:usable].nil?
                args << (options[:usable] ? "--usable" : "--no-usable")
              end

              if options[:search].is_a?(String) && !options[:search].empty?
                args << "--search"
                args << options[:search]
              end

              args
            end

            def format_arg(options)
              format = options[:format]
              return [] if format.nil? || format.empty?

              ["--format", format]
            end
          end
        end
      end
    end
  end
end
