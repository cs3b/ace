# frozen_string_literal: true

require_relative "../atoms/time_range_calculator"
require "date"

module Ace
  module Docs
    module Molecules
      # Finds the appropriate time range for document analysis
      class TimeRangeFinder
        def initialize
          @calculator = Atoms::TimeRangeCalculator
        end

        # Find the oldest last-updated date from a list of documents
        # @param documents [Array<Document>] List of document objects
        # @return [String] Git-compatible since parameter (e.g., "2 weeks ago")
        def find_oldest_update(documents)
          return "1 month ago" if documents.nil? || documents.empty?

          valid_dates = extract_valid_dates(documents)

          # If no valid dates found, use a sensible default
          return "1 month ago" if valid_dates.empty?

          oldest_date = valid_dates.min
          @calculator.calculate_since(oldest_date)
        end

        # Determine time range with override option
        # @param documents [Array<Document>] List of documents
        # @param override_since [String, nil] Override time range if provided
        # @return [String] Time range for git diff
        def determine_range(documents, override_since = nil)
          return override_since if override_since

          find_oldest_update(documents)
        end

        private

        # Extract valid dates from documents
        def extract_valid_dates(documents)
          dates = []

          documents.each do |doc|
            next unless doc.respond_to?(:frontmatter) && doc.frontmatter

            date_str = extract_date_from_frontmatter(doc.frontmatter)
            next unless date_str

            begin
              parsed_date = @calculator.parse_date(date_str)

              # Exclude suspicious future dates
              if parsed_date > Date.today
                warn "Suspicious future date in #{doc.path}: #{date_str}"
                next
              end

              # Exclude very old dates (likely placeholders)
              if parsed_date < Date.today - 365 * 5 # 5 years
                warn "Very old date in #{doc.path}: #{date_str}, using default range"
                next
              end

              dates << parsed_date
            rescue ArgumentError => e
              warn "Invalid date in #{doc.path}: #{date_str}. Error: #{e.message}"
            end
          end

          dates
        end

        # Extract date from frontmatter hash
        def extract_date_from_frontmatter(frontmatter)
          # Try various common date field names
          date_fields = %w[last-updated last_updated lastUpdated updated_at updatedAt date]

          date_fields.each do |field|
            value = frontmatter[field] || frontmatter[field.to_sym]
            return value.to_s if value
          end

          # Check nested update structure
          if frontmatter["update"] && frontmatter["update"]["last-updated"]
            return frontmatter["update"]["last-updated"].to_s
          end

          nil
        end

        def warn(message)
          $stderr.puts "WARNING: #{message}" if ENV["DEBUG"]
        end
      end
    end
  end
end