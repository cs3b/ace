# frozen_string_literal: true

module Ace
  module TestRunner
    module Commands
      class TestCommand
        def initialize(args, options = {})
          @args = args
          @options = build_test_options(options)
        end

        def execute
          display_config_summary

          # Handle special modes first
          result = handle_special_modes
          return result if result

          # Parse CLI arguments using CliArgumentParser
          begin
            arg_parser = Molecules::CliArgumentParser.new(@args)
            parsed_args = arg_parser.parse
            @options.merge!(parsed_args)
          rescue ArgumentError => e
            $stderr.puts "Error: #{e.message}"
            return 1
          end

          # Run tests with special exit! handling for Minitest compatibility
          run_tests_with_exit_handling
        rescue Ace::TestRunner::Error => e
          $stderr.puts "Error: #{e.message}"
          1
        rescue Interrupt
          $stderr.puts "\nTest execution interrupted"
          130
        rescue => e
          $stderr.puts "Unexpected error: #{e.message}"
          $stderr.puts e.backtrace if @options[:verbose]
          1
        end

        private

        def build_test_options(cli_options)
          # Thor returns HashWithIndifferentAccess with string keys internally.
          # Transform to symbol keys for consistent access patterns throughout the codebase.
          symbolized_options = cli_options.transform_keys(&:to_sym)

          # Default options - symbolized_options will override these for any explicit values
          {
            format: "progress",
            save_reports: true,
            verbose: false,
            fail_fast: false,
            fix_deprecations: false,
            color: true,
            per_file: false
          }.merge(symbolized_options)
        end

        def handle_special_modes
          # Handle cleanup reports mode
          if @options[:cleanup_reports]
            return handle_cleanup_reports
          end

          # Handle rake integration modes
          if @options[:set_default_rake] || @options[:unset_default_rake] || @options[:check_rake_status]
            return handle_rake_integration
          end

          # Handle deprecation fixing mode
          if @options[:fix_deprecations]
            return handle_fix_deprecations
          end

          nil # Continue to normal test execution
        end

        def handle_cleanup_reports
          require "ace/test_runner/molecules/report_storage"
          require "ace/test_runner/atoms/timestamp_generator"
          require "ace/test_runner/molecules/config_loader"

          # Load config to get id_format for proper directory detection
          config_loader = Molecules::ConfigLoader.new
          config_data = config_loader.load(@options[:config_path])
          report_config = config_data[:report] || {}
          id_format = (report_config[:id_format] || :base36).to_sym

          timestamp_generator = Atoms::TimestampGenerator.new(id_format: id_format)
          storage = Molecules::ReportStorage.new(
            base_dir: @options[:report_dir] || "test-reports",
            timestamp_generator: timestamp_generator
          )

          keep = @options[:cleanup_keep] || 10
          age = @options[:cleanup_age] || 30

          puts "Cleaning up test reports..."
          puts "  Keeping last #{keep} reports"
          puts "  Deleting reports older than #{age} days"

          deleted = storage.cleanup_old_reports(keep: keep, max_age_days: age)

          if deleted.empty?
            puts "No reports to clean up."
          else
            puts "Deleted #{deleted.size} old reports:"
            deleted.each { |path| puts "  - #{File.basename(path)}" }
          end

          0
        end

        def handle_rake_integration
          require "ace/test_runner/molecules/rake_integration"

          integration = Molecules::RakeIntegration.new

          if @options[:set_default_rake]
            result = integration.set_default
            puts result[:message]
            return (result[:success] ? 0 : 1)
          elsif @options[:unset_default_rake]
            result = integration.unset_default
            puts result[:message]
            return (result[:success] ? 0 : 1)
          elsif @options[:check_rake_status]
            status = integration.check_status
            puts "Rake Test Integration Status:"
            puts "  Rakefile exists: #{status[:rakefile_exists]}"
            puts "  ace-test integrated: #{status[:integrated]}"
            puts "  Message: #{status[:message]}"
            puts "  Backup exists: #{status[:backup_exists]}" if status[:backup_exists]
            puts "  Has test task: #{status[:has_test_task]}" if status.key?(:has_test_task)
            return 0
          end
        end

        def handle_fix_deprecations
          require "ace/test_runner/molecules/deprecation_fixer"

          puts "Scanning for deprecated test patterns..."

          detector = Atoms::TestDetector.new
          fixer = Molecules::DeprecationFixer.new

          test_files = detector.find_test_files
          fixed_count = 0

          test_files.each do |file|
            result = fixer.fix_file(file, dry_run: false)
            if result[:success] && result[:changes] > 0
              puts "  Fixed #{result[:changes]} deprecations in #{file}"
              fixed_count += result[:changes]
            end
          end

          if fixed_count == 0
            puts "No deprecations found to fix."
          else
            puts "Fixed #{fixed_count} deprecations total."
          end

          0
        end

        def run_tests_with_exit_handling
          exit_code = Ace::TestRunner.run(@options)

          # Flush IO buffers before exit! (which skips at_exit handlers including finalizers)
          $stdout.flush
          $stderr.flush

          # IMPORTANT: Use exit! (not exit) to skip Ruby's at_exit handlers.
          # This prevents Minitest from auto-running again via its at_exit hook.
          # When ace-test uses in-process (direct) execution, test files are loaded
          # into the current process. Minitest registers an at_exit handler that would
          # re-run all tests on normal exit. Using exit! bypasses this.
          # See docs/testing-patterns.md for details on this pattern.

          # Note: We cannot use exit! here and return the exit code instead.
          # The exe file wrapper will handle the exit! call.
          exit_code
        end

        def display_config_summary
          return if @options[:quiet]

          require "ace/core"
          Ace::Core::Atoms::ConfigSummary.display(
            command: "test",
            config: @options,
            defaults: {},
            options: @options,
            quiet: false
          )
        end
      end
    end
  end
end
