# frozen_string_literal: true

module CodingAgentTools
  module Models
    # Represents coverage information for a single method
    class MethodCoverage
      attr_reader :name, :start_line, :end_line, :total_lines, :covered_lines, :coverage_percentage

      def initialize(name:, start_line:, end_line:, total_lines:, covered_lines:, coverage_percentage:)
        @name = name
        @start_line = start_line
        @end_line = end_line
        @total_lines = total_lines
        @covered_lines = covered_lines
        @coverage_percentage = coverage_percentage
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

      def to_h
        {
          name: name,
          start_line: start_line,
          end_line: end_line,
          total_lines: total_lines,
          covered_lines: covered_lines,
          coverage_percentage: coverage_percentage,
          uncovered_lines_count: uncovered_lines_count
        }
      end
    end
  end
end