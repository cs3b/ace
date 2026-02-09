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
          # @return [Hash] Paths to written report files
          def write(result, scenario, report_dir:)
            FileUtils.mkdir_p(report_dir)

            summary_path = write_summary(result, scenario, report_dir)
            experience_path = write_experience(result, scenario, report_dir)
            metadata_path = write_metadata(result, scenario, report_dir)

            {
              summary: summary_path,
              experience: experience_path,
              metadata: metadata_path
            }
          end

          private

          # Write summary report
          # @return [String] Path to written file
          def write_summary(result, scenario, report_dir)
            path = File.join(report_dir, "summary.r.md")

            tc_rows = result.test_cases.map do |tc|
              "| #{tc[:id]} | #{tc[:description]} | #{tc[:status].capitalize} |"
            end.join("\n")

            content = <<~REPORT
              ---
              test-id: #{result.test_id}
              package: #{scenario.package}
              agent: ace-test-e2e
              executed: #{result.completed_at.utc.strftime('%Y-%m-%dT%H:%M:%SZ')}
              status: #{result.status}
              passed: #{result.passed_count}
              failed: #{result.failed_count}
              total: #{result.total_count}
              ---

              # E2E Test Report: #{result.test_id}

              ## Test Information

              | Field | Value |
              |-------|-------|
              | Test ID | #{result.test_id} |
              | Title | #{scenario.title} |
              | Package | #{scenario.package} |
              | Agent | ace-test-e2e |
              | Executed | #{result.completed_at.utc.strftime('%Y-%m-%dT%H:%M:%SZ')} |
              | Duration | #{result.duration_display} |

              ## Results Summary

              | Test Case | Description | Status |
              |-----------|-------------|--------|
              #{tc_rows}

              ## Overall Status: #{result.status.upcase}

              #{result.summary}
              #{"## Error\n\n#{result.error}" if result.error}
            REPORT

            File.write(path, content)
            path
          end

          # Write experience report
          # @return [String] Path to written file
          def write_experience(result, scenario, report_dir)
            path = File.join(report_dir, "experience.r.md")

            content = <<~REPORT
              ---
              test-id: #{result.test_id}
              test-title: #{scenario.title}
              package: #{scenario.package}
              agent: ace-test-e2e
              executed: #{result.completed_at.utc.strftime('%Y-%m-%dT%H:%M:%SZ')}
              status: #{result.status == "error" ? "incomplete" : "complete"}
              ---

              # Agent Experience Report: #{result.test_id}

              ## Summary

              Executed via ace-test-e2e CLI using LLM provider.
              #{result.status == "pass" ? "No significant friction encountered." : "Test execution completed with issues noted below."}

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
          def write_metadata(result, scenario, report_dir)
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
              "results" => {
                "passed" => result.passed_count,
                "failed" => result.failed_count,
                "total" => result.total_count
              },
              "failed_test_cases" => result.failed_test_case_ids
            }

            File.write(path, YAML.dump(metadata))
            path
          end
        end
      end
    end
  end
end
