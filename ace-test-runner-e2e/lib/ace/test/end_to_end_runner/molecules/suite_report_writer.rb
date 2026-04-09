# frozen_string_literal: true

require "fileutils"
require "yaml"
require "ace/llm"
require "ace/llm/query_interface"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Writes a suite-level final report aggregating all test results
        #
        # Uses LLM synthesis to generate rich reports with root cause analysis,
        # friction insights, and improvement suggestions. Falls back to a static
        # template on LLM failure.
        class SuiteReportWriter
          # @param config [Hash, nil] Configuration hash (reads reporting.model and reporting.timeout)
          def initialize(config: nil)
            reporting = (config || {}).dig("reporting") || {}
            @model = reporting["model"] || "glite"
            @timeout = reporting["timeout"] || 60
          end

          # Write a suite-level final report
          #
          # @param results [Array<Models::TestResult>] Test results (ordered)
          # @param scenarios [Array<Models::TestScenario>] Corresponding scenarios
          # @param package [String] Package name (e.g., "ace-lint")
          # @param timestamp [String] Timestamp ID for this run
          # @param base_dir [String] Base directory for cache output
          # @return [String] Path to the written report file
          def write(results, scenarios, package:, timestamp:, base_dir:)
            cache_dir = File.join(base_dir, ".ace-local", "test-e2e")
            FileUtils.mkdir_p(cache_dir)

            report_path = File.join(cache_dir, "#{timestamp}-final-report.md")

            overall_status = compute_status(results)
            executed_at = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")

            content = synthesize_report(
              results, scenarios,
              package: package,
              timestamp: timestamp,
              overall_status: overall_status,
              executed_at: executed_at
            )

            File.write(report_path, content)
            report_path
          end

          private

          # Attempt LLM synthesis, falling back to static template
          def synthesize_report(results, scenarios, package:, timestamp:, overall_status:, executed_at:)
            results_data = build_results_data(results, scenarios)

            prompt_builder = Atoms::SuiteReportPromptBuilder.new
            user_prompt = prompt_builder.build(
              results_data,
              package: package,
              timestamp: timestamp,
              overall_status: overall_status,
              executed_at: executed_at
            )

            response = Ace::LLM::QueryInterface.query(
              @model,
              user_prompt,
              system: Atoms::SuiteReportPromptBuilder::SYSTEM_PROMPT,
              timeout: @timeout,
              temperature: 0.3
            )

            total_passed = results.sum(&:passed_count)
            total_tc = results.sum(&:total_count)
            validate_overall_line(response[:text], total_passed, total_tc)
          rescue => e
            # LLM failed — fall back to static report
            warn "Warning: LLM synthesis failed (#{e.class}: #{e.message}), using static report" if ENV["DEBUG"]
            executed_date = Time.now.utc.strftime("%Y-%m-%d")
            total_passed = results.sum(&:passed_count)
            total_failed = results.sum(&:failed_count)
            total_tc = results.sum(&:total_count)

            build_static_report(
              results, scenarios,
              package: package,
              timestamp: timestamp,
              overall_status: overall_status,
              executed_at: executed_at,
              executed_date: executed_date,
              total_passed: total_passed,
              total_failed: total_failed,
              total_tc: total_tc
            )
          end

          # Read summary and experience report content from each result's report dir
          def build_results_data(results, scenarios)
            results.each_with_index.map do |result, i|
              scenario = scenarios[i]
              report_dir = result.report_dir

              summary_content = read_report_file(report_dir, "summary.r.md")
              experience_content = read_report_file(report_dir, "experience.r.md")

              {
                test_id: result.test_id,
                title: scenario.title,
                status: result.status,
                passed: result.passed_count,
                failed: result.failed_count,
                total: result.total_count,
                test_cases: result.test_cases,
                report_dir_name: report_dir ? File.basename(report_dir) : nil,
                summary_content: summary_content,
                experience_content: experience_content
              }
            end
          end

          # Safely read a report file, returning nil if missing
          def read_report_file(report_dir, filename)
            return nil unless report_dir

            path = File.join(report_dir, filename)
            return nil unless File.exist?(path)

            File.read(path)
          end

          # Validate the LLM-generated Overall line against deterministic totals.
          # If the LLM hallucinated wrong numbers, replace the line with correct values.
          def validate_overall_line(report_text, expected_passed, expected_total)
            expected_pct = (expected_total > 0) ? (expected_passed * 100.0 / expected_total).round(0) : 0
            correct_line = "**Overall:** #{expected_passed}/#{expected_total} test cases passed (#{expected_pct}%)"

            # Match patterns like "**Overall:** X/Y test cases passed (Z%)"
            overall_pattern = /\*\*Overall:\*\*\s*\d+\/\d+\s+test cases passed\s*\(\d+%\)/

            if report_text.match?(overall_pattern)
              report_text.gsub(overall_pattern, correct_line)
            else
              # No Overall line found — append the correct one after the summary table
              "#{report_text.rstrip}\n\n#{correct_line}\n"
            end
          end

          def compute_status(results)
            # Filter out skipped tests for status computation
            executed = results.reject(&:skipped?)
            return "skip" if executed.empty?

            if executed.all?(&:success?)
              "pass"
            elsif executed.any?(&:success?)
              "partial"
            else
              "fail"
            end
          end

          # Static fallback report (original template-based approach)
          def build_static_report(results, scenarios, package:, timestamp:, overall_status:,
            executed_at:, executed_date:, total_passed:, total_failed:, total_tc:)
            total_skipped = results.count(&:skipped?)

            parts = []
            parts << build_frontmatter(
              timestamp: timestamp, package: package, overall_status: overall_status,
              tests_run: results.size, executed_at: executed_at, skipped: total_skipped
            )
            parts << build_header(package: package, tests_run: results.size, executed_date: executed_date, skipped: total_skipped)
            parts << build_summary_table(results, scenarios)
            parts << build_overall_line(total_passed: total_passed, total_tc: total_tc)
            parts << build_failed_section(results, scenarios) if results.any?(&:failed?)
            parts << build_reports_section(results, scenarios)
            parts.join("\n")
          end

          def build_frontmatter(timestamp:, package:, overall_status:, tests_run:, executed_at:, skipped: 0)
            skipped_line = (skipped > 0) ? "\nskipped: #{skipped}" : ""
            <<~FRONTMATTER
              ---
              suite-id: #{timestamp}
              package: #{package}
              status: #{overall_status}
              tests-run: #{tests_run}#{skipped_line}
              executed: #{executed_at}
              ---
            FRONTMATTER
          end

          def build_header(package:, tests_run:, executed_date:, skipped: 0)
            skipped_info = (skipped > 0) ? " (#{skipped} skipped)" : ""
            <<~HEADER
              # E2E Test Suite Report

              **Package:** #{package}
              **Tests:** #{tests_run}#{skipped_info}
              **Executed:** #{executed_date}
            HEADER
          end

          def build_summary_table(results, scenarios)
            rows = results.each_with_index.map do |result, i|
              scenario = scenarios[i]
              status_label = result.status.capitalize
              passed = result.skipped? ? "-" : result.passed_count.to_s
              failed = result.skipped? ? "-" : result.failed_count.to_s
              total = result.skipped? ? "-" : result.total_count.to_s
              "| #{result.test_id} | #{scenario.title} | #{status_label} | #{passed} | #{failed} | #{total} |"
            end

            <<~TABLE
              ## Summary

              | Test ID | Title | Status | Passed | Failed | Total |
              |---------|-------|--------|--------|--------|-------|
              #{rows.join("\n")}
            TABLE
          end

          def build_overall_line(total_passed:, total_tc:)
            pct = (total_tc > 0) ? (total_passed * 100.0 / total_tc).round(0) : 0
            "**Overall:** #{total_passed}/#{total_tc} test cases passed (#{pct}%)\n"
          end

          def build_failed_section(results, scenarios)
            parts = ["\n## Failed Tests\n"]

            results.each_with_index do |result, i|
              next if result.success? || result.skipped?

              scenario = scenarios[i]
              parts << "### #{result.test_id}: #{scenario.title} (#{result.passed_count}/#{result.total_count})\n"

              failed_tcs = result.test_cases.select { |tc| tc[:status] == "fail" }
              if failed_tcs.any?
                parts << "**Failed Test Cases (canonical):**"
                failed_tcs.each do |tc|
                  parts << "- #{tc[:id]}: #{tc[:description]}"
                end
                parts << ""
              end

              if result.report_dir
                parts << "**Report:** #{result.report_dir}\n"
              end
            end

            parts.join("\n")
          end

          def build_reports_section(results, scenarios)
            rows = results.each_with_index.map do |result, i|
              dir = result.report_dir ? File.basename(result.report_dir) : "N/A"
              "| #{result.test_id} | #{dir} |"
            end

            <<~SECTION

              ## Reports

              | Test ID | Reports Folder |
              |---------|----------------|
              #{rows.join("\n")}
            SECTION
          end
        end
      end
    end
  end
end
