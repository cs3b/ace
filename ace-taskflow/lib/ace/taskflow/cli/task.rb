# frozen_string_literal: true

require "dry/cli"
require_relative "../commands/task_command"
require_relative "shared_options"

module Ace
  module Taskflow
    module CLI
      # dry-cli Command class for the task command
      #
      # This wraps the existing TaskCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class Task < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Operations on single tasks

          SYNTAX:
            ace-taskflow task [REF] [ACTION] [ARGS]

          EXAMPLES:

            # Show next task
            $ ace-taskflow task

            # Show task by any reference format
            $ ace-taskflow task 114               # By number
            $ ace-taskflow task task.114          # Task ID format
            $ ace-taskflow task v.0.9.0+114      # Full reference

            # Mark task as done
            $ ace-taskflow task done 114

            # Show task status
            $ ace-taskflow task status 114

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
          'done 114                 # Mark task as complete',
          'start 114                # Mark task as in-progress',
          'create "Add caching"     # Create new task',
          'move 114 --child-of 112  # Move task as subtask'
        ]

        # Standard options (inherited from Base but need explicit definition for dry-cli)
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        # Class options that are passed through to TaskCommand
        option :json, type: :boolean, desc: "Output as JSON"
        option :markdown, type: :boolean, desc: "Output as Markdown (default)"
        option :status, type: :string, desc: "Filter by status"
        option :stats, type: :boolean, desc: "Show statistics"
        option :tree, type: :boolean, desc: "Show tree structure"
        option :format, type: :string, desc: "Output format"
        option :limit, type: :integer, desc: "Limit results"
        option :all, type: :boolean, desc: "Show all items"
        option :recently_done_limit, type: :integer, desc: "Max recently done tasks to show"
        option :up_next_limit, type: :integer, desc: "Max up next tasks to show"
        option :include_drafts, type: :boolean, desc: "Include draft tasks in Up Next"
        option :include_activity, type: :boolean, desc: "Include task activity section"
        option :output, type: :string, aliases: %w[-o], desc: "Output file path"

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
