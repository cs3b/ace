# frozen_string_literal: true

module Ace
  module B36ts
    module Atoms
      # Format specifications for granular timestamp encoding.
      #
      # Defines 7 format types with varying precision and length:
      # - 2sec (6 chars, ~1.85s precision) - default
      # - month (2 chars, month precision)
      # - week (3 chars, week precision)
      # - day (3 chars, day precision)
      # - 40min (4 chars, 40-minute block precision)
      # - 50ms (7 chars, ~50ms precision)
      # - ms (8 chars, ~1.4ms precision)
      #
      # Day/week disambiguation (3-char formats):
      # - Day format: 3rd character in 0-30 range
      # - Week format: 3rd character in 31-35 range
      #
      # @example Access format specifications
      #   FormatSpecs::FORMATS[:"2sec"]  # => FormatSpec for 6-char IDs
      #   FormatSpecs::FORMATS[:month]   # => FormatSpec for 2-char IDs
      #
      module FormatSpecs
        # Immutable value object defining a timestamp format specification
        FormatSpec = Data.define(:name, :length, :precision_desc, :pattern)

        # All supported format specifications
        FORMATS = {
          "2sec": FormatSpec.new(
            name: :"2sec",
            length: 6,
            precision_desc: "~1.85s",
            pattern: /\A[0-9a-z]{6}\z/i
          ),
          month: FormatSpec.new(
            name: :month,
            length: 2,
            precision_desc: "month",
            pattern: /\A[0-9a-z]{2}\z/i
          ),
          week: FormatSpec.new(
            name: :week,
            length: 3,
            precision_desc: "week",
            pattern: /\A[0-9a-z]{3}\z/i
          ),
          day: FormatSpec.new(
            name: :day,
            length: 3,
            precision_desc: "day",
            pattern: /\A[0-9a-z]{3}\z/i
          ),
          "40min": FormatSpec.new(
            name: :"40min",
            length: 4,
            precision_desc: "40min",
            pattern: /\A[0-9a-z]{4}\z/i
          ),
          "50ms": FormatSpec.new(
            name: :"50ms",
            length: 7,
            precision_desc: "~50ms",
            pattern: /\A[0-9a-z]{7}\z/i
          ),
          ms: FormatSpec.new(
            name: :ms,
            length: 8,
            precision_desc: "~1.4ms",
            pattern: /\A[0-9a-z]{8}\z/i
          )
        }.freeze

        # Day/week disambiguation for 3-char formats
        # Day format: 3rd char (day value) is 0-30
        # Week format: 3rd char (week value) is 31-35
        DAY_FORMAT_MAX = 30
        WEEK_FORMAT_MIN = 31
        WEEK_FORMAT_MAX = 35
        SPLIT_LEVELS = %i[month week day block].freeze

        class << self
          # Get format specification by name
          #
          # @param name [Symbol] Format name (:"2sec", :month, :week, :day, :"40min", :"50ms", :ms)
          # @return [FormatSpec, nil] Format specification or nil if not found
          def get(name)
            FORMATS[name]
          end

          # Check if format name is valid
          #
          # @param name [Symbol] Format name to check
          # @return [Boolean] True if format is supported
          def valid_format?(name)
            FORMATS.key?(name)
          end

          # Get all format names
          #
          # @return [Array<Symbol>] List of supported format names
          def all_formats
            FORMATS.keys
          end

          # Get all supported lengths
          #
          # @return [Array<Integer>] List of supported ID lengths
          def all_lengths
            FORMATS.values.map(&:length).uniq.sort
          end

          # Validate split level ordering and hierarchy
          #
          # @param levels [Array<Symbol>] Split levels to validate
          # @return [Boolean] True if split levels are valid
          def valid_split_levels?(levels)
            return false unless levels.is_a?(Array)
            return false if levels.empty?
            return false unless levels.all? { |level| SPLIT_LEVELS.include?(level) }
            return false unless levels.uniq.length == levels.length
            return false unless levels.first == :month

            indices = levels.map { |level| SPLIT_LEVELS.index(level) }
            return false unless indices == indices.sort
            return false if levels.include?(:block) && !levels.include?(:day)

            true
          end

          # Detect format from ID string
          # For 3-char IDs, uses the 3rd character value to distinguish day vs week
          #
          # @param encoded_id [String] The encoded ID string
          # @param alphabet [String] Base36 alphabet
          # @return [Symbol, nil] Detected format name or nil if invalid
          def detect_from_id(encoded_id, alphabet: CompactIdEncoder::DEFAULT_ALPHABET)
            return nil if encoded_id.nil? || encoded_id.empty?

            # Validate all characters are in the alphabet
            # Use Set for faster character validation (O(1) vs O(n))
            alphabet_set = (alphabet == CompactIdEncoder::DEFAULT_ALPHABET) ? CompactIdEncoder::DEFAULT_ALPHABET_SET : alphabet.chars.to_set
            return nil unless encoded_id.downcase.chars.all? { |c| alphabet_set.include?(c) }

            length = encoded_id.length

            case length
            when 2
              :month
            when 3
              # Disambiguate day vs week by 3rd character value
              third_char_value = alphabet.index(encoded_id[2].downcase)
              return nil if third_char_value.nil?

              if third_char_value <= DAY_FORMAT_MAX
                :day
              elsif third_char_value <= WEEK_FORMAT_MAX
                :week
              end
              # Note: With base36 (values 0-35), day covers 0-30 and week covers 31-35,
              # so all valid values are handled. This branch implicitly returns nil
              # only if alphabet validation fails (which is caught earlier).
            when 4
              :"40min"
            when 6
              :"2sec"
            when 7
              :"50ms"
            when 8
              :ms
            end
          end
        end
      end
    end
  end
end
