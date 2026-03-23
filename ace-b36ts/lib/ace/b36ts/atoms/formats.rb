# frozen_string_literal: true

require_relative "format_specs"

module Ace
  module B36ts
    module Atoms
      # Detects and validates timestamp format types.
      #
      # Supports multiple compact ID formats:
      # - :"2sec" - 6-character Base36 compact ID (e.g., "i50jj3")
      # - :month - 2-character Base36 month ID (e.g., "i5")
      # - :week - 3-character Base36 week ID (e.g., "i5v")
      # - :day - 3-character Base36 day ID (e.g., "i50")
      # - :"40min" - 4-character Base36 40min block ID (e.g., "i50j")
      # - :"50ms" - 7-character Base36 high-precision ID (e.g., "i50jj3z")
      # - :ms - 8-character Base36 high-precision ID (e.g., "i50jj3zz")
      # - :timestamp - 14-character timestamp format (e.g., "20250101-120000")
      #
      # @example Detect format
      #   Formats.detect("i50jj3")         # => :"2sec"
      #   Formats.detect("i5")             # => :month
      #   Formats.detect("i5v")            # => :week (3rd char 31-35)
      #   Formats.detect("i50")            # => :day (3rd char 0-30)
      #   Formats.detect("i50j")           # => :"40min"
      #   Formats.detect("i50jj3z")        # => :"50ms"
      #   Formats.detect("i50jj3zz")       # => :ms
      #   Formats.detect("20250101-120000") # => :timestamp
      #   Formats.detect("invalid")         # => nil
      #
      module Formats
        # Regex patterns for format detection
        MONTH_PATTERN = /\A[0-9a-z]{2}\z/i
        DAY_WEEK_PATTERN = /\A[0-9a-z]{3}\z/i  # Disambiguate by 3rd char value
        HOUR_PATTERN = /\A[0-9a-z]{4}\z/i
        COMPACT_PATTERN = /\A[0-9a-z]{6}\z/i
        HIGH_7_PATTERN = /\A[0-9a-z]{7}\z/i
        HIGH_8_PATTERN = /\A[0-9a-z]{8}\z/i
        TIMESTAMP_PATTERN = /\A\d{8}-\d{6}\z/

        class << self
          # Detect the format type of a timestamp string
          #
          # For 3-character IDs, uses the 3rd character value to distinguish day vs week:
          # - Day format: 3rd char in 0-30 range
          # - Week format: 3rd char in 31-35 range
          #
          # @param value [String] The timestamp string to analyze
          # @return [Symbol, nil] :"2sec", :month, :week, :day, :"40min", :"50ms", :ms, :timestamp, or nil if unrecognized
          def detect(value)
            return nil unless value.is_a?(String)

            # For compact ID formats, delegate to FormatSpecs for proper detection
            # including day/week disambiguation
            if FormatSpecs::FORMATS.values.any? { |spec| spec.pattern.match?(value) }
              FormatSpecs.detect_from_id(value)
            elsif TIMESTAMP_PATTERN.match?(value)
              :timestamp
            end
          end

          # Check if value is a valid compact ID format
          #
          # @param value [String] The string to check
          # @return [Boolean] true if valid compact format
          def compact?(value)
            detect(value) == :"2sec"
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
