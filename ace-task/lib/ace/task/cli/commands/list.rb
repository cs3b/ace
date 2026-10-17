# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Task
    module CLI
      module Commands
        # ace-support-cli Command class for ace-task list
        class List < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          C = Ace::Support::Items::Atoms::AnsiColors
          desc "List tasks\n\n" \
            "Lists all tasks with optional filtering by status, tags, or folder.\n\n" \
            "Status legend:\n" \
            "  #{C::CYAN}◇ draft#{C::RESET}    #{C::RESET}○ pending    #{C::YELLOW}▶ in-progress#{C::RESET}    #{C::GREEN}✓ done#{C::RESET}\n" \
            "  #{C::RED}✗ blocked#{C::RESET}    #{C::DIM}– skipped  — cancelled#{C::RESET}\n\n" \
            "Priority: #{C::RED}▲ critical#{C::RESET}  ▲ high  #{C::DIM}▼ low#{C::RESET}    Subtasks: ›N"
          remove_const(:C)

          example [
            "                           # Active tasks (root only, default)",
            "--in all                   # All tasks including archived/maybe",
            "--in maybe                 # Tasks in _maybe/",
            "--in _overseer             # Tasks in the private overseer store",
            "--status pending           # Filter by status",
            "--tags ux,design           # Tasks matching any tag",
            "--in next --status pending # Combined filters",
            "--filter status:pending --filter tags:ux|design  # Generic filters",
            "--sort id                   # Sort by ID (chronological)",
            "--sort priority             # Sort by priority level"
          ]

          option :status, type: :string, aliases: %w[-s], desc: "Filter by status (pending, in-progress, done, blocked)"
          option :tags, type: :string, aliases: %w[-T], desc: "Filter by tags (comma-separated, any match)"
          option :in, type: :string, aliases: %w[-i],
            desc: "Folder filter (next [default], all, maybe, archive) or task store name (e.g. _overseer)"
          option :root, type: :string, aliases: %w[-r], desc: "Override root path (subpath within tasks root)"
          option :filter, type: :array, aliases: %w[-f], desc: "Filter by key:value (repeatable, supports key:a|b and key:!value)"
          option :sort, type: :string, aliases: %w[-S], desc: "Sort order: smart (default, dependency-aware), id, priority, created"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(**options)
            status = options[:status]
            in_folder = options[:in]
            root = options[:root]
            tags_str = options[:tags]
            tags = tags_str ? tags_str.split(",").map(&:strip).reject(&:empty?) : []
            filters = options[:filter]
            sort = options[:sort] || "smart"

            config = Ace::Task::Molecules::TaskConfigLoader.load
            store_root = in_folder && Ace::Task::Molecules::TaskConfigLoader.store_root(config, in_folder)
            if store_root && root
              raise Ace::Support::Cli::Error,
                "Cannot combine --root with store selector --in #{in_folder}"
            end
            if in_folder && store_root.nil? && root.nil? && in_folder.start_with?("_") &&
                !existing_task_folder?(config, in_folder)
              raise Ace::Support::Cli::Error,
                "Unknown task store '#{in_folder}'. Configure it under task.stores in " \
                ".ace/task/config.yml, or use an existing task folder."
            end

            manager = if root
              Ace::Task::Organisms::TaskManager.new(root_dir: File.expand_path(root))
            elsif store_root
              Ace::Task::Organisms::TaskManager.new(root_dir: store_root, config: config)
            else
              Ace::Task::Organisms::TaskManager.new(config: config)
            end

            list_opts = {status: status, tags: tags, filters: filters, sort: sort}
            list_opts[:in_folder] = in_folder if in_folder && !store_root
            tasks = manager.list(**list_opts)

            puts Ace::Task::Molecules::TaskDisplayFormatter.format_list(
              tasks, total_count: manager.last_list_total,
              global_folder_stats: manager.last_folder_counts,
              cycle_ids: manager.last_list_cycle_ids
            )
          end

          private

          def existing_task_folder?(config, name)
            root = config.dig("task", "root_dir") || ".ace-tasks"
            File.directory?(File.expand_path(File.join(root, name)))
          end
        end
      end
    end
  end
end
