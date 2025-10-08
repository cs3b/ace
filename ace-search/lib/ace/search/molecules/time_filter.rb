# frozen_string_literal: true

module Ace
  module Search
    module Molecules
      # Filters files by modification time
      # This is a molecule - composed operation for time-based filtering
      class TimeFilter
        # Filter files by time criteria
        # @param files [Array<String>] List of file paths
        # @param since [Time, String, nil] Only files modified after this time
        # @param before [Time, String, nil] Only files modified before this time
        # @return [Array<String>] Filtered list of files
        def self.filter(files, since: nil, before: nil)
          return files if since.nil? && before.nil?

          since_time = parse_time(since) if since
          before_time = parse_time(before) if before

          files.select do |file|
            next false unless File.exist?(file)

            mtime = File.mtime(file)

            passes_since = since_time.nil? || mtime >= since_time
            passes_before = before_time.nil? || mtime <= before_time

            passes_since && passes_before
          end
        end

        # Parse time string or object
        # @param time_input [Time, String] Time to parse
        # @return [Time] Parsed time object
        def self.parse_time(time_input)
          return time_input if time_input.is_a?(Time)

          # Support common time formats
          case time_input
          when /^(\d+)d$/
            # Days ago: "7d" = 7 days ago
            Time.now - ($1.to_i * 24 * 60 * 60)
          when /^(\d+)h$/
            # Hours ago: "24h" = 24 hours ago
            Time.now - ($1.to_i * 60 * 60)
          when /^(\d+)m$/
            # Minutes ago: "30m" = 30 minutes ago
            Time.now - ($1.to_i * 60)
          else
            # Try to parse as ISO 8601 or standard format
            Time.parse(time_input)
          end
        rescue ArgumentError => e
          warn "Failed to parse time '#{time_input}': #{e.message}"
          nil
        end
      end
    end
  end
end
