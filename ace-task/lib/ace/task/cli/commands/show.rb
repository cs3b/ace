# frozen_string_literal: true

require "dry/cli"

module Ace
  module Task
    module CLI
      module Commands
        # dry-cli Command class for ace-task show
        class Show < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Show task details

            Displays a task by reference (full ID like 8pp.t.q7w, short t.q7w, or suffix q7w).
          DESC

          example [
            'q7w                           # Show by suffix shortcut',
            '8pp.t.q7w                     # Show by full ID',
            't.q7w                         # Show by short reference',
            'q7w --path                    # Print file path only',
            'q7w --content                 # Print raw markdown content',
            'q7w --tree                    # Show parent + subtask tree'
          ]

          argument :ref, required: true, desc: "Task reference (full ID, short ref, or suffix)"

          option :path,    type: :boolean, desc: "Print file path only"
          option :content, type: :boolean, desc: "Print raw markdown content"
          option :tree,    type: :boolean, desc: "Show parent + subtask tree view"

          option :quiet,   type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug,   type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref:, **options)
            manager = Ace::Task::Organisms::TaskManager.new
            task = manager.show(ref)

            unless task
              raise Ace::Core::CLI::Error.new("Task '#{ref}' not found")
            end

            if options[:path]
              puts task.file_path
            elsif options[:content]
              puts File.read(task.file_path)
            else
              puts Molecules::TaskDisplayFormatter.format(task, show_content: false)
            end
          end
        end
      end
    end
  end
end
