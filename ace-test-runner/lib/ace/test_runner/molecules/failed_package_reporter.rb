# frozen_string_literal: true

require "pathname"
require_relative "../atoms/report_path_resolver"

module Ace
  module TestRunner
    module Molecules
      module FailedPackageReporter
        module_function

        def format_for_display(package)
          path = extract_path(package)
          report_path = Atoms::ReportPathResolver.call(path)
          
          if report_path
            begin
              relative_path = Pathname.new(report_path).relative_path_from(Dir.pwd)
              "    → See #{relative_path}"
            rescue StandardError => e
              warn "Failed to calculate relative path: #{e.message}" if debug_mode?
              "    → See #{report_path}"
            end
          else
            reports_path = File.join(path, "test-reports")
            begin
              relative_path = Pathname.new(reports_path).relative_path_from(Dir.pwd)
              "    → Check #{relative_path}/ for details"
            rescue StandardError => e
              warn "Failed to calculate relative path: #{e.message}" if debug_mode?
              "    → Check #{reports_path}/ for details"
            end
          end
        end

        def format_for_markdown(package)
          path = extract_path(package)
          report_path = Atoms::ReportPathResolver.call(path)

          if report_path
            relative_report_path = relative_or_absolute(report_path)
            "- Report: `#{relative_report_path}`"
          else
            reports_path = File.join(path, "test-reports")
            relative_reports_path = relative_or_absolute(reports_path)
            "- Report: Check `#{relative_reports_path}/` for details"
          end
        end

        class << self
          private

          def extract_path(package)
            package[:path] || package["path"]
          end

          def debug_mode?
            ENV["DEBUG"]
          end

          def relative_or_absolute(path)
            Pathname.new(path).relative_path_from(Dir.pwd).to_s
          rescue StandardError => e
            warn "Failed to calculate relative path: #{e.message}" if debug_mode?
            path
          end
        end
      end
    end
  end
end
