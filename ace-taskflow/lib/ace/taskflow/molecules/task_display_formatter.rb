# frozen_string_literal: true

require_relative "../atoms/task_reference_parser"

module Ace
  module Taskflow
    module Molecules
      # Pure logic for formatting task display
      # Unit testable - no I/O
      class TaskDisplayFormatter
        # Time constants for format_relative_time
        SECONDS_PER_MINUTE = 60
        MINUTES_PER_HOUR = 60
        HOURS_PER_DAY = 24
        DAYS_PER_MONTH = 30  # Approximate
        MONTHS_PER_YEAR = 12

        # Empty state messages for activity sections (consistency and i18n-readiness)
        NO_RECENTLY_DONE = "No recently completed tasks"
        NO_IN_PROGRESS = "No other tasks in progress"
        NO_PENDING = "No pending tasks"

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

        # Group tasks by release
        # @param tasks [Array<Hash>] Tasks to group
        # @return [Hash] Tasks grouped by release
        def self.group_by_release(tasks)
          tasks.group_by { |t| t[:release] || "unknown" }
        end

        # Format grouped tasks for display
        # @param grouped_tasks [Hash] Tasks grouped by release
        # @param formatter [Symbol] Format type (:line, :list)
        # @return [String] Formatted output
        def self.format_grouped(grouped_tasks, formatter = :line)
          output = []

          grouped_tasks.each do |release, release_tasks|
            output << ""
            output << "#{release}:"
            release_tasks.each do |task|
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

        # Format a time as relative duration (e.g., "2h ago", "1d ago", "just now")
        # @param time [Time] Time to format
        # @param reference_time [Time] Reference time (default: Time.now)
        # @return [String] Relative time string
        def self.format_relative_time(time, reference_time = Time.now)
          return "unknown" if time.nil?
          return "unknown" unless time.is_a?(Time)

          seconds = (reference_time - time).to_i
          # Handle future times or negative values as "just now"
          return "just now" if seconds < SECONDS_PER_MINUTE

          minutes = seconds / SECONDS_PER_MINUTE
          return "#{minutes}m ago" if minutes < MINUTES_PER_HOUR

          hours = minutes / MINUTES_PER_HOUR
          return "#{hours}h ago" if hours < HOURS_PER_DAY

          days = hours / HOURS_PER_DAY
          return "#{days}d ago" if days < DAYS_PER_MONTH

          months = days / DAYS_PER_MONTH
          return "#{months}mo ago" if months < MONTHS_PER_YEAR

          years = months / MONTHS_PER_YEAR
          "#{years}y ago"
        end

        # Format task activity section for context display
        # @param activity [Hash] Activity data from TaskActivityAnalyzer
        #   - :recently_done [Array<Hash>] Recently completed tasks
        #   - :in_progress [Array<Hash>] Currently in-progress tasks (excluding current)
        #   - :up_next [Array<Hash>] Pending tasks coming next
        # @param options [Hash] Formatting options
        #   - :show_time [Boolean] Include relative time for done tasks (default: true)
        #   - :show_worktree [Boolean] Mark tasks with active worktrees (default: true)
        #   - :skip_recently_done [Boolean] Skip Recently Done section entirely (default: false)
        #   - :skip_up_next [Boolean] Skip Up Next section entirely (default: false)
        # @return [String] Formatted markdown section
        def self.format_activity_section(activity, options = {})
          return "" if activity.nil?

          show_time = options.fetch(:show_time, true)
          show_worktree = options.fetch(:show_worktree, true)
          skip_recently_done = options.fetch(:skip_recently_done, false)
          skip_up_next = options.fetch(:skip_up_next, false)
          lines = []

          lines << "## Task Activity"
          lines << ""

          # Recently Done section (skip if limit was 0)
          unless skip_recently_done
            lines << "### Recently Done"
            recently_done = activity[:recently_done] || []
            if recently_done.empty?
              lines << NO_RECENTLY_DONE
            else
              recently_done.each do |task|
                line = format_activity_task_line(task, show_time: show_time, show_worktree: show_worktree)
                lines << "- #{line}"
              end
            end
            lines << ""
          end

          # In Progress section (always shown - no limit option for this)
          lines << "### In Progress"
          in_progress = activity[:in_progress] || []
          if in_progress.empty?
            lines << NO_IN_PROGRESS
          else
            in_progress.each do |task|
              line = format_activity_task_line(task, show_time: false, show_worktree: show_worktree)
              lines << "- #{line}"
            end
          end
          lines << ""

          # Up Next section (skip if limit was 0)
          unless skip_up_next
            lines << "### Up Next"
            up_next = activity[:up_next] || []
            if up_next.empty?
              lines << NO_PENDING
            else
              up_next.each do |task|
                line = format_activity_task_line(task, show_time: false, show_worktree: false)
                lines << "- #{line}"
              end
            end
          end

          lines.join("\n")
        end

        # Format a single task line for activity display
        # @param task [Hash] Task data (expects :completed_at for done tasks)
        # @param show_time [Boolean] Include relative time
        # @param show_worktree [Boolean] Include worktree indicator
        # @return [String] Formatted task line
        def self.format_activity_task_line(task, show_time: false, show_worktree: false)
          # Extract task number from ID (e.g., "v.0.9.0+task.140.02" -> "140.02")
          task_ref = extract_task_number(task[:id]) || task[:id]
          title = task[:title] || "Untitled"

          parts = ["#{task_ref}: #{title}"]

          # Add relative time for done tasks (uses :completed_at from TaskActivityAnalyzer)
          if show_time && task[:completed_at]
            parts << "(done #{format_relative_time(task[:completed_at])})"
          end

          # Add worktree indicator
          if show_worktree && has_worktree?(task)
            parts << "(@worktree)"
          end

          parts.join(" ")
        end

        # Check if task has an active worktree
        # @param task [Hash] Task data
        # @return [Boolean] True if task has worktree metadata
        def self.has_worktree?(task)
          # Check for worktree data at top level or nested in metadata
          worktree_data = task[:worktree] || task.dig(:metadata, :worktree)
          worktree_data.is_a?(Hash) && !worktree_data.empty?
        end

        # Extract task number from a full canonical task ID
        # Delegates to TaskReferenceParser for consistent parsing
        # @param id [String] The task ID (e.g., "v.0.9.0+task.140.02")
        # @return [String, nil] The task number (e.g., "140.02") or nil if invalid
        def self.extract_task_number(id)
          Atoms::TaskReferenceParser.extract_number(id)
        end
      end
    end
  end
end
