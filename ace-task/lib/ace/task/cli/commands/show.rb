# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Task
    module CLI
      module Commands
        # ace-support-cli Command class for ace-task show
        class Show < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc <<~DESC.strip
            Show task details

            Displays a task by reference (full ID like 8pp.t.q7w, short t.q7w, or suffix q7w).
          DESC

          example [
            "q7w                           # Show by suffix shortcut",
            "8pp.t.q7w                     # Show by full ID",
            "t.q7w                         # Show by short reference",
            "q7w --path                    # Print file path only",
            "q7w --content                 # Print raw markdown content",
            "q7w --in _overseer            # Show a task in the private overseer store",
            "q7w --tree                    # Show parent + subtask tree"
          ]

          argument :ref, required: true, desc: "Task reference (full ID, short ref, or suffix)"

          option :path, type: :boolean, desc: "Print file path only"
          option :content, type: :boolean, desc: "Print raw markdown content"
          option :tree, type: :boolean, desc: "Show parent + subtask tree view"

          option :root, type: :string, aliases: %w[-r], desc: "Exact task root directory (overrides project config)"
          option :in, type: :string, aliases: %w[-i], desc: "Task store selector (e.g. _overseer)"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref:, **options)
            config = Ace::Task::Molecules::TaskConfigLoader.load
            store_root = resolve_store_root(config, options[:in])
            if store_root && options[:root]
              raise Ace::Support::Cli::Error,
                "Cannot combine --root with store selector --in #{options[:in]}"
            end
            manager = if store_root
              Ace::Task::Organisms::TaskManager.new(root_dir: store_root, config: config)
            elsif options[:root]
              Ace::Task::Organisms::TaskManager.new(root_dir: File.expand_path(options[:root]))
            else
              Ace::Task::Organisms::TaskManager.new(config: config)
            end
            task = manager.show(ref)

            unless task
              raise Ace::Support::Cli::Error.new("Task '#{ref}' not found")
            end

            if options[:path]
              puts task.file_path
            elsif options[:content]
              puts File.read(task.file_path)
            else
              puts Molecules::TaskDisplayFormatter.format(task, show_content: false)
            end
          end

          private

          def resolve_store_root(config, store)
            return nil unless store

            root = Ace::Task::Molecules::TaskConfigLoader.store_root(config, store)
            return root if root

            raise Ace::Support::Cli::Error,
              "Unknown task store '#{store}'. Configure it under task.stores in .ace/task/config.yml"
          end
        end
      end
    end
  end
end
