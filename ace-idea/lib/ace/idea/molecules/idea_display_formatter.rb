# frozen_string_literal: true

module Ace
  module Idea
    module Molecules
      # Formats idea objects for terminal display.
      class IdeaDisplayFormatter
        STATUS_SYMBOLS = {
          "pending" => "⚪",
          "in-progress" => "🟡",
          "done" => "🟢",
          "obsolete" => "⚫"
        }.freeze

        # Format a single idea for display
        # @param idea [Idea] Idea to format
        # @param show_content [Boolean] Whether to include full content
        # @return [String] Formatted output
        def self.format(idea, show_content: false)
          status_sym = STATUS_SYMBOLS[idea.status] || "⚪"
          tags_str = idea.tags.any? ? " [#{idea.tags.join(", ")}]" : ""
          folder_str = idea.special_folder ? " (#{idea.special_folder})" : ""

          lines = []
          lines << "#{status_sym} #{idea.id} #{idea.title}#{tags_str}#{folder_str}"

          if show_content && idea.content && !idea.content.strip.empty?
            lines << ""
            lines << idea.content
          end

          if idea.attachments.any?
            lines << ""
            lines << "Attachments: #{idea.attachments.join(", ")}"
          end

          lines.join("\n")
        end

        # Format a list of ideas for display
        # @param ideas [Array<Idea>] Ideas to format
        # @param total_count [Integer, nil] Total items before folder filtering
        # @return [String] Formatted list output
        def self.format_list(ideas, total_count: nil)
          return "No ideas found." if ideas.empty?

          lines = ideas.map { |idea| format(idea) }.join("\n")
          "#{lines}\n\n#{format_stats_line(ideas, total_count: total_count)}"
        end

        STATUS_ORDER = %w[pending in-progress done obsolete].freeze

        # Format a stats summary line for a list of ideas.
        # @param ideas [Array<Idea>] Ideas to summarize
        # @param total_count [Integer, nil] Total items before folder filtering
        # @return [String] e.g. "Ideas: ⚪ 3 | 🟡 1 | 🟢 2 • 3 of 8"
        def self.format_stats_line(ideas, total_count: nil)
          stats = Ace::Support::Items::Atoms::ItemStatistics.count_by(ideas, :status)
          folder_stats = Ace::Support::Items::Atoms::ItemStatistics.count_by(ideas, :special_folder)
          Ace::Support::Items::Atoms::StatsLineFormatter.format(
            label: "Ideas",
            stats: stats,
            status_order: STATUS_ORDER,
            status_icons: STATUS_SYMBOLS,
            folder_stats: folder_stats,
            total_count: total_count
          )
        end
      end
    end
  end
end
