# frozen_string_literal: true

require_relative "../formatters/base_formatter"

module Ace
  module TestRunner
    module Organisms
      # Main orchestrator that coordinates the entire test execution flow
      class TestOrchestrator
        attr_reader :configuration, :result

        def initialize(options = {})
          @configuration = build_configuration(options)
          @test_detector = Atoms::TestDetector.new(patterns: @configuration.patterns)
          @test_executor = Molecules::TestExecutor.new(timeout: @configuration.timeout)
          @result_parser = Atoms::ResultParser.new
          @failure_analyzer = Molecules::FailureAnalyzer.new
          @report_generator = ReportGenerator.new(@configuration)
          @formatter = @configuration.formatter_class.new(@configuration.to_h)
        end

        def run
          validate_configuration!

          start_time = Time.now

          # Find test files
          test_files = find_test_files
          if test_files.empty?
            return handle_no_tests
          end

          # Notify start
          @formatter.on_start(test_files.size)

          # Execute tests
          execution_result = execute_tests(test_files)

          # Parse results
          # When executing with progress (multiple commands), we need to aggregate individual results
          if execution_result[:commands]
            # Each file was executed separately, parse and sum them all
            parsed_result = aggregate_individual_results(execution_result[:stdout])
          else
            # Single command execution
            parsed_result = @result_parser.parse_output(execution_result[:stdout])
          end

          # Build result object
          @result = build_result(parsed_result, execution_result, start_time)

          # Analyze failures
          if @result.has_failures?
            analyzed_failures = @failure_analyzer.analyze_all(parsed_result[:failures])
            @result.failures_detail = analyzed_failures
          end

          # Generate and save report
          report = @report_generator.generate(@result, test_files)

          # Output to stdout
          @formatter.on_finish(@result)

          # Save reports if configured
          if @configuration.save_reports
            report_path = save_reports(report)
            puts "\nDetailed reports: #{report_path}/" unless @configuration.format == "json"
          end

          # Return exit code
          @result.success? ? 0 : 1
        end

        private

        def build_configuration(options)
          # Start with cascade configuration if available
          config = Models::TestConfiguration.from_cascade

          # Override with provided options
          config.merge(options)
        end

        def validate_configuration!
          @configuration.validate!
        rescue ArgumentError => e
          puts "Configuration error: #{e.message}"
          exit 1
        end

        def find_test_files
          files = @test_detector.find_test_files

          # Apply filter if provided
          if @configuration.filter
            files = @test_detector.filter_by_pattern(files, @configuration.filter)
          end

          files
        end

        def handle_no_tests
          @result = Models::TestResult.new

          message = if @configuration.filter
            "No test files found matching pattern '#{@configuration.filter}'"
          else
            "No test files found"
          end

          puts message
          0
        end

        def execute_tests(test_files)
          options = {
            fail_fast: @configuration.fail_fast,
            verbose: @configuration.verbose
          }

          # Check if formatter actually wants progress (not just base implementation)
          wants_progress = @configuration.verbose ||
                          (@formatter.class.instance_method(:on_test_complete).owner != Formatters::BaseFormatter)

          if wants_progress
            # Execute with progress reporting
            @test_executor.execute_with_progress(test_files, options) do |event|
              if event[:type] == :complete
                @formatter.on_test_complete(
                  event[:file],
                  event[:success],
                  event[:duration]
                )
              end
            end
          else
            # Execute all at once
            @test_executor.execute_tests(test_files, options)
          end
        end

        def build_result(parsed_result, execution_result, start_time)
          Models::TestResult.new(
            passed: parsed_result[:summary][:passed],
            failed: parsed_result[:summary][:failures],
            errors: parsed_result[:summary][:errors],
            skipped: parsed_result[:summary][:skips],
            assertions: parsed_result[:summary][:assertions],
            duration: parsed_result[:duration] || execution_result[:duration],
            start_time: start_time,
            end_time: Time.now,
            deprecations: parsed_result[:deprecations],
            raw_output: execution_result[:stdout]
          )
        end

        def aggregate_individual_results(combined_output)
          # Split output by test file executions
          individual_outputs = combined_output.split(/^Started with run options/)
          individual_outputs.shift if individual_outputs.first&.empty?

          aggregated = {
            raw_output: combined_output,
            summary: {
              runs: 0,
              assertions: 0,
              failures: 0,
              errors: 0,
              skips: 0,
              passed: 0
            },
            failures: [],
            duration: 0.0,
            deprecations: []
          }

          individual_outputs.each do |output|
            output = "Started with run options" + output  # Restore the split text
            parsed = @result_parser.parse_output(output)

            # Sum up the counts
            aggregated[:summary][:runs] += parsed[:summary][:runs]
            aggregated[:summary][:assertions] += parsed[:summary][:assertions]
            aggregated[:summary][:failures] += parsed[:summary][:failures]
            aggregated[:summary][:errors] += parsed[:summary][:errors]
            aggregated[:summary][:skips] += parsed[:summary][:skips]
            aggregated[:summary][:passed] += parsed[:summary][:passed]

            # Collect failures and deprecations
            aggregated[:failures].concat(parsed[:failures])
            aggregated[:deprecations].concat(parsed[:deprecations])
            aggregated[:duration] += parsed[:duration]
          end

          aggregated
        end

        def save_reports(report)
          storage = Molecules::ReportStorage.new(base_dir: @configuration.report_dir)

          # Save in appropriate format
          report_path = case @configuration.format
          when "json"
            storage.save_report(report, format: :json)
          when "markdown"
            storage.save_report(report, format: :markdown)
          else
            storage.save_report(report, format: :all)
          end

          # Always save raw output
          storage.save_raw_output(@result.raw_output, report_path)

          report.report_path = report_path
          report_path
        end
      end
    end
  end
end