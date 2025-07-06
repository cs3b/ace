# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/taskflow_management/task_manager"
require_relative "../../../atoms/project_root_detector"
require_relative "../../../molecules/taskflow_management/task_sort_engine"
require_relative "../../../molecules/taskflow_management/task_filter_engine"

module CodingAgentTools
  module Cli
    module Commands
      module Task
        # All command for listing all tasks with topological sorting
        class All < Dry::CLI::Command
          desc "List all tasks in current release with dependency order"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :show_cycles, type: :boolean, default: false,
            desc: "Show additional information about dependency cycles"

          option :sort, type: :string,
            desc: "Sort criteria (e.g., 'priority:desc,id:asc' or 'implementation-order')"

          option :filter, type: :array,
            desc: "Filter criteria (e.g., 'status:pending' or 'priority:!low')"

          example [
            "",
            "--debug",
            "--show-cycles",
            "--sort priority:desc,id:asc",
            "--filter status:pending --filter priority:high",
            "--sort implementation-order"
          ]

          def call(**options)
            # Use ProjectRootDetector for reliable path resolution
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            task_manager = CodingAgentTools::Organisms::TaskflowManagement::TaskManager.new(base_path: project_root)
            
            # Get all tasks first
            tasks_result = task_manager.get_all_tasks
            unless tasks_result.success?
              error_output("Error: #{tasks_result.message}")
              return 1
            end
            
            # Apply filtering if specified
            filter_strings = options[:filter] || []
            tasks = tasks_result.tasks
            if !filter_strings.empty?
              filter_result = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterEngine.apply_filter_strings(tasks, filter_strings)
              unless filter_result[:errors].empty?
                filter_result[:errors].each { |error| error_output("Filter error: #{error}") }
                return 1
              end
              tasks = filter_result[:tasks]
            end
            
            # Apply sorting (default to implementation-order)
            sort_string = options[:sort] || CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine.default_all_sort
            sort_result_hash = CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine.apply_sort_string(tasks, sort_string)
            unless sort_result_hash[:errors].empty?
              sort_result_hash[:errors].each { |error| error_output("Sort error: #{error}") }
              return 1
            end
            
            final_result = sort_result_hash[:result]
            handle_result(final_result, options)
            return 0
          rescue => e
            handle_error(e, options[:debug])
            return 1
          end

          private

          def handle_result(result, options)
            if result.sorted_tasks.empty?
              puts "No tasks found matching criteria"
              return
            end

            display_header(result, options)
            display_tasks(result.sorted_tasks)
            display_footer(result, options) if options[:show_cycles] || result.has_cycles?
          end

          def display_header(result, options)
            puts "All Tasks (#{result.sorted_tasks.size} total):"
            puts "=" * 50

            # Show sort/filter metadata if available
            if result.sort_metadata && !result.sort_metadata.empty?
              sort_type = result.sort_metadata[:sort_type] || "custom"
              puts colorize("ℹ️  Sorted by: #{sort_type}", :blue)
            end

            unless result.fully_sorted?
              if result.has_cycles?
                puts colorize("⚠️  WARNING: Dependency cycles detected!", :yellow)
                puts colorize("   #{result.sorted_count}/#{result.total_count} tasks sorted", :yellow)
              else
                puts colorize("ℹ️  Some tasks may have external dependencies", :blue)
              end
              puts ""
            end
          end

          def display_tasks(tasks)
            tasks.each_with_index do |task, index|
              puts "" if index > 0  # Add blank line between tasks
              display_task_info(task, index + 1)
            end
          end

          def display_task_info(task, position)
            status_color = status_color_for(task.status)
            status_display = colorize(task.status.upcase, status_color)

            puts "#{position.to_s.rjust(3)}. #{task.id}"
            puts "     Title: #{task.title || extract_title_from_content(task)}"
            puts "     Status: #{status_display}"
            puts "     Path: #{task.path}"

            if task.dependencies && !task.dependencies.empty?
              deps = task.dependencies.is_a?(Array) ? task.dependencies.join(", ") : task.dependencies
              puts "     Dependencies: #{deps}"
            end

            if task.respond_to?(:estimate) && task.estimate
              puts "     Estimate: #{task.estimate}"
            end

            if task.respond_to?(:priority) && task.priority
              priority_color = priority_color_for(task.priority)
              priority_display = colorize(task.priority.upcase, priority_color)
              puts "     Priority: #{priority_display}"
            end
          end

          def display_footer(result, options)
            if result.has_cycles?
              puts ""
              puts colorize("Dependency Cycle Information:", :red)
              puts colorize("  • #{result.sorted_count} tasks successfully sorted", :green)
              puts colorize("  • #{result.total_count - result.sorted_count} tasks in cycles", :red)
              puts colorize("  • Review task dependencies to resolve cycles", :yellow)
            end
          end

          def extract_title_from_content(task)
            # Try to extract title from content if not available in metadata
            return "Unknown" unless task.respond_to?(:content) && task.content

            # Look for first heading
            lines = task.content.split("\n")
            heading_line = lines.find { |line| line.start_with?("# ") }
            if heading_line
              heading_line.sub(/^# /, "").strip
            else
              "Unknown"
            end
          end

          def status_color_for(status)
            case status&.downcase
            when "done"
              :green
            when "in-progress"
              :blue
            when "pending"
              :yellow
            when "blocked"
              :red
            else
              :default
            end
          end

          def priority_color_for(priority)
            case priority&.downcase
            when "high"
              :red
            when "medium"
              :yellow
            when "low"
              :green
            else
              :default
            end
          end

          def colorize(text, color)
            # Simple colorization - can be enhanced with proper color support
            case color
            when :red
              "\e[31m#{text}\e[0m"
            when :green
              "\e[32m#{text}\e[0m"
            when :yellow
              "\e[33m#{text}\e[0m"
            when :blue
              "\e[34m#{text}\e[0m"
            else
              text
            end
          end

          def handle_error(error, debug_enabled)
            if debug_enabled
              error_output("Error: #{error.class.name}: #{error.message}")
              error_output("\nBacktrace:")
              error.backtrace.each { |line| error_output("  #{line}") }
            else
              error_output("Error: #{error.message}")
              error_output("Use --debug flag for more information")
            end
          end

          def error_output(message)
            warn message
          end
        end
      end
    end
  end
end
