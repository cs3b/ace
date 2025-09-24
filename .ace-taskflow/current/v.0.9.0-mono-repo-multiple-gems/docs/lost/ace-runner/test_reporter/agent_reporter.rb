# frozen_string_literal: true

require 'minitest/reporters'
require 'pathname'
require_relative 'formatters/compact_formatter'
require_relative 'formatters/json_formatter'
require_relative 'formatters/markdown_formatter'

module AceTools
  module TestReporter
    class AgentReporter < Minitest::Reporters::BaseReporter
      attr_reader :config, :group_detector, :report_generator,
                  :results_by_group, :start_time

      def initialize(options = {})
        super(options)
        @config = options
        @group_detector = GroupDetector.new(options[:group_by])
        @report_generator = ReportGenerator.new(options[:report_dir], options[:max_reports])
        @results_by_group = Hash.new { |h, k| h[k] = { passed: [], failed: [], skipped: [], errors: [] } }
        @compact_formatter = Formatters::CompactFormatter.new(options)
        @json_formatter = Formatters::JsonFormatter.new if options[:json_output]
        @markdown_formatter = Formatters::MarkdownFormatter.new if options[:markdown_output]
        @use_colors = should_use_colors?
      end

      def should_use_colors?
        return false if ENV['NO_COLOR'] || ENV['CI']
        return true if ENV['FORCE_COLOR']
        io.respond_to?(:tty?) && io.tty?
      end

      def colorize(text, color_code)
        return text unless @use_colors
        "\e[#{color_code}m#{text}\e[0m"
      end

      def start
        super
        @start_time = Minitest.clock_time
        @current_group = nil
        # Don't print initial separator - we'll print before each group
      end

      def record(result)
        super
        group = group_detector.detect_group(result.source_location&.first)
        category = categorize_result(result)
        @results_by_group[group][category] << result

        # Print progress indicator for each test
        if group != @current_group
          # Print newline after previous group's dots (except for first group)
          io.puts "" if @current_group

          # Print separator and group header for new group
          io.puts "═" * 67 unless config[:mode] == 'quiet'
          group_name = colorize(group.to_s.upcase, '1')  # Bold
          io.print "  #{group_name}: " if config[:mode] != 'quiet'
          @current_group = group
        end

        # Print test result symbol with colors
        symbol = case category
        when :passed
          colorize('.', '32')  # Green
        when :failed
          colorize('F', '31')  # Red
        when :errors
          colorize('E', '33')  # Yellow
        when :skipped
          colorize('S', '36')  # Cyan
        end
        io.print symbol
      end

      def report
        super
        return if config[:mode] == 'quiet'

        # Prepare report directory first if there are failures
        if has_failures_or_errors?
          @report_generator.prepare_report_directory
        end

        print_console_output
        generate_detailed_reports if has_failures_or_errors?
      end

      private

      def categorize_result(result)
        if result.skipped?
          :skipped
        elsif result.error?
          :errors
        elsif result.failure
          :failed
        else
          :passed
        end
      end

      def has_failures_or_errors?
        @results_by_group.any? { |_, results| results[:failed].any? || results[:errors].any? }
      end

      def print_console_output
        # New line after progress dots
        io.puts ""

        # Summary statistics
        total_passed = @results_by_group.sum { |_, r| r[:passed].size }
        total_failed = @results_by_group.sum { |_, r| r[:failed].size }
        total_errors = @results_by_group.sum { |_, r| r[:errors].size }
        total_skipped = @results_by_group.sum { |_, r| r[:skipped].size }
        total_time = Minitest.clock_time - @start_time

        io.puts "─" * 67
        io.puts format("Finished in %.4fs", total_time)

        # Color the summary line based on results
        summary = format("%d tests, %d passed, %d failures, %d errors, %d skipped",
                        total_passed + total_failed + total_errors + total_skipped,
                        total_passed, total_failed, total_errors, total_skipped)
        if total_failed > 0 || total_errors > 0
          io.puts colorize(summary, '31')  # Red for failures/errors
        elsif total_skipped > 0
          io.puts colorize(summary, '33')  # Yellow if only skipped
        else
          io.puts colorize(summary, '32')  # Green for all passed
        end

        # Failures detail
        all_failures = collect_all_failures
        if all_failures.any?
          io.puts "─" * 67
          io.puts colorize("FAILURES:", '31;1')  # Bold red
          all_failures.first(10).each_with_index do |result, idx|
            failure_text = @compact_formatter.format_failure(result)
            io.puts format("  %d) %s", idx + 1, colorize(failure_text, '31'))

            # Add path to detailed report if we're generating reports
            if @report_generator.current_report_path && @markdown_formatter
              filename = @markdown_formatter.generate_failure_filename(result, idx + 1)
              # Make path relative to tools directory
              full_path = File.join(@report_generator.current_report_path, 'failures', filename)
              tools_dir = File.expand_path('../../../..', __FILE__)  # Get tools directory
              relative_path = Pathname.new(full_path).relative_path_from(Pathname.new(tools_dir))
              io.puts "     📄 #{colorize(relative_path.to_s, '36')}"
            end
          end
          io.puts colorize("  ... and #{all_failures.size - 10} more", '33') if all_failures.size > 10
        end

        # Report location
        if has_failures_or_errors? && @report_generator.current_report_path
          io.puts "─" * 67
          # Make path relative to tools directory
          tools_dir = File.expand_path('../../../..', __FILE__)  # Get tools directory
          relative_path = Pathname.new(@report_generator.current_report_path).relative_path_from(Pathname.new(tools_dir))
          io.puts colorize("📁 Full report: #{relative_path}/", '36;1')  # Bold cyan
          io.puts colorize("   View detailed failure information in the report directory above", '36')
        end

        io.puts "═" * 67
      end

      def generate_detailed_reports
        # Report directory already prepared in report method
        report_path = @report_generator.current_report_path

        # Generate summary files
        summary_data = build_summary_data

        # Text summary
        File.write(
          File.join(report_path, 'summary.txt'),
          @compact_formatter.format_full_summary(@results_by_group, Minitest.clock_time - @start_time)
        )

        # JSON summary
        if @json_formatter
          File.write(
            File.join(report_path, 'summary.json'),
            @json_formatter.format_summary(summary_data)
          )

          File.write(
            File.join(report_path, 'failures.json'),
            @json_formatter.format_failures(collect_all_failures)
          )
        end

        # Markdown failure reports
        if @markdown_formatter
          failures_dir = File.join(report_path, 'failures')
          FileUtils.mkdir_p(failures_dir)

          collect_all_failures.each_with_index do |result, index|
            filename = @markdown_formatter.generate_failure_filename(result, index + 1)
            File.write(
              File.join(failures_dir, filename),
              @markdown_formatter.format_failure_report(result)
            )
          end
        end

        @report_generator.cleanup_old_reports
      end

      def collect_all_failures
        @results_by_group.flat_map { |_, results| results[:failed] + results[:errors] }.reject(&:skipped?)
      end

      def elapsed_time_for_group(results)
        all_results = results.values.flatten
        return 0.0 if all_results.empty?

        all_results.sum(&:time)
      end

      def build_summary_data
        {
          total_time: Minitest.clock_time - @start_time,
          total_tests: tests.size,
          total_assertions: assertions,
          groups: @results_by_group.map do |group, results|
            {
              name: group,
              passed: results[:passed].size,
              failed: results[:failed].size,
              errors: results[:errors].size,
              skipped: results[:skipped].size,
              time: elapsed_time_for_group(results)
            }
          end
        }
      end
    end
  end
end