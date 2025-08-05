# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    # TimestampGenerator provides timestamp generation utilities
    # This is an atom - it has no dependencies on other parts of this gem
    class TimestampGenerator
      # Default timestamp format for backups
      DEFAULT_FORMAT = '%Y%m%d-%H%M'

      # ISO 8601 format for metadata
      ISO_FORMAT = '%Y-%m-%d %H:%M:%S'

      # Generate a timestamp string
      # @param time [Time] The time to format (default: current time)
      # @param format [String] The strftime format string
      # @return [String] Formatted timestamp
      def self.generate(time: Time.now, format: DEFAULT_FORMAT)
        time.strftime(format)
      end

      # Generate a backup timestamp
      # @param time [Time] The time to format (default: current time)
      # @return [String] Timestamp suitable for backup directories
      def self.backup_timestamp(time: Time.now)
        generate(time: time, format: DEFAULT_FORMAT)
      end

      # Generate an ISO timestamp for metadata
      # @param time [Time] The time to format (default: current time)
      # @return [String] ISO 8601 formatted timestamp
      def self.iso_timestamp(time: Time.now)
        generate(time: time, format: ISO_FORMAT)
      end

      # Generate a filename-safe timestamp
      # @param time [Time] The time to format (default: current time)
      # @return [String] Timestamp safe for use in filenames
      def self.filename_timestamp(time: Time.now)
        generate(time: time, format: '%Y%m%d_%H%M%S')
      end

      # Parse a timestamp string back to Time object
      # @param timestamp [String] The timestamp string
      # @param format [String] The expected format
      # @return [Time, nil] Parsed time or nil if parsing fails
      def self.parse(timestamp, format: DEFAULT_FORMAT)
        Time.strptime(timestamp, format)
      rescue ArgumentError
        nil
      end
    end
  end
end
