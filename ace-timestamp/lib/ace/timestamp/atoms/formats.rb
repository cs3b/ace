# frozen_string_literal: true

module Ace
  module Timestamp
    module Atoms
      # Detects and validates timestamp format types.
      #
      # Supports two formats:
      # - :compact - 6-character Base36 compact ID (e.g., "i50jj3")
      # - :timestamp - 14-character timestamp format (e.g., "20250101-120000")
      #
      # @example Detect format
      #   Formats.detect("i50jj3")         # => :compact
      #   Formats.detect("20250101-120000") # => :timestamp
      #   Formats.detect("invalid")         # => nil
      #
      module Formats
        # Regex patterns for format detection
        COMPACT_PATTERN = /\A[0-9a-z]{6}\z/i
        TIMESTAMP_PATTERN = /\A\d{8}-\d{6}\z/

        class << self
          # Detect the format type of a timestamp string
          #
          # @param value [String] The timestamp string to analyze
          # @return [Symbol, nil] :compact, :timestamp, or nil if unrecognized
          def detect(value)
            return nil unless value.is_a?(String)

            case value
            when COMPACT_PATTERN
              :compact
            when TIMESTAMP_PATTERN
              :timestamp
            end
          end

          # Check if value is a valid compact ID format
          #
          # @param value [String] The string to check
          # @return [Boolean] true if valid compact format
          def compact?(value)
            detect(value) == :compact
          end

          # Check if value is a valid timestamp format
          #
          # @param value [String] The string to check
          # @return [Boolean] true if valid timestamp format
          def timestamp?(value)
            detect(value) == :timestamp
          end

          # Parse a timestamp format string to Time
          #
          # @param value [String] Timestamp in "YYYYMMDD-HHMMSS" format
          # @return [Time] Parsed time in UTC
          # @raise [ArgumentError] If format is invalid
          def parse_timestamp(value)
            unless timestamp?(value)
              raise ArgumentError, "Invalid timestamp format: #{value} (expected YYYYMMDD-HHMMSS)"
            end

            year = value[0..3].to_i
            month = value[4..5].to_i
            day = value[6..7].to_i
            hour = value[9..10].to_i
            minute = value[11..12].to_i
            second = value[13..14].to_i

            Time.utc(year, month, day, hour, minute, second)
          end

          # Format a Time object to timestamp format
          #
          # @param time [Time] The time to format
          # @return [String] Timestamp in "YYYYMMDD-HHMMSS" format
          def format_timestamp(time)
            time = time.utc if time.respond_to?(:utc)
            time.strftime("%Y%m%d-%H%M%S")
          end
        end
      end
    end
  end
end
