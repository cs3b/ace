# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/task_manager"
require_relative "../../../models/task"
require_relative "../../../atoms/path_formatter"

module Ace
  module Taskflow
    module CLI
      module Commands
        module TaskSubcommands
          # dry-cli Command class for task show nested subcommand
          #
          # Displays task details in various formats.
          class Show < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Show task details

              Displays a task by reference with optional formatting modes.
              Reference formats: 018, task.018, v.0.9.0+018, backlog+025

            DESC

            example [
              '187                    # Show task 187 in formatted view',
              '187 --path             # Show only file path',
              '187 --content          # Show full task content',
              '187 --tree             # Show dependency tree'
            ]

            argument :task_ref, required: true, desc: "Task reference (number, ID, or full reference)"

            option :path, type: :boolean, desc: "Show only task file path"
            option :content, type: :boolean, desc: "Show full task content"
            option :tree, type: :boolean, desc: "Show dependency tree"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(task_ref:, **options)
              # Display config summary unless quiet mode
              display_config_summary(options) unless quiet?(options)

              # Determine display mode
              display_mode = determine_display_mode(options)

              # Call TaskManager
              manager = Ace::Taskflow::Organisms::TaskManager.new
              task = manager.show_task(task_ref)

              unless task
                puts "Valid formats: 018, task.018, v.0.9.0+018, backlog+025"
                raise Ace::Core::CLI::Error.new("Task '#{task_ref}' not found.")
              end

              display_task(task, display_mode)
            end

            private

            # Display config summary
            def display_config_summary(options)
              return unless verbose?(options)

              Ace::Core::Atoms::ConfigSummary.display(
                command: "task show",
                config: Ace::Taskflow.config,
                defaults: Ace::Taskflow.default_config,
                options: options,
                summary_keys: %w[current_release task_dir]
              )
            end

            # Determine display mode from options
            def determine_display_mode(options)
              if options[:path]
                "path"
              elsif options[:content]
                "content"
              elsif options[:tree]
                "tree"
              else
                "formatted"
              end
            end

            # Display task in specified format
            def display_task(task_data, display_mode)
              case display_mode
              when "path"
                display_path(task_data)
              when "content"
                display_content(task_data)
              when "tree"
                display_tree(task_data)
              else
                display_formatted(task_data)
              end
            end

            # Display only the file path
            def display_path(task_data)
              task = Ace::Taskflow::Models::Task.new(task_data)
              if task.path
                root_path = Dir.pwd
                relative_path = Ace::Taskflow::Atoms::PathFormatter.format_relative_path(task.path, root_path)
                puts relative_path
              else
                raise Ace::Core::CLI::Error.new("Task has no path")
              end
            end

            # Display full task content
            def display_content(task_data)
              task = Ace::Taskflow::Models::Task.new(task_data)

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

            # Display formatted task
            def display_formatted(task_data)
              task = Ace::Taskflow::Models::Task.new(task_data)

              status_str = status_icon(task.status)
              ref = task.qualified_reference || task.task_number || task.id
              display_title = strip_task_id_from_title(task.title)
              orchestrator_marker = task_data[:is_orchestrator] && !display_title.include?("Orchestrator") ? " (Orchestrator)" : ""

              puts "Task: #{ref} #{status_str} #{display_title}#{orchestrator_marker}"

              # Show path on second line
              if task.path
                relative_path = format_relative_path(task.path)
                puts "  Path: #{relative_path}"
              end

              # Combine estimate and dependencies on one line if both present
              details = []
              details << "Estimate: #{task.estimate}" if task.estimate && task.estimate != "TBD"
              details << "Dependencies: #{task.dependencies.join(', ')}" unless task.dependencies.empty?

              if details.any?
                puts "  #{details.join(' | ')}"
              end

              # Show subtasks for orchestrator tasks
              if task_data[:is_orchestrator] || task_data[:subtask_ids]&.any?
                display_subtasks(task_data)
              end
            end

            # Display dependency tree
            def display_tree(task_data)
              require_relative "../../../molecules/dependency_tree_visualizer"
              require_relative "../../../molecules/dependency_resolver"

              task = Ace::Taskflow::Models::Task.new(task_data)
              ref = task.qualified_reference || task.task_number || task.id

              puts "Task: #{ref} - #{task.title}"
              puts ""

              # Get all tasks to check dependencies
              manager = Ace::Taskflow::Organisms::TaskManager.new
              all_tasks = manager.list_tasks(release: "all")

              # Generate dependency tree
              tree_output = Ace::Taskflow::Molecules::DependencyTreeVisualizer.generate_task_tree(task.id, all_tasks)
              puts tree_output

              # Show blocking information if dependencies exist
              if task.dependencies && !task.dependencies.empty?
                puts ""
                blocking_tasks = Ace::Taskflow::Molecules::DependencyResolver.get_blocking_tasks(task_data, all_tasks)
                if blocking_tasks.any?
                  puts "Blocked by: #{blocking_tasks.map { |t| t[:task_number] || t[:id] }.join(', ')}"
                else
                  puts "All dependencies met - ready to start"
                end
              end
            end

            # Display subtasks for orchestrator
            def display_subtasks(orchestrator_data)
              subtask_ids = orchestrator_data[:subtask_ids] || []
              return if subtask_ids.empty?

              # Load subtasks
              manager = Ace::Taskflow::Organisms::TaskManager.new
              subtasks = subtask_ids.map do |subtask_id|
                manager.show_task(subtask_id)
              end.compact

              return if subtasks.empty?

              puts "  Subtasks:"
              subtasks.sort_by { |s| s[:id] || "" }.each_with_index do |subtask, idx|
                connector = idx == subtasks.length - 1 ? "└─" : "├─"
                status_str = status_icon(subtask[:status])
                ref = subtask[:id] || subtask[:task_number] || "unknown"
                display_title = strip_task_id_from_title(subtask[:title])
                puts "    #{connector} #{ref} #{status_str} #{display_title}"
              end
            end

            # Format relative path
            def format_relative_path(path)
              root_path = Dir.pwd
              Ace::Taskflow::Atoms::PathFormatter.format_relative_path(path, root_path)
            end

            # Status icon
            def status_icon(status)
              case status.to_s.downcase
              when "draft" then "⚫"
              when "pending" then "⚪"
              when "in-progress" then "🟡"
              when "done" then "🟢"
              when "blocked", "skipped" then "🔴"
              else "?"
              end
            end

            # Strip task ID from title
            def strip_task_id_from_title(title)
              title.to_s.sub(/^#\d+\s*/, "")
            end
          end
        end
      end
    end
  end
end
