# frozen_string_literal: true

require "json"
require "csv"
require "fileutils"

module CodingAgentTools
  module Molecules
    # Formats coverage analysis results into multiple output formats
    # Supports text, JSON, and CSV with proper escaping and formatting
    class ReportFormatter
      class SaveError < StandardError; end
      class InvalidFormatError < StandardError; end

      SUPPORTED_FORMATS = [:text, :json, :csv].freeze

      def initialize(threshold_validator: nil)
        @threshold_validator = threshold_validator || Atoms::ThresholdValidator.new
      end

      # Formats a text report from analysis results
      # @param analysis_result [Models::CoverageAnalysisResult] Analysis results
      # @param format [Symbol] Output format (:compact or :verbose)
      # @return [String] Text formatted report
      def format_text_report(analysis_result, format: :compact)
        lines = []
        lines << "Coverage Analysis Report"
        lines << "=" * 50
        lines << ""
        
        # Summary section
        lines << "Overall Coverage: #{format_coverage_percentage(analysis_result.overall_coverage_percentage)}"
        lines.concat(format_threshold_information(analysis_result))
        lines << "Files Under Threshold: #{analysis_result.under_covered_files.length} of #{analysis_result.total_files}"
        lines << ""
        lines << "Total Lines: #{analysis_result.send(:total_executable_lines)}"
        lines << "Covered Lines: #{analysis_result.send(:total_covered_lines)}"
        # Note: frameworks info will be added when extended in organisms
        lines << ""

        # Public methods needing tests section
        public_methods_needing_tests = extract_public_methods_needing_tests(analysis_result)
        
        if public_methods_needing_tests.any?
          lines << "Public Methods Needing Tests:"
          lines << "-" * 50
          
          public_methods_needing_tests.each do |file_path, methods|
            relative_path = file_path.gsub(%r{^.*/lib/}, "lib/")
            lines << "#{relative_path}:"
            
            methods.each do |method|
              lines << "  • #{method.name} (lines #{method.start_line}-#{method.end_line})"
              lines << "    Coverage: #{format_coverage_percentage(method.coverage_percentage)}"
              
              if method.uncovered_lines.any?
                uncovered_display = format == :verbose ? method.uncovered_lines.join(', ') : method.uncovered_lines_compact
                lines << "    Uncovered lines: #{uncovered_display}"
                lines << "    → Write tests to cover these specific lines"
              end
              lines << ""
            end
          end
          
          lines << "📝 Testing Priority:"
          lines << "• Focus on public methods with 0% coverage first"
          lines << "• Test uncovered lines within each method"
          lines << "• Private/protected methods are not shown (typically tested indirectly)"
        else
          lines << "All public methods have test coverage!"
        end

        lines.join("\n")
      end

      # Formats a detailed file analysis report
      # @param detailed_analysis [Hash] Detailed file analysis data
      # @return [String] Detailed file report
      def format_detailed_file_report(detailed_analysis)
        lines = []
        file_info = detailed_analysis[:file_info]
        method_analysis = detailed_analysis[:method_analysis]
        uncovered_areas = detailed_analysis[:uncovered_areas]
        
        lines << "File: #{file_info[:relative_path]}"
        lines << ""
        
        if method_analysis
          lines << "Method Analysis:"
          lines << "Total Methods: #{method_analysis[:total_methods]}"
          lines << "Under-Covered Methods: #{method_analysis[:under_covered_methods]}"
          lines << "Completely Uncovered: #{method_analysis[:completely_uncovered]}"
          lines << ""
        end

        if uncovered_areas && uncovered_areas.any?
          lines << "Uncovered Areas:"
          uncovered_areas.each do |area|
            if area[:start_line] == area[:end_line]
              lines << "Line #{area[:start_line]}"
            else
              lines << "Lines #{area[:start_line]}-#{area[:end_line]}"
            end
          end
          lines << ""
        end

        if detailed_analysis[:priority_score]
          lines << "Priority Score: #{detailed_analysis[:priority_score]}"
        end

        lines.join("\n")
      end

      # Formats JSON report from analysis results
      # @param analysis_result [Models::CoverageAnalysisResult] Analysis results
      # @param format [Symbol] Output format (:compact or :verbose)
      # @return [String] JSON formatted report
      def format_json_report(analysis_result, format: :compact)
        report_data = analysis_result.to_h(format: format)
        
        case format
        when :compact
          # Compact format returns an array, use it directly
          JSON.pretty_generate(report_data)
        when :verbose
          # Verbose format returns a hash, add metadata
          public_methods_needing_tests = extract_public_methods_needing_tests(analysis_result)
          report_data[:public_methods_needing_tests] = format_public_methods_for_json(public_methods_needing_tests, format: format)
          
          report_data[:metadata] = {
            generated_at: Time.now.iso8601,
            analysis_timestamp: analysis_result.analysis_timestamp.iso8601
          }
          
          # Add adaptive threshold information if available
          if analysis_result.respond_to?(:adaptive_threshold_used?) && analysis_result.adaptive_threshold_used?
            report_data[:adaptive_threshold] = analysis_result.adaptive_threshold_result
          end
          
          JSON.pretty_generate(report_data)
        else
          # Default to compact
          JSON.pretty_generate(report_data)
        end
      end

      # Formats CSV report from analysis results
      # @param analysis_result [Models::CoverageAnalysisResult] Analysis results
      # @return [String] CSV formatted report
      def format_csv_report(analysis_result)
        CSV.generate do |csv|
          # Header row
          csv << ["file_path", "coverage_percentage", "total_lines", "covered_lines", "uncovered_lines", "under_threshold"]
          
          # File data rows
          analysis_result.files.each do |file|
            csv << [
              file.relative_path,
              file.coverage_percentage,
              file.total_lines,
              file.covered_lines,
              file.uncovered_lines_count,
              file.under_threshold?(analysis_result.threshold)
            ]
          end
        end
      end

      # Saves report content to file
      # @param content [String] Report content
      # @param file_path [String] Output file path
      def save_report(content, file_path)
        begin
          FileUtils.mkdir_p(File.dirname(file_path))
          File.write(file_path, content)
        rescue => e
          raise SaveError, "Failed to save report to #{file_path}: #{e.message}"
        end
      end

      # Generates summary statistics for analysis results
      # @param analysis_result [Models::CoverageAnalysisResult] Analysis results
      # @return [Hash] Summary statistics
      def generate_summary_stats(analysis_result)
        files = analysis_result.files
        under_threshold_count = analysis_result.under_covered_files.length
        
        {
          files_summary: {
            total_files: files.length,
            under_threshold_count: under_threshold_count,
            percentage_under_threshold: calculate_percentage(under_threshold_count, files.length)
          },
          coverage_distribution: {
            excellent: files.count { |f| f.coverage_percentage >= 90.0 },
            good: files.count { |f| f.coverage_percentage >= 80.0 && f.coverage_percentage < 90.0 },
            fair: files.count { |f| f.coverage_percentage >= 60.0 && f.coverage_percentage < 80.0 },
            poor: files.count { |f| f.coverage_percentage < 60.0 }
          },
          line_coverage_stats: {
            total_lines: analysis_result.send(:total_executable_lines),
            covered_lines: analysis_result.send(:total_covered_lines),
            overall_percentage: analysis_result.overall_coverage_percentage
          }
        }
      end

      # Detects output format from file extension
      # @param file_path [String] File path
      # @return [Symbol] Detected format
      def detect_output_format(file_path)
        extension = File.extname(file_path).downcase
        case extension
        when '.json'
          :json
        when '.csv'
          :csv
        else
          :text
        end
      end

      # Validates output format
      # @param format [Symbol, String] Format to validate (accepts both symbols and strings)
      # @raise [InvalidFormatError] If format is not supported
      def validate_format(format)
        # Convert string to symbol for consistency
        format_symbol = format.is_a?(String) ? format.to_sym : format
        
        unless SUPPORTED_FORMATS.include?(format_symbol)
          raise InvalidFormatError, "Unsupported format: #{format}. Supported formats: #{SUPPORTED_FORMATS.join(', ')}"
        end
        
        format_symbol
      end

      # Formats report data for create-path integration
      # @param analysis_result [Models::CoverageAnalysisResult] Analysis results
      # @return [Hash] Create-path compatible report data
      def format_for_create_path(analysis_result)
        under_covered_files = analysis_result.under_covered_files
        
        {
          summary: {
            action_required: under_covered_files.any?,
            total_files: analysis_result.total_files,
            under_covered_files: under_covered_files.length,
            overall_coverage: analysis_result.overall_coverage_percentage,
            threshold: analysis_result.threshold
          },
          details: {
            under_covered_files: under_covered_files.map { |file| file.to_h(format: :verbose) }
          },
          recommendations: generate_recommendations(analysis_result)
        }
      end

      private

      def format_coverage_percentage(percentage)
        "#{percentage.round(1)}%"
      end

      def format_threshold_information(analysis_result)
        lines = []
        
        if analysis_result.respond_to?(:adaptive_threshold_used?) && analysis_result.adaptive_threshold_used?
          # Adaptive threshold was used
          lines << "Threshold: #{format_coverage_percentage(analysis_result.threshold)} (adaptive)"
          
          if analysis_result.respond_to?(:adaptive_threshold_result)
            adaptive_result = analysis_result.adaptive_threshold_result
            lines << "Adaptive Selection: #{adaptive_result[:reasoning]}"
            
            # Add brief summary of threshold testing if available
            if adaptive_result[:threshold_testing_results] && adaptive_result[:threshold_testing_results].length > 1
              actionable_count = adaptive_result[:threshold_testing_results].count { |r| r[:actionable] }
              lines << "Thresholds Tested: #{adaptive_result[:threshold_testing_results].length} (#{actionable_count} actionable)"
            end
          end
        else
          # Manual threshold was used
          lines << "Threshold: #{format_coverage_percentage(analysis_result.threshold)}"
        end
        
        lines
      end

      def format_file_size(line_count)
        return "#{line_count} line" if line_count == 1
        
        if line_count >= 1000
          formatted = number_with_delimiter(line_count)
          "#{formatted} lines"
        else
          "#{line_count} lines"
        end
      end

      def format_uncovered_ranges(ranges)
        return "" if ranges.empty?
        
        formatted_ranges = ranges.map do |range|
          if range[:start_line] == range[:end_line]
            range[:start_line].to_s
          else
            "#{range[:start_line]}-#{range[:end_line]}"
          end
        end
        
        formatted_ranges.join(", ")
      end

      def extract_public_methods_needing_tests(analysis_result)
        public_methods_by_file = {}
        
        analysis_result.files.each do |file|
          public_methods = file.methods.select(&:needs_tests?)
          
          if public_methods.any?
            public_methods_by_file[file.file_path] = public_methods.sort_by(&:coverage_percentage)
          end
        end
        
        public_methods_by_file
      end

      def format_public_methods_for_json(public_methods_by_file, format: :compact)
        formatted = {}
        
        public_methods_by_file.each do |file_path, methods|
          relative_path = file_path.gsub(%r{^.*/lib/}, "lib/")
          formatted[relative_path] = methods.map { |method| method.to_h(format: format) }
        end
        
        formatted
      end

      def number_with_delimiter(number)
        number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
      end

      def prioritize_results_by_severity(results)
        results.sort_by(&:coverage_percentage)
      end

      def calculate_percentage(numerator, denominator)
        return 0.0 if denominator.zero?
        ((numerator.to_f / denominator) * 100).round(1)
      end

      def generate_recommendations(analysis_result)
        recommendations = []
        under_covered_files = analysis_result.under_covered_files
        
        if under_covered_files.any?
          recommendations << "#{under_covered_files.length} file#{under_covered_files.length == 1 ? '' : 's'} below #{analysis_result.threshold}% threshold requires attention"
          
          # Focus on worst file
          worst_file = under_covered_files.min_by(&:coverage_percentage)
          recommendations << "Focus testing efforts on #{worst_file.relative_path} (#{format_coverage_percentage(worst_file.coverage_percentage)} coverage)"
        else
          recommendations << "All files meet coverage threshold - excellent work!"
        end
        
        recommendations
      end
    end
  end
end