# frozen_string_literal: true

require "date"
require "time"

module Ace
  module Docs
    module Atoms
      # Pure timestamp parsing and validation functions
      # Supports ISO 8601 UTC, date-only, and legacy datetime formats
      #
      # Timezone Behavior:
      #   - ISO 8601 UTC format (YYYY-MM-DDTHH:MM:SSZ) is the recommended format
      #   - Legacy datetime format (YYYY-MM-DD HH:MM) is parsed as local time and converted to UTC
      #   - Date-only format (YYYY-MM-DD) remains timezone-agnostic
      #
      # Return Types:
      #   - Date-only strings → Date objects
      #   - ISO 8601 UTC strings → Time objects (in UTC)
      #   - Legacy datetime strings → Time objects (converted to UTC)
      #   This polymorphic return type preserves the precision of the input format.
      module TimestampParser
        # Regular expression patterns for timestamp validation
        DATE_ONLY_PATTERN = /^\d{4}-\d{2}-\d{2}$/
        ISO8601_UTC_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/
        DATETIME_PATTERN = /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/  # Legacy format

        # Parse a timestamp string to Date or Time object
        # @param value [String, Date, Time] Timestamp to parse
        # @return [Date, Time] Parsed timestamp
        # @raise [ArgumentError] If format is invalid
        def self.parse_timestamp(value)
          raise ArgumentError, "Cannot parse nil timestamp" if value.nil?

          # Return already parsed objects as-is
          return value if value.is_a?(Date) || value.is_a?(Time)

          # Must be a string at this point
          raise ArgumentError, "Timestamp must be a String, Date, or Time" unless value.is_a?(String)

          # Validate format before parsing
          unless validate_format(value)
            raise ArgumentError, "Invalid timestamp format. Use YYYY-MM-DDTHH:MM:SSZ (ISO 8601 UTC), YYYY-MM-DD, or YYYY-MM-DD HH:MM (legacy)"
          end

          # Parse based on format (try ISO 8601 first, then legacy)
          if value.match?(ISO8601_UTC_PATTERN)
            parse_iso8601_utc(value)
          elsif value.match?(DATETIME_PATTERN)
            parse_datetime(value)  # Legacy format - convert to UTC
          elsif value.match?(DATE_ONLY_PATTERN)
            parse_date(value)
          else
            raise ArgumentError, "Invalid timestamp format. Use YYYY-MM-DDTHH:MM:SSZ (ISO 8601 UTC), YYYY-MM-DD, or YYYY-MM-DD HH:MM (legacy)"
          end
        rescue Date::Error, ArgumentError => e
          # Improve error message for date parsing errors
          raise ArgumentError, "Invalid timestamp: #{e.message}"
        end

        # Validate timestamp format
        # @param value [String] Timestamp string to validate
        # @return [Boolean] true if format is valid
        def self.validate_format(value)
          return false if value.nil? || !value.is_a?(String) || value.empty?

          value.match?(DATE_ONLY_PATTERN) || value.match?(ISO8601_UTC_PATTERN) || value.match?(DATETIME_PATTERN)
        end

        # Format a Date or Time object to string
        # @param time_obj [Date, Time] Object to format
        # @return [String] Formatted timestamp in ISO 8601 UTC format (for Time) or date-only (for Date)
        # @raise [ArgumentError] If object is not Date or Time
        def self.format_timestamp(time_obj)
          raise ArgumentError, "Cannot format nil timestamp" if time_obj.nil?

          case time_obj
          when Date
            time_obj.strftime("%Y-%m-%d")
          when Time
            time_obj.utc.strftime("%Y-%m-%dT%H:%M:%SZ")  # ISO 8601 UTC format
          else
            raise ArgumentError, "Timestamp must be a Date or Time object"
          end
        end

        private

        # Parse date-only string
        # @param date_str [String] Date string in YYYY-MM-DD format
        # @return [Date] Parsed date
        # @raise [ArgumentError] If date is invalid
        def self.parse_date(date_str)
          Date.parse(date_str)
        rescue Date::Error => e
          raise ArgumentError, "Invalid date: #{e.message}"
        end

        # Parse ISO 8601 UTC datetime string
        # @param iso8601_str [String] ISO 8601 datetime string in YYYY-MM-DDTHH:MM:SSZ format
        # @return [Time] Parsed time in UTC
        # @raise [ArgumentError] If datetime is invalid
        def self.parse_iso8601_utc(iso8601_str)
          Time.parse(iso8601_str).utc  # Ensure UTC
        rescue ArgumentError => e
          raise ArgumentError, "Invalid ISO 8601 datetime: #{e.message}"
        end

        # Parse datetime string (legacy format)
        # @param datetime_str [String] Datetime string in YYYY-MM-DD HH:MM format
        # @return [Time] Parsed time converted to UTC
        # @raise [ArgumentError] If datetime is invalid
        def self.parse_datetime(datetime_str)
          # Parse as local time, then convert to UTC for consistency
          Time.parse(datetime_str).utc
        rescue ArgumentError => e
          raise ArgumentError, "Invalid datetime: #{e.message}"
        end
      end
    end
  end
end
