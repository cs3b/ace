# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Pure logic for formatting task display
      # Unit testable - no I/O
      class TaskDisplayFormatter
        # Map status to emoji icon
        # @param status [String] Task status
        # @return [String] Status emoji
        def self.status_icon(status)
          case status.to_s.downcase
          when "draft" then "⚫"
          when "pending" then "⚪"
          when "in-progress" then "🟡"
          when "done" then "🟢"
          when "blocked", "skipped" then "🔴"
          else "?"
          end
        end

        # Format a task line for display
        # @param task [Hash] Task data
        # @param options [Hash] Display options
        # @return [String] Formatted task line
        def self.format_task_line(task, options = {})
          status_str = status_icon(task[:status])
          ref = task[:qualified_reference] || task[:task_number] || task[:id]
          title = task[:title] || "Untitled"

          "  #{ref.ljust(15)} #{status_str} #{title}"
        end

        # Format task details (estimate, dependencies)
        # @param task [Hash] Task data
        # @return [String, nil] Formatted details or nil if none
        def self.format_task_details(task)
          details = []

          if task[:estimate] && task[:estimate] != "TBD"
            details << "Estimate: #{task[:estimate]}"
          end

          unless task[:dependencies].to_a.empty?
            details << "Dependencies: #{task[:dependencies].join(', ')}"
          end

          return nil if details.empty?
          "    #{details.join(' | ')}"
        end

        # Format task as simple list item
        # @param task [Hash] Task data
        # @return [String] Simple list format
        def self.format_list_item(task)
          ref = task[:task_number] || task[:id]
          title = task[:title] || "Untitled"
          "#{ref} #{title}"
        end

        # Group tasks by context
        # @param tasks [Array<Hash>] Tasks to group
        # @return [Hash] Tasks grouped by context
        def self.group_by_context(tasks)
          tasks.group_by { |t| t[:context] || "unknown" }
        end

        # Format grouped tasks for display
        # @param grouped_tasks [Hash] Tasks grouped by context
        # @param formatter [Symbol] Format type (:line, :list)
        # @return [String] Formatted output
        def self.format_grouped(grouped_tasks, formatter = :line)
          output = []

          grouped_tasks.each do |context, context_tasks|
            output << ""
            output << "#{context}:"
            context_tasks.each do |task|
              case formatter
              when :line
                output << format_task_line(task)
              when :list
                output << "  #{format_list_item(task)}"
              end
            end
          end

          output.join("\n")
        end

        # Format full task details for content display
        # @param task [Hash] Task data
        # @return [String] Full task details
        def self.format_full_task(task)
          output = []

          output << "Task: #{task[:id] || task[:task_number]}"
          output << "Title: #{task[:title]}"
          output << "Status: #{status_icon(task[:status])} #{task[:status]}"
          output << "Priority: #{task[:priority]}"
          output << "Estimate: #{task[:estimate] || 'TBD'}"

          unless task[:dependencies].to_a.empty?
            output << "Dependencies: #{task[:dependencies].join(', ')}"
          end

          if task[:path]
            output << "Path: #{task[:path]}"
          end

          output << ""
          output << "--- Content ---"
          output << task[:content] if task[:content]

          output.join("\n")
        end

        # Format task path only
        # @param task [Hash] Task data
        # @param root_path [String] Root path for relative display
        # @return [String] Relative path or error message
        def self.format_task_path(task, root_path = Dir.pwd)
          if task[:path]
            # Calculate relative path
            require_relative "../atoms/path_formatter"
            Atoms::PathFormatter.format_relative_path(task[:path], root_path)
          else
            "# Task has no path"
          end
        end

        # Format success confirmation with timestamp
        # @param message [String] Success message
        # @param action [String] Action performed ("Started", "Completed")
        # @return [String] Formatted confirmation
        def self.format_confirmation(message, action)
          timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
          "#{message}\n#{action} at: #{timestamp}"
        end
      end
    end
  end
end
