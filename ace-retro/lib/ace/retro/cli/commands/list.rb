# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Retro
    module CLI
      module Commands
        # ace-support-cli Command class for ace-retro list
        class List < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          C = Ace::Support::Items::Atoms::AnsiColors
          desc "List retros\n\n" \
            "Lists all retros with optional filtering by status, type, tags, or folder.\n\n" \
            "Status legend:\n" \
            "  #{C::YELLOW}○ active#{C::RESET}    #{C::GREEN}✓ done#{C::RESET}"
          remove_const(:C)

          example [
            '                           # Active retros (root only, default)',
            '--in all                   # All retros including archived',
            '--in archive               # Retros in _archive/',
            '--status active            # Filter by status',
            '--type standard            # Filter by type',
            '--tags sprint,team         # Retros matching any tag',
            '--in archive --type standard  # Combined filters'
          ]

          option :status, type: :string,  aliases: %w[-s], desc: "Filter by status (active, done)"
          option :type,   type: :string,  aliases: %w[-t], desc: "Filter by type (standard, conversation-analysis, self-review)"
          option :tags,   type: :string,  aliases: %w[-T], desc: "Filter by tags (comma-separated, any match)"
          option :in,     type: :string,  aliases: %w[-i], desc: "Filter by folder (next=root only [default], all=everything, archive)"
          option :root,   type: :string,  aliases: %w[-r], desc: "Override root path"

          option :quiet,   type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug,   type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(**options)
            status    = options[:status]
            type      = options[:type]
            in_folder = options[:in]
            tags_str  = options[:tags]
            tags      = tags_str ? tags_str.split(",").map(&:strip).reject(&:empty?) : []

            manager_opts = {}
            manager_opts[:root_dir] = options[:root] if options[:root]
            manager = Ace::Retro::Organisms::RetroManager.new(**manager_opts)
            list_opts = { status: status, type: type, tags: tags }
            list_opts[:in_folder] = in_folder if in_folder
            retros = manager.list(**list_opts)

            puts Ace::Retro::Molecules::RetroDisplayFormatter.format_list(
              retros, total_count: manager.last_list_total,
              global_folder_stats: manager.last_folder_counts
            )
          end
        end
      end
    end
  end
end
