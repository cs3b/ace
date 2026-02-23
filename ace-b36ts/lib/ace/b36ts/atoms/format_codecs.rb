# frozen_string_literal: true

module Ace
  module B36ts
    module Atoms
      # Format-specific encode/decode/increment methods for CompactIdEncoder.
      #
      # Extracted to keep the main encoder focused on dispatch and validation,
      # while this module holds the per-format codec logic.
      #
      # Methods here rely on private helpers defined in CompactIdEncoder
      # (encode_value, decode_value, validate_*, calculate_months_offset, etc.)
      # and are mixed in via `include FormatCodecs` inside the class << self block.
      module FormatCodecs
        # ===================
        # 2sec Format (6 chars, ~1.85s precision)
        # ===================

        # Encode a Time object to a 6-character compact ID (~1.85s precision)
        #
        # @param time [Time] The time to encode (should already be UTC from encode_with_format)
        # @param year_zero [Integer] Base year for encoding (default: 2000)
        # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
        # @return [String] 6-character compact ID
        # @raise [ArgumentError] If time is outside supported range
        def encode_2sec(time, year_zero: CompactIdEncoder::DEFAULT_YEAR_ZERO, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
          # Note: UTC conversion handled by encode_with_format caller
          months_offset = calculate_months_offset(time, year_zero)

          # Day of month (1-31 -> 0-30, fits in single base36 digit 0-35)
          day = time.day - 1

          # 40-minute block of day (0-35)
          minutes_of_day = (time.hour * 60) + time.min
          block = minutes_of_day / CompactIdEncoder::BLOCK_MINUTES

          # Precision within block
          # Clamp seconds to valid range (0-59) to handle edge cases:
          # - Invalid time objects with seconds > 59
          # - Rounding errors in floating point time operation
          # Note: Ruby's Time#sec returns 0-59 for normal times; leap seconds
          # (60) are not typically represented in Ruby Time objects.
          clamped_seconds = time.sec.clamp(0, 59)
          seconds_into_block = ((minutes_of_day % CompactIdEncoder::BLOCK_MINUTES) * 60) + clamped_seconds
          precision = (seconds_into_block * CompactIdEncoder::PRECISION_DIVISOR) / CompactIdEncoder::BLOCK_SECONDS
          # Clamp precision to valid 2-digit base36 range (0-1295)
          # This defensive clamping handles any arithmetic edge cases
          # that could produce values outside the valid range.
          precision = precision.clamp(0, CompactIdEncoder::PRECISION_DIVISOR - 1)

          # Build result string with pre-allocated capacity to reduce allocations
          result = String.new(capacity: 6)
          result << encode_value(months_offset, 2, alphabet)
          result << encode_value(day, 1, alphabet)
          result << encode_value(block, 1, alphabet)
          result << encode_value(precision, 2, alphabet)
          result.freeze
        end

        # Decode a 6-character compact ID to a Time object (~1.85s precision)
        #
        # @param compact_id [String] The 6-character compact ID
        # @param year_zero [Integer] Base year for decoding (default: 2000)
        # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
        # @return [Time] The decoded time (UTC)
        # @raise [ArgumentError] If compact_id format is invalid or components out of range
        def decode_2sec(compact_id, year_zero: CompactIdEncoder::DEFAULT_YEAR_ZERO, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
          validate_length!(compact_id, 6)
          validate_alphabet!(compact_id, alphabet)

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
          minutes_of_day = block * CompactIdEncoder::BLOCK_MINUTES
          seconds_into_block = (precision * CompactIdEncoder::BLOCK_SECONDS) / CompactIdEncoder::PRECISION_DIVISOR

          hour = minutes_of_day / 60
          minute = (minutes_of_day % 60) + (seconds_into_block / 60)
          second = seconds_into_block % 60

          hour, minute = normalize_minute_overflow(hour, minute)

          Time.utc(year, month, calendar_day, hour, minute, second)
        end

        # ===================
        # Month Format (2 chars)
        # ===================

        # Encode to month format (2 chars: months offset only)
        #
        # @param time [Time] The time to encode (should already be UTC from encode_with_format)
        # @param year_zero [Integer] Base year for encoding
        # @param alphabet [String] Base36 alphabet
        # @return [String] 2-character month ID
        def encode_month(time, year_zero: CompactIdEncoder::DEFAULT_YEAR_ZERO, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
          # Note: UTC conversion handled by encode_with_format caller
          months_offset = calculate_months_offset(time, year_zero)
          encode_value(months_offset, 2, alphabet)
        end

        # Decode month format (2 chars)
        #
        # @param encoded_id [String] The 2-character month ID
        # @param year_zero [Integer] Base year for decoding
        # @param alphabet [String] Base36 alphabet
        # @return [Time] The decoded time (UTC, first day of month at midnight)
        def decode_month(encoded_id, year_zero: CompactIdEncoder::DEFAULT_YEAR_ZERO, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
          validate_length!(encoded_id, 2)
          validate_alphabet!(encoded_id, alphabet)

          months_offset = decode_value(encoded_id.downcase, alphabet)

          if months_offset > CompactIdEncoder::MAX_MONTHS_OFFSET
            raise ArgumentError, "Month offset #{months_offset} exceeds maximum (#{CompactIdEncoder::MAX_MONTHS_OFFSET} = 108 years)"
          end

          year = year_zero + (months_offset / 12)
          month = (months_offset % 12) + 1

          Time.utc(year, month, 1, 0, 0, 0)
        end

        # ===================
        # Week Format (3 chars)
        # ===================

        # Encode to week format (3 chars: months + week)
        #
        # Week value is in range 31-35 to distinguish from day format
        #
        # @param time [Time] The time to encode (should already be UTC from encode_with_format)
        # @param year_zero [Integer] Base year for encoding
        # @param alphabet [String] Base36 alphabet
        # @return [String] 3-character week ID
        def encode_week(time, year_zero: CompactIdEncoder::DEFAULT_YEAR_ZERO, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
          # Note: UTC conversion handled by encode_with_format caller
          iso_year, iso_month, week_in_month = iso_week_month_and_number(time)
          months_offset = calculate_months_offset_ym(iso_year, iso_month, year_zero)
          week_value = week_in_month + 30  # Offset to 31-35 range

          result = String.new(capacity: 3)
          result << encode_value(months_offset, 2, alphabet)
          result << encode_value(week_value, 1, alphabet)
          result.freeze
        end

        # Decode week format (3 chars)
        #
        # Returns the Thursday of the Nth ISO week in the encoded month.
        # For week 5 in months with fewer than 5 Thursdays, the result is
        # clamped to the last Thursday of the month (lossy).
        #
        # @param encoded_id [String] The 3-character week ID
        # @param year_zero [Integer] Base year for decoding
        # @param alphabet [String] Base36 alphabet
        # @return [Time] The decoded time (UTC, Thursday of the week at midnight)
        def decode_week(encoded_id, year_zero: CompactIdEncoder::DEFAULT_YEAR_ZERO, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
          validate_length!(encoded_id, 3)
          validate_alphabet!(encoded_id, alphabet)

          id = encoded_id.downcase
          months_offset = decode_value(id[0..1], alphabet)
          week_value = decode_value(id[2], alphabet)

          unless week_value.between?(FormatSpecs::WEEK_FORMAT_MIN, FormatSpecs::WEEK_FORMAT_MAX)
            raise ArgumentError, "Week value #{week_value} must be between #{FormatSpecs::WEEK_FORMAT_MIN}-#{FormatSpecs::WEEK_FORMAT_MAX}"
          end

          if months_offset > CompactIdEncoder::MAX_MONTHS_OFFSET
            raise ArgumentError, "Month offset #{months_offset} exceeds maximum (#{CompactIdEncoder::MAX_MONTHS_OFFSET} = 108 years)"
          end

          year = year_zero + (months_offset / 12)
          month = (months_offset % 12) + 1
          week_in_month = week_value - 30  # Convert back to 1-5 range

          # Find the Nth Thursday in the month
          first_of_month = Date.new(year, month, 1)
          days_until_thu = (4 - first_of_month.wday) % 7
          first_thursday = first_of_month + days_until_thu
          target_thursday = first_thursday + ((week_in_month - 1) * 7)

          # Clamp if week 5 doesn't exist in this month
          if target_thursday.month != month
            last_day = Date.new(year, month, -1)
            target_thursday = last_day - ((last_day.wday - 4) % 7)
          end

          Time.utc(target_thursday.year, target_thursday.month, target_thursday.day, 0, 0, 0)
        end

        # ===================
        # Day Format (3 chars)
        # ===================

        # Encode to day format (3 chars: months + day)
        #
        # Day value is in range 0-30 to distinguish from week format
        #
        # @param time [Time] The time to encode (should already be UTC from encode_with_format)
        # @param year_zero [Integer] Base year for encoding
        # @param alphabet [String] Base36 alphabet
        # @return [String] 3-character day ID
        def encode_day(time, year_zero: CompactIdEncoder::DEFAULT_YEAR_ZERO, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
          # Note: UTC conversion handled by encode_with_format caller
          months_offset = calculate_months_offset(time, year_zero)
          day = (time.day - 1).clamp(0, CompactIdEncoder::MAX_DAY)

          result = String.new(capacity: 3)
          result << encode_value(months_offset, 2, alphabet)
          result << encode_value(day, 1, alphabet)
          result.freeze
        end

        # Decode day format (3 chars)
        #
        # @param encoded_id [String] The 3-character day ID
        # @param year_zero [Integer] Base year for decoding
        # @param alphabet [String] Base36 alphabet
        # @return [Time] The decoded time (UTC, at midnight)
        def decode_day(encoded_id, year_zero: CompactIdEncoder::DEFAULT_YEAR_ZERO, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
          validate_length!(encoded_id, 3)
          validate_alphabet!(encoded_id, alphabet)

          id = encoded_id.downcase
          months_offset = decode_value(id[0..1], alphabet)
          day = decode_value(id[2], alphabet)

          unless day <= FormatSpecs::DAY_FORMAT_MAX
            raise ArgumentError, "Day value #{day} exceeds day format maximum (#{FormatSpecs::DAY_FORMAT_MAX} = 31 calendar days)"
          end

          if months_offset > CompactIdEncoder::MAX_MONTHS_OFFSET
            raise ArgumentError, "Month offset #{months_offset} exceeds maximum (#{CompactIdEncoder::MAX_MONTHS_OFFSET} = 108 years)"
          end

          year = year_zero + (months_offset / 12)
          month = (months_offset % 12) + 1
          calendar_day = day + 1

          Time.utc(year, month, calendar_day, 0, 0, 0)
        end

        # ===================
        # 40min Format (4 chars, 40-minute block precision)
        # ===================

        # Encode to 40min format (4 chars: months + day + 40-minute block)
        #
        # Uses 40-minute blocks (0-35) for consistency with position 4 of compact format
        #
        # @param time [Time] The time to encode (should already be UTC from encode_with_format)
        # @param year_zero [Integer] Base year for encoding
        # @param alphabet [String] Base36 alphabet
        # @return [String] 4-character 40min ID
        def encode_40min(time, year_zero: CompactIdEncoder::DEFAULT_YEAR_ZERO, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
          # Note: UTC conversion handled by encode_with_format caller
          months_offset = calculate_months_offset(time, year_zero)
          day = (time.day - 1).clamp(0, CompactIdEncoder::MAX_DAY)

          # Use 40-minute blocks like position 4 of compact format
          minutes_of_day = (time.hour * 60) + time.min
          block = minutes_of_day / CompactIdEncoder::BLOCK_MINUTES  # 0-35

          result = String.new(capacity: 4)
          result << encode_value(months_offset, 2, alphabet)
          result << encode_value(day, 1, alphabet)
          result << encode_value(block, 1, alphabet)
          result.freeze
        end

        # Decode 40min format (4 chars)
        #
        # @param encoded_id [String] The 4-character 40min ID
        # @param year_zero [Integer] Base year for decoding
        # @param alphabet [String] Base36 alphabet
        # @return [Time] The decoded time (UTC, at start of 40-min block)
        def decode_40min(encoded_id, year_zero: CompactIdEncoder::DEFAULT_YEAR_ZERO, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
          validate_length!(encoded_id, 4)
          validate_alphabet!(encoded_id, alphabet)

          id = encoded_id.downcase
          months_offset = decode_value(id[0..1], alphabet)
          day = decode_value(id[2], alphabet)
          block = decode_value(id[3], alphabet)

          if day > CompactIdEncoder::MAX_DAY
            raise ArgumentError, "Day value #{day} exceeds maximum (#{CompactIdEncoder::MAX_DAY} = 31 calendar days)"
          end

          if months_offset > CompactIdEncoder::MAX_MONTHS_OFFSET
            raise ArgumentError, "Month offset #{months_offset} exceeds maximum (#{CompactIdEncoder::MAX_MONTHS_OFFSET} = 108 years)"
          end

          if block > CompactIdEncoder::MAX_BLOCK
            raise ArgumentError, "Block value #{block} exceeds maximum (#{CompactIdEncoder::MAX_BLOCK} = 36 blocks per day)"
          end

          year = year_zero + (months_offset / 12)
          month = (months_offset % 12) + 1
          calendar_day = day + 1

          # Calculate time from block (40-minute block)
          minutes_of_day = block * CompactIdEncoder::BLOCK_MINUTES
          hour = minutes_of_day / 60
          minute = minutes_of_day % 60

          Time.utc(year, month, calendar_day, hour, minute, 0)
        end

        # ===================
        # 50ms Format (7 chars, ~50ms precision)
        # ===================

        # Encode to 50ms format (7 chars: 2sec + 1 extra precision digit)
        # ~50ms precision
        #
        # @param time [Time] The time to encode (should already be UTC from encode_with_format)
        # @param year_zero [Integer] Base year for encoding
        # @param alphabet [String] Base36 alphabet
        # @return [String] 7-character 50ms ID
        def encode_50ms(time, year_zero: CompactIdEncoder::DEFAULT_YEAR_ZERO, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
          # Note: UTC conversion handled by encode_with_format caller
          months_offset = calculate_months_offset(time, year_zero)
          day = time.day - 1
          minutes_of_day = (time.hour * 60) + time.min
          block = minutes_of_day / CompactIdEncoder::BLOCK_MINUTES

          # 50ms: 3 digits of precision (36^3 = 46656 combinations for ~50ms)
          clamped_seconds = time.sec.clamp(0, 59)
          usec = time.respond_to?(:usec) ? time.usec : 0
          total_usecs = ((minutes_of_day % CompactIdEncoder::BLOCK_MINUTES) * 60 + clamped_seconds) * 1_000_000 + usec
          block_usecs = CompactIdEncoder::BLOCK_SECONDS * 1_000_000
          precision = (total_usecs * CompactIdEncoder::PRECISION_DIVISOR_3) / block_usecs
          precision = precision.clamp(0, CompactIdEncoder::PRECISION_DIVISOR_3 - 1)

          result = String.new(capacity: 7)
          result << encode_value(months_offset, 2, alphabet)
          result << encode_value(day, 1, alphabet)
          result << encode_value(block, 1, alphabet)
          result << encode_value(precision, 3, alphabet)
          result.freeze
        end

        # Decode 50ms format (7 chars)
        #
        # @param encoded_id [String] The 7-character 50ms ID
        # @param year_zero [Integer] Base year for decoding
        # @param alphabet [String] Base36 alphabet
        # @return [Time] The decoded time (UTC, ~50ms precision)
        def decode_50ms(encoded_id, year_zero: CompactIdEncoder::DEFAULT_YEAR_ZERO, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
          validate_length!(encoded_id, 7)
          validate_alphabet!(encoded_id, alphabet)

          id = encoded_id.downcase
          months_offset = decode_value(id[0..1], alphabet)
          day = decode_value(id[2], alphabet)
          block = decode_value(id[3], alphabet)
          precision = decode_value(id[4..6], alphabet)

          validate_base_components!(months_offset, day, block)
          validate_precision_range!(precision, CompactIdEncoder::PRECISION_DIVISOR_3)

          year = year_zero + (months_offset / 12)
          month = (months_offset % 12) + 1
          calendar_day = day + 1

          # Calculate time with 50ms precision
          minutes_of_day = block * CompactIdEncoder::BLOCK_MINUTES
          total_usecs = (precision * CompactIdEncoder::BLOCK_SECONDS * 1_000_000) / CompactIdEncoder::PRECISION_DIVISOR_3

          hour = minutes_of_day / 60
          remaining_usecs = total_usecs % 60_000_000
          minute = (minutes_of_day % 60) + (total_usecs / 60_000_000)
          second = (remaining_usecs / 1_000_000).to_i
          usec = (remaining_usecs % 1_000_000).to_i

          hour, minute = normalize_minute_overflow(hour, minute)

          Time.utc(year, month, calendar_day, hour, minute, second, usec)
        end

        # ===================
        # ms Format (8 chars, ~1.4ms precision)
        # ===================

        # Encode to ms format (8 chars: 50ms + 1 extra precision digit)
        # ~1.4ms precision
        #
        # @param time [Time] The time to encode (should already be UTC from encode_with_format)
        # @param year_zero [Integer] Base year for encoding
        # @param alphabet [String] Base36 alphabet
        # @return [String] 8-character ms ID
        def encode_ms(time, year_zero: CompactIdEncoder::DEFAULT_YEAR_ZERO, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
          # Note: UTC conversion handled by encode_with_format caller
          months_offset = calculate_months_offset(time, year_zero)
          day = time.day - 1
          minutes_of_day = (time.hour * 60) + time.min
          block = minutes_of_day / CompactIdEncoder::BLOCK_MINUTES

          # ms: 4 digits of precision (36^4 = 1679616 combinations for ~1.4ms)
          clamped_seconds = time.sec.clamp(0, 59)
          usec = time.respond_to?(:usec) ? time.usec : 0
          total_usecs = ((minutes_of_day % CompactIdEncoder::BLOCK_MINUTES) * 60 + clamped_seconds) * 1_000_000 + usec
          block_usecs = CompactIdEncoder::BLOCK_SECONDS * 1_000_000
          precision = (total_usecs * CompactIdEncoder::PRECISION_DIVISOR_4) / block_usecs
          precision = precision.clamp(0, CompactIdEncoder::PRECISION_DIVISOR_4 - 1)

          result = String.new(capacity: 8)
          result << encode_value(months_offset, 2, alphabet)
          result << encode_value(day, 1, alphabet)
          result << encode_value(block, 1, alphabet)
          result << encode_value(precision, 4, alphabet)
          result.freeze
        end

        # Decode ms format (8 chars)
        #
        # @param encoded_id [String] The 8-character ms ID
        # @param year_zero [Integer] Base year for decoding
        # @param alphabet [String] Base36 alphabet
        # @return [Time] The decoded time (UTC, ~1.4ms precision)
        def decode_ms(encoded_id, year_zero: CompactIdEncoder::DEFAULT_YEAR_ZERO, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
          validate_length!(encoded_id, 8)
          validate_alphabet!(encoded_id, alphabet)

          id = encoded_id.downcase
          months_offset = decode_value(id[0..1], alphabet)
          day = decode_value(id[2], alphabet)
          block = decode_value(id[3], alphabet)
          precision = decode_value(id[4..7], alphabet)

          validate_base_components!(months_offset, day, block)
          validate_precision_range!(precision, CompactIdEncoder::PRECISION_DIVISOR_4)

          year = year_zero + (months_offset / 12)
          month = (months_offset % 12) + 1
          calendar_day = day + 1

          # Calculate time with ms precision
          minutes_of_day = block * CompactIdEncoder::BLOCK_MINUTES
          total_usecs = (precision * CompactIdEncoder::BLOCK_SECONDS * 1_000_000) / CompactIdEncoder::PRECISION_DIVISOR_4

          hour = minutes_of_day / 60
          remaining_usecs = total_usecs % 60_000_000
          minute = (minutes_of_day % 60) + (total_usecs / 60_000_000)
          second = (remaining_usecs / 1_000_000).to_i
          usec = (remaining_usecs % 1_000_000).to_i

          hour, minute = normalize_minute_overflow(hour, minute)

          Time.utc(year, month, calendar_day, hour, minute, second, usec)
        end

        # ===================
        # Increment ID Helpers
        # ===================

        # Increment month format ID (2 chars)
        # Overflow: month -> ERROR
        def increment_month_id(id, alphabet, base)
          month = decode_value(id[0..1], alphabet)
          month += 1

          if month > CompactIdEncoder::MAX_MONTHS_OFFSET
            raise ArgumentError, "Cannot increment: would exceed month range (max #{CompactIdEncoder::MAX_MONTHS_OFFSET})"
          end

          encode_value(month, 2, alphabet)
        end

        # Increment week format ID (3 chars)
        # Overflow: week -> month
        def increment_week_id(id, alphabet, base)
          month = decode_value(id[0..1], alphabet)
          week = decode_value(id[2], alphabet)

          week += 1
          if week > FormatSpecs::WEEK_FORMAT_MAX
            week = FormatSpecs::WEEK_FORMAT_MIN
            month += 1
            if month > CompactIdEncoder::MAX_MONTHS_OFFSET
              raise ArgumentError, "Cannot increment: would exceed month range (max #{CompactIdEncoder::MAX_MONTHS_OFFSET})"
            end
          end

          result = String.new(capacity: 3)
          result << encode_value(month, 2, alphabet)
          result << encode_value(week, 1, alphabet)
          result.freeze
        end

        # Increment day format ID (3 chars)
        # Overflow: day -> month
        def increment_day_id(id, alphabet, base)
          month = decode_value(id[0..1], alphabet)
          day = decode_value(id[2], alphabet)

          day += 1
          if day > CompactIdEncoder::MAX_DAY
            day = 0
            month += 1
            if month > CompactIdEncoder::MAX_MONTHS_OFFSET
              raise ArgumentError, "Cannot increment: would exceed month range (max #{CompactIdEncoder::MAX_MONTHS_OFFSET})"
            end
          end

          result = String.new(capacity: 3)
          result << encode_value(month, 2, alphabet)
          result << encode_value(day, 1, alphabet)
          result.freeze
        end

        # Increment 40min format ID (4 chars)
        # Overflow: block -> day -> month
        def increment_40min_id(id, alphabet, base)
          month = decode_value(id[0..1], alphabet)
          day = decode_value(id[2], alphabet)
          block = decode_value(id[3], alphabet)

          block += 1
          if block > CompactIdEncoder::MAX_BLOCK
            block = 0
            day += 1
            if day > CompactIdEncoder::MAX_DAY
              day = 0
              month += 1
              if month > CompactIdEncoder::MAX_MONTHS_OFFSET
                raise ArgumentError, "Cannot increment: would exceed month range (max #{CompactIdEncoder::MAX_MONTHS_OFFSET})"
              end
            end
          end

          result = String.new(capacity: 4)
          result << encode_value(month, 2, alphabet)
          result << encode_value(day, 1, alphabet)
          result << encode_value(block, 1, alphabet)
          result.freeze
        end

        # Increment 2sec format ID (6 chars)
        # Overflow: precision -> block -> day -> month
        def increment_2sec_id(id, alphabet, base)
          month = decode_value(id[0..1], alphabet)
          day = decode_value(id[2], alphabet)
          block = decode_value(id[3], alphabet)
          precision = decode_value(id[4..5], alphabet)

          precision += 1
          if precision > CompactIdEncoder::MAX_PRECISION
            precision = 0
            block += 1
            if block > CompactIdEncoder::MAX_BLOCK
              block = 0
              day += 1
              if day > CompactIdEncoder::MAX_DAY
                day = 0
                month += 1
                if month > CompactIdEncoder::MAX_MONTHS_OFFSET
                  raise ArgumentError, "Cannot increment: would exceed month range (max #{CompactIdEncoder::MAX_MONTHS_OFFSET})"
                end
              end
            end
          end

          result = String.new(capacity: 6)
          result << encode_value(month, 2, alphabet)
          result << encode_value(day, 1, alphabet)
          result << encode_value(block, 1, alphabet)
          result << encode_value(precision, 2, alphabet)
          result.freeze
        end

        # Increment 50ms format ID (7 chars)
        # Overflow: precision -> block -> day -> month
        def increment_50ms_id(id, alphabet, base)
          month = decode_value(id[0..1], alphabet)
          day = decode_value(id[2], alphabet)
          block = decode_value(id[3], alphabet)
          precision = decode_value(id[4..6], alphabet)

          max_precision_50ms = CompactIdEncoder::PRECISION_DIVISOR_3 - 1  # 46655

          precision += 1
          if precision > max_precision_50ms
            precision = 0
            block += 1
            if block > CompactIdEncoder::MAX_BLOCK
              block = 0
              day += 1
              if day > CompactIdEncoder::MAX_DAY
                day = 0
                month += 1
                if month > CompactIdEncoder::MAX_MONTHS_OFFSET
                  raise ArgumentError, "Cannot increment: would exceed month range (max #{CompactIdEncoder::MAX_MONTHS_OFFSET})"
                end
              end
            end
          end

          result = String.new(capacity: 7)
          result << encode_value(month, 2, alphabet)
          result << encode_value(day, 1, alphabet)
          result << encode_value(block, 1, alphabet)
          result << encode_value(precision, 3, alphabet)
          result.freeze
        end

        # Increment ms format ID (8 chars)
        # Overflow: precision -> block -> day -> month
        def increment_ms_id(id, alphabet, base)
          month = decode_value(id[0..1], alphabet)
          day = decode_value(id[2], alphabet)
          block = decode_value(id[3], alphabet)
          precision = decode_value(id[4..7], alphabet)

          max_precision_ms = CompactIdEncoder::PRECISION_DIVISOR_4 - 1  # 1679615

          precision += 1
          if precision > max_precision_ms
            precision = 0
            block += 1
            if block > CompactIdEncoder::MAX_BLOCK
              block = 0
              day += 1
              if day > CompactIdEncoder::MAX_DAY
                day = 0
                month += 1
                if month > CompactIdEncoder::MAX_MONTHS_OFFSET
                  raise ArgumentError, "Cannot increment: would exceed month range (max #{CompactIdEncoder::MAX_MONTHS_OFFSET})"
                end
              end
            end
          end

          result = String.new(capacity: 8)
          result << encode_value(month, 2, alphabet)
          result << encode_value(day, 1, alphabet)
          result << encode_value(block, 1, alphabet)
          result << encode_value(precision, 4, alphabet)
          result.freeze
        end
      end
    end
  end
end
