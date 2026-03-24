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
          report_root = extract_report_root(package)
          package_name = extract_name(package) || File.basename(path)
          report_path = Atoms::ReportPathResolver.call(
            path,
            report_root: report_root,
            package_name: package_name
          )

          if report_path
            begin
              relative_path = Pathname.new(report_path).relative_path_from(Dir.pwd)
              "    → See #{relative_path}"
            rescue => e
              warn "Failed to calculate relative path: #{e.message}" if debug_mode?
              "    → See #{report_path}"
            end
          else
            reports_path = fallback_reports_path(path, report_root, package_name)
            begin
              relative_path = Pathname.new(reports_path).relative_path_from(Dir.pwd)
              "    → Check #{relative_path}/ for details"
            rescue => e
              warn "Failed to calculate relative path: #{e.message}" if debug_mode?
              "    → Check #{reports_path}/ for details"
            end
          end
        end

        def format_for_markdown(package)
          path = extract_path(package)
          report_root = extract_report_root(package)
          package_name = extract_name(package) || File.basename(path)
          report_path = Atoms::ReportPathResolver.call(
            path,
            report_root: report_root,
            package_name: package_name
          )

          if report_path
            relative_report_path = relative_or_absolute(report_path)
            "- Report: `#{relative_report_path}`"
          else
            reports_path = fallback_reports_path(path, report_root, package_name)
            relative_reports_path = relative_or_absolute(reports_path)
            "- Report: Check `#{relative_reports_path}/` for details"
          end
        end

        class << self
          private

          def extract_path(package)
            package[:path] || package["path"]
          end

          def extract_name(package)
            package[:name] || package["name"]
          end

          def extract_report_root(package)
            package[:report_root] || package["report_root"]
          end

          def fallback_reports_path(path, report_root, package_name)
            if report_root
              short_name = package_name.to_s.sub(/\Aace-/, "")
              return File.join(report_root, short_name) unless short_name.empty?
            end

            File.join(path, "test-reports")
          end

          def debug_mode?
            ENV["DEBUG"]
          end

          def relative_or_absolute(path)
            Pathname.new(path).relative_path_from(Dir.pwd).to_s
          rescue => e
            warn "Failed to calculate relative path: #{e.message}" if debug_mode?
            path
          end
        end
      end
    end
  end
end
