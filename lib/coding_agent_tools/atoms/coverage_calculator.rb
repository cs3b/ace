# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    # Calculates coverage percentages from line coverage data
    # Handles null values (non-executable lines) correctly
    class CoverageCalculator
      def initialize
        # No state needed - stateless atom
      end

      # Calculates coverage percentage from SimpleCov line array
      # @param lines [Array] SimpleCov lines array (null, 0, or positive integers)
      # @return [Hash] coverage metrics: { total_lines, covered_lines, coverage_percentage }
      def calculate_file_coverage(lines)
        return zero_coverage if lines.nil? || lines.empty?

        executable_lines = count_executable_lines(lines)
        covered_lines = count_covered_lines(lines)

        {
          total_lines: executable_lines,
          covered_lines: covered_lines,
          coverage_percentage: calculate_percentage(covered_lines, executable_lines)
        }
      end

      # Calculates coverage for a specific line range within a file
      # @param lines [Array] SimpleCov lines array
      # @param start_line [Integer] Starting line number (1-based)
      # @param end_line [Integer] Ending line number (1-based)
      # @return [Hash] coverage metrics for the range
      def calculate_range_coverage(lines, start_line, end_line)
        return zero_coverage if lines.nil? || lines.empty?
        return zero_coverage if end_line < start_line

        # Convert to 0-based indexing and extract range
        # SimpleCov uses 1-based indexing with null at index 0
        range_start = [start_line - 1, 0].max
        range_end = [end_line - 1, lines.length - 1].min
        
        return zero_coverage if range_start >= lines.length

        range_lines = lines[range_start..range_end] || []
        calculate_file_coverage(range_lines)
      end

      # Calculates combined coverage from multiple line arrays (e.g., multiple test frameworks)
      # @param lines_arrays [Array<Array>] Array of SimpleCov line arrays
      # @return [Hash] combined coverage metrics
      def calculate_combined_coverage(lines_arrays)
        return zero_coverage if lines_arrays.nil? || lines_arrays.empty?

        # Find the maximum length to handle arrays of different sizes
        max_length = lines_arrays.map(&:length).max
        return zero_coverage if max_length.zero?

        # Combine coverage data: null stays null, numbers get summed
        combined_lines = Array.new(max_length)
        
        (0...max_length).each do |index|
          values = lines_arrays.map { |arr| arr[index] if index < arr.length }.compact
          
          if values.empty? || values.all?(&:nil?)
            combined_lines[index] = nil
          else
            # Sum non-nil values, treat nil as 0 for combination
            combined_lines[index] = values.map { |v| v || 0 }.sum
          end
        end

        calculate_file_coverage(combined_lines)
      end

      private

      def zero_coverage
        {
          total_lines: 0,
          covered_lines: 0,
          coverage_percentage: 0.0
        }
      end

      def count_executable_lines(lines)
        lines.count { |line| !line.nil? }
      end

      def count_covered_lines(lines)
        lines.count { |line| line.is_a?(Integer) && line > 0 }
      end

      def calculate_percentage(covered, total)
        return 0.0 if total.zero?
        
        ((covered.to_f / total) * 100).round(2)
      end
    end
  end
end