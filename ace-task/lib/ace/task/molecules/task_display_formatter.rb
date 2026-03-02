# frozen_string_literal: true

module Ace
  module Task
    module Molecules
      # Formats task objects for terminal display.
      # Handles single-task show output and compact list output,
      # including subtask tree rendering.
      class TaskDisplayFormatter
        STATUS_SYMBOLS = {
          "pending" => "○",
          "in-progress" => "▶",
          "done" => "✓",
          "blocked" => "✗",
          "cancelled" => "—"
        }.freeze

        PRIORITY_LABELS = {
          "critical" => "‼",
          "high" => "!",
          "medium" => "",
          "low" => "↓"
        }.freeze

        # Format a single task for detailed display (show command).
        # @param task [Models::Task] Task to format
        # @param show_content [Boolean] Whether to include body content
        # @return [String] Formatted output
        def self.format(task, show_content: false)
          lines = []

          # Header line: status symbol, ID, title
          status_sym = STATUS_SYMBOLS[task.status] || "○"
          priority_sym = PRIORITY_LABELS[task.priority] || ""
          priority_prefix = priority_sym.empty? ? "" : "#{priority_sym} "
          lines << "#{status_sym} #{priority_prefix}#{task.id}  #{task.title}"

          # Metadata line
          meta_parts = []
          meta_parts << "status: #{task.status}"
          meta_parts << "priority: #{task.priority}" if task.priority
          meta_parts << "estimate: #{task.estimate}" if task.estimate
          lines << "  #{meta_parts.join("  |  ")}"

          # Tags
          if task.tags && task.tags.any?
            lines << "  tags: #{task.tags.join(", ")}"
          end

          # Dependencies
          if task.dependencies && task.dependencies.any?
            lines << "  depends: #{task.dependencies.join(", ")}"
          end

          # Folder info
          if task.special_folder
            lines << "  folder: #{task.special_folder}"
          end

          # Parent info for subtasks
          if task.parent_id
            lines << "  parent: #{task.parent_id}"
          end

          # Subtasks
          if task.has_subtasks?
            lines << ""
            lines << "  Subtasks:"
            task.subtasks.each do |st|
              st_sym = STATUS_SYMBOLS[st.status] || "○"
              lines << "    #{st_sym} #{st.id}  #{st.title}"
            end
          end

          # Body content
          if show_content && task.content && !task.content.strip.empty?
            lines << ""
            lines << task.content.strip
          end

          lines.join("\n")
        end

        # Format a list of tasks for compact display (list command).
        # @param tasks [Array<Models::Task>] Tasks to format
        # @return [String] Formatted list output
        def self.format_list(tasks)
          return "No tasks found." if tasks.empty?

          lines = tasks.map { |task| format_list_item(task) }.join("\n")
          "#{lines}\n\n#{format_stats_line(tasks)}"
        end

        STATUS_ORDER = %w[pending in-progress done blocked cancelled].freeze

        # Format a stats summary line for a list of tasks.
        # @param tasks [Array<Models::Task>] Tasks to summarize
        # @return [String] e.g. "Tasks: ○ 2 | ▶ 1 | ✓ 5 • 8 total • 63% complete"
        def self.format_stats_line(tasks)
          stats = Ace::Support::Items::Atoms::ItemStatistics.count_by(tasks, :status)
          Ace::Support::Items::Atoms::StatsLineFormatter.format(
            label: "Tasks",
            stats: stats,
            status_order: STATUS_ORDER,
            status_icons: STATUS_SYMBOLS,
            completion_values: ["done"]
          )
        end

        private

        # Format a single task as a compact list item.
        def self.format_list_item(task)
          status_sym = STATUS_SYMBOLS[task.status] || "○"
          priority_sym = PRIORITY_LABELS[task.priority] || ""
          priority_prefix = priority_sym.empty? ? "" : "#{priority_sym} "
          tags_str = task.tags && task.tags.any? ? " [#{task.tags.join(", ")}]" : ""
          folder_str = task.special_folder ? " (#{task.special_folder})" : ""
          subtask_str = task.has_subtasks? ? " +#{task.subtasks.length}" : ""

          "#{status_sym} #{priority_prefix}#{task.id}  #{task.title}#{tags_str}#{folder_str}#{subtask_str}"
        end

        private_class_method :format_list_item
      end
    end
  end
end
