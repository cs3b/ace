# frozen_string_literal: true

require "dry/cli"

module Ace
  module Task
    module CLI
      module Commands
        # dry-cli Command class for ace-task move
        class Move < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Move a task to a different folder

            Relocates a task to a special folder or back to root.
          DESC

          example [
            'q7w --to archive       # Move to _archive/',
            'q7w --to maybe         # Move to _maybe/',
            'q7w --to anytime       # Move to _anytime/',
            'q7w --to root          # Move back to root (no special folder)'
          ]

          argument :ref, required: true, desc: "Task reference (full ID, short ref, or suffix)"

          option :to, type: :string, required: true, aliases: %w[-t], desc: "Target folder (archive, maybe, anytime, root)"

          option :git_commit, type: :boolean, aliases: %w[--gc], desc: "Auto-commit changes"

          option :quiet,   type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug,   type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref:, **options)
            to = options[:to]

            unless to
              raise Ace::Core::CLI::Error.new("--to FOLDER is required")
            end

            manager = Ace::Task::Organisms::TaskManager.new
            task = manager.move(ref, to: to)

            unless task
              raise Ace::Core::CLI::Error.new("Task '#{ref}' not found")
            end

            folder_info = task.special_folder || "root"
            puts "Task moved: #{task.id} → #{folder_info}"
            puts "  Path: #{task.file_path}"

            if options[:git_commit]
              Ace::Support::Items::Molecules::GitCommitter.commit(
                paths: [manager.root_dir],
                intention: "move task #{task.id} to #{folder_info}"
              )
            end
          end
        end
      end
    end
  end
end
