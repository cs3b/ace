# frozen_string_literal: true

require "time"

module Ace
  module Git
    module Atoms
      # Pure functions for formatting timestamps as relative time strings
      # Examples: "2h ago", "1d ago", "3w ago"
      module TimeFormatter
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

          # Format an array of merged PR data with relative times
          # @api private
          # @note Currently unused in production code - kept for potential future use.
          #   The ContextFormatter.format_merged_time_compact method is used instead
          #   for inline formatting during output generation.
          # @param prs [Array<Hash>] PRs with mergedAt field
          # @param reference_time [Time] Time to compare against
          # @return [Array<Hash>] PRs with merged_ago field added
          def add_relative_times(prs, reference_time: Time.now)
            prs.map do |pr|
              pr.merge("merged_ago" => relative_time(pr["mergedAt"], reference_time: reference_time))
            end
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
            return "just now" if seconds < 60

            minutes = seconds / 60
            return "#{minutes}m ago" if minutes < 60

            hours = minutes / 60
            return "#{hours}h ago" if hours < 24

            days = hours / 24
            return "#{days}d ago" if days < 7

            weeks = days / 7
            return "#{weeks}w ago" if days < 30

            # Use months until we hit a full year (365 days)
            # This avoids "0y ago" for 360-364 day intervals
            # Note: Using 30 days/month is a simplification (actual avg is ~30.44)
            # but is acceptable for relative time display purposes
            # Use floor with minimum 1 to avoid "0mo ago" for 30-day intervals
            months = [(days * 12.0 / 365).floor, 1].max
            return "#{months}mo ago" if days < 365

            years = days / 365
            "#{years}y ago"
          end
        end
      end
    end
  end
end
