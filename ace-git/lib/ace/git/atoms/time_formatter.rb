# frozen_string_literal: true

require "time"

module Ace
  module Git
    module Atoms
      # Pure functions for formatting timestamps as relative time strings
      # Examples: "2h ago", "1d ago", "3w ago"
      module TimeFormatter
        # Time constants for format_duration calculations
        SECONDS_PER_MINUTE = 60
        MINUTES_PER_HOUR = 60
        HOURS_PER_DAY = 24
        DAYS_PER_WEEK = 7
        DAYS_PER_MONTH = 30  # Simplified (actual avg ~30.44)
        DAYS_PER_YEAR = 365
        MONTHS_PER_YEAR = 12

        class << self
          # Convert an ISO8601 timestamp to relative time
          # @param timestamp [String, Time] ISO8601 timestamp or Time object
          # @param reference_time [Time] Time to compare against (default: Time.now)
          # @return [String] Relative time string like "2h ago", "1d ago", or empty for future times
          def relative_time(timestamp, reference_time: Time.now)
            return "" if timestamp.nil? || (timestamp.is_a?(String) && timestamp.empty?)

            time = parse_timestamp(timestamp)
            return "" if time.nil?

            seconds_ago = (reference_time - time).to_i
            # Don't format future times (negative duration)
            return "" if seconds_ago < 0

            format_duration(seconds_ago)
          end

          private

          # Parse timestamp to Time object
          # @param timestamp [String, Time] Timestamp to parse
          # @return [Time, nil] Parsed time or nil
          def parse_timestamp(timestamp)
            return timestamp if timestamp.is_a?(Time)

            Time.parse(timestamp)
          rescue ArgumentError, TypeError
            nil
          end

          # Format duration in seconds as human-readable string
          # @param seconds [Integer] Duration in seconds
          # @return [String] Formatted duration
          def format_duration(seconds)
            return "just now" if seconds < SECONDS_PER_MINUTE

            minutes = seconds / SECONDS_PER_MINUTE
            return "#{minutes}m ago" if minutes < MINUTES_PER_HOUR

            hours = minutes / MINUTES_PER_HOUR
            return "#{hours}h ago" if hours < HOURS_PER_DAY

            days = hours / HOURS_PER_DAY
            return "#{days}d ago" if days < DAYS_PER_WEEK

            weeks = days / DAYS_PER_WEEK
            return "#{weeks}w ago" if days < DAYS_PER_MONTH

            # Use months until we hit a full year (365 days)
            # This avoids "0y ago" for 360-364 day intervals
            # Note: Using 30 days/month is a simplification (actual avg is ~30.44)
            # but is acceptable for relative time display purposes
            # Use floor with minimum 1 to avoid "0mo ago" for 30-day intervals
            months = [(days * MONTHS_PER_YEAR.to_f / DAYS_PER_YEAR).floor, 1].max
            return "#{months}mo ago" if days < DAYS_PER_YEAR

            years = days / DAYS_PER_YEAR
            "#{years}y ago"
          end
        end
      end
    end
  end
end
