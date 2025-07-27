# frozen_string_literal: true

module CodingAgentTools
  module Models
    # Represents coverage analysis results for a single file
    class CoverageResult
      attr_reader :file_path, :total_lines, :covered_lines, :coverage_percentage, :methods, :uncovered_details

      def initialize(file_path:, total_lines:, covered_lines:, coverage_percentage:, methods: [], uncovered_details: nil)
        @file_path = file_path
        @total_lines = total_lines
        @covered_lines = covered_lines
        @coverage_percentage = coverage_percentage
        @methods = methods
        @uncovered_details = uncovered_details || { uncovered_lines: [], uncovered_ranges: [], total_uncovered: 0 }
      end

      def under_threshold?(threshold)
        coverage_percentage < threshold
      end

      def uncovered_lines_count
        total_lines - covered_lines
      end

      def relative_path
        @relative_path ||= file_path.gsub(%r{^.*/lib/}, "lib/")
      end

      def uncovered_lines
        uncovered_details[:uncovered_lines] || []
      end

      def uncovered_ranges
        uncovered_details[:uncovered_ranges] || []
      end

      def uncovered_lines_compact
        @uncovered_lines_compact ||= compact_range_formatter.format_compact_ranges(uncovered_lines)
      end

      def uncovered_lines_verbose
        uncovered_lines
      end

      def to_h(format: :compact)
        case format
        when :compact
          # Truly minimal format - only essential data with methods that need tests
          methods_needing_tests = methods.select(&:needs_tests?)
          return nil if methods_needing_tests.empty?
          
          {
            relative_path: relative_path,
            coverage_percentage: coverage_percentage,
            methods: methods_needing_tests.map { |method| method.to_h(format: :compact) }
          }
        when :verbose
          # Full detailed format
          {
            file_path: file_path,
            relative_path: relative_path,
            total_lines: total_lines,
            covered_lines: covered_lines,
            coverage_percentage: coverage_percentage,
            uncovered_lines_count: uncovered_lines_count,
            uncovered_ranges: uncovered_ranges,
            uncovered_lines: uncovered_lines_verbose,
            methods: methods.map { |method| method.to_h(format: :verbose) }
          }
        else
          # Default to compact
          {
            relative_path: relative_path,
            coverage_percentage: coverage_percentage,
            methods: methods.map { |method| method.to_h(format: :compact) }
          }
        end
      end

      private

      def compact_range_formatter
        @compact_range_formatter ||= CodingAgentTools::Atoms::CompactRangeFormatter.new
      end
    end
  end
end