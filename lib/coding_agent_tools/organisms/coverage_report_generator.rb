# frozen_string_literal: true

module CodingAgentTools
  module Organisms
    # Advanced report generation organism that creates comprehensive coverage reports
    # Integrates with create-path workflow and provides multiple output formats
    class CoverageReportGenerator
      def initialize(
        analyzer: nil,
        extractor: nil,
        formatter: nil,
        path_resolver: nil
      )
        @analyzer = analyzer || CoverageAnalyzer.new
        @extractor = extractor || UndercoveredItemsExtractor.new
        @formatter = formatter || Molecules::ReportFormatter.new
        @path_resolver = path_resolver || Molecules::PathResolver.new
      end

      # Generates a comprehensive coverage report with multiple sections
      # @param file_path [String] Path to SimpleCov .resultset.json file
      # @param options [Hash] Report generation options
      # @option options [Float] :threshold Coverage threshold percentage (default: 85.0)
      # @option options [Array<Symbol>] :sections Sections to include (default: [:summary, :files, :recommendations])
      # @option options [Boolean] :include_method_analysis Include method-level analysis (default: false)
      # @option options [Integer] :max_files Maximum files to detail (default: 20)
      # @return [Hash] Comprehensive report data
      def generate_comprehensive_report(file_path, options = {})
        validated_options = validate_report_options(options)
        
        # Perform analysis
        analysis_result = @analyzer.analyze_coverage(file_path, validated_options)
        
        # Extract under-covered items
        undercovered_items = @extractor.extract_undercovered_items(
          analysis_result,
          max_files: validated_options[:max_files],
          include_method_details: validated_options[:include_method_analysis]
        )
        
        # Build comprehensive report
        report = {
          metadata: {
            generated_at: Time.now.iso8601,
            analysis_timestamp: analysis_result.analysis_timestamp.iso8601,
            input_file: file_path,
            threshold: analysis_result.threshold
          }
        }

        # Add requested sections
        validated_options[:sections].each do |section|
          case section
          when :summary
            report[:summary] = generate_summary_section(analysis_result)
          when :files
            report[:files] = generate_files_section(analysis_result, undercovered_items)
          when :recommendations
            report[:recommendations] = generate_recommendations_section(analysis_result, undercovered_items)
          when :statistics
            report[:statistics] = @analyzer.generate_statistics(analysis_result)
          when :priorities
            report[:priorities] = generate_priorities_section(analysis_result)
          end
        end

        report
      end

      # Generates a report optimized for create-path workflow integration
      # @param file_path [String] Path to SimpleCov .resultset.json file
      # @param output_path [String] Desired output path for report
      # @param options [Hash] Generation options
      # @return [Hash] Create-path compatible report structure
      def generate_for_create_path(file_path, output_path, options = {})
        validated_options = validate_report_options(options)
        
        # Perform analysis
        analysis_result = @analyzer.analyze_coverage(file_path, validated_options)
        
        # Determine if action is required
        action_required = analysis_result.under_covered_files.any?
        
        # Extract critical items for action
        critical_items = if action_required
          @extractor.find_high_impact_files(analysis_result, limit: 5)
        else
          []
        end
        
        # Generate create-path compatible structure
        {
          action_required: action_required,
          summary: {
            total_files: analysis_result.total_files,
            under_covered_files: analysis_result.under_covered_files.length,
            overall_coverage: analysis_result.overall_coverage_percentage,
            threshold: analysis_result.threshold
          },
          critical_items: critical_items.map do |item|
            {
              file_path: item[:file].relative_path,
              coverage_percentage: item[:file].coverage_percentage,
              impact_score: item[:impact_score],
              effort_estimate: item[:effort_estimate][:effort_level]
            }
          end,
          recommendations: generate_actionable_recommendations(analysis_result),
          next_steps: generate_next_steps(analysis_result, critical_items),
          output_suggestions: suggest_output_paths(output_path, analysis_result)
        }
      end

      # Generates multiple report formats and saves them to specified paths
      # @param file_path [String] Path to SimpleCov .resultset.json file
      # @param output_directory [String] Directory to save reports
      # @param options [Hash] Generation options
      # @option options [Array<Symbol>] :formats Formats to generate (default: [:text, :json])
      # @option options [String] :base_name Base filename (default: "coverage_report")
      # @return [Hash] Paths to generated report files
      def generate_multi_format_reports(file_path, output_directory, options = {})
        validated_options = validate_report_options(options)
        formats = validated_options[:formats] || [:text, :json]
        base_name = validated_options[:base_name] || "coverage_report"
        
        # Ensure output directory exists
        FileUtils.mkdir_p(output_directory)
        
        # Perform analysis once
        analysis_result = @analyzer.analyze_coverage(file_path, validated_options)
        
        # Generate each format
        generated_files = {}
        
        formats.each do |format|
          extension = case format
                     when :text then '.txt'
                     when :json then '.json'
                     when :csv then '.csv'
                     else ".#{format}"
                     end
          
          output_path = File.join(output_directory, "#{base_name}#{extension}")
          report_path = @analyzer.save_report(analysis_result, output_path, format)
          generated_files[format] = report_path
        end
        
        # Generate comprehensive report if requested
        if validated_options[:include_comprehensive]
          comprehensive_path = File.join(output_directory, "#{base_name}_comprehensive.json")
          comprehensive_report = generate_comprehensive_report(file_path, validated_options)
          File.write(comprehensive_path, JSON.pretty_generate(comprehensive_report))
          generated_files[:comprehensive] = comprehensive_path
        end
        
        generated_files
      end

      # Generates a focused report for specific files or patterns
      # @param file_path [String] Path to SimpleCov .resultset.json file
      # @param focus_patterns [Array<String>] File patterns to focus on
      # @param options [Hash] Generation options
      # @return [Hash] Focused report data
      def generate_focused_report(file_path, focus_patterns, options = {})
        validated_options = validate_report_options(options)
        
        # Add focus patterns to include patterns
        validated_options[:include_patterns] = focus_patterns
        
        # Perform focused analysis
        analysis_result = @analyzer.analyze_coverage(file_path, validated_options)
        
        {
          focus_area: {
            patterns: focus_patterns,
            files_found: analysis_result.files.length,
            files_under_threshold: analysis_result.under_covered_files.length
          },
          analysis: analysis_result.to_h,
          detailed_breakdown: analysis_result.files.map do |file|
            {
              file_path: file.relative_path,
              coverage_percentage: file.coverage_percentage,
              lines_breakdown: {
                total: file.total_lines,
                covered: file.covered_lines,
                uncovered: file.uncovered_lines_count
              },
              methods_count: file.methods.length,
              under_threshold: file.under_threshold?(analysis_result.threshold)
            }
          end
        }
      end

      private

      def validate_report_options(options)
        {
          threshold: options[:threshold] || 85.0,
          sections: options[:sections] || [:summary, :files, :recommendations],
          include_method_analysis: options[:include_method_analysis] || false,
          max_files: options[:max_files] || 20,
          include_patterns: options[:include_patterns] || ["**/lib/**"],
          exclude_patterns: options[:exclude_patterns] || ["**/spec/**", "**/test/**"],
          formats: options[:formats] || [:text, :json],
          base_name: options[:base_name] || "coverage_report",
          include_comprehensive: options[:include_comprehensive] || false
        }
      end

      def generate_summary_section(analysis_result)
        {
          overall_coverage: analysis_result.overall_coverage_percentage,
          threshold: analysis_result.threshold,
          files_analyzed: analysis_result.total_files,
          files_under_threshold: analysis_result.under_covered_files.length,
          methods_analyzed: analysis_result.total_methods,
          methods_under_threshold: analysis_result.under_covered_methods.length,
          coverage_status: determine_coverage_status(analysis_result)
        }
      end

      def generate_files_section(analysis_result, undercovered_items)
        {
          under_covered_files: undercovered_items[:files],
          urgency_breakdown: undercovered_items[:urgency_breakdown],
          total_files_count: analysis_result.total_files
        }
      end

      def generate_recommendations_section(analysis_result, undercovered_items)
        {
          immediate_actions: undercovered_items[:recommendations],
          testing_strategy: @extractor.generate_testing_recommendations(analysis_result, :comprehensive),
          priority_files: @analyzer.prioritize_critical_files(analysis_result, 5).map(&:relative_path)
        }
      end

      def generate_priorities_section(analysis_result)
        high_impact_files = @extractor.find_high_impact_files(analysis_result, limit: 10)
        
        {
          high_impact_files: high_impact_files,
          quick_wins: @extractor.generate_testing_recommendations(analysis_result, :quick_wins),
          critical_items: @extractor.generate_testing_recommendations(analysis_result, :critical)
        }
      end

      def determine_coverage_status(analysis_result)
        overall = analysis_result.overall_coverage_percentage
        threshold = analysis_result.threshold
        
        if overall >= threshold
          "excellent"
        elsif overall >= threshold - 10
          "good"
        elsif overall >= threshold - 20
          "needs_improvement"
        else
          "critical"
        end
      end

      def generate_actionable_recommendations(analysis_result)
        recommendations = []
        under_covered = analysis_result.under_covered_files
        
        if under_covered.any?
          worst_file = under_covered.min_by(&:coverage_percentage)
          recommendations << "Start with #{worst_file.relative_path} (#{worst_file.coverage_percentage}% coverage)"
          
          if under_covered.length > 1
            recommendations << "Focus on #{under_covered.length} files below #{analysis_result.threshold}% threshold"
          end
          
          large_gaps = under_covered.select { |f| f.coverage_percentage < 50.0 }
          if large_gaps.any?
            recommendations << "#{large_gaps.length} file(s) have significant coverage gaps requiring immediate attention"
          end
        else
          recommendations << "All files meet coverage threshold - consider raising the threshold for even better coverage"
        end
        
        recommendations
      end

      def generate_next_steps(analysis_result, critical_items)
        steps = []
        
        if critical_items.any?
          steps << "Review high-impact files identified in critical_items section"
          steps << "Prioritize testing based on impact_score values"
          steps << "Start with files marked as 'low' or 'medium' effort"
        end
        
        if analysis_result.under_covered_files.any?
          steps << "Run coverage analysis regularly during development"
          steps << "Set up CI/CD checks to maintain coverage threshold"
        end
        
        steps
      end

      def suggest_output_paths(base_path, analysis_result)
        base_dir = File.dirname(base_path)
        base_name = File.basename(base_path, File.extname(base_path))
        
        suggestions = {
          detailed_report: File.join(base_dir, "#{base_name}_detailed.json"),
          summary_report: File.join(base_dir, "#{base_name}_summary.txt"),
          csv_export: File.join(base_dir, "#{base_name}_data.csv")
        }
        
        if analysis_result.under_covered_files.any?
          suggestions[:action_plan] = File.join(base_dir, "#{base_name}_action_plan.md")
        end
        
        suggestions
      end
    end
  end
end