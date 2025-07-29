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

        # Ensure start_line and end_line are integers
        start_line = start_line.to_i
        end_line = end_line.to_i

        # Convert to 0-based indexing and extract range
        # SimpleCov uses 1-based indexing with null at index 0
        range_start = [start_line - 1, 0].max
        range_end = [end_line - 1, lines.length - 1].min

        return zero_coverage if range_start >= lines.length

        # Safely extract the range
        begin
          range_lines = lines[range_start..range_end] || []
          calculate_file_coverage(range_lines)
        rescue TypeError => e
          warn "Warning: Error calculating range coverage for range #{range_start}..#{range_end}: #{e.message}"
          zero_coverage
        end
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

          combined_lines[index] = if values.empty? || values.all?(&:nil?)
            nil
          else
            # Sum non-nil values, treat nil as 0 for combination
            values.map { |v| v || 0 }.sum
          end
        end

        calculate_file_coverage(combined_lines)
      end

      # Extracts uncovered line numbers and ranges from SimpleCov line array
      # @param lines [Array] SimpleCov lines array (null, 0, or positive integers)
      # @return [Hash] uncovered line details: { uncovered_lines, uncovered_ranges, total_uncovered }
      def extract_uncovered_lines(lines)
        return {uncovered_lines: [], uncovered_ranges: [], total_uncovered: 0} if lines.nil? || lines.empty?

        uncovered_lines = []

        lines.each_with_index do |coverage, index|
          # Line numbers are 1-based, array indices are 0-based
          line_number = index + 1

          # Uncovered line: executable (not nil) but with 0 coverage
          if coverage == 0
            uncovered_lines << line_number
          end
        end

        {
          uncovered_lines: uncovered_lines,
          uncovered_ranges: group_into_ranges(uncovered_lines),
          total_uncovered: uncovered_lines.length
        }
      end

      # Extracts detailed line-by-line coverage information
      # @param lines [Array] SimpleCov lines array
      # @return [Array<Hash>] detailed line information
      def extract_detailed_line_info(lines)
        return [] if lines.nil? || lines.empty?

        line_details = []

        lines.each_with_index do |coverage, index|
          line_number = index + 1

          next if coverage.nil? # Skip non-executable lines

          line_details << {
            line_number: line_number,
            coverage_count: coverage,
            status: (coverage > 0) ? :covered : :uncovered
          }
        end

        line_details
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

      def group_into_ranges(line_numbers)
        return [] if line_numbers.empty?

        ranges = []
        current_start = line_numbers.first
        current_end = line_numbers.first

        line_numbers[1..-1].each do |line_num|
          if line_num == current_end + 1
            # Consecutive line, extend the current range
            current_end = line_num
          else
            # Gap found, save current range and start a new one
            ranges << {start_line: current_start, end_line: current_end}
            current_start = line_num
            current_end = line_num
          end
        end

        # Add the final range
        ranges << {start_line: current_start, end_line: current_end}
        ranges
      end
    end
  end
end
