# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    # Maps coverage line data to Ruby method definitions
    # Combines Ruby AST parsing with SimpleCov line coverage
    class MethodCoverageMapper
      def initialize(method_parser: nil, calculator: nil)
        @method_parser = method_parser || Atoms::RubyMethodParser.new
        @calculator = calculator || Atoms::CoverageCalculator.new
      end

      # Maps coverage data to methods for a single file
      # @param file_path [String] Path to Ruby source file
      # @param lines_data [Array] SimpleCov lines array
      # @return [Array<Models::MethodCoverage>] Method coverage objects
      def map_file_coverage(file_path, lines_data)
        return [] if lines_data.nil? || lines_data.empty?

        begin
          method_definitions = @method_parser.parse_file(file_path)
          map_methods_to_coverage(method_definitions, lines_data)
        rescue Atoms::RubyMethodParser::ParseError => e
          # Log error but continue - we can still analyze file-level coverage
          warn "Warning: Could not parse methods in #{file_path}: #{e.message}"
          []
        end
      end

      # Maps coverage data to methods using source content
      # @param source_content [String] Ruby source code
      # @param lines_data [Array] SimpleCov lines array
      # @param source_name [String] Name for error reporting
      # @return [Array<Models::MethodCoverage>] Method coverage objects
      def map_content_coverage(source_content, lines_data, source_name = "<string>")
        return [] if lines_data.nil? || lines_data.empty?

        begin
          method_definitions = @method_parser.parse_content(source_content, source_name)
          map_methods_to_coverage(method_definitions, lines_data)
        rescue Atoms::RubyMethodParser::ParseError => e
          # Log error but continue - we can still analyze file-level coverage
          warn "Warning: Could not parse methods in #{source_name}: #{e.message}"
          []
        end
      end

      # Filters methods by coverage threshold
      # @param method_coverages [Array<Models::MethodCoverage>] Method coverage objects
      # @param threshold [Float] Coverage threshold percentage
      # @return [Array<Models::MethodCoverage>] Under-covered methods
      def filter_under_covered_methods(method_coverages, threshold)
        method_coverages.select { |method| method.under_threshold?(threshold) }
      end

      # Groups methods by coverage level for prioritization
      # @param method_coverages [Array<Models::MethodCoverage>] Method coverage objects
      # @return [Hash] Methods grouped by coverage level
      def group_methods_by_coverage(method_coverages)
        {
          uncovered: method_coverages.select { |m| m.coverage_percentage.zero? },
          low_coverage: method_coverages.select { |m| m.coverage_percentage > 0 && m.coverage_percentage < 50 },
          medium_coverage: method_coverages.select { |m| m.coverage_percentage >= 50 && m.coverage_percentage < 80 },
          good_coverage: method_coverages.select { |m| m.coverage_percentage >= 80 }
        }
      end

      # Identifies methods with specific coverage patterns
      # @param method_coverages [Array<Models::MethodCoverage>] Method coverage objects
      # @return [Hash] Methods with specific patterns
      def identify_coverage_patterns(method_coverages)
        patterns = {
          completely_uncovered: [],
          partially_covered: [],
          well_tested: [],
          single_line_methods: [],
          large_uncovered_methods: []
        }

        method_coverages.each do |method|
          line_count = method.total_lines

          case method.coverage_percentage
          when 0
            patterns[:completely_uncovered] << method
          when 100
            patterns[:well_tested] << method
          else
            patterns[:partially_covered] << method
          end

          patterns[:single_line_methods] << method if line_count <= 1
          patterns[:large_uncovered_methods] << method if line_count >= 10 && method.coverage_percentage < 50
        end

        patterns
      end

      private

      def map_methods_to_coverage(method_definitions, lines_data)
        method_definitions.map do |method_def|
          coverage_data = @calculator.calculate_range_coverage(
            lines_data,
            method_def.start_line,
            method_def.end_line
          )

          # Extract uncovered lines within this method's range
          method_lines = extract_method_lines(lines_data, method_def.start_line, method_def.end_line)
          uncovered_lines = extract_uncovered_lines_in_method(method_lines, method_def.start_line)

          Models::MethodCoverage.new(
            name: method_def.name,
            start_line: method_def.start_line,
            end_line: method_def.end_line,
            total_lines: coverage_data[:total_lines],
            covered_lines: coverage_data[:covered_lines],
            coverage_percentage: coverage_data[:coverage_percentage],
            visibility: method_def.visibility,
            uncovered_lines: uncovered_lines
          )
        end
      end

      def extract_method_lines(lines_data, start_line, end_line)
        return [] if lines_data.nil? || lines_data.empty?
        
        # Ensure start_line and end_line are integers
        start_line = start_line.to_i
        end_line = end_line.to_i
        
        # Convert to 0-based indexing
        range_start = [start_line - 1, 0].max
        range_end = [end_line - 1, lines_data.length - 1].min
        
        return [] if range_start >= lines_data.length
        
        # Safely extract the range
        begin
          lines_data[range_start..range_end] || []
        rescue TypeError => e
          warn "Warning: Error extracting method lines for range #{range_start}..#{range_end}: #{e.message}"
          []
        end
      end

      def extract_uncovered_lines_in_method(method_lines, method_start_line)
        uncovered_lines = []
        
        method_lines.each_with_index do |coverage, index|
          # Calculate actual line number in file
          actual_line_number = method_start_line + index
          
          # Uncovered line: executable (not nil) but with 0 coverage
          if coverage == 0
            uncovered_lines << actual_line_number
          end
        end
        
        uncovered_lines
      end
    end
  end
end