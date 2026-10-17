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

            desc "List active worktrees with optional detail and filters"

            example [
              "                          # Worktrees active in the last 18h",
              "--full                    # Every worktree with absolute paths",
              "--active-within 3d        # Wider activity window",
              "--format json             # Machine-readable output",
              "--search auth             # Filter by branch pattern"
            ]

            option :format, desc: "Output format: table, json, simple", aliases: [], default: "table"
            option :compact, desc: "Active worktrees only (default)", type: :boolean
            option :full, desc: "List every worktree with absolute paths", type: :boolean
            option :active_within, desc: "Activity window (Nm, Nh, Nd, or bare hours; default 18h)", aliases: []
            option :task_associated, desc: "Show only task-associated worktrees", type: :boolean
            option :usable, desc: "Show only usable worktrees", type: :boolean
            option :search, desc: "Filter by branch name pattern", aliases: []
            option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress the count footer"
            option :verbose, type: :boolean, aliases: ["-v"], desc: "Show verbose output"
            option :debug, type: :boolean, aliases: ["-d"], desc: "Show debug output"

            def call(**options)
              display_config_summary("list", options) unless options[:format] == "json"

              # Keep explicit false values as --no-* flags so the parser receives filters.
              args = list_options_to_args(options)

              Ace::Git::Worktree::Commands::ListCommand.new.run(args)
            end

            private

            def list_options_to_args(options)
              args = []
              args.concat(format_arg(options))
              args << "--compact" if options[:compact]
              args << "--full" if options[:full]
              args << "--quiet" if options[:quiet]

              if options[:active_within].is_a?(String) && !options[:active_within].empty?
                args << "--active-within"
                args << options[:active_within]
              end

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
