# frozen_string_literal: true

require_relative "../organisms/task_manager"
require_relative "../models/task"

module Ace
  module Taskflow
    module Commands
      # Handle task subcommand
      class TaskCommand
        def initialize
          @manager = Organisms::TaskManager.new
        end

        def execute(args)
          subaction = args.shift

          case subaction
          when nil, "next"
            show_next_task(args)
          when "create"
            create_task(args)
          when "start"
            start_task(args)
          when "done"
            complete_task(args)
          when "move"
            move_task(args)
          when "update"
            update_task(args)
          when "--help", "-h"
            show_help
          else
            # Try to show specific task
            show_task(subaction)
          end
        rescue StandardError => e
          puts "Error: #{e.message}"
          exit 1
        end

        private

        def show_next_task(args)
          context = parse_context(args)
          task = @manager.get_next_task(context: context)

          if task
            display_task(task)
          else
            puts "No pending or in-progress tasks found."
            puts "Use 'ace-taskflow task create' to add a new task."
          end
        end

        def show_task(reference)
          task = @manager.show_task(reference)

          if task
            display_task(task)
          else
            puts "Task '#{reference}' not found."
            puts "Valid formats: 018, task.018, v.0.9.0+018, backlog+025"
            exit 1
          end
        end

        def create_task(args)
          # Parse options
          title_parts = []
          context = "current"

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--backlog"
              context = "backlog"
              i += 1
            when "--release"
              context = args[i + 1]
              i += 2
            else
              title_parts << arg
              i += 1
            end
          end

          title = title_parts.join(" ")

          if title.empty?
            puts "Usage: ace-taskflow task create <title> [options]"
            puts "Options:"
            puts "  --backlog          Create in backlog"
            puts "  --release <name>   Create in specific release"
            exit 1
          end

          result = @manager.create_task(title, context: context)

          if result[:success]
            puts result[:message]
            puts "Path: #{result[:path]}"
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def start_task(args)
          reference = args.first

          unless reference
            puts "Usage: ace-taskflow task start <reference>"
            puts "Example: ace-taskflow task start 019"
            exit 1
          end

          result = @manager.start_task(reference)

          if result[:success]
            puts result[:message]
            puts "Started at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def complete_task(args)
          reference = args.first

          unless reference
            puts "Usage: ace-taskflow task done <reference>"
            puts "Example: ace-taskflow task done 019"
            exit 1
          end

          result = @manager.complete_task(reference)

          if result[:success]
            puts result[:message]
            puts "Completed at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def move_task(args)
          reference = args[0]
          target = args[1]

          unless reference && target
            puts "Usage: ace-taskflow task move <reference> <target>"
            puts "Examples:"
            puts "  ace-taskflow task move 019 backlog"
            puts "  ace-taskflow task move backlog+025 v.0.10.0"
            exit 1
          end

          result = @manager.move_task(reference, target)

          if result[:success]
            puts result[:message]
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def update_task(args)
          reference = args.first

          unless reference
            puts "Usage: ace-taskflow task update <reference>"
            puts "Note: This command is not yet implemented"
            exit 1
          end

          puts "Task update functionality coming soon"
          exit 0
        end

        def display_task(task_data)
          task = Models::Task.new(task_data)

          puts "Task: #{task.id || task.task_number}"
          puts "Title: #{task.title}"
          puts "Status: #{status_icon(task.status)} #{task.status}"
          puts "Priority: #{task.priority}"
          puts "Estimate: #{task.estimate || 'TBD'}"

          unless task.dependencies.empty?
            puts "Dependencies: #{task.dependencies.join(', ')}"
          end

          if task.path
            puts "Path: #{task.path}"
          end

          puts ""
          puts "--- Content ---"
          puts task.content if task.content
        end

        def status_icon(status)
          case status.to_s.downcase
          when "done" then "✓"
          when "in-progress" then "⚡"
          when "pending" then "○"
          when "blocked" then "⊘"
          else "?"
          end
        end

        def parse_context(args)
          args.each_with_index do |arg, index|
            case arg
            when "--backlog"
              return "backlog"
            when "--release"
              return args[index + 1]
            when "--current"
              return "current"
            end
          end
          "current"
        end

        def show_help
          puts "Usage: ace-taskflow task [subcommand] [options]"
          puts ""
          puts "Subcommands:"
          puts "  (none)             Show next task from active release"
          puts "  <reference>        Show specific task"
          puts "  create <title>     Create new task"
          puts "    --backlog        Create in backlog"
          puts "    --release <name> Create in specific release"
          puts "  start <reference>  Mark task as in-progress"
          puts "  done <reference>   Mark task as completed"
          puts "  move <ref> <target> Move task to different context"
          puts "  update <reference> Update task metadata"
          puts ""
          puts "Reference formats:"
          puts "  018               Task in current context"
          puts "  task.018          Task in current context"
          puts "  v.0.9.0+018       Task from specific release"
          puts "  backlog+025       Task from backlog"
          puts "  current+018       Explicit current/active"
          puts ""
          puts "Examples:"
          puts "  ace-taskflow task"
          puts "  ace-taskflow task 019"
          puts "  ace-taskflow task create 'Add caching layer'"
          puts "  ace-taskflow task start 019"
          puts "  ace-taskflow task done 019"
          puts "  ace-taskflow task move backlog+025 v.0.10.0"
        end
      end
    end
  end
end