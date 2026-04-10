# frozen_string_literal: true

require "fileutils"
require "yaml"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Generates TC-first reports from standalone verifier output.
        class PipelineReportGenerator
          FAILURE_CATEGORIES = %w[test-spec-error tool-bug runner-error infrastructure-error].freeze

          # @param report_writer [Molecules::ReportWriter]
          def initialize(report_writer: nil)
            @report_writer = report_writer || Molecules::ReportWriter.new
          end

          # @param scenario [Models::TestScenario]
          # @param verifier_output [String]
          # @param report_dir [String]
          # @param provider [String]
          # @param runner_provider [String]
          # @param verifier_provider [String]
          # @param started_at [Time]
          # @param completed_at [Time]
          # @return [Models::TestResult]
          def generate(scenario:, verifier_output:, report_dir:, provider: nil, runner_provider: nil,
            verifier_provider: nil, started_at:, completed_at:)
            resolved_runner_provider = runner_provider || provider
            resolved_verifier_provider = verifier_provider || provider || resolved_runner_provider
            parsed = parse_verifier_output(verifier_output, scenario)

            result = Models::TestResult.new(
              test_id: scenario.test_id,
              status: parsed[:status],
              test_cases: parsed[:test_cases],
              summary: parsed[:summary],
              error: parsed[:error],
              started_at: started_at,
              completed_at: completed_at
            )

            FileUtils.mkdir_p(report_dir)
            @report_writer.write(result, scenario, report_dir: report_dir)
            write_goal_report(
              path: File.join(report_dir, "report.md"),
              scenario: scenario,
              runner_provider: resolved_runner_provider,
              verifier_provider: resolved_verifier_provider,
              result: result
            )
            result.with_report_dir(report_dir)
          end

          # Write deterministic error reports when pipeline execution fails before
          # normal verifier parsing/report generation can complete.
          #
          # @param scenario [Models::TestScenario]
          # @param report_dir [String]
          # @param provider [String]
          # @param runner_provider [String]
          # @param verifier_provider [String]
          # @param started_at [Time]
          # @param completed_at [Time]
          # @param error_message [String]
          # @return [Models::TestResult]
          def write_failure_report(scenario:, report_dir:, provider: nil, runner_provider: nil,
            verifier_provider: nil, started_at:, completed_at:, error_message:)
            resolved_runner_provider = runner_provider || provider
            resolved_verifier_provider = verifier_provider || provider || resolved_runner_provider
            result = Models::TestResult.new(
              test_id: scenario.test_id,
              status: "error",
              test_cases: [],
              summary: "Execution pipeline failed",
              error: error_message,
              started_at: started_at,
              completed_at: completed_at
            )

            FileUtils.mkdir_p(report_dir)
            @report_writer.write(result, scenario, report_dir: report_dir)
            write_goal_report(
              path: File.join(report_dir, "report.md"),
              scenario: scenario,
              runner_provider: resolved_runner_provider,
              verifier_provider: resolved_verifier_provider,
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
              summary: parsed[:summary],
              error: parsed[:observations]
            }
          rescue Atoms::ResultParser::ParseError => e
            issue = summarize_unstructured_verifier_output(text)
            {
              status: "error",
              test_cases: [],
              summary: "Verifier returned unstructured output",
              error: issue || e.message
            }
          end

          def parse_goal_sections(text, scenario)
            lines = text.to_s.lines
            headers = []
            lines.each_with_index do |line, idx|
              match = line.match(/^\#{2,3}\s+Goal\s+(\d+)\s*[—-]\s*(.+?)\s*$/i)
              headers << [idx, match[1].to_i, match[2].strip] if match
            end
            return [] if headers.empty?

            scenario_test_cases = scenario.test_cases || []

            headers.each_with_index.map do |(start_idx, goal_number, title), index|
              end_idx = (index + 1 < headers.size) ? headers[index + 1][0] : lines.size
              block = lines[start_idx...end_idx].join

              verdict = normalize_verdict(extract_field_token(block, %w[Verdict Status]))
              evidence = extract_evidence(block)
              next if verdict.nil?

              tc_id = scenario_test_cases[goal_number - 1]&.tc_id || format("TC-%03d", goal_number)
              category = extract_category(block, evidence)

              {
                id: tc_id,
                description: title,
                status: (verdict == "PASS") ? "pass" : "fail",
                notes: evidence,
                category: ((verdict == "FAIL") ? category : nil)
              }
            end.compact
          end

          def extract_value(block, field)
            match = block.match(/^\s*[-*]?\s*\*\*#{Regexp.escape(field)}\*\*:\s*(.+?)\s*$/im)
            return nil unless match

            match[1].strip
          end

          def extract_evidence(block)
            lines = block.to_s.lines
            marker_index = nil
            inline_value = nil

            lines.each_with_index do |line, idx|
              match = line.match(/^\s*[-*]?\s*\*\*Evidence(?:\s+of\s+failure)?\*\*:\s*(.*)$/i)
              next unless match

              marker_index = idx
              inline_value = match[1].to_s.strip
              break
            end

            return inline_value unless marker_index

            collected = []
            collected << inline_value unless inline_value.empty?

            lines[(marker_index + 1)..]&.each do |line|
              break if line.match?(/^\s*[-*]?\s*\*\*(Category|Verdict)\*\*:/i)
              break if line.match?(/^\#{2,3}\s+Goal\s+\d+/i)
              break if line.match?(/^\s*\*\*Results/i)
              break if line.strip == "---"

              text = line.rstrip
              next if text.strip.empty?

              text = text.sub(/^\s*[-*]\s+/, "")
              collected << text.strip
            end

            collected.join(" ").strip
          end

          def extract_category(block, evidence)
            explicit = extract_field_token(block, %w[Category])
            return normalize_category(explicit) if explicit

            inline = block.to_s.match(/`(test-spec-error|tool-bug|runner-error|infrastructure-error)`/i)
            return normalize_category(inline[1]) if inline

            paren = block.to_s.match(/\((test-spec-error|tool-bug|runner-error|infrastructure-error)\)/i)
            return normalize_category(paren[1]) if paren

            normalize_category("#{block}\n#{evidence}")
          end

          def normalize_category(value)
            category = value.to_s.strip.downcase
            match = category.match(/\b(test-spec-error|tool-bug|runner-error|infrastructure-error)\b/)
            return match[1] if match

            "runner-error"
          end

          def normalize_verdict(value)
            raw = value.to_s.strip
            return nil if raw.empty?

            token = raw.gsub(/[*_`]/, "").upcase.match(/\b(PASS|FAIL)\b/)
            return token[1] if token

            nil
          end

          def extract_field_token(block, fields)
            fields.each do |field|
              direct = extract_value(block, field)
              return direct if direct && !direct.empty?

              bold_inline = block.match(/\*\*#{Regexp.escape(field)}\s*:\s*([^*\n]+)\*\*/i)
              return bold_inline[1].strip if bold_inline

              plain = block.match(/^\s*(?:[-*]\s+)?#{Regexp.escape(field)}\s*:\s*(.+?)\s*$/im)
              return plain[1].strip if plain
            end

            nil
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

          def summarize_unstructured_verifier_output(text)
            summary = text.to_s.lines.map(&:strip).reject(&:empty?).first(3).join(" ")
            return nil if summary.empty?

            (summary.length > 240) ? "#{summary[0, 237]}..." : summary
          end

          def write_goal_report(path:, scenario:, runner_provider:, verifier_provider:, result:)
            passed = result.passed_count
            failed = result.failed_count
            total = result.total_count
            score = total.zero? ? 0.0 : (passed.to_f / total).round(3)
            verdict = if result.status == "error"
              "fail"
            elsif failed.zero?
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
              "runner-provider" => runner_provider,
              "verifier-provider" => verifier_provider,
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
