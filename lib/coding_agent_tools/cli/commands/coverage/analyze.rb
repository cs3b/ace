# frozen_string_literal: true

require "dry/cli"

module CodingAgentTools
  module Cli
    module Commands
      module Coverage
        # CLI command for coverage analysis operations
        # Provides comprehensive coverage analysis with multiple output formats
        class Analyze < Dry::CLI::Command
          desc "Analyze SimpleCov coverage data and generate reports"

          argument :input_file, required: true, desc: "Path to SimpleCov .resultset.json file"

          option :threshold, type: :float, default: 85.0, desc: "Coverage threshold percentage (0-100)"
          option :output_dir, type: :string, default: "./coverage_analysis", desc: "Output directory for reports"
          option :format, type: :string, default: "text,json", desc: "Output formats (comma-separated: text,json,csv)"
          option :include_patterns, type: :string, default: "**/lib/**/*.rb", desc: "File patterns to include (comma-separated)"
          option :exclude_patterns, type: :string, default: "**/spec/**,**/test/**", desc: "File patterns to exclude (comma-separated)"
          option :detailed, type: :boolean, default: false, desc: "Include method-level analysis"
          option :quick, type: :boolean, default: false, desc: "Quick analysis mode (faster, less detailed)"
          option :focus, type: :string, desc: "Focus on specific file patterns (comma-separated)"
          option :create_path, type: :boolean, default: false, desc: "Enable create-path workflow integration"
          option :max_files, type: :integer, default: 20, desc: "Maximum number of files to analyze in detail"
          option :comprehensive, type: :boolean, default: false, desc: "Generate comprehensive report with all sections"
          option :recommend, type: :boolean, default: false, desc: "Only analyze file and provide recommendations (no full analysis)"
          option :compact, type: :boolean, default: true, desc: "Use compact range format for uncovered lines (default)"
          option :verbose, type: :boolean, default: false, desc: "Use verbose format with full uncovered line arrays"

          example [
            "coverage.resultset.json                                    # Basic analysis with default settings",
            "coverage.resultset.json --threshold 90 --format text,csv  # Custom threshold and formats",
            "coverage.resultset.json --quick --output_dir ./reports     # Quick analysis to custom directory",
            "coverage.resultset.json --focus \"**/models/**,**/services/**\" # Focus on specific directories",
            "coverage.resultset.json --detailed --comprehensive        # Full detailed analysis with all sections",
            "coverage.resultset.json --recommend                       # Just get recommendations without full analysis",
            "coverage.resultset.json --verbose                         # Use verbose format with full line arrays",
            "coverage.resultset.json --compact                         # Use compact range format (default)"
          ]

          def call(input_file:, **options)
            workflow = CodingAgentTools::Ecosystems::CoverageAnalysisWorkflow.new

            begin
              # Handle recommendation-only mode
              if options[:recommend]
                handle_recommend_mode(workflow, input_file)
                return
              end

              # Prepare workflow options
              workflow_options = prepare_workflow_options(options)

              # Execute appropriate analysis type
              if options[:quick]
                handle_quick_analysis(workflow, input_file, workflow_options)
              elsif options[:focus]
                handle_focused_analysis(workflow, input_file, options[:focus], workflow_options)
              else
                handle_full_analysis(workflow, input_file, workflow_options)
              end

            rescue => error
              handle_error(error, input_file)
              exit(1)
            end
          end

          private

          def prepare_workflow_options(options)
            # Determine report format (verbose takes precedence over compact if both are specified)
            report_format = if options[:verbose]
                             :verbose
                           else
                             :compact
                           end

            {
              threshold: options[:threshold],
              output_dir: options[:output_dir],
              formats: parse_comma_separated(options[:format]),
              include_patterns: parse_comma_separated(options[:include_patterns]),
              exclude_patterns: parse_comma_separated(options[:exclude_patterns]),
              detailed_analysis: options[:detailed],
              create_path_integration: options[:create_path],
              max_files: options[:max_files],
              include_comprehensive: options[:comprehensive],
              report_format: report_format
            }
          end

          def parse_comma_separated(value)
            return [] if value.nil? || value.empty?
            value.split(',').map(&:strip).reject(&:empty?)
          end

          def handle_recommend_mode(workflow, input_file)
            puts "🔍 Analyzing SimpleCov file for recommendations..."
            puts

            recommendations = workflow.analyze_and_recommend(input_file)

            display_validation_results(recommendations[:file_validation])
            display_analysis_recommendations(recommendations[:analysis_recommendations])
            display_workflow_suggestions(recommendations[:workflow_suggestions])
          end

          def handle_quick_analysis(workflow, input_file, options)
            puts "⚡ Executing quick coverage analysis..."
            puts

            result = workflow.execute_quick_analysis(input_file, options)

            display_quick_results(result)
          end

          def handle_focused_analysis(workflow, input_file, focus_patterns, options)
            patterns = parse_comma_separated(focus_patterns)
            puts "🎯 Executing focused analysis on: #{patterns.join(', ')}"
            puts

            result = workflow.execute_focused_analysis(input_file, patterns, options)

            display_focused_results(result)
          end

          def handle_full_analysis(workflow, input_file, options)
            puts "🔄 Executing full coverage analysis..."
            puts

            result = workflow.execute_full_analysis(input_file, options)

            if result[:success]
              display_full_analysis_results(result)
            else
              display_workflow_error(result[:error])
              exit(1)
            end
          end

          def display_validation_results(validation)
            puts "📋 File Validation Results:"
            puts "  Status: ✅ Valid SimpleCov file"
            puts "  Frameworks: #{validation[:frameworks_detected].join(', ')}"
            puts "  Total files: #{validation[:total_files]}"
            puts "  Library files: #{validation[:lib_files]}"
            puts "  Test files: #{validation[:test_files]}"
            puts
          end

          def display_analysis_recommendations(recommendations)
            puts "💡 Analysis Recommendations:"
            puts "  Suggested threshold: #{recommendations[:suggested_threshold]}%"
            puts "  Recommended approach: #{recommendations[:recommended_focus]}"
            puts "  Estimated time: #{recommendations[:estimated_analysis_time]}"
            puts "  Suggested formats: #{recommendations[:suggested_output_formats].join(', ')}"
            puts
          end

          def display_workflow_suggestions(suggestions)
            puts "⚙️  Workflow Suggestions:"
            puts "  Include method analysis: #{suggestions[:include_method_analysis] ? '✅' : '❌'}"
            puts "  Enable create-path: #{suggestions[:enable_create_path] ? '✅' : '❌'}"
            
            if suggestions[:focus_patterns]
              puts "  Suggested focus patterns:"
              suggestions[:focus_patterns].each { |pattern| puts "    - #{pattern}" }
            end
            puts
          end

          def display_quick_results(result)
            puts "📊 Quick Analysis Results:"
            puts "  Overall Coverage: #{format_percentage(result[:overall_coverage])}"
            puts "  Threshold: #{format_percentage(result[:threshold])}"
            puts "  Status: #{format_status(result[:status])}"
            puts "  Files under threshold: #{result[:files_under_threshold]}/#{result[:total_files]}"
            puts

            if result[:critical_files].any?
              puts "🚨 Critical Files (Top 5):"
              result[:critical_files].each_with_index do |file, index|
                puts "  #{index + 1}. #{file[:path]}: #{format_percentage(file[:coverage])} (#{file[:uncovered_lines]} uncovered lines)"
              end
              puts
            end

            puts "📝 Quick Recommendations:"
            result[:recommendations].each { |rec| puts "  • #{rec}" }
            puts
          end

          def display_focused_results(result)
            focus_area = result[:focus_patterns]
            summary = result[:summary]

            puts "🎯 Focused Analysis Results:"
            puts "  Focus patterns: #{focus_area.join(', ')}"
            puts "  Files found: #{summary[:files_found]}"
            puts "  Files under threshold: #{summary[:files_under_threshold]}"
            puts

            if summary[:coverage_distribution]
              dist = summary[:coverage_distribution]
              puts "📈 Coverage Distribution:"
              puts "  Range: #{format_percentage(dist[:min_coverage])} - #{format_percentage(dist[:max_coverage])}"
              puts "  Average: #{format_percentage(dist[:average_coverage])}"
              puts "  Files under 50%: #{dist[:files_under_50]}"
              puts "  Files under 75%: #{dist[:files_under_75]}"
            end
            puts
          end

          def display_full_analysis_results(result)
            summary = result[:execution_summary]
            analysis = summary[:analysis_summary]

            puts "✅ Full Analysis Complete!"
            puts "  Execution time: #{format_duration(summary[:execution_time])}"
            puts "  Output directory: #{summary[:output_directory]}"
            puts

            puts "📊 Analysis Summary:"
            puts "  Overall Coverage: #{format_percentage(analysis[:overall_coverage])}"
            puts "  Threshold: #{format_percentage(analysis[:threshold])}"
            puts "  Status: #{format_status(analysis[:coverage_status])}"
            puts "  Files analyzed: #{analysis[:total_files]}"
            puts "  Files under threshold: #{analysis[:under_covered_files]}"
            puts

            puts "📄 Generated Reports:"
            result[:generated_reports].each do |format, path|
              puts "  #{format.to_s.upcase}: #{path}"
            end
            puts

            undercovered = summary[:undercovered_summary]
            if undercovered[:critical_files] > 0 || undercovered[:high_priority_files] > 0
              puts "🚨 Priority Summary:"
              puts "  Critical files: #{undercovered[:critical_files]}"
              puts "  High priority files: #{undercovered[:high_priority_files]}"
              puts "  Total recommendations: #{undercovered[:total_recommendations]}"
              puts
            end

            if result[:create_path_results]
              create_path = result[:create_path_results]
              puts "🔗 Create-Path Integration:"
              puts "  Output file: #{create_path[:output_file]}"
              puts "  Action required: #{create_path[:action_required] ? '✅' : '❌'}"
              puts "  Critical items: #{create_path[:critical_items_count]}"
              puts
            end

            puts "🎉 Analysis complete! Check the generated reports for detailed information."
          end

          def display_workflow_error(error)
            puts "❌ Analysis failed:"
            puts "  Error: #{error[:type]} - #{error[:message]}"
            puts

            if error[:suggestions]
              puts "💡 Suggestions:"
              error[:suggestions].each { |suggestion| puts "  • #{suggestion}" }
            end
          end

          def handle_error(error, input_file)
            puts "❌ Error analyzing coverage:"
            puts "  File: #{input_file}"
            puts "  Error: #{error.class.name} - #{error.message}"
            puts

            case error
            when Errno::ENOENT
              puts "💡 The input file was not found. Please check the file path."
            when JSON::ParserError
              puts "💡 The input file is not valid JSON. Please ensure it's a proper SimpleCov file."
            when ArgumentError
              puts "💡 Please check your command-line arguments and try again."
            else
              puts "💡 Please check file permissions and paths, then try again."
            end
          end

          def format_percentage(value)
            return "N/A" if value.nil?
            "#{value.round(1)}%"
          end

          def format_status(status)
            case status
            when "excellent"
              "🟢 Excellent"
            when "good"
              "🟡 Good"
            when "needs_improvement"
              "🟠 Needs Improvement"
            when "critical"
              "🔴 Critical"
            else
              status.to_s.capitalize
            end
          end

          def format_duration(seconds)
            if seconds < 1
              "#{(seconds * 1000).round}ms"
            elsif seconds < 60
              "#{seconds.round(1)}s"
            else
              minutes = (seconds / 60).floor
              remaining_seconds = (seconds % 60).round
              "#{minutes}m #{remaining_seconds}s"
            end
          end
        end
      end
    end
  end
end