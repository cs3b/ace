# frozen_string_literal: true

module Ace
  module Retro
    module Molecules
      # Formats retro objects for terminal display.
      class RetroDisplayFormatter
        STATUS_SYMBOLS = {
          "active" => "🟡",
          "done" => "🟢"
        }.freeze

        TYPE_LABELS = {
          "standard" => "standard",
          "conversation-analysis" => "conversation",
          "self-review" => "self-review"
        }.freeze

        # Format a single retro for display
        # @param retro [Retro] Retro to format
        # @param show_content [Boolean] Whether to include full content
        # @return [String] Formatted output
        def self.format(retro, show_content: false)
          status_sym = STATUS_SYMBOLS[retro.status] || "⚪"
          tags_str = retro.tags.any? ? " [#{retro.tags.join(", ")}]" : ""
          folder_str = retro.special_folder ? " (#{retro.special_folder})" : ""
          type_str = " <#{TYPE_LABELS[retro.type] || retro.type}>"
          task_str = retro.task_ref ? " → #{retro.task_ref}" : ""

          lines = []
          lines << "#{status_sym} #{retro.id} #{retro.title}#{type_str}#{tags_str}#{task_str}#{folder_str}"

          if show_content && retro.content && !retro.content.strip.empty?
            lines << ""
            lines << retro.content
          end

          if retro.folder_contents&.any?
            lines << ""
            lines << "Files: #{retro.folder_contents.join(", ")}"
          end

          lines.join("\n")
        end

        # Format a list of retros for display
        # @param retros [Array<Retro>] Retros to format
        # @return [String] Formatted list output
        def self.format_list(retros)
          return "No retros found." if retros.empty?

          lines = retros.map { |retro| format(retro) }.join("\n")
          "#{lines}\n\n#{format_stats_line(retros)}"
        end

        STATUS_ORDER = %w[active done].freeze

        # Format a stats summary line for a list of retros.
        # @param retros [Array<Retro>] Retros to summarize
        # @return [String] e.g. "Retros: 🟡 2 | 🟢 5 • 7 total • 71% complete"
        def self.format_stats_line(retros)
          stats = Ace::Support::Items::Atoms::ItemStatistics.count_by(retros, :status)
          Ace::Support::Items::Atoms::StatsLineFormatter.format(
            label: "Retros",
            stats: stats,
            status_order: STATUS_ORDER,
            status_icons: STATUS_SYMBOLS,
            completion_values: ["done"]
          )
        end
      end
    end
  end
end
