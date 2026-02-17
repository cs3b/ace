# frozen_string_literal: true

require "time"
require "date"
require "set"

require_relative "format_specs"

module Ace
  module B36ts
  module Atoms
      # Encodes and decodes timestamps to/from variable-length Base36 compact IDs.
      #
      # Supports 7 format types with varying precision and length:
      # - 2sec (6 chars, ~1.85s precision) - default
      # - month (2 chars, month precision)
      # - week (3 chars, week precision)
      # - day (3 chars, day precision)
      # - 40min (4 chars, 40-minute block precision)
      # - 50ms (7 chars, ~50ms precision)
      # - ms (8 chars, ~1.4ms precision)
      #
      # Compact format design (6 Base36 digits):
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
        DEFAULT_ALPHABET_SET = DEFAULT_ALPHABET.chars.to_set.freeze

        # 40-minute block duration (36 blocks per day = 24 * 60 / 40)
        BLOCK_MINUTES = 40
        BLOCK_SECONDS = BLOCK_MINUTES * 60  # 2400 seconds per block

        # Precision values within a 40-minute block
        # 36^2 = 1296 combinations for 2400 seconds = ~1.85s precision
        PRECISION_DIVISOR = 1296  # 36^2

        # Additional precision for high-7 and high-8 formats
        PRECISION_DIVISOR_3 = 46_656   # 36^3 for high-7 (~50ms precision)
        PRECISION_DIVISOR_4 = 1_679_616  # 36^4 for high-8 (~1.4ms precision)

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
            encode_with_format(time, format: :"2sec", year_zero: year_zero, alphabet: alphabet)
          end

          # Encode a Time object to a compact ID with specified format
          #
          # @param time [Time] The time to encode
          # @param format [Symbol] Output format (:"2sec", :month, :week, :day, :"40min", :"50ms", :ms)
          # @param year_zero [Integer] Base year for encoding (default: 2000)
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [String] Variable-length compact ID (2-8 characters depending on format)
          # @raise [ArgumentError] If time is outside supported range or format is invalid
          def encode_with_format(time, format:, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            time = time.utc if time.respond_to?(:utc)

            case format
            when :"2sec"
              encode_2sec(time, year_zero: year_zero, alphabet: alphabet)
            when :month
              encode_month(time, year_zero: year_zero, alphabet: alphabet)
            when :week
              encode_week(time, year_zero: year_zero, alphabet: alphabet)
            when :day
              encode_day(time, year_zero: year_zero, alphabet: alphabet)
            when :"40min"
              encode_40min(time, year_zero: year_zero, alphabet: alphabet)
            when :"50ms"
              encode_50ms(time, year_zero: year_zero, alphabet: alphabet)
            when :ms
              encode_ms(time, year_zero: year_zero, alphabet: alphabet)
            else
              suggestion = suggest_format_name(format)
              msg = "Invalid format: #{format}. Must be one of #{FormatSpecs.all_formats.join(', ')}"
              msg += ". Did you mean '#{suggestion}'?" if suggestion
              raise ArgumentError, msg
            end
          end

          # Decode a 6-character compact ID to a Time object
          #
          # @param compact_id [String] The 6-character compact ID
          # @param year_zero [Integer] Base year for decoding (default: 2000)
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [Time] The decoded time (UTC)
          # @raise [ArgumentError] If compact_id format is invalid or components out of range
          def decode(compact_id, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            decode_with_format(compact_id, format: :"2sec", year_zero: year_zero, alphabet: alphabet)
          end

          # Decode a compact ID to a Time object with specified format
          #
          # @param compact_id [String] The compact ID to decode
          # @param format [Symbol] Format of the compact ID
          # @param year_zero [Integer] Base year for decoding (default: 2000)
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [Time] The decoded time (UTC)
          # @raise [ArgumentError] If compact_id format is invalid or components out of range
          def decode_with_format(compact_id, format:, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            case format
            when :"2sec"
              decode_2sec(compact_id, year_zero: year_zero, alphabet: alphabet)
            when :month
              decode_month(compact_id, year_zero: year_zero, alphabet: alphabet)
            when :week
              decode_week(compact_id, year_zero: year_zero, alphabet: alphabet)
            when :day
              decode_day(compact_id, year_zero: year_zero, alphabet: alphabet)
            when :"40min"
              decode_40min(compact_id, year_zero: year_zero, alphabet: alphabet)
            when :"50ms"
              decode_50ms(compact_id, year_zero: year_zero, alphabet: alphabet)
            when :ms
              decode_ms(compact_id, year_zero: year_zero, alphabet: alphabet)
            else
              suggestion = suggest_format_name(format)
              msg = "Invalid format: #{format}. Must be one of #{FormatSpecs.all_formats.join(', ')}"
              msg += ". Did you mean '#{suggestion}'?" if suggestion
              raise ArgumentError, msg
            end
          end

          # Detect the format of a compact ID string
          #
          # @param encoded_id [String] The encoded ID string
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [Symbol, nil] Detected format or nil if unrecognized
          def detect_format(encoded_id, alphabet: DEFAULT_ALPHABET)
            FormatSpecs.detect_from_id(encoded_id, alphabet: alphabet)
          end

          # Decode a compact ID with automatic format detection
          #
          # @param encoded_id [String] The compact ID to decode (2-8 characters)
          # @param year_zero [Integer] Base year for decoding (default: 2000)
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [Time] The decoded time (UTC)
          # @raise [ArgumentError] If format cannot be detected or components out of range
          def decode_auto(encoded_id, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            format = detect_format(encoded_id, alphabet: alphabet)

            if format.nil?
              raise ArgumentError, "Cannot detect format for compact ID: #{encoded_id} (unsupported length or invalid characters)"
            end

            decode_with_format(encoded_id, format: format, year_zero: year_zero, alphabet: alphabet)
          end

          # Encode a Time object into split components for hierarchical paths
          #
          # @param time [Time] The time to encode
          # @param levels [Array<Symbol>, String] Split levels (month, week, day, block)
          # @param year_zero [Integer] Base year for encoding (default: 2000)
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [Hash] Hash of split components, rest, path, and full
          def encode_split(time, levels:, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            time = time.utc if time.respond_to?(:utc)
            levels = normalize_split_levels(levels)
            validate_split_levels!(levels)

            full_compact = encode_2sec(time, year_zero: year_zero, alphabet: alphabet)
            components = {
              month: full_compact[0..1],
              day: full_compact[2],
              block: full_compact[3],
              precision: full_compact[4..5]
            }

            week_value = simple_week_in_month(time)
            week_token = encode_value(week_value, 1, alphabet)

            output = {}
            levels.each do |level|
              output[level] = level == :week ? week_token : components[level]
            end

            rest = split_rest_for(levels, full_compact)
            output[:rest] = rest

            path_components = levels.map { |level| output[level] } + [rest]
            output[:path] = path_components.join("/")
            output[:full] = path_components.join("")

            output
          end

          # Decode a hierarchical split path into a Time object
          #
          # @param path_string [String] Split path string (with or without separators)
          # @param year_zero [Integer] Base year for decoding (default: 2000)
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [Time] The decoded time (UTC)
          def decode_path(path_string, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            raise ArgumentError, "Split path must be a string" unless path_string.is_a?(String)

            segments = path_string.split(/[\/\\:]+/).reject(&:empty?)
            full = segments.join

            # 7-char format: month(2) + week(1) + day(1) + block(1) + precision(2) = MMWDBRR
            # Strip week token (position 2) to get standard 6-char 2sec format: MMDBRRR
            if full.length == 7
              full = full[0..1] + full[3..-1]
            elsif full.length != 6
              raise ArgumentError, "Split path must resolve to 6 or 7 characters, got #{full.length}"
            end

            decode_2sec(full, year_zero: year_zero, alphabet: alphabet)
          end

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
          def encode_2sec(time, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            # Note: UTC conversion handled by encode_with_format caller
            months_offset = calculate_months_offset(time, year_zero)

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

          # Decode a 6-character compact ID to a Time object (~1.85s precision)
          #
          # @param compact_id [String] The 6-character compact ID
          # @param year_zero [Integer] Base year for decoding (default: 2000)
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [Time] The decoded time (UTC)
          # @raise [ArgumentError] If compact_id format is invalid or components out of range
          def decode_2sec(compact_id, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
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
            minutes_of_day = block * BLOCK_MINUTES
            seconds_into_block = (precision * BLOCK_SECONDS) / PRECISION_DIVISOR

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
          def encode_month(time, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
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
          def decode_month(encoded_id, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            validate_length!(encoded_id, 2)
            validate_alphabet!(encoded_id, alphabet)

            months_offset = decode_value(encoded_id.downcase, alphabet)

            if months_offset > MAX_MONTHS_OFFSET
              raise ArgumentError, "Month offset #{months_offset} exceeds maximum (#{MAX_MONTHS_OFFSET} = 108 years)"
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
          def encode_week(time, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
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
          def decode_week(encoded_id, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            validate_length!(encoded_id, 3)
            validate_alphabet!(encoded_id, alphabet)

            id = encoded_id.downcase
            months_offset = decode_value(id[0..1], alphabet)
            week_value = decode_value(id[2], alphabet)

            unless week_value.between?(FormatSpecs::WEEK_FORMAT_MIN, FormatSpecs::WEEK_FORMAT_MAX)
              raise ArgumentError, "Week value #{week_value} must be between #{FormatSpecs::WEEK_FORMAT_MIN}-#{FormatSpecs::WEEK_FORMAT_MAX}"
            end

            if months_offset > MAX_MONTHS_OFFSET
              raise ArgumentError, "Month offset #{months_offset} exceeds maximum (#{MAX_MONTHS_OFFSET} = 108 years)"
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
          def encode_day(time, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            # Note: UTC conversion handled by encode_with_format caller
            months_offset = calculate_months_offset(time, year_zero)
            day = (time.day - 1).clamp(0, MAX_DAY)

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
          def decode_day(encoded_id, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            validate_length!(encoded_id, 3)
            validate_alphabet!(encoded_id, alphabet)

            id = encoded_id.downcase
            months_offset = decode_value(id[0..1], alphabet)
            day = decode_value(id[2], alphabet)

            unless day <= FormatSpecs::DAY_FORMAT_MAX
              raise ArgumentError, "Day value #{day} exceeds day format maximum (#{FormatSpecs::DAY_FORMAT_MAX} = 31 calendar days)"
            end

            if months_offset > MAX_MONTHS_OFFSET
              raise ArgumentError, "Month offset #{months_offset} exceeds maximum (#{MAX_MONTHS_OFFSET} = 108 years)"
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
          def encode_40min(time, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            # Note: UTC conversion handled by encode_with_format caller
            months_offset = calculate_months_offset(time, year_zero)
            day = (time.day - 1).clamp(0, MAX_DAY)

            # Use 40-minute blocks like position 4 of compact format
            minutes_of_day = (time.hour * 60) + time.min
            block = minutes_of_day / BLOCK_MINUTES  # 0-35

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
          def decode_40min(encoded_id, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            validate_length!(encoded_id, 4)
            validate_alphabet!(encoded_id, alphabet)

            id = encoded_id.downcase
            months_offset = decode_value(id[0..1], alphabet)
            day = decode_value(id[2], alphabet)
            block = decode_value(id[3], alphabet)

            if day > MAX_DAY
              raise ArgumentError, "Day value #{day} exceeds maximum (#{MAX_DAY} = 31 calendar days)"
            end

            if months_offset > MAX_MONTHS_OFFSET
              raise ArgumentError, "Month offset #{months_offset} exceeds maximum (#{MAX_MONTHS_OFFSET} = 108 years)"
            end

            if block > MAX_BLOCK
              raise ArgumentError, "Block value #{block} exceeds maximum (#{MAX_BLOCK} = 36 blocks per day)"
            end

            year = year_zero + (months_offset / 12)
            month = (months_offset % 12) + 1
            calendar_day = day + 1

            # Calculate time from block (40-minute block)
            minutes_of_day = block * BLOCK_MINUTES
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
          def encode_50ms(time, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            # Note: UTC conversion handled by encode_with_format caller
            months_offset = calculate_months_offset(time, year_zero)
            day = time.day - 1
            minutes_of_day = (time.hour * 60) + time.min
            block = minutes_of_day / BLOCK_MINUTES

            # 50ms: 3 digits of precision (36^3 = 46656 combinations for ~50ms)
            clamped_seconds = time.sec.clamp(0, 59)
            usec = time.respond_to?(:usec) ? time.usec : 0
            total_usecs = ((minutes_of_day % BLOCK_MINUTES) * 60 + clamped_seconds) * 1_000_000 + usec
            block_usecs = BLOCK_SECONDS * 1_000_000
            precision = (total_usecs * PRECISION_DIVISOR_3) / block_usecs
            precision = precision.clamp(0, PRECISION_DIVISOR_3 - 1)

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
          def decode_50ms(encoded_id, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            validate_length!(encoded_id, 7)
            validate_alphabet!(encoded_id, alphabet)

            id = encoded_id.downcase
            months_offset = decode_value(id[0..1], alphabet)
            day = decode_value(id[2], alphabet)
            block = decode_value(id[3], alphabet)
            precision = decode_value(id[4..6], alphabet)

            validate_base_components!(months_offset, day, block)
            validate_precision_range!(precision, PRECISION_DIVISOR_3)

            year = year_zero + (months_offset / 12)
            month = (months_offset % 12) + 1
            calendar_day = day + 1

            # Calculate time with 50ms precision
            minutes_of_day = block * BLOCK_MINUTES
            total_usecs = (precision * BLOCK_SECONDS * 1_000_000) / PRECISION_DIVISOR_3

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
          def encode_ms(time, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            # Note: UTC conversion handled by encode_with_format caller
            months_offset = calculate_months_offset(time, year_zero)
            day = time.day - 1
            minutes_of_day = (time.hour * 60) + time.min
            block = minutes_of_day / BLOCK_MINUTES

            # ms: 4 digits of precision (36^4 = 1679616 combinations for ~1.4ms)
            clamped_seconds = time.sec.clamp(0, 59)
            usec = time.respond_to?(:usec) ? time.usec : 0
            total_usecs = ((minutes_of_day % BLOCK_MINUTES) * 60 + clamped_seconds) * 1_000_000 + usec
            block_usecs = BLOCK_SECONDS * 1_000_000
            precision = (total_usecs * PRECISION_DIVISOR_4) / block_usecs
            precision = precision.clamp(0, PRECISION_DIVISOR_4 - 1)

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
          def decode_ms(encoded_id, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            validate_length!(encoded_id, 8)
            validate_alphabet!(encoded_id, alphabet)

            id = encoded_id.downcase
            months_offset = decode_value(id[0..1], alphabet)
            day = decode_value(id[2], alphabet)
            block = decode_value(id[3], alphabet)
            precision = decode_value(id[4..7], alphabet)

            validate_base_components!(months_offset, day, block)
            validate_precision_range!(precision, PRECISION_DIVISOR_4)

            year = year_zero + (months_offset / 12)
            month = (months_offset % 12) + 1
            calendar_day = day + 1

            # Calculate time with ms precision
            minutes_of_day = block * BLOCK_MINUTES
            total_usecs = (precision * BLOCK_SECONDS * 1_000_000) / PRECISION_DIVISOR_4

            hour = minutes_of_day / 60
            remaining_usecs = total_usecs % 60_000_000
            minute = (minutes_of_day % 60) + (total_usecs / 60_000_000)
            second = (remaining_usecs / 1_000_000).to_i
            usec = (remaining_usecs % 1_000_000).to_i

            hour, minute = normalize_minute_overflow(hour, minute)

            Time.utc(year, month, calendar_day, hour, minute, second, usec)
          end

          # ===================
          # Validation Methods
          # ===================

          # Validate a 6-character compact ID string (legacy method)
          #
          # NOTE: This method only validates the 6-character "2sec" compact format.
          # For validating IDs of any format, use valid_any_format? instead.
          #
          # @param compact_id [String] The ID to validate
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [Boolean] true if valid 6-char compact ID, false otherwise
          # @see valid_any_format? for validating all format lengths
          def valid?(compact_id, alphabet: DEFAULT_ALPHABET)
            return false unless compact_id.is_a?(String)
            return false unless compact_id.length == 6

            # Use Set for faster character validation (O(1) vs O(n))
            alphabet_set = alphabet == DEFAULT_ALPHABET ? DEFAULT_ALPHABET_SET : alphabet.chars.to_set
            return false unless compact_id.downcase.chars.all? { |c| alphabet_set.include?(c) }

            # Also validate semantic ranges
            id = compact_id.downcase
            months_offset = decode_value(id[0..1], alphabet)
            day = decode_value(id[2], alphabet)
            block = decode_value(id[3], alphabet)
            precision = decode_value(id[4..5], alphabet)

            # Check component ranges (day must be 0-30 for calendar days 1-31)
            months_offset <= 1295 && day <= 30 && block <= 35 && precision <= 1295
          end

          # Generate a sequence of sequential compact IDs starting from a time
          #
          # @param time [Time] The starting time
          # @param count [Integer] Number of IDs to generate
          # @param format [Symbol] Output format (:"2sec", :month, :week, :day, :"40min", :"50ms", :ms)
          # @param year_zero [Integer] Base year for encoding (default: 2000)
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [Array<String>] Array of sequential compact IDs
          # @raise [ArgumentError] If count <= 0 or format is invalid
          def encode_sequence(time, count:, format:, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            raise ArgumentError, "count must be greater than 0" if count <= 0

            time = time.utc if time.respond_to?(:utc)

            # Generate the first ID
            first_id = encode_with_format(time, format: format, year_zero: year_zero, alphabet: alphabet)

            return [first_id] if count == 1

            # Generate subsequent IDs by incrementing
            result = [first_id]
            current_id = first_id

            (count - 1).times do
              current_id = increment_id(current_id, format: format, alphabet: alphabet)
              result << current_id
            end

            result
          end

          # Increment a compact ID to the next sequential value
          #
          # Increments the smallest unit for the format, handling overflow cascade:
          # ms → 50ms → 2sec → block → day → month
          #
          # @param compact_id [String] The compact ID to increment
          # @param format [Symbol] Format of the compact ID
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [String] The next sequential compact ID
          # @raise [ArgumentError] If overflow would exceed month range
          def increment_id(compact_id, format:, alphabet: DEFAULT_ALPHABET)
            base = alphabet.length
            id = compact_id.downcase

            case format
            when :month
              increment_month_id(id, alphabet, base)
            when :week
              increment_week_id(id, alphabet, base)
            when :day
              increment_day_id(id, alphabet, base)
            when :"40min"
              increment_40min_id(id, alphabet, base)
            when :"2sec"
              increment_2sec_id(id, alphabet, base)
            when :"50ms"
              increment_50ms_id(id, alphabet, base)
            when :ms
              increment_ms_id(id, alphabet, base)
            else
              raise ArgumentError, "Invalid format: #{format}"
            end
          end

          # Validate a compact ID string of any supported format
          #
          # Supports all 7 formats: month (2 chars), week (3 chars), day (3 chars),
          # 40min (4 chars), 2sec (6 chars), 50ms (7 chars), ms (8 chars).
          #
          # @param compact_id [String] The ID to validate (2-8 characters)
          # @param alphabet [String] Base36 alphabet (default: 0-9a-z)
          # @return [Boolean] true if valid compact ID of any format, false otherwise
          def valid_any_format?(compact_id, alphabet: DEFAULT_ALPHABET)
            return false unless compact_id.is_a?(String)

            # Use Set for faster character validation (O(1) vs O(n))
            alphabet_set = alphabet == DEFAULT_ALPHABET ? DEFAULT_ALPHABET_SET : alphabet.chars.to_set
            return false unless compact_id.downcase.chars.all? { |c| alphabet_set.include?(c) }

            # Try to detect format
            format = detect_format(compact_id, alphabet: alphabet)
            return false if format.nil?

            # Try to decode - if it succeeds, it's valid
            begin
              decode_with_format(compact_id, format: format, alphabet: alphabet)
              true
            rescue ArgumentError
              false
            end
          end

          private

          # ===================
          # Helper Methods
          # ===================

          # Deprecated format name mappings (old name => new name)
          DEPRECATED_FORMAT_NAMES = {
            compact: :"2sec",
            hour: :"40min",
            high_7: :"50ms",
            high_8: :ms
          }.freeze

          # Suggest a format name for deprecated/mistyped formats
          #
          # @param format [Symbol] The invalid format name
          # @return [Symbol, nil] Suggested format name or nil
          def suggest_format_name(format)
            DEPRECATED_FORMAT_NAMES[format]
          end

          # Calculate months offset from year_zero
          #
          # @param time [Time] The time to calculate offset for
          # @param year_zero [Integer] Base year for encoding
          # @return [Integer] Months since year_zero (0-1295)
          # @raise [ArgumentError] If time is outside supported range
          def calculate_months_offset(time, year_zero)
            months_offset = ((time.year - year_zero) * 12) + (time.month - 1)

            if months_offset.negative? || months_offset > MAX_MONTHS_OFFSET
              raise ArgumentError, "Time #{time} is outside supported range (#{year_zero} to #{year_zero + 107})"
            end

            months_offset
          end

          # Simple day-based week number within month (1-5)
          # days 1-7 = week 1, 8-14 = week 2, etc.
          # Used by encode_split for organizational path buckets only.
          #
          # @param time [Time] The time to calculate week for
          # @return [Integer] Week number in month (1-5)
          def simple_week_in_month(time)
            ((time.day - 1) / 7) + 1
          end

          # ISO Thursday-based week-in-month calculation.
          # A week belongs to the month containing its Thursday.
          #
          # @param time [Time] The time to calculate week for
          # @return [Array<Integer>] [year, month, week_in_month]
          def iso_week_month_and_number(time)
            date = Date.new(time.year, time.month, time.day)
            days_since_monday = (date.wday - 1) % 7  # Mon=0..Sun=6
            thursday = date + (3 - days_since_monday)

            # Week belongs to Thursday's month
            first_of_month = Date.new(thursday.year, thursday.month, 1)
            days_until_thu = (4 - first_of_month.wday) % 7
            first_thursday = first_of_month + days_until_thu

            week_in_month = ((thursday - first_thursday).to_i / 7) + 1
            [thursday.year, thursday.month, week_in_month]
          end

          # Calculate months offset from year_zero using explicit year/month
          #
          # @param year [Integer] The year
          # @param month [Integer] The month (1-12)
          # @param year_zero [Integer] Base year for encoding
          # @return [Integer] Months since year_zero (0-1295)
          # @raise [ArgumentError] If outside supported range
          def calculate_months_offset_ym(year, month, year_zero)
            months_offset = ((year - year_zero) * 12) + (month - 1)

            if months_offset.negative? || months_offset > MAX_MONTHS_OFFSET
              raise ArgumentError, "Time #{year}-#{month} is outside supported range (#{year_zero} to #{year_zero + 107})"
            end

            months_offset
          end

          # Normalize split levels into symbol list
          #
          # @param levels [Array<Symbol>, String] Level list or comma-separated string
          # @return [Array<Symbol>] Normalized levels
          def normalize_split_levels(levels)
            list = levels.is_a?(String) ? levels.split(",") : Array(levels)
            list.map { |level| level.to_s.strip }
                .reject(&:empty?)
                .map(&:to_sym)
          end

          # Validate split levels ordering and hierarchy
          #
          # @param levels [Array<Symbol>] Normalized split levels
          # @raise [ArgumentError] If validation fails
          def validate_split_levels!(levels)
            raise ArgumentError, "split levels must be provided" if levels.empty?

            unknown = levels - FormatSpecs::SPLIT_LEVELS
            unless unknown.empty?
              raise ArgumentError, "unknown level: #{unknown.first} (valid: #{FormatSpecs::SPLIT_LEVELS.join(', ')})"
            end

            unless levels.first == :month
              raise ArgumentError, "levels must start with month"
            end

            indices = levels.map { |level| FormatSpecs::SPLIT_LEVELS.index(level) }
            unless indices == indices.sort && indices.uniq.length == indices.length
              raise ArgumentError, "levels must be in order: month -> week -> day -> block"
            end

            if levels.include?(:block) && !levels.include?(:day)
              raise ArgumentError, "block requires day"
            end
          end

          # Determine rest component based on final split level
          #
          # @param levels [Array<Symbol>] Split levels
          # @param full_compact [String] Full 2sec compact ID
          # @return [String] Remaining precision component
          def split_rest_for(levels, full_compact)
            # Determine the "rest" portion of the compact ID based on the deepest split level
            # Levels are validated by validate_split_levels! before this is called
            case levels.last
            when :month, :week
              full_compact[2..5]  # After month (2 chars), rest is day+block+precision
            when :day
              full_compact[3..5]  # After day (3 chars total), rest is block+precision
            when :block
              full_compact[4..5]  # After block (4 chars total), rest is precision only
            else
              # Defensive fallback: treat as month/week level (should not be reached
              # after validation, but provides safe default if called directly)
              full_compact[2..5]
            end
          end

          # Normalize minute overflow when minute >= 60
          #
          # @param hour [Integer] Hour value (0-23)
          # @param minute [Integer] Minute value (may be >= 60)
          # @return [Array<Integer>] Normalized [hour, minute] pair
          def normalize_minute_overflow(hour, minute)
            if minute >= 60
              [hour + minute / 60, minute % 60]
            else
              [hour, minute]
            end
          end

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

          # ===================
          # Validation Helpers
          # ===================

          # Validate length of encoded ID
          #
          # @param encoded_id [String] The encoded ID
          # @param expected_length [Integer] Expected length
          # @raise [ArgumentError] If length is incorrect
          def validate_length!(encoded_id, expected_length)
            raise ArgumentError, "Compact ID must be a string" unless encoded_id.is_a?(String)
            raise ArgumentError, "Compact ID must be #{expected_length} characters, got #{encoded_id.length}" unless encoded_id.length == expected_length
          end

          # Validate alphabet of encoded ID
          #
          # @param encoded_id [String] The encoded ID
          # @param alphabet [String] Expected alphabet
          # @raise [ArgumentError] If invalid characters found
          def validate_alphabet!(encoded_id, alphabet)
            # Use Set for faster character validation (O(1) vs O(n))
            alphabet_set = alphabet == DEFAULT_ALPHABET ? DEFAULT_ALPHABET_SET : alphabet.chars.to_set
            invalid_chars = encoded_id.downcase.chars.reject { |c| alphabet_set.include?(c) }
            unless invalid_chars.empty?
              raise ArgumentError, "Invalid characters in compact ID: #{invalid_chars.join(', ')}"
            end
          end

          # Validate precision range for high-precision formats
          #
          # @param precision [Integer] Precision value
          # @param max_precision [Integer] Maximum allowed precision
          # @raise [ArgumentError] If precision exceeds maximum
          def validate_precision_range!(precision, max_precision)
            if precision > max_precision
              raise ArgumentError, "Precision value #{precision} exceeds maximum (#{max_precision})"
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

          # Validate base components (month offset, day, block) without precision check
          # Used for 50ms and ms formats where precision is validated separately
          #
          # @param months_offset [Integer] Months from year_zero (max 1295 = 108 years)
          # @param day [Integer] Day of month (max 30 for calendar days 1-31)
          # @param block [Integer] 40-minute block (max 35 for 36 blocks/day)
          # @raise [ArgumentError] If any component is out of range
          def validate_base_components!(months_offset, day, block)
            if months_offset > MAX_MONTHS_OFFSET
              raise ArgumentError, "Month offset #{months_offset} exceeds maximum (#{MAX_MONTHS_OFFSET} = 108 years)"
            end

            if day > MAX_DAY
              raise ArgumentError, "Day value #{day} exceeds maximum (#{MAX_DAY} for calendar days 1-31)"
            end

            if block > MAX_BLOCK
              raise ArgumentError, "Block value #{block} exceeds maximum (#{MAX_BLOCK} for 36 blocks/day)"
            end
          end

          # ===================
          # Increment ID Helpers
          # ===================

          # Increment month format ID (2 chars)
          # Overflow: month → ERROR
          def increment_month_id(id, alphabet, base)
            month = decode_value(id[0..1], alphabet)
            month += 1

            if month > MAX_MONTHS_OFFSET
              raise ArgumentError, "Cannot increment: would exceed month range (max #{MAX_MONTHS_OFFSET})"
            end

            encode_value(month, 2, alphabet)
          end

          # Increment week format ID (3 chars)
          # Overflow: week → month
          def increment_week_id(id, alphabet, base)
            month = decode_value(id[0..1], alphabet)
            week = decode_value(id[2], alphabet)

            week += 1
            if week > FormatSpecs::WEEK_FORMAT_MAX
              week = FormatSpecs::WEEK_FORMAT_MIN
              month += 1
              if month > MAX_MONTHS_OFFSET
                raise ArgumentError, "Cannot increment: would exceed month range (max #{MAX_MONTHS_OFFSET})"
              end
            end

            result = String.new(capacity: 3)
            result << encode_value(month, 2, alphabet)
            result << encode_value(week, 1, alphabet)
            result.freeze
          end

          # Increment day format ID (3 chars)
          # Overflow: day → month
          def increment_day_id(id, alphabet, base)
            month = decode_value(id[0..1], alphabet)
            day = decode_value(id[2], alphabet)

            day += 1
            if day > MAX_DAY
              day = 0
              month += 1
              if month > MAX_MONTHS_OFFSET
                raise ArgumentError, "Cannot increment: would exceed month range (max #{MAX_MONTHS_OFFSET})"
              end
            end

            result = String.new(capacity: 3)
            result << encode_value(month, 2, alphabet)
            result << encode_value(day, 1, alphabet)
            result.freeze
          end

          # Increment 40min format ID (4 chars)
          # Overflow: block → day → month
          def increment_40min_id(id, alphabet, base)
            month = decode_value(id[0..1], alphabet)
            day = decode_value(id[2], alphabet)
            block = decode_value(id[3], alphabet)

            block += 1
            if block > MAX_BLOCK
              block = 0
              day += 1
              if day > MAX_DAY
                day = 0
                month += 1
                if month > MAX_MONTHS_OFFSET
                  raise ArgumentError, "Cannot increment: would exceed month range (max #{MAX_MONTHS_OFFSET})"
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
          # Overflow: precision → block → day → month
          def increment_2sec_id(id, alphabet, base)
            month = decode_value(id[0..1], alphabet)
            day = decode_value(id[2], alphabet)
            block = decode_value(id[3], alphabet)
            precision = decode_value(id[4..5], alphabet)

            precision += 1
            if precision > MAX_PRECISION
              precision = 0
              block += 1
              if block > MAX_BLOCK
                block = 0
                day += 1
                if day > MAX_DAY
                  day = 0
                  month += 1
                  if month > MAX_MONTHS_OFFSET
                    raise ArgumentError, "Cannot increment: would exceed month range (max #{MAX_MONTHS_OFFSET})"
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
          # Overflow: precision → block → day → month
          def increment_50ms_id(id, alphabet, base)
            month = decode_value(id[0..1], alphabet)
            day = decode_value(id[2], alphabet)
            block = decode_value(id[3], alphabet)
            precision = decode_value(id[4..6], alphabet)

            max_precision_50ms = PRECISION_DIVISOR_3 - 1  # 46655

            precision += 1
            if precision > max_precision_50ms
              precision = 0
              block += 1
              if block > MAX_BLOCK
                block = 0
                day += 1
                if day > MAX_DAY
                  day = 0
                  month += 1
                  if month > MAX_MONTHS_OFFSET
                    raise ArgumentError, "Cannot increment: would exceed month range (max #{MAX_MONTHS_OFFSET})"
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
          # Overflow: precision → block → day → month
          def increment_ms_id(id, alphabet, base)
            month = decode_value(id[0..1], alphabet)
            day = decode_value(id[2], alphabet)
            block = decode_value(id[3], alphabet)
            precision = decode_value(id[4..7], alphabet)

            max_precision_ms = PRECISION_DIVISOR_4 - 1  # 1679615

            precision += 1
            if precision > max_precision_ms
              precision = 0
              block += 1
              if block > MAX_BLOCK
                block = 0
                day += 1
                if day > MAX_DAY
                  day = 0
                  month += 1
                  if month > MAX_MONTHS_OFFSET
                    raise ArgumentError, "Cannot increment: would exceed month range (max #{MAX_MONTHS_OFFSET})"
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
end
