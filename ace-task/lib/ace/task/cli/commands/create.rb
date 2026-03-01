# frozen_string_literal: true

require "dry/cli"

module Ace
  module Task
    module CLI
      module Commands
        # dry-cli Command class for ace-task create
        class Create < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Create a new task

            Creates a new task with a B36TS-based type-marked ID (xxx.t.yyy).
          DESC

          example [
            '"Fix login bug"                              # Create task with title',
            '"Fix auth" --priority high --tags auth,security  # With priority and tags',
            '"Setup DB" --child-of q7w                    # Create as subtask',
            '"Quick task" --in next                       # Create in _next/ folder',
            '"Preview only" --dry-run                     # Show what would be created'
          ]

          argument :title, required: true, desc: "Task title"

          option :priority,   type: :string,  aliases: %w[-p], desc: "Priority (critical, high, medium, low)"
          option :tags,       type: :string,  aliases: %w[-T], desc: "Tags (comma-separated)"
          option :"child-of", type: :string,  desc: "Parent task reference (creates subtask)"
          option :in,         type: :string,  aliases: %w[-i], desc: "Target folder (e.g. next, maybe)"
          option :"dry-run",  type: :boolean, aliases: %w[-n], desc: "Preview without writing"

          option :quiet,   type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug,   type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(title:, **options)
            dry_run   = options[:"dry-run"]
            priority  = options[:priority]
            tags_str  = options[:tags]
            tags      = tags_str ? tags_str.split(",").map(&:strip).reject(&:empty?) : []
            child_of  = options[:"child-of"]
            in_folder = options[:in]

            if dry_run
              puts "Would create task:"
              puts "  Title:    #{title}"
              puts "  Priority: #{priority}" if priority
              puts "  Tags:     #{tags.join(', ')}" if tags.any?
              puts "  Parent:   #{child_of}" if child_of
              puts "  Folder:   #{in_folder}" if in_folder
              return
            end

            manager = Ace::Task::Organisms::TaskManager.new

            task = if child_of
              manager.create_subtask(child_of, title, priority: priority, tags: tags)
            else
              manager.create(title, priority: priority, tags: tags)
            end

            unless task
              raise Ace::Core::CLI::Error.new("Parent task '#{child_of}' not found") if child_of
              raise Ace::Core::CLI::Error.new("Failed to create task")
            end

            # Move to folder if specified
            if in_folder && !child_of
              task = manager.move(task.id, to: in_folder)
            end

            puts "Created task #{task.id}"
            puts "  Path: #{task.file_path}"
          end
        end
      end
    end
  end
end
