# frozen_string_literal: true

module CodingAgentTools
  module Models
    # Represents coverage analysis results for a single file
    class CoverageResult
      attr_reader :file_path, :total_lines, :covered_lines, :coverage_percentage, :methods

      def initialize(file_path:, total_lines:, covered_lines:, coverage_percentage:, methods: [])
        @file_path = file_path
        @total_lines = total_lines
        @covered_lines = covered_lines
        @coverage_percentage = coverage_percentage
        @methods = methods
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

      def to_h
        {
          file_path: file_path,
          relative_path: relative_path,
          total_lines: total_lines,
          covered_lines: covered_lines,
          coverage_percentage: coverage_percentage,
          uncovered_lines_count: uncovered_lines_count,
          methods: methods.map(&:to_h)
        }
      end
    end
  end
end