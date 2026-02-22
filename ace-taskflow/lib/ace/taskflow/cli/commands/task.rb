# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../../commands/task_command"
require_relative "../shared_options"

module Ace
  module Taskflow
    module CLI
      module Commands
        # dry-cli Command class for the task command
        #
        # This handles the base "task" command cases:
        # - No arguments: Show next task
        # - Task reference: Show specific task
        #
        # All subcommands (create, show, start, done, etc.) are handled
        # by nested dry-cli commands in CLI::Commands::Task::* namespace.
        class Task < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Operations on single tasks

            SYNTAX:
              ace-taskflow task [REF]

            EXAMPLES:

              # Show next task
              $ ace-taskflow task

              # Show task by any reference format
              $ ace-taskflow task 114               # By number
              $ ace-taskflow task task.114          # Task ID format
              $ ace-taskflow task v.0.9.0+114      # Full reference

            SUBCOMMANDS:

              Use 'ace-taskflow task <subcommand> --help' for details:
              - create: Create new task
              - show: Show task details
              - start: Mark task as in-progress
              - done: Mark task as complete
              - undone: Reopen completed task
              - defer: Defer task to future
              - undefer: Restore deferred task
              - move: Move or reorganize task
              - update: Update task metadata
              - add-dependency: Add task dependency
              - remove-dependency: Remove task dependency
          DESC

          example [
            '                         # Show next task',
            '114                      # Show task by number',
            'task.114                 # Show task by ID format',
            'v.0.9.0+114              # Show task by full reference'
          ]

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          option :path, type: :boolean, desc: "Show only task file path"
          option :content, type: :boolean, desc: "Show full task content"
          option :tree, type: :boolean, desc: "Show dependency tree"

          def call(**options)
            args = options[:args] || []
            clean_options = options.reject { |k, _| k == :args }
            SharedOptions.convert_numeric_options(clean_options, *SharedOptions::NUMERIC_OPTIONS)

            command = ::Ace::Taskflow::Commands::TaskCommand.new(args, clean_options)
            command.execute
          end
        end
      end
    end
  end
end
