# frozen_string_literal: true

module CodingAgentTools
  module Models
    # Represents coverage information for a single method
    class MethodCoverage
      attr_reader :name, :start_line, :end_line, :total_lines, :covered_lines, :coverage_percentage, :visibility, :uncovered_lines

      def initialize(name:, start_line:, end_line:, total_lines:, covered_lines:, coverage_percentage:, visibility: :public, uncovered_lines: [])
        @name = name
        @start_line = start_line
        @end_line = end_line
        @total_lines = total_lines
        @covered_lines = covered_lines
        @coverage_percentage = coverage_percentage
        @visibility = visibility
        @uncovered_lines = uncovered_lines
      end

      def under_threshold?(threshold)
        coverage_percentage < threshold
      end

      def line_range
        start_line..end_line
      end

      def uncovered_lines_count
        total_lines - covered_lines
      end

      def public?
        visibility == :public
      end

      def private?
        visibility == :private
      end

      def protected?
        visibility == :protected
      end

      def needs_tests?
        public? && (coverage_percentage < 100.0 || uncovered_lines.any?)
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
          # Truly minimal format - only method name and uncovered lines
          {
            name: name,
            uncovered_lines: uncovered_lines_compact
          }
        when :verbose
          # Full detailed format
          {
            name: name,
            start_line: start_line,
            end_line: end_line,
            total_lines: total_lines,
            covered_lines: covered_lines,
            coverage_percentage: coverage_percentage,
            uncovered_lines_count: uncovered_lines_count,
            visibility: visibility,
            needs_tests: needs_tests?,
            uncovered_lines: uncovered_lines_verbose
          }
        else
          # Default to compact
          {
            name: name,
            uncovered_lines: uncovered_lines_compact
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