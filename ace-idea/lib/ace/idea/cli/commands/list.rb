# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Idea
    module CLI
      module Commands
        # ace-support-cli Command class for ace-idea list
        class List < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base

          C = Ace::Support::Items::Atoms::AnsiColors
          desc "List ideas\n\n" \
            "Lists all ideas with optional filtering by status, tags, or folder.\n\n" \
            "Status legend:\n" \
            "  #{C::RESET}○ pending    #{C::YELLOW}▶ in-progress#{C::RESET}    #{C::GREEN}✓ done#{C::RESET}    #{C::DIM}✗ obsolete#{C::RESET}"
          remove_const(:C)

          example [
            '                           # Active ideas (root only, default)',
            '--in all                   # All ideas including archived/maybe',
            '--in maybe                 # Ideas in _maybe/',
            '--status pending           # Filter by status',
            '--tags ux,design           # Ideas matching any tag',
            '--in next --status pending # Combined filters',
            '--filter status:pending --filter tags:ux|design  # Generic filters'
          ]

          option :status, type: :string,  aliases: %w[-s], desc: "Filter by status (pending, in-progress, done, obsolete)"
          option :tags,   type: :string,  aliases: %w[-T], desc: "Filter by tags (comma-separated, any match)"
          option :in,     type: :string,  aliases: %w[-i], desc: "Filter by folder (next=root only [default], all=everything, maybe, archive)"
          option :root,   type: :string,  aliases: %w[-r], desc: "Override root path (subpath within ideas root)"
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

            manager = Ace::Idea::Organisms::IdeaManager.new
            list_opts = { status: status, tags: tags, root: root, filters: filters }
            list_opts[:in_folder] = in_folder if in_folder
            ideas = manager.list(**list_opts)

            puts Ace::Idea::Molecules::IdeaDisplayFormatter.format_list(
              ideas, total_count: manager.last_list_total,
              global_folder_stats: manager.last_folder_counts
            )
          end
        end
      end
    end
  end
end
