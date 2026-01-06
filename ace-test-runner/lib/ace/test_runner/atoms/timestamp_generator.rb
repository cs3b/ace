# frozen_string_literal: true

require "ace/timestamp"

module Ace
  module TestRunner
    module Atoms
      # Generates consistent timestamps for reports
      #
      # Supports two ID formats:
      # - :base36 - 6-character compact IDs (e.g., "i50jj3") - NEW DEFAULT
      # - :timestamp - 14-character timestamps (e.g., "20250106-123000") - LEGACY
      #
      # @example Using Base36 format (default)
      #   generator = TimestampGenerator.new(id_format: :base36)
      #   generator.generate  # => "i50jj3"
      #
      # @example Using legacy timestamp format
      #   generator = TimestampGenerator.new(id_format: :timestamp)
      #   generator.generate  # => "20250106-123000"
      #
      # @example Detect format of existing ID
      #   # Note: detect_format returns :compact (detection result from ace-timestamp)
      #   # while id_format config uses :base36 (configuration option). Both refer to
      #   # the same 6-character Base36 encoded format.
      #   TimestampGenerator.detect_format("i50jj3")        # => :compact
      #   TimestampGenerator.detect_format("20250106-123000") # => :timestamp
      #
      class TimestampGenerator
        TIMESTAMP_FORMAT = "%Y%m%d-%H%M%S"
        ISO_FORMAT = "%Y-%m-%dT%H:%M:%S"

        # Valid ID format options
        VALID_ID_FORMATS = %i[base36 timestamp].freeze

        # @param id_format [Symbol] ID format (:base36 or :timestamp)
        # @param format [String] strftime format for timestamp mode (legacy param)
        def initialize(id_format: :base36, format: TIMESTAMP_FORMAT)
          @id_format = validate_id_format(id_format)
          @timestamp_format = format
        end

        # Generate an ID for the given time
        #
        # @param time [Time] The time to encode (default: Time.now)
        # @return [String] Generated ID in configured format
        def generate(time = Time.now)
          case @id_format
          when :base36
            Ace::Timestamp.encode(time)
          when :timestamp
            time.strftime(@timestamp_format)
          end
        end

        # Generate an ISO timestamp
        #
        # @param time [Time] The time to format (default: Time.now)
        # @return [String] ISO formatted timestamp
        def iso_timestamp(time = Time.now)
          time.strftime(ISO_FORMAT)
        end

        # Generate a directory name (alias for generate)
        #
        # @param time [Time] The time to encode (default: Time.now)
        # @return [String] Directory name in configured format
        def directory_name(time = Time.now)
          generate(time)
        end

        # Generate a filename timestamp with optional extension
        #
        # @param time [Time] The time to encode (default: Time.now)
        # @param extension [String, nil] Optional file extension
        # @return [String] Filename with optional extension
        def filename_timestamp(time = Time.now, extension = nil)
          base = generate(time)
          extension ? "#{base}#{extension}" : base
        end

        # Parse a timestamp or compact ID string to Time
        #
        # @param id_str [String] The ID string to parse
        # @param format [String] strftime format (for timestamp format)
        # @return [Time, nil] Parsed time or nil if invalid
        def parse(id_str, format = @timestamp_format)
          detected = self.class.detect_format(id_str)

          case detected
          when :compact
            Ace::Timestamp.decode(id_str)
          when :timestamp
            Time.strptime(id_str, format)
          end
        rescue ArgumentError
          nil
        end

        # Calculate elapsed time between two times
        #
        # @param start_time [Time] Start time
        # @param end_time [Time] End time (default: Time.now)
        # @return [String] Human-readable duration
        def elapsed_time(start_time, end_time = Time.now)
          duration = end_time - start_time
          format_duration(duration)
        end

        # Detect the format of an ID string
        #
        # @param value [String] The ID string to analyze
        # @return [Symbol, nil] :compact, :timestamp, or nil
        def self.detect_format(value)
          Ace::Timestamp.detect_format(value)
        end

        # Get current ID format setting
        #
        # @return [Symbol] Current ID format (:base36 or :timestamp)
        attr_reader :id_format

        private

        def validate_id_format(format)
          unless VALID_ID_FORMATS.include?(format)
            raise ArgumentError,
              "Invalid id_format: #{format.inspect}. Valid options: #{VALID_ID_FORMATS.join(', ')}"
          end
          format
        end

        def format_duration(seconds)
          if seconds < 1
            "#{(seconds * 1000).round(2)}ms"
          elsif seconds < 60
            "#{seconds.round(2)}s"
          else
            minutes = (seconds / 60).floor
            remaining_seconds = (seconds % 60).round
            "#{minutes}m #{remaining_seconds}s"
          end
        end
      end
    end
  end
end