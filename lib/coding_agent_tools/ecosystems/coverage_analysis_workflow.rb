# frozen_string_literal: true

module CodingAgentTools
  module Ecosystems
    # Top-level workflow ecosystem for coverage analysis operations
    # Orchestrates the complete coverage analysis pipeline from SimpleCov input to actionable reports
    class CoverageAnalysisWorkflow
      def initialize(
        analyzer: nil,
        extractor: nil,
        report_generator: nil,
        path_resolver: nil,
        threshold_validator: nil
      )
        @analyzer = analyzer || Organisms::CoverageAnalyzer.new
        @extractor = extractor || Organisms::UndercoveredItemsExtractor.new
        @report_generator = report_generator || Organisms::CoverageReportGenerator.new
        @path_resolver = path_resolver || Molecules::PathResolver.new
        @threshold_validator = threshold_validator || Atoms::ThresholdValidator.new
      end

      # Executes the complete coverage analysis workflow
      # @param input_file [String] Path to SimpleCov .resultset.json file
      # @param options [Hash] Workflow options
      # @option options [Float] :threshold Coverage threshold percentage (default: 85.0)
      # @option options [Boolean] :adaptive_threshold Use adaptive threshold detection (overrides :threshold when true)
      # @option options [String] :output_dir Output directory for reports (default: "./coverage_analysis")
      # @option options [Array<Symbol>] :formats Output formats (default: [:text, :json])
      # @option options [Boolean] :create_path_integration Enable create-path workflow integration (default: false)
      # @option options [Boolean] :detailed_analysis Include method-level analysis (default: false)
      # @option options [Array<String>] :include_patterns File patterns to include (default: ["**/lib/**"])
      # @option options [Array<String>] :exclude_patterns File patterns to exclude (default: ["**/spec/**", "**/test/**"])
      # @return [Hash] Workflow execution results with adaptive threshold information when enabled
      def execute_full_analysis(input_file, options = {})
        workflow_options = validate_and_prepare_options(options)
        execution_start = Time.now

        begin
          # Step 1: Validate input file
          validate_input_file(input_file)

          # Step 2: Prepare output directory
          prepare_output_directory(workflow_options[:output_dir])

          # Step 3: Execute core analysis
          analysis_result = @analyzer.analyze_coverage(input_file, workflow_options)

          # Step 4: Extract under-covered items
          undercovered_items = @extractor.extract_undercovered_items(
            analysis_result,
            max_files: workflow_options[:max_files],
            include_method_details: workflow_options[:detailed_analysis]
          )

          # Step 5: Generate reports in requested formats using the analysis result
          generated_reports = @report_generator.generate_multi_format_reports(
            input_file,
            workflow_options[:output_dir],
            workflow_options,
            analysis_result: analysis_result
          )

          # Step 6: Create-path integration if requested
          create_path_results = if workflow_options[:create_path_integration]
            generate_create_path_output(input_file, analysis_result, workflow_options)
          end

          # Step 7: Generate workflow summary
          execution_summary = {
            execution_time: Time.now - execution_start,
            input_file: input_file,
            output_directory: workflow_options[:output_dir],
            analysis_summary: {
              total_files: analysis_result.total_files,
              under_covered_files: analysis_result.under_covered_files.length,
              overall_coverage: analysis_result.overall_coverage_percentage,
              threshold: analysis_result.threshold,
              coverage_status: determine_overall_status(analysis_result)
            },
            generated_reports: generated_reports,
            undercovered_summary: {
              critical_files: undercovered_items[:urgency_breakdown][:critical][:count],
              high_priority_files: undercovered_items[:urgency_breakdown][:high][:count],
              total_recommendations: undercovered_items[:recommendations].length
            },
            create_path_integration: create_path_results
          }

          {
            success: true,
            analysis_result: analysis_result,
            undercovered_items: undercovered_items,
            generated_reports: generated_reports,
            create_path_results: create_path_results,
            execution_summary: execution_summary
          }
        rescue => error
          handle_workflow_error(error, input_file, workflow_options)
        end
      end

      # Executes a quick analysis workflow for immediate feedback
      # @param input_file [String] Path to SimpleCov .resultset.json file
      # @param options [Hash] Quick analysis options
      # @return [Hash] Quick analysis results
      def execute_quick_analysis(input_file, options = {})
        workflow_options = validate_and_prepare_options(options.merge(
          formats: [:text],
          detailed_analysis: false,
          max_files: 10
        ))

        analysis_result = @analyzer.analyze_coverage(input_file, workflow_options)
        critical_files = @analyzer.prioritize_critical_files(analysis_result, 5)

        {
          overall_coverage: analysis_result.overall_coverage_percentage,
          threshold: analysis_result.threshold,
          files_under_threshold: analysis_result.under_covered_files.length,
          total_files: analysis_result.total_files,
          status: determine_overall_status(analysis_result),
          critical_files: critical_files.map do |file|
            {
              path: file.relative_path,
              coverage: file.coverage_percentage,
              uncovered_lines: file.uncovered_lines_count
            }
          end,
          recommendations: generate_quick_recommendations(analysis_result)
        }
      end

      # Executes focused analysis on specific file patterns
      # @param input_file [String] Path to SimpleCov .resultset.json file
      # @param focus_patterns [Array<String>] File patterns to focus on
      # @param options [Hash] Focus analysis options
      # @return [Hash] Focused analysis results
      def execute_focused_analysis(input_file, focus_patterns, options = {})
        workflow_options = validate_and_prepare_options(options.merge(
          include_patterns: focus_patterns
        ))

        focused_report = @report_generator.generate_focused_report(
          input_file,
          focus_patterns,
          workflow_options
        )

        {
          focus_patterns: focus_patterns,
          analysis_result: focused_report,
          summary: {
            files_found: focused_report[:focus_area][:files_found],
            files_under_threshold: focused_report[:focus_area][:files_under_threshold],
            coverage_distribution: calculate_focus_distribution(focused_report[:detailed_breakdown])
          }
        }
      end

      # Validates SimpleCov file and provides analysis recommendations
      # @param input_file [String] Path to SimpleCov .resultset.json file
      # @return [Hash] Validation and recommendation results
      def analyze_and_recommend(input_file)
        # Quick validation
        file_reader = Atoms::CoverageFileReader.new
        raw_data = file_reader.read(input_file)
        file_reader.validate_structure(raw_data)

        # Extract basic information
        frameworks = file_reader.extract_frameworks(raw_data)
        file_paths = file_reader.extract_file_paths(raw_data)

        # Analyze file patterns
        lib_files = file_paths.select { |path| path.include?("/lib/") }
        test_files = file_paths.select { |path| path.match?(%r{/(spec|test)/}) }

        {
          file_validation: {
            valid: true,
            frameworks_detected: frameworks,
            total_files: file_paths.length,
            lib_files: lib_files.length,
            test_files: test_files.length
          },
          analysis_recommendations: {
            suggested_threshold: suggest_threshold_based_on_size(lib_files.length),
            recommended_focus: (lib_files.length > 50) ? "focused_analysis" : "full_analysis",
            estimated_analysis_time: estimate_analysis_time(lib_files.length),
            suggested_output_formats: [:text, :json]
          },
          workflow_suggestions: {
            include_method_analysis: lib_files.length <= 20,
            enable_create_path: true,
            focus_patterns: (lib_files.length > 50) ? suggest_focus_patterns(lib_files) : nil
          }
        }
      end

      private

      def validate_and_prepare_options(options)
        {
          threshold: @threshold_validator.validate_threshold(options[:threshold] || 85.0),
          adaptive_threshold: options[:adaptive_threshold] || false,
          output_dir: options[:output_dir] || "./coverage_analysis",
          formats: options[:formats] || [:text, :json],
          create_path_integration: options[:create_path_integration] || false,
          detailed_analysis: options[:detailed_analysis] || false,
          include_patterns: options[:include_patterns] || ["**/lib/**/*.rb"],
          exclude_patterns: options[:exclude_patterns] || ["**/spec/**", "**/test/**"],
          max_files: options[:max_files] || 20,
          base_name: options[:base_name] || "coverage_analysis",
          include_comprehensive: options[:include_comprehensive] || false
        }
      end

      def validate_input_file(input_file)
        unless File.exist?(input_file)
          raise ArgumentError, "Input file does not exist: #{input_file}"
        end

        unless File.readable?(input_file)
          raise ArgumentError, "Input file is not readable: #{input_file}"
        end

        unless input_file.end_with?(".json")
          raise ArgumentError, "Input file must be a JSON file: #{input_file}"
        end
      end

      def prepare_output_directory(output_dir)
        FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)
      rescue => error
        raise "Failed to create output directory #{output_dir}: #{error.message}"
      end

      def generate_create_path_output(input_file, analysis_result, options)
        create_path_output = File.join(options[:output_dir], "create_path_integration.json")

        create_path_data = @report_generator.generate_for_create_path(
          input_file,
          create_path_output,
          options
        )

        File.write(create_path_output, JSON.pretty_generate(create_path_data))

        {
          output_file: create_path_output,
          action_required: create_path_data[:action_required],
          critical_items_count: create_path_data[:critical_items].length,
          recommendations_count: create_path_data[:recommendations].length
        }
      end

      def determine_overall_status(analysis_result)
        overall = analysis_result.overall_coverage_percentage
        threshold = analysis_result.threshold
        under_covered_count = analysis_result.under_covered_files.length

        if overall >= threshold && under_covered_count == 0
          "excellent"
        elsif overall >= threshold - 5
          "good"
        elsif overall >= threshold - 15
          "needs_improvement"
        else
          "critical"
        end
      end

      def generate_quick_recommendations(analysis_result)
        recommendations = []
        under_covered = analysis_result.under_covered_files

        if under_covered.empty?
          recommendations << "All files meet the coverage threshold! Consider raising the threshold for even better coverage."
        else
          worst_file = under_covered.min_by(&:coverage_percentage)
          recommendations << "Start with #{worst_file.relative_path} (#{worst_file.coverage_percentage}% coverage)"

          if under_covered.length > 3
            recommendations << "#{under_covered.length} files need attention - consider focusing on the worst cases first"
          end

          critical_files = under_covered.select { |f| f.coverage_percentage < 25.0 }
          if critical_files.any?
            recommendations << "#{critical_files.length} file(s) have critical coverage gaps (<25%)"
          end
        end

        recommendations
      end

      def calculate_focus_distribution(detailed_breakdown)
        return {} if detailed_breakdown.empty?

        coverages = detailed_breakdown.map { |item| item[:coverage_percentage] }

        {
          min_coverage: coverages.min,
          max_coverage: coverages.max,
          average_coverage: (coverages.sum / coverages.length.to_f).round(2),
          files_under_50: coverages.count { |c| c < 50.0 },
          files_under_75: coverages.count { |c| c < 75.0 }
        }
      end

      def suggest_threshold_based_on_size(file_count)
        case file_count
        when 0..10
          90.0  # Small projects can aim high
        when 11..30
          85.0  # Medium projects
        when 31..100
          80.0  # Larger projects
        else
          75.0  # Very large projects
        end
      end

      def estimate_analysis_time(file_count)
        # Very rough estimates in seconds
        case file_count
        when 0..10
          "< 5 seconds"
        when 11..50
          "5-15 seconds"
        when 51..200
          "15-60 seconds"
        else
          "1-3 minutes"
        end
      end

      def suggest_focus_patterns(lib_files)
        # Suggest focusing on most common directories
        directories = lib_files.map { |path| File.dirname(path).split("/lib/").last&.split("/")&.first }.compact
        common_dirs = directories.tally.sort_by { |_, count| -count }.first(3).map(&:first)

        common_dirs.map { |dir| "**/lib/#{dir}/**" }
      end

      def handle_workflow_error(error, input_file, options)
        {
          success: false,
          error: {
            type: error.class.name,
            message: error.message,
            input_file: input_file,
            options: options.select { |k, _| k != :sensitive_data }
          },
          suggestions: generate_error_suggestions(error)
        }
      end

      def generate_error_suggestions(error)
        case error
        when Atoms::CoverageFileReader::InvalidFileError
          ["Ensure the input file is a valid SimpleCov .resultset.json file",
            "Check that SimpleCov generated the file correctly",
            "Verify file permissions and accessibility"]
        when ArgumentError
          ["Check command-line arguments and file paths",
            "Ensure threshold values are between 0 and 100",
            "Verify output directory permissions"]
        else
          ["Check file permissions and paths",
            "Ensure sufficient disk space for output files",
            "Try with simpler options to isolate the issue"]
        end
      end
    end
  end
end
