# frozen_string_literal: true

require_relative "../formatters/base_formatter"
require_relative "../molecules/config_loader"
require_relative "../molecules/pattern_resolver"

module Ace
  module TestRunner
    module Organisms
      # Main orchestrator that coordinates the entire test execution flow
      class TestOrchestrator
        attr_reader :configuration, :result

        def initialize(options = {})
          @configuration = build_configuration(options)
          @pattern_resolver = Molecules::PatternResolver.new(@configuration)
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
          # Check if we executed multiple commands (per-file) or single command (grouped)
          if execution_result[:commands] && execution_result[:commands].is_a?(Array)
            # Each file was executed separately, parse and sum them all
            parsed_result = aggregate_individual_results(execution_result[:stdout])
          else
            # Single command execution (grouped)
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
            # Don't print report path here - formatter already shows it
          end

          # Return exit code
          @result.success? ? 0 : 1
        end

        private

        def build_configuration(options)
          # Load configuration from file
          config_loader = Molecules::ConfigLoader.new
          config_data = config_loader.load(options[:config_path])

          # Merge with command-line options
          config_with_options = config_loader.merge_with_options(config_data, options)

          # Create TestConfiguration with merged data
          Models::TestConfiguration.new(
            format: config_with_options.defaults[:reporter] || options[:format],
            report_dir: config_with_options.defaults[:report_dir] || options[:report_dir],
            save_reports: config_with_options.defaults[:save_reports] != false && options[:save_reports] != false,
            fail_fast: config_with_options.defaults[:fail_fast] || options[:fail_fast],
            verbose: options[:verbose],
            filter: options[:filter],
            fix_deprecations: options[:fix_deprecations],
            patterns: config_with_options.patterns,
            groups: config_with_options.groups,
            target: options[:target],
            config_path: options[:config_path],
            timeout: options[:timeout],
            parallel: options[:parallel],
            color: config_with_options.defaults[:color] == "auto" ? true : config_with_options.defaults[:color],
            per_file: options[:per_file]
          )
        end

        def validate_configuration!
          @configuration.validate!
        rescue ArgumentError => e
          puts "Configuration error: #{e.message}"
          exit 1
        end

        def find_test_files
          # Use PatternResolver if target is specified
          if @configuration.target
            begin
              files = @pattern_resolver.resolve_target(@configuration.target)
            rescue ArgumentError => e
              puts "Error: #{e.message}"
              puts "Available targets: #{@pattern_resolver.available_targets.join(', ')}"
              exit 1
            end
          else
            # Fall back to detector for default behavior
            files = @test_detector.find_test_files
          end

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
            verbose: @configuration.verbose,
            per_file: @configuration.per_file  # Allow per-file execution if needed for debugging
          }

          # Always use execute_with_progress for consistent interface
          # The method internally decides whether to run per-file or grouped
          @test_executor.execute_with_progress(test_files, options) do |event|
            case event[:type]
            when :stdout
              # Pass stdout to formatter for per-test progress
              @formatter.on_test_stdout(event[:content]) if @formatter.respond_to?(:on_test_stdout)
            when :complete
              if @formatter.respond_to?(:on_test_complete)
                @formatter.on_test_complete(
                  event[:file],
                  event[:success],
                  event[:duration]
                )
              end
            end
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