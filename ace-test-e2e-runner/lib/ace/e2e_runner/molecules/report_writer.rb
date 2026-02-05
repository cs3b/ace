# frozen_string_literal: true

require "fileutils"
require "time"
require "yaml"

module Ace
  module E2eRunner
    module Molecules
      class ReportWriter
        def initialize(report_dir:, run_id:, agent_name: "ace-e2e-test")
          @report_dir = report_dir
          @run_id = run_id
          @agent_name = agent_name
        end

        def write_all(results, scenarios:, suite_report: false)
          path_builder = Atoms::ReportPathBuilder.new(base_dir: @report_dir)
          report_map = {}

          results.each do |result|
            scenario = scenarios.fetch(result.test_id) { nil }
            paths = path_builder.build(
              test_id: result.test_id,
              package: result.package,
              run_id: @run_id
            )
            report_map[result.test_id] = paths
            write_test_report(result, scenario, paths)
          end

          write_suite_report(results, report_map) if suite_report
          report_map
        end

        private

        def write_test_report(result, scenario, paths)
          FileUtils.mkdir_p(paths[:test_dir])
          FileUtils.mkdir_p(paths[:report_dir])

          summary_content = build_summary_content(result, scenario)
          experience_content = build_experience_content(result, scenario)
          metadata_content = build_metadata_content(result, scenario, paths)

          File.write(paths[:summary_path], summary_content)
          File.write(paths[:experience_path], experience_content)
          File.write(paths[:metadata_path], metadata_content)
        end

        def write_suite_report(results, report_map)
          suite_id = Atoms::RunIdGenerator.new.generate
          suite_path = File.join(@report_dir, "#{suite_id}-final-report.md")

          content = String.new("---\n")
          content << "suite-id: #{suite_id}\n"
          content << "agent: #{@agent_name}\n"
          content << "executed: #{Time.now.utc.iso8601}\n"
          content << "tests-run: #{results.length}\n"
          content << "status: #{results.all?(&:success?) ? "pass" : "fail"}\n"
          content << "---\n\n"
          content << "# E2E Test Suite Report\n\n"
          content << "| Test ID | Package | Status | Report Path |\n"
          content << "|---------|---------|--------|-------------|\n"
          results.each do |result|
            report_dir = report_map.dig(result.test_id, :report_dir) || "-"
            content << "| #{result.test_id} | #{result.package || "-"} | #{result.status} | #{report_dir} |\n"
          end

          File.write(suite_path, content)
        end

        def build_summary_content(result, scenario)
          executed_at = Time.now.utc.iso8601
          frontmatter = String.new("---\n")
          frontmatter << "test-id: #{result.test_id}\n"
          frontmatter << "package: #{result.package}\n" if result.package
          frontmatter << "agent: #{@agent_name}\n"
          frontmatter << "executed: #{executed_at}\n"
          frontmatter << "status: #{result.status}\n"
          frontmatter << "passed: #{count_passed(result)}\n"
          frontmatter << "failed: #{count_failed(result)}\n"
          frontmatter << "total: #{count_total(result)}\n"
          frontmatter << "---\n\n"

          content = frontmatter
          content << "# E2E Test Report: #{result.test_id}\n\n"
          content << "## Test Information\n\n"
          content << "| Field | Value |\n"
          content << "|-------|-------|\n"
          content << "| Test ID | #{result.test_id} |\n"
          content << "| Title | #{scenario&.title || "Unknown"} |\n"
          content << "| Package | #{result.package || "-"} |\n"
          content << "| Agent | #{@agent_name} |\n"
          content << "| Executed | #{executed_at} |\n"
          content << "| Duration | #{format_duration(result.duration)} |\n"
          if scenario&.frontmatter && scenario.frontmatter.any?
            content << "| Priority | #{scenario.frontmatter["priority"] || "-"} |\n"
            content << "| Expected Duration | #{scenario.frontmatter["duration"] || "-"} |\n"
          end
          content << "\n## Results Summary\n\n"

          if result.test_cases && result.test_cases.is_a?(Array) && result.test_cases.any?
            content << "| Test Case | Status | Notes |\n"
            content << "|-----------|--------|-------|\n"
            result.test_cases.each do |test_case|
              content << "| #{test_case["id"] || "TC"} | #{test_case["status"] || "-"} | #{test_case["notes"] || "-"} |\n"
            end
          else
            content << "No structured test cases reported.\n"
          end

          if result.summary
            content << "\n## Summary\n\n#{result.summary}\n"
          end

          if result.error_message
            content << "\n## Error\n\n#{result.error_message}\n"
          end

          content
        end

        def build_experience_content(result, scenario)
          executed_at = Time.now.utc.iso8601
          frontmatter = String.new("---\n")
          frontmatter << "test-id: #{result.test_id}\n"
          frontmatter << "test-title: #{scenario&.title || "Unknown"}\n"
          frontmatter << "package: #{result.package}\n" if result.package
          frontmatter << "agent: #{@agent_name}\n"
          frontmatter << "executed: #{executed_at}\n"
          frontmatter << "status: #{result.status == "pass" ? "complete" : "partial"}\n"
          frontmatter << "---\n\n"

          content = frontmatter
          content << "# Agent Experience Report: #{result.test_id}\n\n"
          content << "## Summary\n"
          content << "No significant friction encountered.\n\n"
          content << "## Friction Points\n\n"
          content << "### Documentation Gaps\n- None\n\n"
          content << "### Tool Behavior Issues\n- None\n\n"
          content << "### API/CLI Friction\n- None\n\n"
          content << "## Root Cause Analysis\n"
          content << "N/A\n\n"
          content << "## Improvement Suggestions\n"
          content << "- [ ] None\n\n"
          content << "## Workarounds Used\n- None\n\n"
          content << "## Positive Observations\n- Execution completed with expected output.\n"
          content
        end

        def build_metadata_content(result, scenario, paths)
          started = Time.now.utc.iso8601
          completed = Time.now.utc.iso8601
          duration = result.duration ? "#{result.duration.round(2)}s" : "-"

          content = String.new("")
          content << "run-id: \"#{paths[:run_id]}\"\n"
          content << "test-id: \"#{result.test_id}\"\n"
          content << "package: \"#{result.package}\"\n" if result.package
          content << "agent: \"#{@agent_name}\"\n"
          content << "started: \"#{started}\"\n"
          content << "completed: \"#{completed}\"\n"
          content << "duration: \"#{duration}\"\n"
          content << "status: \"#{result.status}\"\n"
          content << "results:\n"
          content << "  passed: #{count_passed(result)}\n"
          content << "  failed: #{count_failed(result)}\n"
          content << "  total: #{count_total(result)}\n"
          content << "git:\n"
          content << "  branch: \"#{current_branch}\"\n"
          content << "  commit: \"#{current_commit}\"\n"
          content << "tools:\n"
          content << "  ruby: \"#{ruby_version}\"\n"
          content
        end

        def count_passed(result)
          return result.test_cases.count { |c| c["status"] == "pass" } if result.test_cases.is_a?(Array)
          result.status == "pass" ? 1 : 0
        end

        def count_failed(result)
          return result.test_cases.count { |c| c["status"] == "fail" } if result.test_cases.is_a?(Array)
          result.status == "fail" ? 1 : 0
        end

        def count_total(result)
          return result.test_cases.length if result.test_cases.is_a?(Array)
          1
        end

        def current_branch
          branch = `git symbolic-ref --short HEAD 2>/dev/null`.strip
          branch.empty? ? "detached-HEAD" : branch
        rescue StandardError
          "detached-HEAD"
        end

        def current_commit
          `git rev-parse --short HEAD`.strip
        rescue StandardError
          "unknown"
        end

        def ruby_version
          `ruby --version`.split[1]
        rescue StandardError
          "unknown"
        end

        def format_duration(duration)
          return "-" unless duration
          "#{duration.round(2)}s"
        end
      end
    end
  end
end
