# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    # Formats arrays of line numbers into compact range notation
    # Converts arrays like [11, 12, 13, 22, 23, 25, 26, 27, 28]
    # into compact strings like "11..13,22,23,25..28"
    class CompactRangeFormatter
      def initialize
        # No state needed - stateless atom
      end

      # Formats an array of line numbers into compact range notation
      # @param line_numbers [Array<Integer>] Array of line numbers (sorted or unsorted)
      # @return [String] Compact range string (e.g., "11..13,22,23,25..28")
      def format_compact_ranges(line_numbers)
        return "" if line_numbers.nil? || line_numbers.empty?

        # Sort and remove duplicates
        sorted_lines = line_numbers.uniq.sort

        # Group consecutive numbers into ranges
        ranges = group_consecutive_numbers(sorted_lines)

        # Format each range/single number
        formatted_ranges = ranges.map { |range| format_single_range(range) }

        # Join with commas
        formatted_ranges.join(",")
      end

      # Expands a compact range string back into an array of line numbers
      # @param compact_string [String] Compact range string (e.g., "11..13,22,23,25..28")
      # @return [Array<Integer>] Array of line numbers
      def expand_compact_ranges(compact_string)
        return [] if compact_string.nil? || compact_string.strip.empty?

        line_numbers = []

        # Split by commas to get individual ranges/numbers
        parts = compact_string.split(",").map(&:strip)

        parts.each do |part|
          if part.include?("..")
            # Handle range (e.g., "11..13")
            start_num, end_num = part.split("..").map(&:to_i)
            line_numbers.concat((start_num..end_num).to_a)
          elsif part.include?("-")
            # Handle alternative range format (e.g., "25-28")
            start_num, end_num = part.split("-").map(&:to_i)
            line_numbers.concat((start_num..end_num).to_a)
          else
            # Handle single number (e.g., "22")
            line_numbers << part.to_i
          end
        end

        line_numbers.sort.uniq
      end

      # Validates that a compact range string is properly formatted
      # @param compact_string [String] Compact range string to validate
      # @return [Hash] validation result: { valid: Boolean, errors: Array }
      def validate_compact_format(compact_string)
        return {valid: true, errors: []} if compact_string.nil? || compact_string.strip.empty?

        errors = []

        # Basic format validation
        unless compact_string.match?(/\A[\d,.\-\s]+\z/)
          errors << "Contains invalid characters (only digits, commas, dots, and hyphens allowed)"
        end

        # Check for malformed ranges
        parts = compact_string.split(",").map(&:strip)
        parts.each_with_index do |part, index|
          if part.include?("..")
            range_parts = part.split("..")
            if range_parts.length != 2
              errors << "Malformed range at position #{index + 1}: '#{part}'"
            elsif range_parts.any? { |p| !p.match?(/\A\d+\z/) }
              errors << "Range contains non-numeric values at position #{index + 1}: '#{part}'"
            elsif range_parts[0].to_i > range_parts[1].to_i
              errors << "Invalid range order at position #{index + 1}: '#{part}' (start > end)"
            end
          elsif part.include?("-")
            range_parts = part.split("-")
            if range_parts.length != 2
              errors << "Malformed range at position #{index + 1}: '#{part}'"
            elsif range_parts.any? { |p| !p.match?(/\A\d+\z/) }
              errors << "Range contains non-numeric values at position #{index + 1}: '#{part}'"
            elsif range_parts[0].to_i > range_parts[1].to_i
              errors << "Invalid range order at position #{index + 1}: '#{part}' (start > end)"
            end
          elsif !part.match?(/\A\d+\z/)
            errors << "Invalid number at position #{index + 1}: '#{part}'"
          end
        end

        {
          valid: errors.empty?,
          errors: errors
        }
      end

      # Calculates the compression ratio achieved by compact formatting
      # @param original_array [Array<Integer>] Original array of line numbers
      # @param compact_string [String] Compact range string
      # @return [Hash] compression metrics: { original_size, compact_size, compression_ratio }
      def calculate_compression_metrics(original_array, compact_string = nil)
        return zero_compression_metrics if original_array.nil? || original_array.empty?

        compact_string ||= format_compact_ranges(original_array)

        # Calculate sizes in characters (rough approximation)
        original_size = original_array.join(",").length
        compact_size = compact_string.length

        compression_ratio = (original_size > 0) ? (compact_size.to_f / original_size * 100).round(2) : 0.0

        {
          original_size: original_size,
          compact_size: compact_size,
          compression_ratio: compression_ratio,
          space_saved: original_size - compact_size,
          space_saved_percentage: (original_size > 0) ? ((original_size - compact_size).to_f / original_size * 100).round(2) : 0.0
        }
      end

      private

      def group_consecutive_numbers(sorted_numbers)
        return [] if sorted_numbers.empty?

        ranges = []
        current_start = sorted_numbers.first
        current_end = sorted_numbers.first

        sorted_numbers[1..].each do |number|
          if number == current_end + 1
            # Consecutive number, extend the current range
            current_end = number
          else
            # Gap found, save current range and start a new one
            ranges << {start: current_start, end: current_end}
            current_start = number
            current_end = number
          end
        end

        # Add the final range
        ranges << {start: current_start, end: current_end}
        ranges
      end

      def format_single_range(range)
        if range[:start] == range[:end]
          # Single number
          range[:start].to_s
        elsif range[:end] == range[:start] + 1
          # Two consecutive numbers, better to list them separately
          "#{range[:start]},#{range[:end]}"
        else
          # Range of 3+ numbers, use range notation
          "#{range[:start]}..#{range[:end]}"
        end
      end

      def zero_compression_metrics
        {
          original_size: 0,
          compact_size: 0,
          compression_ratio: 0.0,
          space_saved: 0,
          space_saved_percentage: 0.0
        }
      end
    end
  end
end
