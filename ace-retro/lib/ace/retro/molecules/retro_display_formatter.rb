# frozen_string_literal: true

module Ace
  module Retro
    module Molecules
      # Formats retro objects for terminal display.
      class RetroDisplayFormatter
        STATUS_SYMBOLS = {
          "active" => "○",
          "done" => "✓"
        }.freeze

        STATUS_COLORS = {
          "active" => Ace::Support::Items::Atoms::AnsiColors::YELLOW,
          "done" => Ace::Support::Items::Atoms::AnsiColors::GREEN
        }.freeze

        TYPE_LABELS = {
          "standard" => "standard",
          "conversation-analysis" => "conversation",
          "self-review" => "self-review"
        }.freeze

        # Return the status symbol with ANSI color applied.
        def self.colored_status_sym(status)
          sym = STATUS_SYMBOLS[status] || "○"
          color = STATUS_COLORS[status]
          color ? Ace::Support::Items::Atoms::AnsiColors.colorize(sym, color) : sym
        end

        private_class_method :colored_status_sym

        # Format a single retro for display
        # @param retro [Retro] Retro to format
        # @param show_content [Boolean] Whether to include full content
        # @return [String] Formatted output
        def self.format(retro, show_content: false)
          status_sym = colored_status_sym(retro.status)
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
        # @param total_count [Integer, nil] Total items before folder filtering
        # @param global_folder_stats [Hash, nil] Folder name → count hash from full scan
        # @return [String] Formatted list output
        def self.format_list(retros, total_count: nil, global_folder_stats: nil)
          return "No retros found." if retros.empty?

          lines = retros.map { |retro| format(retro) }.join("\n")
          "#{lines}\n\n#{format_stats_line(retros, total_count: total_count, global_folder_stats: global_folder_stats)}"
        end

        STATUS_ORDER = %w[active done].freeze

        # Format a stats summary line for a list of retros.
        # @param retros [Array<Retro>] Retros to summarize
        # @param total_count [Integer, nil] Total items before folder filtering
        # @param global_folder_stats [Hash, nil] Folder name → count hash from full scan
        # @return [String] e.g. "Retros: ○ 2 | ✓ 5 • 2 of 7"
        def self.format_stats_line(retros, total_count: nil, global_folder_stats: nil)
          stats = Ace::Support::Items::Atoms::ItemStatistics.count_by(retros, :status)
          folder_stats = Ace::Support::Items::Atoms::ItemStatistics.count_by(retros, :special_folder)
          Ace::Support::Items::Atoms::StatsLineFormatter.format(
            label: "Retros",
            stats: stats,
            status_order: STATUS_ORDER,
            status_icons: STATUS_SYMBOLS,
            folder_stats: folder_stats,
            total_count: total_count,
            global_folder_stats: global_folder_stats
          )
        end
      end
    end
  end
end
