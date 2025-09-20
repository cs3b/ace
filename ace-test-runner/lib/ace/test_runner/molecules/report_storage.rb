# frozen_string_literal: true

module Ace
  module TestRunner
    module Molecules
      # Handles storage of test reports to filesystem
      class ReportStorage
        def initialize(base_dir: "test-reports", timestamp_generator: nil)
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

        def list_reports(limit: 10)
          ensure_base_directory

          reports = Dir.glob(File.join(@base_dir, "*"))
                       .select { |d| File.directory?(d) && !File.symlink?(d) }
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

          reports = Dir.glob(File.join(@base_dir, "*"))
                       .select { |d| File.directory?(d) && !File.symlink?(d) }
                       .map { |d| report_info(d) }
                       .compact
                       .sort_by { |r| r[:timestamp] }
                       .reverse

          # Keep the most recent N reports
          to_keep = reports.take(keep)

          # Also keep reports newer than max_age_days
          cutoff_time = Time.now - (max_age_days * 24 * 60 * 60)
          to_keep += reports.select { |r| r[:timestamp] > cutoff_time }

          to_keep_paths = to_keep.map { |r| r[:path] }.uniq

          deleted = []
          reports.each do |report|
            next if to_keep_paths.include?(report[:path])

            FileUtils.rm_rf(report[:path])
            deleted << report[:path]
          end

          deleted
        end

        private

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
      end
    end
  end
end