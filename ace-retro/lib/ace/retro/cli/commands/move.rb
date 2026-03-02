# frozen_string_literal: true

require "dry/cli"

module Ace
  module Retro
    module CLI
      module Commands
        # dry-cli Command class for ace-retro move
        class Move < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Move a retro to a different folder

            Relocates a retro to a special folder or back to root.

          DESC

          example [
            'q7w --to archive       # Move to _archive/',
            'q7w --to root          # Move back to root (no special folder)'
          ]

          argument :ref, required: true, desc: "Retro reference (6-char ID or 3-char shortcut)"

          option :to, type: :string, required: true, aliases: %w[-t], desc: "Target folder (archive, root)"

          option :git_commit, type: :boolean, aliases: %w[--gc], desc: "Auto-commit changes"

          option :quiet,   type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug,   type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref:, **options)
            to = options[:to]

            unless to
              raise Ace::Core::CLI::Error.new("--to FOLDER is required")
            end

            manager = Ace::Retro::Organisms::RetroManager.new
            retro = manager.move(ref, to: to)

            unless retro
              raise Ace::Core::CLI::Error.new("Retro '#{ref}' not found")
            end

            folder_info = retro.special_folder || "root"
            puts "Retro moved: #{retro.id} → #{folder_info}"
            puts "  Path: #{retro.file_path}"

            if options[:git_commit]
              Ace::Support::Items::Molecules::GitCommitter.commit(
                paths: [manager.root_dir],
                intention: "move retro #{retro.id} to #{folder_info}"
              )
            end
          end
        end
      end
    end
  end
end
