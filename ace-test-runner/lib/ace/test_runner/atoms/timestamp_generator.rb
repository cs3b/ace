# frozen_string_literal: true

require "ace/b36ts"

module Ace
  module TestRunner
    module Atoms
      # Generates Base36 compact IDs for test reports
      #
      # Uses ace-b36ts to generate 6-character compact IDs (e.g., "i50jj3")
      # for test report directories and files. Reports are temporary, so no
      # backward compatibility with legacy timestamp format is needed.
      #
      # @example Generate a compact ID
      #   generator = TimestampGenerator.new
      #   generator.generate  # => "i50jj3"
      #
      # @example Generate ISO timestamp for human-readable output
      #   generator = TimestampGenerator.new
      #   generator.iso_timestamp  # => "2025-01-06T12:30:00"
      #
      class TimestampGenerator
        ISO_FORMAT = "%Y-%m-%dT%H:%M:%S"

        # Generate a Base36 compact ID for the given time
        #
        # @param time [Time] The time to encode (default: Time.now)
        # @return [String] 6-character Base36 compact ID
        def generate(time = Time.now)
          Ace::B36ts.encode(time)
        end

        # Generate an ISO timestamp for human-readable output
        #
        # @param time [Time] The time to format (default: Time.now)
        # @return [String] ISO formatted timestamp
        def iso_timestamp(time = Time.now)
          time.strftime(ISO_FORMAT)
        end

        # Generate a directory name (alias for generate)
        #
        # @param time [Time] The time to encode (default: Time.now)
        # @return [String] 6-character Base36 compact ID
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

        # Parse a Base36 compact ID string to Time
        #
        # @param id_str [String] The Base36 ID string to parse
        # @return [Time, nil] Parsed time or nil if invalid
        def parse(id_str)
          Ace::B36ts.decode(id_str)
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
        # @return [Symbol, nil] :"2sec" for valid Base36 IDs, :timestamp for legacy format, or nil
        def self.detect_format(value)
          Ace::B36ts.detect_format(value)
        end

        private

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
