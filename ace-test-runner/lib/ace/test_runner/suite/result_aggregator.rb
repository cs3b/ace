# frozen_string_literal: true

require "json"

module Ace
  module TestRunner
    module Suite
      class ResultAggregator
        attr_reader :packages

        def initialize(packages)
          @packages = packages
        end

        def aggregate
          results = collect_results

          {
            total_tests: results.sum { |r| r[:total] || 0 },
            total_passed: results.sum { |r| r[:passed] || 0 },
            total_failed: results.sum { |r| (r[:failed] || 0) + (r[:errors] || 0) },
            total_duration: results.map { |r| r[:duration] || 0 }.max,
            packages_passed: results.count { |r| r[:success] },
            packages_failed: results.count { |r| !r[:success] },
            failed_packages: collect_failed_packages(results),
            results: results
          }
        end

        def collect_results
          @packages.map do |package|
            summary_path = File.join(package["path"], "test-reports", "latest", "summary.json")

            if File.exist?(summary_path)
              begin
                data = JSON.parse(File.read(summary_path), symbolize_names: true)
                data[:package] = package["name"]
                data[:path] = package["path"]
                data
              rescue JSON::ParserError => e
                # If we can't parse the summary, create a failure result
                {
                  package: package["name"],
                  path: package["path"],
                  success: false,
                  error: "Failed to parse summary.json: #{e.message}",
                  total: 0,
                  passed: 0,
                  failed: 0,
                  errors: 1
                }
              end
            else
              # No summary file means tests didn't complete or save
              {
                package: package["name"],
                path: package["path"],
                success: false,
                error: "No test results found (summary.json missing)",
                total: 0,
                passed: 0,
                failed: 0,
                errors: 1
              }
            end
          end
        end

        def collect_failed_packages(results)
          results.select { |r| !r[:success] }.map do |result|
            {
              name: result[:package],
              path: result[:path],
              failures: result[:failed] || 0,
              errors: result[:errors] || 0,
              error_message: result[:error]
            }
          end
        end

        def generate_report(summary)
          report = []
          report << "# ACE Test Suite Report"
          report << ""
          report << "## Summary"
          report << ""

          if summary[:packages_failed] == 0
            report << "✅ **All tests passed!**"
          else
            report << "❌ **Some tests failed**"
          end

          report << ""
          report << "- Packages: #{summary[:packages_passed]} passed, #{summary[:packages_failed]} failed"
          report << "- Tests: #{summary[:total_tests]} total, #{summary[:total_passed]} passed, #{summary[:total_failed]} failed"
          report << "- Duration: #{sprintf('%.2f', summary[:total_duration])}s"
          report << ""

          if summary[:failed_packages] && !summary[:failed_packages].empty?
            report << "## Failed Packages"
            report << ""

            summary[:failed_packages].each do |pkg|
              report << "### #{pkg[:name]}"
              report << ""
              report << "- Failures: #{pkg[:failures]}"
              report << "- Errors: #{pkg[:errors]}"
              report << "- Error: #{pkg[:error_message]}" if pkg[:error_message]
              report << "- Report: `#{pkg[:path]}/test-reports/latest/failures.json`"
              report << ""
            end
          end

          report << "## Package Results"
          report << ""
          report << "| Package | Status | Tests | Passed | Failed | Duration |"
          report << "|---------|--------|-------|--------|--------|----------|"

          summary[:results].each do |result|
            status = result[:success] ? "✅ Pass" : "❌ Fail"
            report << "| #{result[:package]} | #{status} | #{result[:total]} | #{result[:passed]} | #{result[:failed] || 0} | #{sprintf('%.2f', result[:duration] || 0)}s |"
          end

          report.join("\n")
        end

        def save_report(summary, path = "test-suite-report.md")
          File.write(path, generate_report(summary))
          path
        end
      end
    end
  end
end