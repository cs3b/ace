# frozen_string_literal: true

module Ace
  module TestRunner
    module Suite
      class ResultAggregator
        attr_reader :packages

        def initialize(packages, runtime_results: {})
          @packages = packages
          @runtime_results = runtime_results || {}
        end

        def aggregate
          results = collect_results

          {
            total_tests: results.sum { |r| r[:total] || 0 },
            total_passed: results.sum { |r| r[:passed] || 0 },
            total_failed: results.sum { |r| (r[:failed] || 0) + (r[:errors] || 0) },
            total_skipped: results.sum { |r| r[:skipped] || 0 },
            total_assertions: results.sum { |result| result[:assertions] || 0 },
            assertions_failed: 0,
            total_duration: results.map { |r| r[:duration] || 0 }.max,
            packages_passed: results.count { |r| r[:success] },
            packages_failed: results.count { |r| !r[:success] },
            failed_packages: collect_failed_packages(results),
            results: results
          }
        end

        def collect_results
          @packages.map do |package|
            runtime_result(package) || {
              package: package["name"], path: package["path"], entry_id: package["entry_id"],
              report_dir: nil, success: false, error: "No verified execution completion evidence",
              total: 0, passed: 0, failed: 0, errors: 1, assertions: 0
            }
          end
        end

        def collect_failed_packages(results)
          results.select { |r| !r[:success] }.map do |result|
            {
              name: result[:package],
              path: result[:path],
              report_dir: result[:report_dir],
              execution_id: result[:execution_id],
              entry_id: result[:entry_id],
              failures: result[:failed] || 0,
              errors: result[:errors] || 0,
              error_message: result[:error]
            }
          end
        end

        def runtime_result(package)
          status = @runtime_results[package["entry_id"]]
          return nil unless status && status[:completed]

          results = status[:results] || {}
          total = results[:tests] || 0
          failures = results[:failures] || 0
          errors = results[:errors] || 0
          skipped = results[:skipped] || 0

          {
            package: package["name"],
            path: package["path"],
            report_dir: results[:report_dir],
            completion_path: results[:completion_path],
            execution_id: results[:execution_id],
            entry_id: package["entry_id"],
            success: status[:success],
            error: results[:error],
            total: total,
            passed: results[:passed] || 0,
            failed: failures,
            errors: errors,
            skipped: skipped,
            duration: results[:duration] || status[:elapsed] || 0,
            assertions: results[:assertions] || 0
          }
        end

        def generate_report(summary)
          report = []
          report << "# ACE Test Suite Report"
          report << ""
          report << "## Summary"
          report << ""

          report << if summary[:packages_failed] == 0
            "✅ **All tests passed!**"
          else
            "❌ **Some tests failed**"
          end

          report << ""
          report << "- Packages: #{summary[:packages_passed]} passed, #{summary[:packages_failed]} failed"
          report << "- Tests: #{summary[:total_tests]} total, #{summary[:total_passed]} passed, #{summary[:total_failed]} failed"
          report << "- Duration: #{sprintf("%.2f", summary[:total_duration])}s"
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
              report << Ace::TestRunner::Molecules::FailedPackageReporter.format_for_markdown(pkg)
              report << ""
            end
          end

          report << "## Package Results"
          report << ""
          report << "| Package | Status | Tests | Passed | Failed | Skipped | Duration |"
          report << "|---------|--------|-------|--------|--------|---------|----------|"

          summary[:results].each do |result|
            status = result[:success] ? "✅ Pass" : "❌ Fail"
            report << "| #{result[:package]} | #{status} | #{result[:total]} | #{result[:passed]} | #{result[:failed] || 0} | #{result[:skipped] || 0} | #{sprintf("%.2f", result[:duration] || 0)}s |"
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
