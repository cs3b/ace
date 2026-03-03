# frozen_string_literal: true

require_relative "ansi_colors"

module Ace
  module Support
    module Items
      module Atoms
        # Generic stats line builder for item lists.
        # Produces a summary like: "Tasks: ○ 3 | ▶ 1 | ✓ 5 • 3 of 660"
        class StatsLineFormatter
          # @param label [String] e.g. "Tasks", "Ideas", "Retros"
          # @param stats [Hash] Output of ItemStatistics.count_by (by :status)
          # @param status_order [Array<String>] Ordered status keys to display
          # @param status_icons [Hash<String,String>] Status → icon mapping
          # @param folder_stats [Hash, nil] Output of ItemStatistics.count_by (by :special_folder)
          # @param total_count [Integer, nil] Total items before folder filtering (enables "X of Y" display)
          # @param global_folder_stats [Hash, nil] Folder name → count hash from full scan (always shown)
          # @return [String] e.g. "Tasks: ○ 3 | ▶ 1 | ✓ 5 • 3 of 660"
          def self.format(label:, stats:, status_order:, status_icons:, folder_stats: nil, total_count: nil, global_folder_stats: nil)
            parts = []
            status_order.each do |status|
              count = stats[:by_field][status] || 0
              next if count == 0

              icon = status_icons[status] || status
              parts << "#{icon} #{count}"
            end

            # Catch any statuses not in status_order (unknown/unexpected)
            stats[:by_field].each do |status, count|
              next if count == 0 || status_order.include?(status)

              icon = status_icons[status] || status
              parts << "#{icon} #{count}"
            end

            line = "#{label}: #{parts.join(" | ")}"

            shown = stats[:total]
            total = total_count || shown

            if shown < total
              # Filtered view: show ratio
              line += " \u2022 #{shown} of #{total}"
            else
              # Full view: show total
              line += " \u2022 #{shown} total"
              # Inline folder breakdown from current results (only when unfiltered
              # and global_folder_stats not provided — global takes precedence)
              if !global_folder_stats && folder_stats && folder_stats[:by_field].size > 1
                folder_parts = folder_stats[:by_field]
                  .sort_by { |_, count| -count }
                  .map { |folder, count| "#{folder_label(folder)} #{count}" }
                suffix = " \u2014 #{folder_parts.join(" | ")}"
                line += AnsiColors.colorize(suffix, AnsiColors::DIM)
              end
            end

            # Global folder breakdown (always shown when provided and multi-folder)
            if global_folder_stats && global_folder_stats.size > 1
              global_parts = global_folder_stats
                .sort_by { |_, count| -count }
                .map { |folder, count| "#{folder_label(folder)} #{count}" }
              suffix = " \u2014 #{global_parts.join(" | ")}"
              line += AnsiColors.colorize(suffix, AnsiColors::DIM)
            end

            line
          end

          # Map special_folder values to display labels.
          # nil (root items) renders as "next".
          def self.folder_label(folder)
            return "next" if folder.nil? || folder.empty? || folder == ""

            folder.delete_prefix("_")
          end

          private_class_method :folder_label
        end
      end
    end
  end
end
