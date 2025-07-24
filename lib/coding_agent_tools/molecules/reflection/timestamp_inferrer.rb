# frozen_string_literal: true

require "date"
require_relative "../../models/result"

module CodingAgentTools
  module Molecules
    module Reflection
      # Infers timestamp range from reflection note files
      class TimestampInferrer
        def initialize
          @date_patterns = [
            # Filename patterns
            /(\d{4})-?(\d{2})-?(\d{2})/,        # YYYY-MM-DD or YYYYMMDD
            /(\d{4})(\d{2})(\d{2})/,            # YYYYMMDD
            # Content patterns
            /\*\*[Dd]ate\*\*:?\s*(\d{4})-(\d{2})-(\d{2})/,
            /^[Dd]ate:?\s*(\d{4})-(\d{2})-(\d{2})/,
            /^#.*(\d{4})-(\d{2})-(\d{2})/
          ]
        end

        def infer_timestamp_range(reflection_files)
          dates = []

          reflection_files.each do |file_path|
            file_dates = extract_dates_from_file(file_path)
            dates.concat(file_dates)
          end

          if dates.empty?
            return Models::Result.failure("No dates found in reflection files")
          end

          dates.sort!
          from_date = dates.first
          to_date = dates.last
          days_covered = (to_date - from_date).to_i + 1

          Models::Result.success(
            from_date: from_date,
            to_date: to_date,
            days_covered: days_covered,
            total_dates: dates.length
          )
        end

        private

        def extract_dates_from_file(file_path)
          dates = []

          # Try extracting from filename first
          filename = File.basename(file_path)
          filename_date = extract_date_from_string(filename)
          dates << filename_date if filename_date

          # Try extracting from file content
          begin
            content = File.read(file_path, encoding: "utf-8")
            content_dates = extract_dates_from_content(content)
            dates.concat(content_dates)
          rescue => e
            # If we can't read content, filename date is better than nothing
            Rails.logger.warn("Could not read content from #{file_path}: #{e.message}") if defined?(Rails)
          end

          dates.compact.uniq
        end

        def extract_date_from_string(string)
          @date_patterns.each do |pattern|
            match = string.match(pattern)
            next unless match

            begin
              year = match[1].to_i
              month = match[2].to_i
              day = match[3].to_i

              # Basic validation
              next if year < 2000 || year > 2030
              next if month < 1 || month > 12
              next if day < 1 || day > 31

              return Date.new(year, month, day)
            rescue Date::Error
              # Invalid date, continue trying other patterns
              next
            end
          end

          nil
        end

        def extract_dates_from_content(content)
          dates = []

          content.lines.each do |line|
            line.strip!
            next if line.empty?

            # Look for date patterns in content
            date = extract_date_from_string(line)
            dates << date if date
          end

          dates.compact.uniq
        end
      end
    end
  end
end
