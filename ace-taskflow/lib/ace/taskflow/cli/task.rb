# frozen_string_literal: true

require "dry/cli"
require_relative "../commands/task_command"
require_relative "shared_options"

module Ace
  module Taskflow
    module CLI
      # dry-cli Command class for the task command
      #
      # This handles the base "task" command cases:
      # - No arguments: Show next task
      # - Task reference: Show specific task
      #
      # All subcommands (create, show, start, done, etc.) are now handled
      # by nested dry-cli commands in Commands::Task::* namespace.
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

          CONFIGURATION:

            Global config:  ~/.ace/taskflow/config.yml
            Project config: .ace/taskflow/config.yml
            Example:        ace-taskflow/.ace-defaults/taskflow/config.yml

          OUTPUT:

            Task details printed to stdout
            Exit codes: 0 (success), 1 (error)

          TASK REFERENCE SYSTEM:

            Tasks can be referenced by multiple formats:
            114           → Task number in current release
            task.114      → Task ID format
            v.0.9.0+114  → Full task reference

            ace-taskflow handles resolution automatically
        DESC

        example [
          '                         # Show next task',
          '114                      # Show task by number',
          'task.114                 # Show task by ID format',
          'v.0.9.0+114              # Show task by full reference',
          'create "Add caching"     # Create new task (nested command)',
          'done 114                 # Mark task as complete (nested command)',
          'start 114                # Mark task as in-progress (nested command)'
        ]

        # Standard options (inherited from Base but need explicit definition for dry-cli)
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        # Display mode options
        option :path, type: :boolean, desc: "Show only task file path"
        option :content, type: :boolean, desc: "Show full task content"
        option :tree, type: :boolean, desc: "Show dependency tree"

        def call(**options)
          # Remaining arguments are in options[:args]
          args = options[:args] || []

          # Remove dry-cli specific keys and convert numeric options
          clean_options = options.reject { |k, _| k == :args }
          SharedOptions.convert_numeric_options(clean_options, *SharedOptions::NUMERIC_OPTIONS)

          # Use the existing TaskCommand logic
          command = Commands::TaskCommand.new(args, clean_options)
          command.execute
        end
      end
    end
  end
end
