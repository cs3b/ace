# frozen_string_literal: true

require "fileutils"
require "ostruct"
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
            results_data = build_results_data(results, scenarios)
            narrative_sections = synthesize_narrative_sections(
              results_data,
              package: package,
              timestamp: timestamp,
              overall_status: overall_status,
              executed_at: executed_at
            )
            content = build_report(
              results_data,
              package: package,
              timestamp: timestamp,
              overall_status: overall_status,
              executed_at: executed_at,
              narrative_sections: narrative_sections
            )

            File.write(report_path, content)
            report_path
          end

          private

          # Attempt LLM synthesis for narrative sections only, falling back to
          # deterministic defaults when the model is unavailable or malformed.
          def synthesize_narrative_sections(results_data, package:, timestamp:, overall_status:, executed_at:)
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
            extract_narrative_sections(response[:text])
          rescue => e
            warn "Warning: LLM synthesis failed (#{e.class}: #{e.message}), using deterministic narrative" if ENV["DEBUG"]
            fallback_narrative_sections(results_data)
          end

          # Read summary and experience report content from each result's report dir
          def build_results_data(results, scenarios)
            results.each_with_index.map do |result, i|
              scenario = scenario_for_result(result, scenarios, i)
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

          def build_report(results_data, package:, timestamp:, overall_status:, executed_at:, narrative_sections:)
            total_skipped = results_data.count { |r| r[:status] == "skip" }
            total_passed = results_data.sum { |r| r[:passed] }
            total_tc = results_data.sum { |r| r[:total] }

            parts = []
            parts << build_frontmatter(
              timestamp: timestamp, package: package, overall_status: overall_status,
              tests_run: results_data.size, executed_at: executed_at, skipped: total_skipped
            )
            parts << build_header(package: package)
            parts << build_summary_table(results_data)
            parts << build_overall_line(total_passed: total_passed, total_tc: total_tc)
            parts << build_failed_section(results_data) if results_data.any? { |r| r[:failed].positive? }
            parts << build_narrative_section("Friction Analysis", narrative_sections[:friction])
            parts << build_narrative_section("Improvement Suggestions", narrative_sections[:improvements])
            parts << build_narrative_section("Positive Observations", narrative_sections[:positive])
            parts << build_reports_section(results_data)
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

          def build_header(package:)
            <<~HEADER
              # E2E Suite Report: `#{package}`
            HEADER
          end

          def build_summary_table(results_data)
            rows = results_data.map do |result|
              status_label = result[:status].capitalize
              passed = (result[:status] == "skip") ? "-" : result[:passed].to_s
              failed = (result[:status] == "skip") ? "-" : result[:failed].to_s
              total = (result[:status] == "skip") ? "-" : result[:total].to_s
              "| #{result[:test_id]} | #{result[:title]} | #{status_label} | #{passed} | #{failed} | #{total} |"
            end

            <<~TABLE
              ## Summary Table

              | Test ID | Title | Status | Passed | Failed | Total |
              |---|---|---:|---:|---:|---:|
              #{rows.join("\n")}
            TABLE
          end

          def build_overall_line(total_passed:, total_tc:)
            pct = (total_tc > 0) ? (total_passed * 100.0 / total_tc).round(1) : 0.0
            formatted_pct = (pct % 1).zero? ? pct.to_i.to_s : format("%.1f", pct)
            <<~OVERALL
              ## Overall Line

              **Overall:** #{total_passed}/#{total_tc} test cases passed (#{formatted_pct}%)
            OVERALL
          end

          def build_failed_section(results_data)
            parts = ["\n## Failed Tests\n"]

            results_data.each do |result|
              next unless result[:failed].positive?

              parts << "### #{result[:test_id]}"
              parts << ""
              parts << "**Failed test case details**"

              failed_tcs = result[:test_cases].select { |tc| tc[:status] == "fail" }
              if failed_tcs.any?
                failed_tcs.each do |tc|
                  category = tc[:category] || "runner-error"
                  details = tc[:notes].to_s.strip
                  details = tc[:description].to_s if details.empty?
                  parts << "- `#{tc[:id]}` (#{category}) — #{details}"
                end
              end

              if result[:report_dir_name]
                parts << ""
                parts << "**Report directory:** `#{result[:report_dir_name]}`"
              end
              parts << ""
            end

            parts.join("\n")
          end

          def build_narrative_section(title, content)
            return nil if content.to_s.strip.empty?

            <<~SECTION
              ## #{title}

              #{content.to_s.strip}
            SECTION
          end

          def build_reports_section(results_data)
            rows = results_data.map do |result|
              dir = result[:report_dir_name] || "N/A"
              "| #{result[:test_id]} | `#{dir}` |"
            end

            <<~SECTION

              ## Reports Table

              | Test ID | Report Directory |
              |---|---|
              #{rows.join("\n")}
            SECTION
          end

          def extract_narrative_sections(report_text)
            text = report_text.to_s
            sections = {
              friction: extract_markdown_section(text, "Friction Analysis"),
              improvements: extract_markdown_section(text, "Improvement Suggestions"),
              positive: extract_markdown_section(text, "Positive Observations")
            }

            fallback = strip_canonical_sections(text)
            has_markdown_sections = text.match?(/^\#{2,3}\s+/)
            sections[:positive] = fallback if sections.values.all? { |value| value.to_s.strip.empty? } &&
              !fallback.empty? && !has_markdown_sections
            sections
          end

          def extract_markdown_section(text, heading)
            match = text.match(/^\#{2,3}\s+#{Regexp.escape(heading)}\s*$\n?(.*?)(?=^\#{1,3}\s|\z)/mi)
            return "" unless match

            match[1].to_s.strip
          end

          def strip_canonical_sections(text)
            body = text.to_s.dup
            body.sub!(/\A---.*?^---\s*/m, "")
            body.gsub!(/^\#{1,3}\s+.*$/, "")
            body.gsub!(/^\|.*\|\s*$/, "")
            body.gsub!(/^\*\*Overall:\*\*.*$/, "")
            body.lines.map(&:rstrip).reject(&:empty?).join("\n").strip
          end

          def fallback_narrative_sections(results_data)
            failed_results = results_data.select { |result| result[:failed].positive? }

            {
              friction: failed_results.empty? ? "" : failed_results.map { |result|
                "- #{result[:test_id]} had #{result[:failed]} failing test case(s); inspect `#{result[:report_dir_name]}` for scenario details."
              }.join("\n"),
              improvements: failed_results.empty? ? "" : failed_results.map { |result|
                "- Re-run #{result[:test_id]} after the targeted fix and confirm the failing test case set is empty."
              }.join("\n"),
              positive: results_data.select { |result| result[:failed].zero? }.map { |result|
                "- #{result[:test_id]} passed #{result[:passed]}/#{result[:total]} test cases."
              }.join("\n")
            }
          end

          def scenario_for_result(result, scenarios, index)
            scenarios[index] || OpenStruct.new(
              title: result.metadata[:phase] == "preflight" || result.metadata["phase"] == "preflight" ? "Preflight" : result.test_id
            )
          end
        end
      end
    end
  end
end
