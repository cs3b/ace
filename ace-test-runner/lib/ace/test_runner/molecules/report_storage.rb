# frozen_string_literal: true

module Ace
  module TestRunner
    module Molecules
      # Handles storage of test reports to filesystem
      class ReportStorage
        def initialize(base_dir: ".ace-local/test/reports", timestamp_generator: nil)
          @base_dir = base_dir
          @timestamp_generator = timestamp_generator || Atoms::TimestampGenerator.new
        end

        def save_report(report, format: :json)
          ensure_base_directory
          report_dir = create_report_directory

          case format
          when :json
            save_json_report(report, report_dir)
          when :markdown
            save_markdown_report(report, report_dir)
          when :all
            save_all_formats(report, report_dir)
          else
            raise ArgumentError, "Unknown report format: #{format}"
          end

          create_latest_symlink(report_dir)
          report_dir
        end

        def save_raw_output(output, report_dir)
          ensure_directory(report_dir)
          output_file = File.join(report_dir, "raw_output.txt")
          File.write(output_file, output)
          output_file
        end

        def save_stderr(stderr, report_dir)
          return nil if stderr.nil? || stderr.empty?

          ensure_directory(report_dir)
          stderr_file = File.join(report_dir, "raw_stderr.txt")
          File.write(stderr_file, stderr)
          stderr_file
        end

        def save_summary(result, report_dir)
          ensure_directory(report_dir)
          summary_file = File.join(report_dir, "summary.json")

          summary_data = {
            passed: result.passed,
            failed: result.failed,
            errors: result.errors,
            skipped: result.skipped,
            total: result.total_tests,
            pass_rate: result.pass_rate,
            duration: result.duration,
            success: result.success?,
            timestamp: Time.now.iso8601
          }

          File.write(summary_file, JSON.pretty_generate(summary_data))
          summary_file
        end

        def save_failures(failures, report_dir)
          return nil if failures.empty?

          ensure_directory(report_dir)
          failures_file = File.join(report_dir, "failures.json")

          failures_data = failures.map(&:to_h)
          File.write(failures_file, JSON.pretty_generate(failures_data))
          failures_file
        end

        def save_individual_failure_reports(failures, report_dir, formatter, max_display: nil)
          return [] if failures.empty?

          failures_dir = File.join(report_dir, "failures")
          ensure_directory(failures_dir)

          # Limit number of individual .md files to max_display if specified
          failures_to_save = max_display ? failures.take(max_display) : failures

          report_files = []
          failures_to_save.each_with_index do |failure, index|
            filename = generate_failure_filename(failure, index + 1)
            filepath = File.join(failures_dir, filename)

            content = formatter.generate_failure_report(failure, index + 1)
            File.write(filepath, content)
            report_files << filepath
          end

          # Create an index file for ALL failures (not just the limited ones)
          create_failure_index(failures, failures_dir)

          report_files
        end

        def list_reports(limit: 10)
          ensure_base_directory

          report_directories
            .map { |d| report_info(d) }
            .compact
            .sort_by { |r| r[:timestamp] }
            .reverse
            .take(limit)
        end

        def latest_report_path
          latest_link = File.join(@base_dir, "latest")
          return nil unless File.exist?(latest_link) && File.symlink?(latest_link)

          File.readlink(latest_link)
        end

        def load_report(report_dir)
          return nil unless Dir.exist?(report_dir)

          summary_file = File.join(report_dir, "summary.json")
          return nil unless File.exist?(summary_file)

          summary = JSON.parse(File.read(summary_file), symbolize_names: true)

          # Load additional data if available
          failures_file = File.join(report_dir, "failures.json")
          failures = if File.exist?(failures_file)
            JSON.parse(File.read(failures_file), symbolize_names: true)
          else
            []
          end

          {
            summary: summary,
            failures: failures,
            report_dir: report_dir
          }
        end

        def cleanup_old_reports(keep: 10, max_age_days: 30)
          ensure_base_directory

          cutoff_time = Time.now - (max_age_days * 24 * 60 * 60)
          deleted = []

          # In centralized mode, base_dir contains package subfolders; in legacy mode it may contain reports directly.
          reports_by_scope = report_directories
            .map { |d| report_info(d) }
            .compact
            .group_by { |r| File.dirname(r[:path]) }

          reports_by_scope.each_value do |reports|
            sorted = reports.sort_by { |r| r[:timestamp] }.reverse

            to_keep = sorted.take(keep)
            to_keep += sorted.select { |r| r[:timestamp] > cutoff_time }
            to_keep_paths = to_keep.map { |r| r[:path] }.uniq

            sorted.each do |report|
              next if to_keep_paths.include?(report[:path])

              FileUtils.rm_rf(report[:path])
              deleted << report[:path]
            end
          end

          deleted
        end

        private

        def generate_failure_filename(failure, index)
          # Create a safe filename from the test name
          test_name = failure.full_test_name.gsub(/\W+/, "_").downcase
          test_name = test_name[0...50] if test_name.length > 50
          format("%03d-%s.md", index, test_name)
        end

        def create_failure_index(failures, failures_dir)
          index_file = File.join(failures_dir, "index.md")

          lines = []
          lines << "# Test Failures Index"
          lines << ""
          lines << "Total failures: #{failures.size}"
          lines << ""
          lines << "## Failures"
          lines << ""

          failures.each_with_index do |failure, index|
            filename = generate_failure_filename(failure, index + 1)
            lines << "#{index + 1}. [#{failure.full_test_name}](./#{filename})"
            lines << "   - **Type:** #{failure.type}"
            lines << "   - **Location:** `#{failure.location}`"
            lines << ""
          end

          File.write(index_file, lines.join("\n"))
        end

        def ensure_base_directory
          FileUtils.mkdir_p(@base_dir) unless Dir.exist?(@base_dir)
        end

        def ensure_directory(dir)
          FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        end

        def create_report_directory
          ensure_base_directory
          timestamp = @timestamp_generator.directory_name
          report_dir = File.join(@base_dir, timestamp)
          FileUtils.mkdir_p(report_dir)
          report_dir
        end

        def create_latest_symlink(report_dir)
          latest_link = File.join(@base_dir, "latest")

          # Remove existing symlink if present
          FileUtils.rm_f(latest_link) if File.exist?(latest_link)

          # Create new symlink to the latest report
          FileUtils.ln_s(File.basename(report_dir), latest_link)
        end

        def save_json_report(report, report_dir)
          report_file = File.join(report_dir, "report.json")
          File.write(report_file, report.to_json)
          report_file
        end

        def save_markdown_report(report, report_dir)
          report_file = File.join(report_dir, "report.md")
          File.write(report_file, report.to_markdown)
          report_file
        end

        def save_all_formats(report, report_dir)
          files = [
            save_json_report(report, report_dir),
            save_markdown_report(report, report_dir),
            save_summary(report.result, report_dir)
          ]

          if report.result.has_failures?
            files << save_failures(report.result.failures_detail, report_dir)
          end

          files.compact
        end

        def report_info(dir)
          return nil unless Dir.exist?(dir)

          summary_file = File.join(dir, "summary.json")
          return nil unless File.exist?(summary_file)

          summary = JSON.parse(File.read(summary_file), symbolize_names: true)

          {
            path: dir,
            name: File.basename(dir),
            timestamp: Time.parse(summary[:timestamp]),
            success: summary[:success],
            stats: {
              passed: summary[:passed],
              failed: summary[:failed],
              total: summary[:total]
            }
          }
        rescue JSON::ParserError, ArgumentError
          nil
        end

        def report_directories
          top_level = Dir.glob(File.join(@base_dir, "*"))
            .select { |d| File.directory?(d) && !File.symlink?(d) }

          dirs = []
          top_level.each do |entry|
            if File.exist?(File.join(entry, "summary.json"))
              dirs << entry
              next
            end

            nested = Dir.glob(File.join(entry, "*"))
              .select { |d| File.directory?(d) && !File.symlink?(d) }
              .select { |d| File.exist?(File.join(d, "summary.json")) }
            dirs.concat(nested)
          end

          dirs
        end
      end
    end
  end
end
