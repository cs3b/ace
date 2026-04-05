# frozen_string_literal: true

module Ace
  module Hitl
    module Molecules
      # Formats HITL events for list output with stats footer.
      class HitlDisplayFormatter
        C = Ace::Support::Items::Atoms::AnsiColors

        STATUS_SYMBOLS = {
          "pending" => "○",
          "answered" => "✓"
        }.freeze

        STATUS_ORDER = %w[pending answered].freeze

        def self.format_list(events, total_count: nil, global_folder_stats: nil)
          body = if events.empty?
            "No HITL events found"
          else
            events.sort_by(&:id).map { |event| format_list_line(event) }.join("\n")
          end

          stats = Ace::Support::Items::Atoms::ItemStatistics.count_by(events, :status)
          folder_stats = Ace::Support::Items::Atoms::ItemStatistics.count_by(events, :special_folder)
          footer = Ace::Support::Items::Atoms::StatsLineFormatter.format(
            label: "HITL Events",
            stats: stats,
            status_order: STATUS_ORDER,
            status_icons: STATUS_SYMBOLS,
            folder_stats: folder_stats,
            total_count: total_count,
            global_folder_stats: global_folder_stats
          )

          "#{body}\n\n#{footer}"
        end

        def self.format_list_line(event)
          status_sym = STATUS_SYMBOLS[event.status] || "○"
          id_str = C.colorize(event.id, C::DIM)
          tags_str = event.tags.any? ? C.colorize(" [#{event.tags.join(", ")}]", C::DIM) : ""
          folder_label = event.special_folder ? Ace::Support::Items::Atoms::SpecialFolderDetector.short_name(event.special_folder) : nil
          folder_str = folder_label ? C.colorize(" (#{folder_label})", C::DIM) : ""

          "#{status_sym}   #{id_str}  #{event.title}#{tags_str}#{folder_str}"
        end

        private_class_method :format_list_line
      end
    end
  end
end
