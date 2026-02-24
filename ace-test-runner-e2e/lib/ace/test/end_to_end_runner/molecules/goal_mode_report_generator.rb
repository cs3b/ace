# frozen_string_literal: true

require "fileutils"
require "yaml"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Generates TC-first reports from standalone goal-mode verifier output.
        class GoalModeReportGenerator
          FAILURE_CATEGORIES = %w[test-spec-error tool-bug runner-error infrastructure-error].freeze

          # @param report_writer [Molecules::ReportWriter]
          def initialize(report_writer: nil)
            @report_writer = report_writer || Molecules::ReportWriter.new
          end

          # @param scenario [Models::TestScenario]
          # @param verifier_output [String]
          # @param report_dir [String]
          # @param provider [String]
          # @param started_at [Time]
          # @param completed_at [Time]
          # @return [Models::TestResult]
          def generate(scenario:, verifier_output:, report_dir:, provider:, started_at:, completed_at:)
            parsed = parse_verifier_output(verifier_output, scenario)

            result = Models::TestResult.new(
              test_id: scenario.test_id,
              status: parsed[:status],
              test_cases: parsed[:test_cases],
              summary: parsed[:summary],
              started_at: started_at,
              completed_at: completed_at
            )

            FileUtils.mkdir_p(report_dir)
            @report_writer.write(result, scenario, report_dir: report_dir)
            write_goal_report(
              path: File.join(report_dir, "report.md"),
              scenario: scenario,
              provider: provider,
              result: result
            )
            result.with_report_dir(report_dir)
          end

          private

          def parse_verifier_output(text, scenario)
            goals = parse_goal_sections(text, scenario)
            return build_result_from_goals(goals) unless goals.empty?

            parsed = Atoms::SkillResultParser.parse_verifier(text)
            {
              status: parsed[:status],
              test_cases: parsed[:test_cases],
              summary: parsed[:summary]
            }
          end

          def parse_goal_sections(text, scenario)
            lines = text.to_s.lines
            headers = []
            lines.each_with_index do |line, idx|
              match = line.match(/^###\s+Goal\s+(\d+)\s+[—-]\s*(.+?)\s*$/)
              headers << [idx, match[1].to_i, match[2].strip] if match
            end
            return [] if headers.empty?

            headers.each_with_index.map do |(start_idx, goal_number, title), index|
              end_idx = index + 1 < headers.size ? headers[index + 1][0] : lines.size
              block = lines[start_idx...end_idx].join

              verdict = extract_value(block, "Verdict")&.upcase
              evidence = extract_value(block, "Evidence") || ""
              next if verdict.nil?

              tc_id = scenario.test_cases[goal_number - 1]&.tc_id || format("TC-%03d", goal_number)
              category = extract_category(block, evidence)

              {
                id: tc_id,
                description: title,
                status: verdict == "PASS" ? "pass" : "fail",
                notes: evidence,
                category: (verdict == "FAIL" ? category : nil)
              }
            end.compact
          end

          def extract_value(block, field)
            match = block.match(/- \*\*#{Regexp.escape(field)}\*\*:\s*(.+?)\s*$/i)
            return nil unless match

            match[1].strip
          end

          def extract_category(block, evidence)
            explicit = extract_value(block, "Category")
            return normalize_category(explicit) if explicit

            inferred = FAILURE_CATEGORIES.find do |name|
              block.to_s.downcase.include?(name) || evidence.to_s.downcase.include?(name)
            end
            inferred || "runner-error"
          end

          def normalize_category(value)
            category = value.to_s.strip.downcase
            return category if FAILURE_CATEGORIES.include?(category)

            "runner-error"
          end

          def build_result_from_goals(goals)
            passed = goals.count { |goal| goal[:status] == "pass" }
            total = goals.size
            status = if passed == total
              "pass"
            elsif passed.zero?
              "fail"
            else
              "partial"
            end

            {
              status: status,
              test_cases: goals,
              summary: "#{passed}/#{total} passed"
            }
          end

          def write_goal_report(path:, scenario:, provider:, result:)
            passed = result.passed_count
            failed = result.failed_count
            total = result.total_count
            score = total.zero? ? 0.0 : (passed.to_f / total).round(3)
            verdict = if failed.zero?
              "pass"
            elsif passed.zero?
              "fail"
            else
              "partial"
            end

            frontmatter = {
              "test-id" => scenario.test_id,
              "title" => scenario.title,
              "package" => scenario.package,
              "runner-provider" => provider,
              "verifier-provider" => provider,
              "timestamp" => result.completed_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
              "tcs-passed" => passed,
              "tcs-failed" => failed,
              "tcs-total" => total,
              "score" => score,
              "verdict" => verdict,
              "passed" => result.test_cases.select { |tc| tc[:status] == "pass" }.map { |tc| tc[:id] },
              "failed" => result.test_cases.select { |tc| tc[:status] == "fail" }.map do |tc|
                {
                  "tc" => tc[:id],
                  "category" => tc[:category] || "runner-error",
                  "evidence" => tc[:notes].to_s
                }
              end
            }
            frontmatter_yaml = YAML.dump(frontmatter).sub(/\A---\s*\n/, "").sub(/\.\.\.\s*\n\z/, "")

            rows = result.test_cases.map do |tc|
              "| #{tc[:id]} | #{tc[:status].upcase} | #{tc[:notes]} |"
            end.join("\n")

            content = <<~REPORT
              ---
              #{frontmatter_yaml.rstrip}
              ---

              # E2E Report: #{scenario.title}

              ## Goal Results

              | Goal | Verdict | Evidence |
              |------|---------|----------|
              #{rows}

              ## Summary

              | Metric | Value |
              |--------|-------|
              | Passed | #{passed} |
              | Failed | #{failed} |
              | Total  | #{total} |
              | Score  | #{(score * 100).round(1)}% |
            REPORT

            File.write(path, content)
          end
        end
      end
    end
  end
end
