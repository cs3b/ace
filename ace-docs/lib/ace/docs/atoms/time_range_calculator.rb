# frozen_string_literal: true

require "date"
require "time"

module Ace
  module Docs
    module Atoms
      # Pure function for time range calculations
      class TimeRangeCalculator
        class << self
          # Calculate a git-compatible "since" string from a date
          # @param date [Date, Time, String] The date to calculate from
          # @return [String] Git-compatible since string (e.g., "2 weeks ago")
          def calculate_since(date)
            return date if date.is_a?(String) && date.match?(/^\d+\s+(days?|weeks?|months?)\s+ago$/)

            parsed_date = parse_date(date)
            days_ago = (Date.today - parsed_date.to_date).to_i

            format_days_ago(days_ago)
          end

          # Parse a date from various formats
          # @param date_string [String, Date, Time] Date in various formats
          # @return [Date] Parsed date
          def parse_date(date_string)
            return date_string if date_string.is_a?(Date)
            return date_string.to_date if date_string.is_a?(Time)

            # Handle various string formats
            case date_string
            when /^today$/i
              Date.today
            when /^yesterday$/i
              Date.today - 1
            when /^(\d+)\s+days?\s+ago$/i
              Date.today - Regexp.last_match(1).to_i
            when /^(\d+)\s+weeks?\s+ago$/i
              Date.today - (Regexp.last_match(1).to_i * 7)
            when /^(\d+)\s+months?\s+ago$/i
              Date.today << Regexp.last_match(1).to_i
            when /^\d{4}-\d{2}-\d{2}$/
              Date.parse(date_string)
            else
              # Try to parse with Date.parse as fallback
              Date.parse(date_string)
            end
          rescue ArgumentError => e
            raise ArgumentError, "Invalid date format: #{date_string}. Error: #{e.message}"
          end

          # Format a date for human-readable display
          # @param date [Date, Time] Date to format
          # @return [String] Human-readable date (e.g., "2 weeks ago", "3 days ago")
          def format_human(date)
            parsed_date = parse_date(date)
            days_ago = (Date.today - parsed_date).to_i

            format_days_ago(days_ago)
          end

          private

          # Format days into human-readable time ago string
          def format_days_ago(days)
            case days
            when 0
              "today"
            when 1
              "yesterday"
            when 2..6
              "#{days} days ago"
            when 7..13
              "1 week ago"
            when 14..20
              "2 weeks ago"
            when 21..29
              "3 weeks ago"
            when 30..59
              "1 month ago"
            when 60..89
              "2 months ago"
            when 90..179
              "3 months ago"
            when 180..364
              "6 months ago"
            else
              "#{(days / 365.0).round} years ago"
            end
          end
        end
      end
    end
  end
end
