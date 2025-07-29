# frozen_string_literal: true

module CodingAgentTools
  module Organisms
    # Specialized organism for extracting and prioritizing under-covered code items
    # Focuses on identifying the most critical areas that need testing attention
    class UndercoveredItemsExtractor
      def initialize(
        file_analyzer: nil,
        method_mapper: nil,
        threshold_validator: nil
      )
        @file_analyzer = file_analyzer || Molecules::FileAnalyzer.new
        @method_mapper = method_mapper || Molecules::MethodCoverageMapper.new
        @threshold_validator = threshold_validator || Atoms::ThresholdValidator.new
      end

      # Extracts all under-covered items from analysis results
      # @param analysis_result [Models::CoverageAnalysisResult] Analysis results
      # @param options [Hash] Extraction options
      # @option options [Integer] :max_files Maximum files to include (default: 20)
      # @option options [Integer] :max_methods_per_file Maximum methods per file (default: 10)
      # @option options [Boolean] :include_method_details Include detailed method analysis (default: true)
      # @return [Hash] Structured under-covered items
      def extract_undercovered_items(analysis_result, options = {})
        validated_options = validate_extraction_options(options)
        under_covered_files = analysis_result.under_covered_files
        threshold = analysis_result.threshold

        # Prioritize files by urgency
        prioritized_files = prioritize_files_by_urgency(under_covered_files, threshold)
          .first(validated_options[:max_files])

        {
          summary: {
            total_under_covered_files: under_covered_files.length,
            files_analyzed: prioritized_files.length,
            threshold_used: threshold,
            extraction_timestamp: Time.now.iso8601
          },
          files: prioritized_files.map do |file|
            extract_file_items(file, threshold, validated_options)
          end,
          urgency_breakdown: categorize_by_urgency(under_covered_files, threshold),
          recommendations: generate_action_recommendations(prioritized_files, threshold)
        }
      end

      # Extracts specific types of under-covered items
      # @param analysis_result [Models::CoverageAnalysisResult] Analysis results
      # @param item_type [Symbol] Type of items to extract (:files, :methods, :lines, :all)
      # @param options [Hash] Extraction options
      # @return [Array] Extracted items of specified type
      def extract_by_type(analysis_result, item_type, options = {})
        case item_type
        when :files
          extract_critical_files(analysis_result, options)
        when :methods
          extract_critical_methods(analysis_result, options)
        when :lines
          extract_critical_line_ranges(analysis_result, options)
        when :all
          {
            files: extract_critical_files(analysis_result, options),
            methods: extract_critical_methods(analysis_result, options),
            lines: extract_critical_line_ranges(analysis_result, options)
          }
        else
          raise ArgumentError, "Invalid item_type: #{item_type}. Valid types: :files, :methods, :lines, :all"
        end
      end

      # Finds files with the worst coverage that would have the highest impact if improved
      # @param analysis_result [Models::CoverageAnalysisResult] Analysis results
      # @param options [Hash] Search options
      # @option options [Integer] :limit Number of files to return (default: 5)
      # @option options [Integer] :min_size Minimum file size in lines (default: 10)
      # @return [Array<Hash>] High-impact files with improvement potential
      def find_high_impact_files(analysis_result, options = {})
        limit = options[:limit] || 5
        min_size = options[:min_size] || 10
        threshold = analysis_result.threshold

        under_covered_files = analysis_result.under_covered_files
          .select { |file| file.total_lines >= min_size }

        # Calculate impact score: (uncovered_lines * coverage_gap) / file_size
        # This favors files with many uncovered lines but penalizes very large files
        scored_files = under_covered_files.map do |file|
          coverage_gap = threshold - file.coverage_percentage
          uncovered_lines = file.uncovered_lines_count
          impact_score = (uncovered_lines * coverage_gap) / Math.sqrt(file.total_lines)

          {
            file: file,
            impact_score: impact_score,
            improvement_potential: calculate_improvement_potential(file, threshold),
            effort_estimate: estimate_testing_effort(file)
          }
        end

        scored_files
          .sort_by { |item| -item[:impact_score] }
          .first(limit)
      end

      # Generates specific testing recommendations for under-covered items
      # @param analysis_result [Models::CoverageAnalysisResult] Analysis results
      # @param focus_area [Symbol] Area to focus on (:critical, :quick_wins, :comprehensive)
      # @return [Array<Hash>] Actionable testing recommendations
      def generate_testing_recommendations(analysis_result, focus_area = :critical)
        case focus_area
        when :critical
          generate_critical_recommendations(analysis_result)
        when :quick_wins
          generate_quick_win_recommendations(analysis_result)
        when :comprehensive
          generate_comprehensive_recommendations(analysis_result)
        else
          raise ArgumentError, "Invalid focus_area: #{focus_area}. Valid areas: :critical, :quick_wins, :comprehensive"
        end
      end

      private

      def validate_extraction_options(options)
        {
          max_files: options[:max_files] || 20,
          max_methods_per_file: options[:max_methods_per_file] || 10,
          include_method_details: options[:include_method_details] != false
        }
      end

      def prioritize_files_by_urgency(files, threshold)
        files.map do |file|
          urgency_score = calculate_urgency_score(file, threshold)
          {file: file, urgency_score: urgency_score}
        end
          .sort_by { |item| -item[:urgency_score] }
          .map { |item| item[:file] }
      end

      def calculate_urgency_score(file, threshold)
        # Factors: coverage gap, file size, number of uncovered lines
        coverage_gap = threshold - file.coverage_percentage
        size_factor = Math.log(file.total_lines + 1) # Logarithmic scaling for file size
        uncovered_factor = file.uncovered_lines_count.to_f / file.total_lines

        (coverage_gap * size_factor * uncovered_factor * 100).round(2)
      end

      def extract_file_items(file, threshold, options)
        base_info = {
          file_path: file.relative_path,
          coverage_percentage: file.coverage_percentage,
          total_lines: file.total_lines,
          uncovered_lines: file.uncovered_lines_count,
          urgency_score: calculate_urgency_score(file, threshold)
        }

        if options[:include_method_details] && file.methods.any?
          under_covered_methods = file.methods
            .select { |m| m.under_threshold?(threshold) }
            .first(options[:max_methods_per_file])

          base_info[:methods] = under_covered_methods.map do |method|
            {
              name: method.name,
              coverage_percentage: method.coverage_percentage,
              total_lines: method.total_lines,
              start_line: method.start_line,
              end_line: method.end_line
            }
          end
        end

        base_info
      end

      def categorize_by_urgency(files, threshold)
        critical = files.select { |f| f.coverage_percentage < 25.0 }
        high = files.select { |f| f.coverage_percentage >= 25.0 && f.coverage_percentage < 50.0 }
        medium = files.select { |f| f.coverage_percentage >= 50.0 && f.coverage_percentage < threshold }

        {
          critical: {count: critical.length, files: critical.map(&:relative_path)},
          high: {count: high.length, files: high.map(&:relative_path)},
          medium: {count: medium.length, files: medium.map(&:relative_path)}
        }
      end

      def generate_action_recommendations(files, threshold)
        recommendations = []

        if files.any?
          worst_file = files.first
          recommendations << "IMMEDIATE: Focus on #{worst_file.relative_path} (#{worst_file.coverage_percentage}% coverage)"

          large_files = files.select { |f| f.total_lines > 100 }
          if large_files.any?
            recommendations << "STRATEGY: Break down large files like #{large_files.first.relative_path} into smaller, testable units"
          end

          completely_uncovered = files.select { |f| f.coverage_percentage.zero? }
          if completely_uncovered.any?
            recommendations << "URGENT: #{completely_uncovered.length} file(s) have no test coverage at all"
          end
        end

        recommendations
      end

      def extract_critical_files(analysis_result, options)
        limit = options[:limit] || 10
        analysis_result.under_covered_files
          .sort_by(&:coverage_percentage)
          .first(limit)
          .map(&:relative_path)
      end

      def extract_critical_methods(analysis_result, options)
        limit = options[:limit] || 20
        threshold = analysis_result.threshold

        all_methods = analysis_result.files.flat_map(&:methods)
        under_covered_methods = all_methods.select { |m| m.under_threshold?(threshold) }

        under_covered_methods
          .sort_by(&:coverage_percentage)
          .first(limit)
          .map { |m| {name: m.name, coverage: m.coverage_percentage} }
      end

      def extract_critical_line_ranges(analysis_result, options)
        limit = options[:limit] || 15

        under_covered_files = analysis_result.under_covered_files.first(limit)
        under_covered_files.map do |file|
          {
            file: file.relative_path,
            uncovered_lines: file.uncovered_lines_count,
            total_lines: file.total_lines
          }
        end
      end

      def calculate_improvement_potential(file, threshold)
        current_gap = threshold - file.coverage_percentage
        max_possible_improvement = 100.0 - file.coverage_percentage

        {
          to_meet_threshold: current_gap,
          to_perfect_coverage: max_possible_improvement,
          lines_to_test: file.uncovered_lines_count
        }
      end

      def estimate_testing_effort(file)
        # Simple heuristic: 1 test per 3-5 lines of untested code
        uncovered_lines = file.uncovered_lines_count
        estimated_tests = (uncovered_lines / 4.0).ceil

        {
          estimated_test_cases: estimated_tests,
          effort_level: case estimated_tests
                        when 0..5 then "low"
                        when 6..15 then "medium"
                        when 16..30 then "high"
                        else "very_high"
                        end
        }
      end

      def generate_critical_recommendations(analysis_result)
        critical_files = analysis_result.under_covered_files
          .select { |f| f.coverage_percentage < 25.0 }
          .first(3)

        critical_files.map do |file|
          {
            priority: "CRITICAL",
            action: "Add basic test coverage",
            target: file.relative_path,
            current_coverage: file.coverage_percentage,
            estimated_effort: estimate_testing_effort(file)[:effort_level]
          }
        end
      end

      def generate_quick_win_recommendations(analysis_result)
        # Focus on smaller files with moderate coverage gaps
        quick_wins = analysis_result.under_covered_files
          .select { |f| f.total_lines < 50 && f.coverage_percentage > 40.0 }
          .first(5)

        quick_wins.map do |file|
          {
            priority: "QUICK_WIN",
            action: "Fill coverage gaps",
            target: file.relative_path,
            current_coverage: file.coverage_percentage,
            estimated_effort: "low"
          }
        end
      end

      def generate_comprehensive_recommendations(analysis_result)
        all_recommendations = []

        # Critical items first
        all_recommendations.concat(generate_critical_recommendations(analysis_result))

        # Quick wins second
        all_recommendations.concat(generate_quick_win_recommendations(analysis_result))

        # Larger files for comprehensive coverage
        large_files = analysis_result.under_covered_files
          .select { |f| f.total_lines > 100 }
          .first(3)

        large_files.each do |file|
          all_recommendations << {
            priority: "STRATEGIC",
            action: "Comprehensive test coverage",
            target: file.relative_path,
            current_coverage: file.coverage_percentage,
            estimated_effort: estimate_testing_effort(file)[:effort_level]
          }
        end

        all_recommendations
      end
    end
  end
end
