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
          "draft" => "◇",
          "skipped" => "–",
          "cancelled" => "—"
        }.freeze

        STATUS_COLORS = {
          "pending" => nil,
          "in-progress" => Ace::Support::Items::Atoms::AnsiColors::YELLOW,
          "done" => Ace::Support::Items::Atoms::AnsiColors::GREEN,
          "blocked" => Ace::Support::Items::Atoms::AnsiColors::RED,
          "draft" => Ace::Support::Items::Atoms::AnsiColors::CYAN,
          "skipped" => Ace::Support::Items::Atoms::AnsiColors::DIM,
          "cancelled" => Ace::Support::Items::Atoms::AnsiColors::DIM
        }.freeze

        PRIORITY_LABELS = {
          "critical" => "‼",
          "high" => "!",
          "medium" => "",
          "low" => "↓"
        }.freeze

        # Return the status symbol with ANSI color applied.
        # @param status [String] Status string
        # @return [String] Colored status symbol
        def self.colored_status_sym(status)
          sym = STATUS_SYMBOLS[status] || "○"
          color = STATUS_COLORS[status]
          color ? Ace::Support::Items::Atoms::AnsiColors.colorize(sym, color) : sym
        end

        private_class_method :colored_status_sym

        # Format a single task for detailed display (show command).
        # @param task [Models::Task] Task to format
        # @param show_content [Boolean] Whether to include body content
        # @return [String] Formatted output
        def self.format(task, show_content: false)
          lines = []

          # Header line: status symbol, ID, title
          status_sym = colored_status_sym(task.status)
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
              st_sym = colored_status_sym(st.status)
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
        # @param total_count [Integer, nil] Total items before folder filtering
        # @param global_folder_stats [Hash, nil] Folder name → count hash from full scan
        # @return [String] Formatted list output
        def self.format_list(tasks, total_count: nil, global_folder_stats: nil)
          return "No tasks found." if tasks.empty?

          lines = tasks.map { |task| format_list_item(task) }.join("\n")
          "#{lines}\n\n#{format_stats_line(tasks, total_count: total_count, global_folder_stats: global_folder_stats)}"
        end

        STATUS_ORDER = %w[draft pending in-progress done blocked skipped cancelled].freeze

        # Format a status overview with up-next, stats, and recently-done sections.
        # @param categorized [Hash] Output of StatusCategorizer.categorize
        # @param all_tasks [Array<Models::Task>] All tasks for stats computation
        # @return [String] Formatted status output
        def self.format_status(categorized, all_tasks:)
          sections = []

          # Up Next
          sections << format_up_next_section(categorized[:up_next])

          # Stats summary
          sections << format_stats_line(all_tasks)

          # Recently Done
          sections << format_recently_done_section(categorized[:recently_done])

          sections.join("\n\n")
        end

        # Format a stats summary line for a list of tasks.
        # @param tasks [Array<Models::Task>] Tasks to summarize
        # @param total_count [Integer, nil] Total items before folder filtering
        # @param global_folder_stats [Hash, nil] Folder name → count hash from full scan
        # @return [String] e.g. "Tasks: ○ 2 | ▶ 1 | ✓ 5 • 3 of 660"
        def self.format_stats_line(tasks, total_count: nil, global_folder_stats: nil)
          stats = Ace::Support::Items::Atoms::ItemStatistics.count_by(tasks, :status)
          folder_stats = Ace::Support::Items::Atoms::ItemStatistics.count_by(tasks, :special_folder)
          Ace::Support::Items::Atoms::StatsLineFormatter.format(
            label: "Tasks",
            stats: stats,
            status_order: STATUS_ORDER,
            status_icons: STATUS_SYMBOLS,
            folder_stats: folder_stats,
            total_count: total_count,
            global_folder_stats: global_folder_stats
          )
        end

        # Format a single task as a compact status line (id + title only).
        # @param task [Models::Task] Task to format
        # @return [String] e.g. "  ○ 8pp.t.q7w  Fix login bug"
        def self.format_status_line(task)
          status_sym = colored_status_sym(task.status)
          "  #{status_sym} #{task.id}  #{task.title}"
        end

        private

        # Format the "Up Next" section.
        def self.format_up_next_section(up_next)
          return "Up Next:\n  (none)" if up_next.empty?

          lines = up_next.map { |task| format_status_line(task) }
          "Up Next:\n#{lines.join("\n")}"
        end

        # Format the "Recently Done" section.
        def self.format_recently_done_section(recently_done)
          return "Recently Done:\n  (none)" if recently_done.empty?

          lines = recently_done.map do |entry|
            task = entry[:item]
            time_str = Ace::Support::Items::Atoms::RelativeTimeFormatter.format(entry[:completed_at])
            "  #{format_status_line(task).strip}  (#{time_str})"
          end
          "Recently Done:\n#{lines.join("\n")}"
        end

        private_class_method :format_up_next_section, :format_recently_done_section

        # Format a single task as a compact list item.
        def self.format_list_item(task)
          status_sym = colored_status_sym(task.status)
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
