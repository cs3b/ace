# frozen_string_literal: true

require "fileutils"
require "yaml"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Writes E2E test reports to disk
        #
        # Generates summary, experience, and metadata reports following
        # the standard report path contract.
        class ReportWriter
          # Write all reports for a test result
          #
          # @param result [Models::TestResult] The test result
          # @param scenario [Models::TestScenario] The test scenario
          # @param report_dir [String] Directory to write reports to
          # @param test_case [Models::TestCase, nil] Optional single test case for TC-level reports
          # @return [Hash] Paths to written report files
          def write(result, scenario, report_dir:, test_case: nil)
            FileUtils.mkdir_p(report_dir)

            summary_path = write_summary(result, scenario, report_dir, test_case)
            experience_path = write_experience(result, scenario, report_dir, test_case)
            metadata_path = write_metadata(result, scenario, report_dir, test_case)

            {
              summary: summary_path,
              experience: experience_path,
              metadata: metadata_path
            }
          end

          private

          # Write summary report
          # @return [String] Path to written file
          def write_summary(result, scenario, report_dir, test_case = nil)
            path = File.join(report_dir, "summary.r.md")

            tc_rows = result.test_cases.map do |tc|
              "| #{tc[:id]} | #{tc[:description]} | #{tc[:status].capitalize} |"
            end.join("\n")

            goal_criteria_sections = build_goal_criteria_sections(result.test_cases)
            failed_entries = result.test_cases
              .select { |tc| tc[:status] == "fail" }
              .map do |tc|
                {
                  "tc" => tc[:id],
                  "category" => tc[:category] || "runner-error",
                  "evidence" => tc[:notes].to_s
                }
            end
            verdict = if result.failed_count.zero?
              (result.status == "error") ? "fail" : "pass"
            elsif result.passed_count.zero?
              "fail"
            else
              "partial"
            end
            score = result.total_count.zero? ? 0.0 : (result.passed_count.to_f / result.total_count).round(3)

            frontmatter_hash = {
              "test-id" => result.test_id
            }
            if test_case
              frontmatter_hash["tc-id"] = test_case.tc_id
              frontmatter_hash["scenario-id"] = scenario.test_id
            end
            frontmatter_hash.merge!(
              "package" => scenario.package,
              "agent" => "ace-test-e2e",
              "executed" => result.completed_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
              "status" => result.status,
              "tcs-passed" => result.passed_count,
              "tcs-failed" => result.failed_count,
              "tcs-total" => result.total_count,
              "score" => score,
              "verdict" => verdict,
              "failed" => failed_entries
            )
            frontmatter_yaml = YAML.dump(frontmatter_hash).sub(/\A---\s*\n/, "").sub(/\.\.\.\s*\n\z/, "")

            tc_info_rows = if test_case
              "| TC ID | #{test_case.tc_id} |\n| TC Title | #{test_case.title} |\n"
            else
              ""
            end

            content = <<~REPORT
              ---
              #{frontmatter_yaml.rstrip}
              ---

              # E2E Test Report: #{result.test_id}

              ## Test Information

              | Field | Value |
              |-------|-------|
              | Test ID | #{result.test_id} |
              #{tc_info_rows}| Title | #{scenario.title} |
              | Package | #{scenario.package} |
              | Agent | ace-test-e2e |
              | Executed | #{result.completed_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ")} |
              | Duration | #{result.duration_display} |

              ## Results Summary

              | Test Case | Description | Status |
              |-----------|-------------|--------|
              #{tc_rows}

              ## Overall Status: #{result.status.upcase}

              #{goal_criteria_sections}

              #{result.summary}
              #{"## Error\n\n#{result.error}" if result.error}
            REPORT

            File.write(path, content)
            path
          end

          # Write experience report
          # @return [String] Path to written file
          def write_experience(result, scenario, report_dir, test_case = nil)
            path = File.join(report_dir, "experience.r.md")

            tc_title_suffix = test_case ? " / #{test_case.tc_id}" : ""

            exp_frontmatter_lines = [
              "test-id: #{result.test_id}"
            ]
            exp_frontmatter_lines << "tc-id: #{test_case.tc_id}" if test_case
            exp_frontmatter_lines.concat([
              "test-title: #{scenario.title}",
              "package: #{scenario.package}",
              "agent: ace-test-e2e",
              "executed: #{result.completed_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ")}",
              "status: #{(result.status == "pass") ? "complete" : "incomplete"}"
            ])

            content = <<~REPORT
              ---
              #{exp_frontmatter_lines.join("\n")}
              ---

              # Agent Experience Report: #{result.test_id}#{tc_title_suffix}

              ## Summary

              Executed via ace-test-e2e CLI using LLM provider.
              #{(result.status == "pass") ? "No significant friction encountered." : "Test execution completed with issues noted below."}

              ## Friction Points

              ### Documentation Gaps

              - Automated execution via LLM - no documentation gaps observed

              ### Tool Behavior Issues

              - #{result.error || "None observed"}

              ## Positive Observations

              - Automated test execution completed successfully via LLM
            REPORT

            File.write(path, content)
            path
          end

          # Write metadata file
          # @return [String] Path to written file
          def write_metadata(result, scenario, report_dir, test_case = nil)
            path = File.join(report_dir, "metadata.yml")

            metadata = {
              "run-id" => File.basename(report_dir).sub(/-reports\z/, ""),
              "test-id" => result.test_id,
              "package" => scenario.package,
              "agent" => "ace-test-e2e",
              "started" => result.started_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
              "completed" => result.completed_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
              "duration" => "#{result.duration.round(0)}s",
              "status" => result.status,
              "score" => (result.total_count.zero? ? 0.0 : (result.passed_count.to_f / result.total_count).round(3)),
              "verdict" => (if result.status == "error"
                              "fail"
                            else
                              (if result.failed_count.zero?
                                 "pass"
                               else
                                 (result.passed_count.zero? ? "fail" : "partial")
                               end)
                            end),
              "tcs-passed" => result.passed_count,
              "tcs-failed" => result.failed_count,
              "tcs-total" => result.total_count,
              "results" => {
                "passed" => result.passed_count,
                "failed" => result.failed_count,
                "total" => result.total_count
              },
              "failed" => result.test_cases
                .select { |tc| tc[:status] == "fail" }
                .map do |tc|
                  {
                    "tc" => tc[:id],
                    "category" => tc[:category] || "runner-error",
                    "evidence" => tc[:notes].to_s
                  }
              end,
              "failed_test_cases" => result.failed_test_case_ids
            }

            if test_case
              metadata["scenario-id"] = scenario.test_id
              metadata["tc-id"] = test_case.tc_id
            end

            File.write(path, YAML.dump(metadata))
            path
          end

          def build_goal_criteria_sections(test_cases)
            sections = test_cases.filter_map do |tc|
              criteria = tc[:criteria]
              next if criteria.nil? || criteria.empty?

              rows = criteria.map do |criterion|
                desc = criterion[:description].to_s.empty? ? criterion[:id] : criterion[:description]
                "| #{desc} | #{criterion[:status].to_s.upcase} | #{criterion[:evidence]} |"
              end.join("\n")

              <<~SECTION
                ### Goal Criteria: #{tc[:id]}

                | Criterion | Status | Evidence |
                |-----------|--------|----------|
                #{rows}
              SECTION
            end

            return "" if sections.empty?

            "## Goal Evaluation\n\n#{sections.join("\n")}"
          end
        end
      end
    end
  end
end
