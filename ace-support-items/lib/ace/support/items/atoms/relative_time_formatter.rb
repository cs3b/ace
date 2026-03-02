# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Atoms
        # Formats a Time into a human-readable relative string like "2h ago".
        # Pure function — no I/O, fully testable with injected reference time.
        class RelativeTimeFormatter
          SECONDS_PER_MINUTE = 60
          MINUTES_PER_HOUR = 60
          HOURS_PER_DAY = 24
          DAYS_PER_WEEK = 7
          DAYS_PER_MONTH = 30
          MONTHS_PER_YEAR = 12

          # @param time [Time] The timestamp to format
          # @param reference [Time] The "now" reference point (default: Time.now)
          # @return [String] e.g. "just now", "5m ago", "2h ago", "3d ago", "2w ago", "1mo ago", "1y ago"
          def self.format(time, reference: Time.now)
            return "unknown" if time.nil?
            return "unknown" unless time.is_a?(Time)

            seconds = (reference - time).to_i
            return "just now" if seconds < SECONDS_PER_MINUTE

            minutes = seconds / SECONDS_PER_MINUTE
            return "#{minutes}m ago" if minutes < MINUTES_PER_HOUR

            hours = minutes / MINUTES_PER_HOUR
            return "#{hours}h ago" if hours < HOURS_PER_DAY

            days = hours / HOURS_PER_DAY
            return "#{days}d ago" if days < DAYS_PER_WEEK

            return "#{days / DAYS_PER_WEEK}w ago" if days < DAYS_PER_MONTH

            months = days / DAYS_PER_MONTH
            return "#{months}mo ago" if months < MONTHS_PER_YEAR

            years = months / MONTHS_PER_YEAR
            "#{years}y ago"
          end
        end
      end
    end
  end
end
