# frozen_string_literal: true

module CodingAgentTools
  module Organisms
    # High-level orchestrator for coverage analysis workflow
    # Coordinates data processing, file analysis, and result generation
    class CoverageAnalyzer
      def initialize(
        data_processor: nil,
        file_analyzer: nil,
        report_formatter: nil,
        threshold_validator: nil
      )
        @data_processor = data_processor || Molecules::CoverageDataProcessor.new
        @file_analyzer = file_analyzer || Molecules::FileAnalyzer.new
        @report_formatter = report_formatter || Molecules::ReportFormatter.new
        @threshold_validator = threshold_validator || Atoms::ThresholdValidator.new
      end

      # Performs complete coverage analysis from SimpleCov file
      # @param file_path [String] Path to SimpleCov .resultset.json file
      # @param options [Hash] Analysis options
      # @option options [Float] :threshold Coverage threshold percentage (default: 85.0)
      # @option options [Array<String>] :include_patterns File patterns to include (default: ["**/lib/**"])
      # @option options [Array<String>] :exclude_patterns File patterns to exclude (default: ["**/spec/**", "**/test/**"])
      # @option options [Boolean] :detailed_analysis Include method-level analysis (default: false)
      # @option options [String] :sort_by Sorting criteria ('coverage', 'uncovered_lines', 'file_name') (default: 'coverage')
      # @return [Models::CoverageAnalysisResult] Complete analysis results
      def analyze_coverage(file_path, options = {})
        # Validate and set defaults
        validated_options = validate_options(options)
        threshold = validated_options[:threshold]
        
        # Process SimpleCov data
        processed_data = @data_processor.process_file(file_path, validated_options)
        
        # Analyze files
        file_results = @file_analyzer.analyze_files(
          processed_data,
          threshold: threshold,
          sort_by: validated_options[:sort_by],
          detailed_analysis: validated_options[:detailed_analysis]
        )
        
        # Create analysis result
        Models::CoverageAnalysisResult.new(
          files: file_results,
          threshold: threshold,
          analysis_timestamp: Time.now
        )
      end

      # Analyzes a single file in detail with method-level breakdown
      # @param file_path [String] Path to source file
      # @param coverage_data [Hash] File coverage data from SimpleCov
      # @param options [Hash] Analysis options
      # @return [Hash] Detailed file analysis
      def analyze_file_details(file_path, coverage_data, options = {})
        validated_options = validate_options(options)
        
        @file_analyzer.detailed_file_analysis(
          file_path,
          coverage_data,
          threshold: validated_options[:threshold]
        )
      end

      # Generates analysis report in specified format
      # @param analysis_result [Models::CoverageAnalysisResult] Analysis results
      # @param format [Symbol] Output format (:text, :json, :csv)
      # @param options [Hash] Report options
      # @return [String] Formatted report
      def generate_report(analysis_result, format = :text, options = {})
        @report_formatter.validate_format(format)
        
        case format
        when :text
          @report_formatter.format_text_report(analysis_result)
        when :json
          @report_formatter.format_json_report(analysis_result)
        when :csv
          @report_formatter.format_csv_report(analysis_result)
        end
      end

      # Saves analysis report to file
      # @param analysis_result [Models::CoverageAnalysisResult] Analysis results
      # @param output_path [String] Output file path
      # @param format [Symbol] Output format (auto-detected from extension if nil)
      # @return [String] Path to saved file
      def save_report(analysis_result, output_path, format = nil)
        format ||= @report_formatter.detect_output_format(output_path)
        report_content = generate_report(analysis_result, format)
        
        @report_formatter.save_report(report_content, output_path)
        output_path
      end

      # Identifies files most urgently needing test coverage
      # @param analysis_result [Models::CoverageAnalysisResult] Analysis results
      # @param limit [Integer] Maximum number of files to return (default: 10)
      # @return [Array<Models::CoverageResult>] Prioritized list of under-covered files
      def prioritize_critical_files(analysis_result, limit = 10)
        under_covered = analysis_result.under_covered_files
        
        # Calculate priority scores for each file
        scored_files = under_covered.map do |file|
          priority_score = @file_analyzer.calculate_priority_score(file, analysis_result.threshold)
          { file: file, priority_score: priority_score }
        end
        
        # Sort by priority score (descending) and take the top files
        scored_files
          .sort_by { |item| -item[:priority_score] }
          .first(limit)
          .map { |item| item[:file] }
      end

      # Generates summary statistics across the codebase
      # @param analysis_result [Models::CoverageAnalysisResult] Analysis results
      # @return [Hash] Comprehensive statistics
      def generate_statistics(analysis_result)
        base_stats = @report_formatter.generate_summary_stats(analysis_result)
        
        # Add additional organism-level statistics
        files = analysis_result.files
        under_covered_files = analysis_result.under_covered_files
        
        base_stats.merge(
          coverage_trends: {
            worst_file: files.min_by(&:coverage_percentage),
            best_file: files.max_by(&:coverage_percentage),
            average_coverage: files.sum(&:coverage_percentage) / files.length.to_f,
            median_coverage: calculate_median_coverage(files)
          },
          urgency_metrics: {
            critical_files_count: under_covered_files.count { |f| f.coverage_percentage < 50.0 },
            needs_attention_count: under_covered_files.count { |f| f.coverage_percentage >= 50.0 && f.coverage_percentage < analysis_result.threshold },
            large_uncovered_files: under_covered_files.select { |f| f.total_lines > 100 && f.coverage_percentage < 70.0 }.length
          }
        )
      end

      private

      def validate_options(options)
        validated = {
          threshold: @threshold_validator.validate_threshold(options[:threshold] || 85.0),
          include_patterns: options[:include_patterns] || ["**/lib/**"],
          exclude_patterns: options[:exclude_patterns] || ["**/spec/**", "**/test/**"],
          detailed_analysis: options[:detailed_analysis] || false,
          sort_by: options[:sort_by] || 'coverage'
        }
        
        # Validate sort_by option
        valid_sort_options = ['coverage', 'uncovered_lines', 'file_name']
        unless valid_sort_options.include?(validated[:sort_by])
          raise ArgumentError, "Invalid sort_by option: #{validated[:sort_by]}. Valid options: #{valid_sort_options.join(', ')}"
        end
        
        validated
      end

      def calculate_median_coverage(files)
        sorted_percentages = files.map(&:coverage_percentage).sort
        count = sorted_percentages.length
        
        if count.even?
          (sorted_percentages[count / 2 - 1] + sorted_percentages[count / 2]) / 2.0
        else
          sorted_percentages[count / 2]
        end
      end
    end
  end
end