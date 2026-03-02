# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Atoms
        # Generic stats line builder for item lists.
        # Produces a summary like: "Tasks: ○ 3 | ▶ 1 | ✓ 5 • 9 total • 56% complete"
        class StatsLineFormatter
          # @param label [String] e.g. "Tasks", "Ideas", "Retros"
          # @param stats [Hash] Output of ItemStatistics.count_by
          # @param status_order [Array<String>] Ordered status keys to display
          # @param status_icons [Hash<String,String>] Status → icon mapping
          # @param completion_values [Array<String>, nil] If set, append "N% complete"
          # @return [String] e.g. "Tasks: ○ 3 | ▶ 1 | ✓ 5 • 9 total • 56% complete"
          def self.format(label:, stats:, status_order:, status_icons:, completion_values: nil)
            parts = []
            status_order.each do |status|
              count = stats[:by_field][status] || 0
              next if count == 0

              icon = status_icons[status] || status
              parts << "#{icon} #{count}"
            end

            line = "#{label}: #{parts.join(" | ")}"
            line += " \u2022 #{stats[:total]} total"

            if completion_values
              rate = ItemStatistics.completion_rate(stats, done_values: completion_values)
              line += " \u2022 #{rate}% complete"
            end

            line
          end
        end
      end
    end
  end
end
