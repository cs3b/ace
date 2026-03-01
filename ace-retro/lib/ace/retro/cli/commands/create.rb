# frozen_string_literal: true

require "dry/cli"

module Ace
  module Retro
    module CLI
      module Commands
        # dry-cli Command class for ace-retro create
        class Create < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Create a new retro

            Creates a new retrospective with title, type, tags, and optional task linkage.

          DESC

          example [
            '"Sprint Review" --type standard --tags sprint,team        # Standard retro',
            '"Quick self-review" --type self-review                    # Self-review retro',
            '"Sprint Review" --task-ref q7w                            # Link to task',
            '"Sprint Review" --move-to archive                        # Create in _archive/',
            '"Sprint Review" --dry-run                                # Preview without writing'
          ]

          argument :title, required: false, desc: "Retro title"

          option :type,      type: :string,  aliases: %w[-t], desc: "Retro type (standard, conversation-analysis, self-review)"
          option :tags,      type: :string,  aliases: %w[-T], desc: "Comma-separated tags"
          option :"task-ref", type: :string,  aliases: %w[-r], desc: "Link to task reference"
          option :"move-to", type: :string,  aliases: %w[-m], desc: "Target folder (e.g. archive)"
          option :"dry-run", type: :boolean, aliases: %w[-n], desc: "Preview without writing"

          option :quiet,   type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug,   type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(title: nil, **options)
            type     = options[:type]
            tags_str = options[:tags]
            task_ref = options[:"task-ref"]
            move_to  = options[:"move-to"]
            dry_run  = options[:"dry-run"]

            tags = tags_str ? tags_str.split(",").map(&:strip).reject(&:empty?) : []

            unless title
              warn "Error: title is required"
              warn ""
              warn "Usage: ace-retro create TITLE [--type TYPE] [--tags T1,T2] [--task-ref REF] [--move-to FOLDER]"
              raise Ace::Core::CLI::Error.new("Title required")
            end

            if dry_run
              puts "Would create retro:"
              puts "  Title:    #{title}"
              puts "  Type:     #{type || 'standard'}"
              puts "  Tags:     #{tags.any? ? tags.join(', ') : '(none)'}"
              puts "  Task ref: #{task_ref || '(none)'}"
              puts "  Folder:   #{move_to ? "_#{move_to.delete_prefix('_')}" : '(root)'}"
              return
            end

            manager = Ace::Retro::Organisms::RetroManager.new
            retro = manager.create(
              title,
              type: type,
              tags: tags,
              task_ref: task_ref,
              move_to: move_to
            )

            folder_info = retro.special_folder ? " (#{retro.special_folder})" : ""
            puts "Retro created: #{retro.id} #{retro.title}#{folder_info}"
            puts "  Path: #{retro.file_path}"
          end
        end
      end
    end
  end
end
