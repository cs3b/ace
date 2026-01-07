# frozen_string_literal: true

require "time"

module Ace
  module Timestamp
    module Atoms
      # Encodes and decodes timestamps to/from 6-character Base36 compact IDs.
      #
      # Format design (6 Base36 digits):
      # - Positions 1-2: Month offset from year_zero (0-1295 = 108 years of months)
      # - Position 3: Day of month (0-30 maps to 1-31 calendar days)
      # - Position 4: 40-minute hour block (0-35 = 36 blocks covering 24 hours)
      # - Positions 5-6: Precision within 40-minute window (~1.85s precision)
      #
      # Total capacity: 36^6 = 2,176,782,336 unique IDs over 108 years
      #
      # @example Encode a time
      #   CompactIdEncoder.encode(Time.utc(2025, 1, 6, 12, 30, 0))
      #   # => "i50jj3"
      #
      # @example Decode a compact ID
      #   CompactIdEncoder.decode("i50jj3")
      #   # => 2025-01-06 12:30:00 UTC (approximately)
      #
      # @example Validate format
      #   CompactIdEncoder.valid?("i50jj3")  # => true
      #   CompactIdEncoder.valid?("invalid") # => false
      #
      class CompactIdEncoder
        DEFAULT_YEAR_ZERO = 2000
        DEFAULT_ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyz"

        # 40-minute block duration (36 blocks per day = 24 * 60 / 40)
        BLOCK_MINUTES = 40
        BLOCK_SECONDS = BLOCK_MINUTES * 60  # 2400 seconds per block

        # Precision values within a 40-minute block
        # 36^2 = 1296 combinations for 2400 seconds = ~1.85s precision
        PRECISION_DIVISOR = 1296  # 36^2

        # Maximum values for component validation
        MAX_MONTHS_OFFSET = 1295  # 108 years * 12 months
        MAX_DAY = 30              # Calendar days 1-31 map to 0-30
        MAX_BLOCK = 35            # 36 blocks per day (0-35)
        MAX_PRECISION = 1295      # 36^2 - 1

        class << self
          # Encode a Time object to a 6-character compact ID
          #
          # @param time [Time] The time to encode
          # @param year_zero [Integer] Base year for encoding (default: 2000)
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [String] 6-character compact ID
          # @raise [ArgumentError] If time is outside supported range
          def encode(time, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            time = time.utc if time.respond_to?(:utc)

            # Calculate month offset from year_zero
            months_offset = ((time.year - year_zero) * 12) + (time.month - 1)

            if months_offset.negative? || months_offset > 1295
              raise ArgumentError, "Time #{time} is outside supported range (#{year_zero} to #{year_zero + 107})"
            end

            # Day of month (1-31 -> 0-30, fits in single base36 digit 0-35)
            day = time.day - 1

            # 40-minute block of day (0-35)
            minutes_of_day = (time.hour * 60) + time.min
            block = minutes_of_day / BLOCK_MINUTES

            # Precision within block
            # Clamp seconds to valid range (0-59) to handle edge cases:
            # - Invalid time objects with seconds > 59
            # - Rounding errors in floating point time operations
            # Note: Ruby's Time#sec returns 0-59 for normal times; leap seconds
            # (60) are not typically represented in Ruby Time objects.
            clamped_seconds = time.sec.clamp(0, 59)
            seconds_into_block = ((minutes_of_day % BLOCK_MINUTES) * 60) + clamped_seconds
            precision = (seconds_into_block * PRECISION_DIVISOR) / BLOCK_SECONDS
            # Clamp precision to valid 2-digit base36 range (0-1295)
            # This defensive clamping handles any arithmetic edge cases
            # that could produce values outside the valid range.
            precision = precision.clamp(0, PRECISION_DIVISOR - 1)

            # Build result string with pre-allocated capacity to reduce allocations
            result = String.new(capacity: 6)
            result << encode_value(months_offset, 2, alphabet)
            result << encode_value(day, 1, alphabet)
            result << encode_value(block, 1, alphabet)
            result << encode_value(precision, 2, alphabet)
            result.freeze
          end

          # Decode a 6-character compact ID to a Time object
          #
          # @param compact_id [String] The 6-character compact ID
          # @param year_zero [Integer] Base year for decoding (default: 2000)
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [Time] The decoded time (UTC)
          # @raise [ArgumentError] If compact_id format is invalid or components out of range
          def decode(compact_id, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            validate_format!(compact_id, alphabet)

            id = compact_id.downcase

            # Decode components
            months_offset = decode_value(id[0..1], alphabet)
            day = decode_value(id[2], alphabet)
            block = decode_value(id[3], alphabet)
            precision = decode_value(id[4..5], alphabet)

            # Validate component ranges to prevent Time.utc ArgumentError
            validate_component_ranges!(months_offset, day, block, precision)

            # Calculate date/time components
            year = year_zero + (months_offset / 12)
            month = (months_offset % 12) + 1
            calendar_day = day + 1

            # Calculate time from block and precision
            minutes_of_day = block * BLOCK_MINUTES
            seconds_into_block = (precision * BLOCK_SECONDS) / PRECISION_DIVISOR

            hour = minutes_of_day / 60
            minute = (minutes_of_day % 60) + (seconds_into_block / 60)
            second = seconds_into_block % 60

            # Handle minute overflow
            if minute >= 60
              hour += minute / 60
              minute = minute % 60
            end

            Time.utc(year, month, calendar_day, hour, minute, second)
          end

          # Validate if a string is a valid compact ID format
          #
          # Checks both format (6 chars, valid alphabet) and semantic validity
          # (components within valid ranges that won't cause Time.utc errors).
          #
          # @param compact_id [String] The string to validate
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [Boolean] true if valid format and semantically valid
          def valid?(compact_id, alphabet: DEFAULT_ALPHABET)
            return false unless compact_id.is_a?(String)
            return false unless compact_id.length == 6
            return false unless compact_id.downcase.chars.all? { |c| alphabet.include?(c) }

            # Also validate semantic ranges
            id = compact_id.downcase
            months_offset = decode_value(id[0..1], alphabet)
            day = decode_value(id[2], alphabet)
            block = decode_value(id[3], alphabet)
            precision = decode_value(id[4..5], alphabet)

            # Check component ranges (day must be 0-30 for calendar days 1-31)
            months_offset <= 1295 && day <= 30 && block <= 35 && precision <= 1295
          end

          private

          # Encode a numeric value to base36 with specified width
          #
          # @param value [Integer] Value to encode
          # @param width [Integer] Number of characters
          # @param alphabet [String] Encoding alphabet
          # @return [String] Encoded string
          def encode_value(value, width, alphabet)
            base = alphabet.length
            result = ""

            width.times do
              result = alphabet[value % base] + result
              value /= base
            end

            result
          end

          # Decode a base36 string to numeric value
          #
          # @param str [String] String to decode
          # @param alphabet [String] Encoding alphabet
          # @return [Integer] Decoded value
          # @raise [ArgumentError] If character not found in alphabet
          def decode_value(str, alphabet)
            base = alphabet.length
            value = 0

            str.each_char do |c|
              idx = alphabet.index(c)
              # Defensive check - validate_format! should catch this, but be safe
              raise ArgumentError, "Invalid character in compact ID: #{c}" unless idx

              value = (value * base) + idx
            end

            value
          end

          # Validate compact ID format
          #
          # @param compact_id [String] The string to validate
          # @param alphabet [String] Base36 alphabet
          # @raise [ArgumentError] If format is invalid
          def validate_format!(compact_id, alphabet)
            raise ArgumentError, "Compact ID must be a string" unless compact_id.is_a?(String)
            raise ArgumentError, "Compact ID must be 6 characters" unless compact_id.length == 6

            invalid_chars = compact_id.downcase.chars.reject { |c| alphabet.include?(c) }
            unless invalid_chars.empty?
              raise ArgumentError, "Invalid characters in compact ID: #{invalid_chars.join(', ')}"
            end
          end

          # Validate decoded component ranges
          #
          # @param months_offset [Integer] Months since year_zero (max 1295 = 108 years)
          # @param day [Integer] Day of month 0-indexed (max 30 for days 1-31)
          # @param block [Integer] 40-minute block (max 35 for 36 blocks/day)
          # @param precision [Integer] Precision within block (max 1295 = 36^2 - 1)
          # @raise [ArgumentError] If any component is out of range
          def validate_component_ranges!(months_offset, day, block, precision)
            if months_offset > MAX_MONTHS_OFFSET
              raise ArgumentError, "Month offset #{months_offset} exceeds maximum (#{MAX_MONTHS_OFFSET} = 108 years)"
            end

            if day > MAX_DAY
              raise ArgumentError, "Day value #{day} exceeds maximum (#{MAX_DAY} for calendar days 1-31)"
            end

            if block > MAX_BLOCK
              raise ArgumentError, "Block value #{block} exceeds maximum (#{MAX_BLOCK} for 36 blocks/day)"
            end

            if precision > MAX_PRECISION
              raise ArgumentError, "Precision value #{precision} exceeds maximum (#{MAX_PRECISION} = 36^2 - 1)"
            end
          end
        end
      end
    end
  end
end
