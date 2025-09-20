# frozen_string_literal: true

require 'fileutils'
require 'time'
require 'pathname'

module AceTools
  module TestReporter
    class ReportGenerator
      attr_reader :report_dir, :max_reports, :current_report_path

      def initialize(report_dir = 'test-report', max_reports = 10)
        # Convert to absolute path if relative
        @report_dir = ensure_absolute_path(report_dir || 'test-report')
        @max_reports = max_reports || 10
        @current_report_path = nil
      end

      def prepare_report_directory
        # Ensure parent directory exists first
        # Handle nil or non-string report_dir
        dir = @report_dir || 'test-report'
        dir = dir.to_s if dir.respond_to?(:to_s)
        FileUtils.mkdir_p(dir)

        timestamp = Time.now.strftime('%Y%m%d-%H%M%S')
        @current_report_path = File.join(dir, timestamp)
        FileUtils.mkdir_p(@current_report_path)
        @current_report_path
      end

      def cleanup_old_reports
        return unless Dir.exist?(@report_dir)

        # Get all report directories sorted by creation time
        report_dirs = Dir.glob(File.join(@report_dir, '*'))
                        .select { |d| File.directory?(d) }
                        .sort_by { |d| File.ctime(d) }

        # Keep only the most recent max_reports
        if report_dirs.size > @max_reports
          dirs_to_remove = report_dirs[0...(report_dirs.size - @max_reports)]
          dirs_to_remove.each { |dir| FileUtils.rm_rf(dir) }
        end
      end

      def write_file(filename, content)
        path = File.join(@current_report_path, filename)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
        path
      end

      private

      def ensure_absolute_path(path)
        pathname = Pathname.new(path)

        # If already absolute, return as-is
        return path if pathname.absolute?

        # Store the original working directory at initialization time
        @original_pwd ||= Dir.pwd
        File.expand_path(path, @original_pwd)
      end
    end
  end
end