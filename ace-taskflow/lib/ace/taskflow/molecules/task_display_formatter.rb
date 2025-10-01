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
      end
    end
  end
end
