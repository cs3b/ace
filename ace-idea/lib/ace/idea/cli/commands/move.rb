# frozen_string_literal: true

require "dry/cli"

module Ace
  module Idea
    module CLI
      module Commands
        # dry-cli Command class for ace-idea move
        class Move < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Move an idea to a different folder

            Relocates an idea to a special folder or back to root.

          DESC

          example [
            'q7w --to archive       # Move to _archive/',
            'q7w --to maybe         # Move to _maybe/',
            'q7w --to anytime       # Move to _anytime/',
            'q7w --to root          # Move back to root (no special folder)'
          ]

          argument :ref, required: true, desc: "Idea reference (6-char ID or 3-char shortcut)"

          option :to, type: :string, required: true, aliases: %w[-t], desc: "Target folder (archive, maybe, anytime, root)"

          option :quiet,   type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug,   type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref:, **options)
            to = options[:to]

            unless to
              raise Ace::Core::CLI::Error.new("--to FOLDER is required")
            end

            manager = Ace::Idea::Organisms::IdeaManager.new
            idea = manager.move(ref, to: to)

            unless idea
              raise Ace::Core::CLI::Error.new("Idea '#{ref}' not found")
            end

            folder_info = idea.special_folder || "root"
            puts "Idea moved: #{idea.id} → #{folder_info}"
            puts "  Path: #{idea.file_path}"
          end
        end
      end
    end
  end
end
