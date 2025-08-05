# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    # Analyzes individual files for coverage metrics and method-level details
    # Combines coverage data processing with method mapping
    class FileAnalyzer
      def initialize(method_mapper: nil, calculator: nil)
        @method_mapper = method_mapper || MethodCoverageMapper.new
        @calculator = calculator || Atoms::CoverageCalculator.new
      end

      # Analyzes a single file's coverage including methods
      # @param file_path [String] Path to the source file
      # @param file_coverage_data [Hash] Coverage data from CoverageDataProcessor
      # @return [Models::CoverageResult] Complete file analysis
      def analyze_file(file_path, file_coverage_data)
        coverage_info = file_coverage_data[:coverage_data]
        lines_data = file_coverage_data[:lines_data]

        # Map method coverage if file exists and is readable
        methods = if File.exist?(file_path) && File.readable?(file_path)
          @method_mapper.map_file_coverage(file_path, lines_data)
        else
          warn "Warning: Cannot read source file #{file_path} for method analysis"
                    []
        end

        Models::CoverageResult.new(
          file_path: file_path,
          total_lines: coverage_info[:total_lines],
          covered_lines: coverage_info[:covered_lines],
          coverage_percentage: coverage_info[:coverage_percentage],
          methods: methods,
          uncovered_details: file_coverage_data[:uncovered_details]
        )
      end

      # Analyzes multiple files and returns prioritized results
      # @param processed_data [Hash] Data from CoverageDataProcessor
      # @param options [Hash] Analysis options
      # @option options [Float] :threshold Coverage threshold for filtering
      # @option options [String] :sort_by Sort method ('coverage', 'uncovered_lines', 'file_name')
      # @option options [Boolean] :methods_only Only return files with method analysis
      # @return [Array<Models::CoverageResult>] Analyzed files
      def analyze_files(processed_data, options = {})
        threshold = options[:threshold] || 85.0
        sort_by = options[:sort_by] || 'coverage'
        methods_only = options[:methods_only] || false

        file_results = processed_data[:file_coverage].map do |file_path, file_data|
          analyze_file(file_path, file_data)
        end

        # Filter for methods_only if requested
        file_results = file_results.select { |result| !result.methods.empty? } if methods_only

        # Sort results based on criteria
        sorted_results = sort_file_results(file_results, sort_by)

        # Prioritize under-covered files
        under_covered, well_covered = sorted_results.partition { |result| result.under_threshold?(threshold) }

        # Return under-covered files first, then well-covered
        under_covered + well_covered
      end

      # Provides detailed analysis for a specific file
      # @param file_path [String] Path to the source file
      # @param file_coverage_data [Hash] Coverage data from CoverageDataProcessor
      # @param options [Hash] Analysis options
      # @return [Hash] Detailed analysis report
      def detailed_file_analysis(file_path, file_coverage_data, options = {})
        threshold = options[:threshold] || 85.0

        file_result = analyze_file(file_path, file_coverage_data)

        # Analyze methods if available
        method_analysis = if file_result.methods.any?
          analyze_file_methods(file_result.methods, threshold)
        else
          { message: 'No methods found or file could not be parsed' }
        end

        # Analyze line-by-line coverage for uncovered areas
        uncovered_lines = find_uncovered_line_ranges(file_coverage_data[:lines_data])

        {
          file_info: {
            path: file_result.file_path,
            relative_path: file_result.relative_path,
            total_lines: file_result.total_lines,
            covered_lines: file_result.covered_lines,
            coverage_percentage: file_result.coverage_percentage,
            under_threshold: file_result.under_threshold?(threshold)
          },
          method_analysis: method_analysis,
          uncovered_areas: uncovered_lines,
          frameworks: file_coverage_data[:frameworks],
          priority_score: calculate_priority_score(file_result, threshold)
        }
      end

      # Calculates a priority score for testing focus
      # @param file_result [Models::CoverageResult] File coverage result
      # @param threshold [Float] Coverage threshold
      # @return [Integer] Priority score (higher = more urgent)
      def calculate_priority_score(file_result, threshold)
        score = 0

        # Base score on how far below threshold
        if file_result.under_threshold?(threshold)
          gap = threshold - file_result.coverage_percentage
          score += (gap * 2).to_i # 2 points per percentage point below threshold
        end

        # Bonus for files with many uncovered lines
        score += [file_result.uncovered_lines_count / 5, 20].min # Up to 20 bonus points

        # Bonus for files with uncovered methods
        uncovered_methods = file_result.methods.count { |m| m.coverage_percentage.zero? }
        score += uncovered_methods * 5 # 5 points per completely uncovered method

        # Bonus for large methods with low coverage
        large_low_coverage_methods = file_result.methods.count do |m|
          m.total_lines >= 10 && m.coverage_percentage < 50
        end
        score += large_low_coverage_methods * 10 # 10 points per large under-covered method

        score
      end

      private

      def analyze_file_methods(methods, threshold)
        method_patterns = @method_mapper.identify_coverage_patterns(methods)
        under_covered = @method_mapper.filter_under_covered_methods(methods, threshold)

        {
          total_methods: methods.length,
          under_covered_methods: under_covered.length,
          coverage_patterns: method_patterns.transform_values(&:length),
          worst_methods: methods.sort_by(&:coverage_percentage).first(5),
          largest_uncovered_methods: methods
            .select { |m| m.total_lines >= 5 && m.coverage_percentage < 50 }
            .sort_by { |m| -m.total_lines }
            .first(3)
        }
      end

      def find_uncovered_line_ranges(lines_data)
        return [] if lines_data.nil? || lines_data.empty?

        uncovered_ranges = []
        current_range = nil

        lines_data.each_with_index do |coverage, index|
          line_number = index + 1 # Convert to 1-based line numbers

          if coverage == 0 # Uncovered executable line
            if current_range
              current_range[:end_line] = line_number
            else
              current_range = { start_line: line_number, end_line: line_number }
            end
          elsif current_range
            # End of uncovered range
            uncovered_ranges << current_range
            current_range = nil
          end
        end

        # Add final range if we ended on an uncovered line
        uncovered_ranges << current_range if current_range

        uncovered_ranges
      end

      def sort_file_results(file_results, sort_by)
        case sort_by.to_s.downcase
        when 'coverage'
          file_results.sort_by(&:coverage_percentage)
        when 'uncovered_lines'
          file_results.sort_by { |result| -result.uncovered_lines_count }
        when 'file_name'
          file_results.sort_by(&:relative_path)
        when 'priority'
          file_results.sort_by { |result| -calculate_priority_score(result, 85.0) }
        else
          file_results.sort_by(&:coverage_percentage)
        end
      end
    end
  end
end
