# frozen_string_literal: true

module CodingAgentTools
  module Models
    # Represents the complete results of a coverage analysis run
    class CoverageAnalysisResult
      attr_reader :files, :threshold, :analysis_timestamp

      def initialize(files:, threshold:, analysis_timestamp: Time.now)
        @files = files
        @threshold = threshold
        @analysis_timestamp = analysis_timestamp
      end

      def under_covered_files
        @under_covered_files ||= files.select { |file| file.under_threshold?(threshold) }
      end

      def under_covered_methods
        @under_covered_methods ||= files.flat_map(&:methods).select { |method| method.under_threshold?(threshold) }
      end

      def total_files
        files.length
      end

      def total_methods
        files.sum { |file| file.methods.length }
      end

      def overall_coverage_percentage
        return 0.0 if total_executable_lines.zero?

        (total_covered_lines.to_f / total_executable_lines * 100).round(2)
      end

      def summary_stats
        {
          total_files: total_files,
          total_methods: total_methods,
          under_covered_files_count: under_covered_files.length,
          under_covered_methods_count: under_covered_methods.length,
          overall_coverage_percentage: overall_coverage_percentage,
          threshold: threshold,
          analysis_timestamp: analysis_timestamp.iso8601
        }
      end

      def to_h
        {
          summary: summary_stats,
          under_covered_files: under_covered_files.map(&:to_h),
          under_covered_methods: under_covered_methods.map(&:to_h)
        }
      end

      private

      def total_executable_lines
        @total_executable_lines ||= files.sum(&:total_lines)
      end

      def total_covered_lines
        @total_covered_lines ||= files.sum(&:covered_lines)
      end
    end
  end
end