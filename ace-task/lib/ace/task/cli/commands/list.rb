# frozen_string_literal: true

require "dry/cli"

module Ace
  module Task
    module CLI
      module Commands
        # dry-cli Command class for ace-task list
        class List < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            List tasks

            Lists all tasks with optional filtering by status, tags, or folder.
          DESC

          example [
            '                           # Active tasks (root only, default)',
            '--in all                   # All tasks including archived/maybe',
            '--in maybe                 # Tasks in _maybe/',
            '--status pending           # Filter by status',
            '--tags ux,design           # Tasks matching any tag',
            '--in next --status pending # Combined filters',
            '--filter status:pending --filter tags:ux|design  # Generic filters'
          ]

          option :status, type: :string,  aliases: %w[-s], desc: "Filter by status (pending, in-progress, done, blocked)"
          option :tags,   type: :string,  aliases: %w[-T], desc: "Filter by tags (comma-separated, any match)"
          option :in,     type: :string,  aliases: %w[-i], desc: "Filter by folder (next=root only [default], all=everything, maybe, archive)"
          option :root,   type: :string,  aliases: %w[-r], desc: "Override root path (subpath within tasks root)"
          option :filter, type: :array,   aliases: %w[-f], desc: "Filter by key:value (repeatable, supports key:a|b and key:!value)"

          option :quiet,   type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug,   type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(**options)
            status    = options[:status]
            in_folder = options[:in]
            root      = options[:root]
            tags_str  = options[:tags]
            tags      = tags_str ? tags_str.split(",").map(&:strip).reject(&:empty?) : []
            filters   = options[:filter]

            manager = if root
              Ace::Task::Organisms::TaskManager.new(root_dir: File.expand_path(root))
            else
              Ace::Task::Organisms::TaskManager.new
            end

            list_opts = { status: status, tags: tags, filters: filters }
            list_opts[:in_folder] = in_folder if in_folder
            tasks = manager.list(**list_opts)

            puts Ace::Task::Molecules::TaskDisplayFormatter.format_list(tasks, total_count: manager.last_list_total)
          end
        end
      end
    end
  end
end
