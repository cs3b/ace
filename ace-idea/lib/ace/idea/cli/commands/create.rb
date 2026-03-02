# frozen_string_literal: true

require "dry/cli"

module Ace
  module Idea
    module CLI
      module Commands
        # dry-cli Command class for ace-idea create
        class Create < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Create a new idea

            Captures a new idea with optional title, tags, and folder placement.
            Content can be provided as a positional argument or via --clipboard.

          DESC

          example [
            '"Dark mode for night coding"                          # Basic capture',
            '"Dark mode" --title "Dark mode" --tags ux,design      # With metadata',
            '"raw thought" --move-to maybe                         # Place in _maybe/',
            '--clipboard --llm-enhance --move-to maybe             # From clipboard with LLM',
            '"rough idea" --dry-run                                # Preview without writing'
          ]

          argument :content, required: false, desc: "Idea content (positional)"

          option :title,       type: :string,  aliases: %w[-t],   desc: "Explicit title"
          option :tags,        type: :string,  aliases: %w[-T],   desc: "Comma-separated tags"
          option :"move-to",   type: :string,  aliases: %w[-m],   desc: "Target folder (e.g. next, maybe, archive)"
          option :clipboard,   type: :boolean, aliases: %w[-c],   desc: "Capture content from clipboard"
          option :"llm-enhance", type: :boolean, aliases: %w[-l], desc: "Enhance content with LLM"
          option :"dry-run",   type: :boolean, aliases: %w[-n],   desc: "Preview without writing"

          option :quiet,   type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug,   type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(content: nil, **options)
            clipboard  = options[:clipboard]
            llm_enhance = options[:"llm-enhance"]
            move_to    = options[:"move-to"]
            title      = options[:title]
            tags_str   = options[:tags]
            dry_run    = options[:"dry-run"]

            # Parse tags from comma-separated string
            tags = tags_str ? tags_str.split(",").map(&:strip).reject(&:empty?) : []

            # Require content or clipboard
            if content.nil? && !clipboard
              warn "Error: provide content or --clipboard"
              warn ""
              warn "Usage: ace-idea create [CONTENT] [--clipboard] [--title T] [--tags T1,T2] [--move-to FOLDER]"
              raise Ace::Core::CLI::Error.new("Content or --clipboard required")
            end

            if dry_run
              puts "Would create idea:"
              puts "  Content:  #{content || '(from clipboard)'}"
              puts "  Title:    #{title || '(auto-generated)'}"
              puts "  Tags:     #{tags.any? ? tags.join(', ') : '(none)'}"
              puts "  Folder:   #{move_to ? "_#{move_to.delete_prefix('_')}" : '(root)'}"
              puts "  LLM:      #{llm_enhance ? 'yes' : 'no'}"
              return
            end

            manager = Ace::Idea::Organisms::IdeaManager.new
            idea = manager.create(
              content,
              title: title,
              tags: tags,
              move_to: move_to,
              clipboard: clipboard || false,
              llm_enhance: llm_enhance || false
            )

            folder_info = idea.special_folder ? " (#{idea.special_folder})" : ""
            puts "Idea created: #{idea.id} #{idea.title}#{folder_info}"
            puts "  Path: #{idea.file_path}"
          end
        end
      end
    end
  end
end
