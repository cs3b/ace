# frozen_string_literal: true

module Ace
  module Idea
    module Molecules
      # Formats idea objects for terminal display.
      class IdeaDisplayFormatter
        STATUS_SYMBOLS = {
          "pending" => "○",
          "in-progress" => "▶",
          "done" => "✓",
          "obsolete" => "✗"
        }.freeze

        STATUS_COLORS = {
          "pending" => nil,
          "in-progress" => Ace::Support::Items::Atoms::AnsiColors::YELLOW,
          "done" => Ace::Support::Items::Atoms::AnsiColors::GREEN,
          "obsolete" => Ace::Support::Items::Atoms::AnsiColors::DIM
        }.freeze

        # Return the status symbol with ANSI color applied.
        def self.colored_status_sym(status)
          normalized = normalize_status(status)
          sym = STATUS_SYMBOLS[normalized] || "○"
          color = STATUS_COLORS[normalized]
          color ? Ace::Support::Items::Atoms::AnsiColors.colorize(sym, color) : sym
        end

        private_class_method :colored_status_sym

        def self.normalize_status(status)
          value = status.to_s
          return "obsolete" if value == "cancelled"

          value
        end

        private_class_method :normalize_status

        # Format a single idea for display
        # @param idea [Idea] Idea to format
        # @param show_content [Boolean] Whether to include full content
        # @return [String] Formatted output
        def self.format(idea, show_content: false)
          c = Ace::Support::Items::Atoms::AnsiColors
          status_sym = colored_status_sym(idea.status)
          id_str = show_content ? idea.id : c.colorize(idea.id, c::DIM)
          tags_str = idea.tags.any? ? c.colorize(" [#{idea.tags.join(", ")}]", c::DIM) : ""
          folder_str = idea.special_folder ? c.colorize(" (#{idea.special_folder})", c::DIM) : ""

          lines = []
          lines << "#{status_sym} #{id_str} #{idea.title}#{tags_str}#{folder_str}"

          if show_content && idea.content && !idea.content.strip.empty?
            lines << ""
            lines << idea.content
          end

          if show_content && idea.attachments.any?
            lines << ""
            lines << "Attachments: #{idea.attachments.join(", ")}"
          end

          lines.join("\n")
        end

        # Format a list of ideas for display
        # @param ideas [Array<Idea>] Ideas to format
        # @param total_count [Integer, nil] Total items before folder filtering
        # @param global_folder_stats [Hash, nil] Folder name → count hash from full scan
        # @return [String] Formatted list output
        def self.format_list(ideas, total_count: nil, global_folder_stats: nil)
          return "No ideas found." if ideas.empty?

          lines = ideas.map { |idea| format(idea) }.join("\n")
          "#{lines}\n\n#{format_stats_line(ideas, total_count: total_count, global_folder_stats: global_folder_stats)}"
        end

        STATUS_ORDER = %w[pending in-progress done obsolete].freeze

        # Format a status overview with up-next, stats, and recently-done sections.
        # @param categorized [Hash] Output of StatusCategorizer.categorize
        # @param all_ideas [Array<Idea>] All ideas for stats computation
        # @return [String] Formatted status output
        def self.format_status(categorized, all_ideas:)
          sections = []

          # Up Next
          sections << format_up_next_section(categorized[:up_next])

          # Stats summary
          sections << format_stats_line(all_ideas)

          # Recently Done
          sections << format_recently_done_section(categorized[:recently_done])

          sections.join("\n\n")
        end

        # Format a single idea as a compact status line (id + title only).
        # @param idea [Idea] Idea to format
        # @return [String] e.g. "  ⚪ 8ppq7w  Dark mode support"
        def self.format_status_line(idea)
          status_sym = colored_status_sym(idea.status)
          "  #{status_sym} #{idea.id}  #{idea.title}"
        end

        # Format a stats summary line for a list of ideas.
        # @param ideas [Array<Idea>] Ideas to summarize
        # @param total_count [Integer, nil] Total items before folder filtering
        # @param global_folder_stats [Hash, nil] Folder name → count hash from full scan
        # @return [String] e.g. "Ideas: ○ 3 | ▶ 1 | ✓ 2 • 3 of 8"
        def self.format_stats_line(ideas, total_count: nil, global_folder_stats: nil)
          stats = { total: ideas.size, by_field: Hash.new(0) }
          folder_stats = { total: ideas.size, by_field: Hash.new(0) }

          ideas.each do |idea|
            stats[:by_field][normalize_status(idea.status)] += 1
            folder_stats[:by_field][idea.special_folder] += 1
          end

          Ace::Support::Items::Atoms::StatsLineFormatter.format(
            label: "Ideas",
            stats: stats,
            status_order: STATUS_ORDER,
            status_icons: STATUS_SYMBOLS,
            folder_stats: folder_stats,
            total_count: total_count,
            global_folder_stats: global_folder_stats
          )
        end

        # Format the "Up Next" section.
        def self.format_up_next_section(up_next)
          return "Up Next:\n  (none)" if up_next.empty?

          lines = up_next.map { |idea| format_status_line(idea) }
          "Up Next:\n#{lines.join("\n")}"
        end

        # Format the "Recently Done" section.
        def self.format_recently_done_section(recently_done)
          return "Recently Done:\n  (none)" if recently_done.empty?

          lines = recently_done.map do |entry|
            idea = entry[:item]
            time_str = Ace::Support::Items::Atoms::RelativeTimeFormatter.format(entry[:completed_at])
            "  #{format_status_line(idea).strip}  (#{time_str})"
          end
          "Recently Done:\n#{lines.join("\n")}"
        end

        private_class_method :format_up_next_section, :format_recently_done_section
      end
    end
  end
end
