# frozen_string_literal: true

require_relative "../formatters/base_formatter"
require_relative "../molecules/config_loader"
require_relative "../molecules/pattern_resolver"
require_relative "../atoms/report_directory_resolver"
require_relative "sequential_group_executor"

module Ace
  module TestRunner
    module Organisms
      # Main orchestrator that coordinates the entire test execution flow
      class TestOrchestrator
        attr_reader :configuration, :result

        def initialize(options = {})
          @package_dir = options[:package_dir]
          @original_dir = Dir.pwd
          @options = options

          # Fail fast: validate package_dir exists before proceeding
          if @package_dir && !Dir.exist?(@package_dir)
            raise Error, "Package directory not found: #{@package_dir}"
          end

          # Track if user explicitly specified --report-dir to avoid auto-detection override
          @report_dir_override = options[:report_dir] ? :user_specified : nil

          # Component initialization strategy:
          # - Package mode: defer setup to run() when we're in the correct directory
          # - Non-package mode: set up immediately for backward compatibility
          #   (callers may access @configuration after initialize)
          if @package_dir
            @configuration = nil
            @components_initialized = false
          else
            setup_components
            @components_initialized = true
          end
        end

        def run
          # Change to package directory if specified - this is done in run to ensure
          # the ensure block always restores the directory, even on initialization errors
          Dir.chdir(@package_dir) if @package_dir

          # Initialize components if not already done (package mode)
          setup_components unless @components_initialized

          run_with_package_context
        ensure
          # Restore original directory if we changed it
          Dir.chdir(@original_dir) if @package_dir && Dir.pwd != @original_dir
        end

        def run_with_package_context
          validate_configuration!

          start_time = Time.now

          # Print package context if running in different directory
          if @package_dir
            puts "Running tests in #{File.basename(@package_dir)}..."
          end

          # Check if sequential group execution should be used
          if should_execute_sequentially?
            # Use default "all" group if no target specified in grouped mode
            @configuration.target ||= "all"
            return run_sequential_groups(start_time)
          end

          # Find test files
          test_files = find_test_files
          if test_files.empty?
            return handle_no_tests
          end

          resolve_and_set_report_dir_context(test_files)

          # Count total available test files (before filtering)
          total_available = count_total_test_files

          # Notify start with both counts
          if @formatter.respond_to?(:on_start_with_totals)
            @formatter.on_start_with_totals(test_files.size, total_available)
          else
            @formatter.on_start(test_files.size)
          end

          # Execute tests
          execution_result = execute_tests(test_files)

          # Check if execution failed with LoadError (stdout is empty means tests didn't run)
          @parsed_result = if !execution_result[:success] && execution_result[:stdout].to_s.empty? && execution_result[:stderr] && !execution_result[:stderr].empty?
            # Handle load errors or other failures that prevented test execution
            {
              summary: {
                runs: 0,
                assertions: 0,
                failures: 0,
                errors: test_files.size,  # Count all test files as errors
                skips: 0,
                passed: 0
              },
              failures: [],
              errors: [{
                message: execution_result[:stderr].strip,
                type: "LoadError",
                files: test_files
              }],
              deprecations: [],
              duration: execution_result[:duration]
            }
          elsif execution_result[:commands] && execution_result[:commands].is_a?(Array)
            # Each file was executed separately, parse and sum them all
            aggregate_individual_results(execution_result[:stdout])
          else
            # Single command execution (grouped)
            @result_parser.parse_output(execution_result[:stdout])
          end

          # Build result object
          @result = build_result(@parsed_result, execution_result, start_time)

          # Analyze failures and errors
          if @result.has_failures?
            # Collect both failures and errors for analysis
            all_failures = @parsed_result[:failures] || []

            # Convert errors to failure format if present
            if @parsed_result[:errors] && @parsed_result[:errors].any?
              error_failures = @parsed_result[:errors].map do |error|
                {
                  type: :error,
                  test_name: error[:type] || "LoadError",
                  message: error[:message] || "Unknown error",
                  location: nil,
                  full_content: error[:message] || "Unknown error",
                  files: error[:files]
                }
              end
              all_failures += error_failures
            end

            analyzed_failures = @failure_analyzer.analyze_all(
              all_failures,
              stderr: @result.stderr
            )
            @result.failures_detail = analyzed_failures
          end

          # Generate and save report
          report = @report_generator.generate(@result, test_files)

          # Save reports if configured
          if @configuration.save_reports
            report_path = save_reports(report)
            # Pass report path to formatter before outputting
            @formatter.report_path = report_path if @formatter.respond_to?(:report_path=)
          end

          # Output to stdout
          @formatter.on_finish(@result)

          # Display profile results if requested
          if @configuration.profile && @parsed_result[:test_times] && !@parsed_result[:test_times].empty?
            display_profile(@parsed_result[:test_times], @configuration.profile)
          end

          # Return exit code
          @result.success? ? 0 : 1
        end

        private

        def setup_components
          @configuration = build_configuration(@options)
          @pattern_resolver = Molecules::PatternResolver.new(@configuration)
          @test_detector = Atoms::TestDetector.new(patterns: @configuration.patterns)

          # Use SmartTestExecutor for intelligent subprocess/direct execution choice
          require_relative "../molecules/smart_test_executor"
          force_mode = if @options[:direct]
            :direct
          else
            (@options[:subprocess] ? :subprocess : nil)
          end
          @test_executor = Molecules::SmartTestExecutor.new(
            timeout: @configuration.timeout,
            force_mode: force_mode
          )
          @result_parser = Atoms::ResultParser.new
          @failure_analyzer = Molecules::FailureAnalyzer.new
          @report_generator = ReportGenerator.new(@configuration)

          # Initialize formatter - will be updated after pattern resolution
          formatter_options = @configuration.to_h
          if @configuration.failure_limits
            formatter_options[:max_failures_to_display] = @configuration.failure_limits[:max_display]
          end
          # Disable group headers in on_test_complete to avoid duplicates with on_group_start/complete
          formatter_options[:show_groups] = false
          @formatter = @configuration.formatter_class.new(formatter_options)
        end

        def run_sequential_groups(start_time)
          # Resolve groups sequentially
          groups = @pattern_resolver.resolve_group_sequential(@configuration.target)

          if groups.empty?
            return handle_no_tests
          end

          # Count total files
          all_files = groups.flat_map { |g| g[:files] }

          resolve_and_set_report_dir_context(all_files)

          total_available = count_total_test_files

          # Notify start
          if @formatter.respond_to?(:on_start_with_totals)
            @formatter.on_start_with_totals(all_files.size, total_available)
          else
            @formatter.on_start(all_files.size)
          end

          # Create sequential executor
          executor = SequentialGroupExecutor.new(
            test_executor: @test_executor,
            result_parser: @result_parser,
            formatter: @formatter
          )

          # Execute groups sequentially
          execution_result = executor.execute_groups(groups, sequential_options) do |event|
            case event[:type]
            when :stdout
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

          # Use the parsed result from sequential executor
          @parsed_result = execution_result[:parsed_result]

          # Build result object
          @result = build_result(@parsed_result, execution_result, start_time)

          # Analyze failures
          if @result.has_failures?
            all_failures = @parsed_result[:failures] || []

            if @parsed_result[:errors] && @parsed_result[:errors].any?
              error_failures = @parsed_result[:errors].map do |error|
                {
                  type: :error,
                  test_name: error[:type] || "LoadError",
                  message: error[:message] || "Unknown error",
                  location: nil,
                  full_content: error[:message] || "Unknown error",
                  files: error[:files]
                }
              end
              all_failures += error_failures
            end

            analyzed_failures = @failure_analyzer.analyze_all(
              all_failures,
              stderr: @result.stderr
            )
            @result.failures_detail = analyzed_failures
          end

          # Generate and save report
          report = @report_generator.generate(@result, all_files)

          if @configuration.save_reports
            report_path = save_reports(report)
            @formatter.report_path = report_path if @formatter.respond_to?(:report_path=)
          end

          # Output to stdout
          @formatter.on_finish(@result)

          # Display profile results if requested
          if @configuration.profile && @parsed_result[:test_times] && !@parsed_result[:test_times].empty?
            display_profile(@parsed_result[:test_times], @configuration.profile)
          end

          # Show stopped message if execution was stopped
          if execution_result[:stopped_at_group]
            puts "\nSTOPPED: Group '#{execution_result[:stopped_at_group]}' failed (--fail-fast enabled)"
          end

          # Return exit code
          @result.success? ? 0 : 1
        end

        def should_execute_sequentially?
          # If explicit files are provided via CLI, bypass group execution
          # This ensures that commands like `ace-test test/atoms/foo_test.rb` run only that file
          return false if @configuration.files && !@configuration.files.empty?

          # Only use sequential groups if execution_mode is "grouped"
          return false unless @configuration.execution_mode == "grouped"

          # Explicit --run-in-single-batch bypasses grouped execution
          return false if @configuration.run_in_single_batch

          # When profiling without a specific target, run as single batch for accurate timing
          # Profiling requires verbose output which works better with all-at-once execution
          if @configuration.profile && !@configuration.target
            return false
          end

          # If no target specified, default to "all" group for grouped mode
          target = @configuration.target || "all"

          target_str = target.to_s
          target_sym = target.to_sym

          # Check both string and symbol keys for compatibility
          @configuration.groups&.key?(target_str) || @configuration.groups&.key?(target_sym)
        end

        def sequential_options
          {
            fail_fast: @configuration.fail_fast,
            verbose: @configuration.verbose,
            per_file: @configuration.per_file,
            profile: @configuration.profile,
            group_fail_fast: @configuration.execution&.[](:group_fail_fast),
            group_isolation: @configuration.group_isolation
          }
        end

        def build_configuration(options)
          # Load configuration from file
          config_loader = Molecules::ConfigLoader.new
          config_data = config_loader.load(options[:config_path])

          # Merge with command-line options
          config_with_options = config_loader.merge_with_options(config_data, options)

          # Create TestConfiguration with merged data
          Models::TestConfiguration.new(
            format: config_with_options.defaults[:reporter] || options[:format],
            report_dir: options[:report_dir] || config_with_options.defaults[:report_dir],
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
            color: (config_with_options.defaults[:color] == "auto") ? true : config_with_options.defaults[:color],
            per_file: options[:per_file],
            failure_limits: config_with_options.failure_limits,
            profile: options[:profile],
            execution: config_with_options.execution || {},
            files: options[:files],
            run_in_single_batch: options[:run_in_single_batch]
          )
        end

        def validate_configuration!
          @configuration.validate!
        rescue ArgumentError => e
          puts "Configuration error: #{e.message}"
          exit 1
        end

        def find_test_files
          # If specific files are provided (e.g., from command line), use them directly
          if @configuration.files && !@configuration.files.empty?
            files = @configuration.files

            # Don't apply filter when files contain line numbers (file:line format)
            has_line_numbers = files.any? { |f| f.match?(/:\d+$/) }

            # Apply filter only if no line numbers and filter is provided
            if @configuration.filter && !has_line_numbers
              files = @test_detector.filter_by_pattern(files, @configuration.filter)
            end

            return files
          end

          # Otherwise, use PatternResolver for consistency
          begin
            files = if @configuration.target
              @pattern_resolver.resolve_target(@configuration.target)
            else
              # When no target specified, resolve all files
              @pattern_resolver.resolve_target(nil)
            end
          rescue ArgumentError => e
            puts "Error: #{e.message}"
            puts "Available targets: #{@pattern_resolver.available_targets.join(", ")}"
            exit 1
          end

          # If using catch-all pattern, reinitialize formatter without groups
          if @pattern_resolver.using_catch_all
            formatter_options = @configuration.to_h.merge(show_groups: false)
            if @configuration.failure_limits
              formatter_options[:max_failures_to_display] = @configuration.failure_limits[:max_display]
            end
            @formatter = @configuration.formatter_class.new(formatter_options)
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

        def count_total_test_files
          # Count all test files in test directory regardless of configuration
          Dir.glob("test/**/*_test.rb").select { |f| File.file?(f) }.size
        end

        def execute_tests(test_files)
          options = {
            fail_fast: @configuration.fail_fast,
            verbose: @configuration.verbose,
            per_file: @configuration.per_file,  # Allow per-file execution if needed for debugging
            profile: @configuration.profile,      # Add profile option for verbose timing
            group_isolation: @configuration.group_isolation  # Pass through for execution mode selection
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
            raw_output: execution_result[:stdout],
            stderr: execution_result[:stderr]
          )
        end

        def aggregate_individual_results(combined_output)
          # Split output by test file executions
          individual_outputs = combined_output.split(/^Started with run options/)
          individual_outputs.shift if individual_outputs.first && individual_outputs.first.empty?

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
            deprecations: [],
            test_times: []
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

            # Collect test times if available
            aggregated[:test_times].concat(parsed[:test_times]) if parsed[:test_times]
          end

          # Re-sort test times by duration
          aggregated[:test_times].sort_by! { |t| -t[:duration] } if aggregated[:test_times]

          aggregated
        end

        def resolve_and_set_report_dir_context(test_files)
          explicit_cli_override = @report_dir_override == :user_specified

          report_root_start_path = Dir.pwd
          if explicit_cli_override && @package_dir
            report_root_start_path = @original_dir
          end

          report_root = Atoms::ReportDirectoryResolver.resolve_report_root(
            @configuration.report_dir,
            explicit_cli_override: explicit_cli_override,
            start_path: report_root_start_path
          )

          if explicit_cli_override
            @configuration.report_dir = report_root
            return
          end

          package_name = Atoms::ReportDirectoryResolver.infer_package_name(
            package_dir: @package_dir,
            test_files: test_files,
            cwd: Dir.pwd
          )

          @configuration.report_dir = Atoms::ReportDirectoryResolver.resolve_package_report_dir(
            report_root: report_root,
            package_name: package_name
          )
        end

        def save_reports(report)
          timestamp_generator = Atoms::TimestampGenerator.new
          storage = Molecules::ReportStorage.new(
            base_dir: @configuration.report_dir,
            timestamp_generator: timestamp_generator
          )

          # Save in appropriate format
          report_path = case @configuration.format
          when "json"
            storage.save_report(report, format: :json)
          else
            storage.save_report(report, format: :all)
          end

          # Always save raw output
          storage.save_raw_output(@result.raw_output, report_path)

          # Save stderr if present
          storage.save_stderr(@result.stderr, report_path) if @result.stderr && !@result.stderr.empty?

          # Save individual failure reports if there are failures
          if @result.has_failures? && @configuration.format != "json"
            markdown_formatter_class = Atoms::LazyLoader.load_formatter("markdown")
            markdown_formatter = markdown_formatter_class.new(@configuration.to_h)
            max_display = @configuration.failure_limits ? @configuration.failure_limits[:max_display] : nil
            storage.save_individual_failure_reports(
              @result.failures_detail,
              report_path,
              markdown_formatter,
              max_display: max_display
            )
          end

          report.report_path = report_path
          report_path
        end

        def display_profile(test_times, count)
          return if test_times.empty?

          # Take only the slowest N tests
          slowest = test_times.first(count)

          puts "\n" + "=" * 60
          puts "Slowest Tests (Top #{[count, test_times.size].min})"
          puts "=" * 60

          slowest.each_with_index do |test, index|
            # Format duration nicely
            duration = format("%.3fs", test[:duration])

            # Try to shorten the file path if location is available
            location = if test[:location]
              test[:location].gsub(/^.*\/test\//, "test/")
            else
              "unknown location"
            end

            puts format("%2d. %-50s %8s",
              index + 1,
              test[:name][0..49],  # Truncate long test names
              duration)
            puts "    #{location}" if test[:location]
          end

          # Show total time for all tests
          total_time = test_times.sum { |t| t[:duration] }
          puts "-" * 60
          puts format("Total time in tests: %.3fs", total_time)
        end
      end
    end
  end
end
