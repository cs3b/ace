# frozen_string_literal: true

require "dry/cli"

module Ace
  module Retro
    module CLI
      module Commands
        # dry-cli Command class for ace-retro list
        class List < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            List retros

            Lists all retros with optional filtering by status, type, tags, or folder.

          DESC

          example [
            '                           # All retros',
            '--in archive               # Retros in _archive/',
            '--status active            # Filter by status',
            '--type standard            # Filter by type',
            '--tags sprint,team         # Retros matching any tag',
            '--in archive --type standard  # Combined filters'
          ]

          option :status, type: :string,  aliases: %w[-s], desc: "Filter by status (active, done)"
          option :type,   type: :string,  aliases: %w[-t], desc: "Filter by type (standard, conversation-analysis, self-review)"
          option :tags,   type: :string,  aliases: %w[-T], desc: "Filter by tags (comma-separated, any match)"
          option :in,     type: :string,  aliases: %w[-i], desc: "Filter by folder (e.g. archive)"
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
            retros = manager.list(
              status: status,
              type: type,
              in_folder: in_folder,
              tags: tags
            )

            puts Ace::Retro::Molecules::RetroDisplayFormatter.format_list(retros)
          end
        end
      end
    end
  end
end
