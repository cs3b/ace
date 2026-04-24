# frozen_string_literal: true

require "fileutils"
require "ostruct"
require "yaml"
require "set"
require "date"
require "ace/llm"
require "ace/llm/query_interface"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Writes an aggregated package or suite report
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

          REPORT_KINDS = {
            package: ->(timestamp, package) { "#{timestamp}-#{package}-report.md" },
            suite: ->(timestamp, _package) { "#{timestamp}-suite-report.md" },
            suite_final: ->(timestamp, _package) { "#{timestamp}-suite-final-report.md" }
          }.freeze

          # Write an aggregated report
          #
          # @param results [Array<Models::TestResult>] Test results (ordered)
          # @param scenarios [Array<Models::TestScenario>] Corresponding scenarios
          # @param package [String] Package name (e.g., "ace-lint")
          # @param timestamp [String] Timestamp ID for this run
          # @param base_dir [String] Base directory for cache output
          # @return [String] Path to the written report file
          def write(results, scenarios, package:, timestamp:, base_dir:, report_kind: :package, diagnostics: nil)
            cache_dir = File.join(base_dir, ".ace-local", "test-e2e")
            FileUtils.mkdir_p(cache_dir)

            report_path = File.join(cache_dir, report_filename(report_kind, timestamp, package))

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
              narrative_sections: narrative_sections,
              diagnostics: diagnostics
            )

            File.write(report_path, content)
            report_path
          end

          # Write a deterministic wrapper report for a two-attempt suite run.
          #
          # Preserves first-pass failure evidence while reflecting the final retry outcome.
          def write_retry_summary(initial_results:, retry_results:, timestamp:, base_dir:, package: "suite")
            cache_dir = File.join(base_dir, ".ace-local", "test-e2e")
            FileUtils.mkdir_p(cache_dir)

            report_path = File.join(cache_dir, report_filename(:suite_final, timestamp, package))
            initial_entries = flatten_attempt_results(initial_results, base_dir: base_dir)
            retry_entries = flatten_attempt_results(retry_results, base_dir: base_dir)
            retry_by_test = retry_entries.each_with_object({}) { |entry, memo| memo[entry[:test_id]] = entry }

            flaky_entries = initial_entries.filter_map do |entry|
              next if entry[:status] == "pass"

              retry_entry = retry_by_test[entry[:test_id]]
              next unless retry_entry && retry_entry[:status] == "pass"

              entry.merge(retry_entry: retry_entry)
            end.sort_by { |entry| entry[:test_id] }
            remaining_entries = retry_entries.reject { |entry| entry[:status] == "pass" }.sort_by { |entry| entry[:test_id] }
            final_status = compute_retry_summary_status(retry_entries)

            content = build_retry_summary_content(
              timestamp: timestamp,
              initial_results: initial_results,
              retry_results: retry_results,
              initial_entries: initial_entries,
              flaky_entries: flaky_entries,
              remaining_entries: remaining_entries,
              final_status: final_status,
              base_dir: base_dir
            )

            File.write(report_path, content)
            report_path
          end

          private

          def report_filename(report_kind, timestamp, package)
            builder = REPORT_KINDS[report_kind.to_sym]
            raise ArgumentError, "Unknown report kind: #{report_kind}" unless builder

            builder.call(timestamp, package)
          end

          def flatten_attempt_results(results, base_dir:)
            results.fetch(:packages, {}).values.flatten.map do |result|
              report_dir = result[:report_dir]
              metadata = read_retry_metadata(report_dir)
              report_frontmatter = read_report_frontmatter(report_dir)
              test_name = result[:test_name] || result[:test_id] || ""
              test_id = metadata["test-id"] || canonical_retry_test_id(test_name)
              failed_entries = Array(metadata["failed"]).filter_map do |entry|
                next unless entry.is_a?(Hash)

                {
                  tc: entry["tc"] || entry[:tc],
                  category: entry["category"] || entry[:category] || "runner-error",
                  evidence: entry["evidence"] || entry[:evidence] || "See attempt report for details"
                }
              end
              if failed_entries.empty? && result[:status] != "pass"
                failed_entries << {
                  tc: nil,
                  category: result[:status] || "runner-error",
                  evidence: result[:summary] || result[:error] || "See attempt report for details"
                }
              end

              {
                test_id: test_id,
                title: report_frontmatter["title"] || test_id,
                status: result[:status],
                report_dir: report_dir,
                report_dir_display: display_path(report_dir, base_dir),
                report_dir_name: report_dir ? File.basename(report_dir) : nil,
                failed_entries: failed_entries,
                passed_cases: result[:passed_cases] || metadata["tcs-passed"] || metadata.dig("results", "passed") || 0,
                total_cases: result[:total_cases] || metadata["tcs-total"] || metadata.dig("results", "total") || 0
              }
            end
          end

          def read_retry_metadata(report_dir)
            return {} unless report_dir

            path = File.join(report_dir, "metadata.yml")
            return {} unless File.exist?(path)

            YAML.safe_load_file(path, permitted_classes: [Time, Date]) || {}
          rescue
            {}
          end

          def canonical_retry_test_id(test_name)
            match = test_name.to_s.match(/\A(TS-[A-Z0-9]+-\d+[a-z]*)/i)
            match ? match[1].upcase : test_name
          end

          def display_path(path, base_dir)
            return nil if path.nil?

            path.start_with?(base_dir) ? path.delete_prefix("#{base_dir}/") : path
          end

          def compute_retry_summary_status(entries)
            executed = entries.reject { |entry| entry[:status] == "skip" }
            return "skip" if executed.empty?
            return "pass" if executed.all? { |entry| entry[:status] == "pass" }
            return "partial" if executed.any? { |entry| entry[:status] == "pass" }

            "fail"
          end

          def build_retry_summary_content(timestamp:, initial_results:, retry_results:, initial_entries:, flaky_entries:, remaining_entries:, final_status:, base_dir:)
            total_initial_failures = initial_entries.count { |entry| entry[:status] != "pass" }
            lines = []
            lines << "---"
            lines << "suite-id: #{timestamp}"
            lines << "package: suite"
            lines << "status: #{final_status}"
            lines << "retry-attempted: true"
            lines << "flaky-scenarios: #{flaky_entries.length}"
            lines << "remaining-failures: #{remaining_entries.length}"
            lines << "attempt-1-report: #{display_path(initial_results[:report_path], base_dir)}"
            lines << "attempt-2-report: #{display_path(retry_results[:report_path], base_dir)}"
            lines << "---"
            lines << ""
            lines << "# E2E Final Suite Report: `suite`"
            lines << ""
            lines << "## Attempt Summary"
            lines << ""
            lines << "| Attempt | Report | Status | Scenarios | Failures |"
            lines << "|---|---|---:|---:|---:|"
            lines << "| 1 | `#{display_path(initial_results[:report_path], base_dir)}` | #{initial_results[:failed].to_i > 0 || initial_results[:errors].to_i > 0 ? "Fail" : "Pass"} | #{initial_results[:total]} | #{initial_results[:failed].to_i + initial_results[:errors].to_i} |"
            lines << "| 2 | `#{display_path(retry_results[:report_path], base_dir)}` | #{retry_results[:failed].to_i > 0 || retry_results[:errors].to_i > 0 ? "Fail" : "Pass"} | #{retry_results[:total]} | #{retry_results[:failed].to_i + retry_results[:errors].to_i} |"
            lines << ""
            lines << "First-pass failing scenarios: #{total_initial_failures}"
            lines << "Recovered on retry (flaky): #{flaky_entries.length}"
            lines << "Remaining failures after retry: #{remaining_entries.length}"
            lines << ""
            lines << "## Flaky Recoveries"
            lines << ""
            if flaky_entries.empty?
              lines << "None."
            else
              flaky_entries.each do |entry|
                lines << "### #{entry[:test_id]}"
                lines << ""
                lines << "- Title: #{entry[:title]}"
                lines << "- Attempt 1 status: `#{entry[:status]}`"
                lines << "- Attempt 1 report directory: `#{entry[:report_dir_display]}`"
                lines << "- Attempt 2 report directory: `#{entry[:retry_entry][:report_dir_display]}`"
                entry[:failed_entries].each do |failure|
                  lines << "- #{format_failure_entry(failure)}"
                end
                lines << ""
              end
            end
            lines << "## Remaining Failures"
            lines << ""
            if remaining_entries.empty?
              lines << "None."
            else
              remaining_entries.each do |entry|
                lines << "### #{entry[:test_id]}"
                lines << ""
                lines << "- Title: #{entry[:title]}"
                lines << "- Attempt 2 status: `#{entry[:status]}`"
                lines << "- Attempt 2 report directory: `#{entry[:report_dir_display]}`"
                entry[:failed_entries].each do |failure|
                  lines << "- #{format_failure_entry(failure)}"
                end
                lines << ""
              end
            end

            lines.join("\n")
          end

          def format_failure_entry(failure)
            tc = failure[:tc] || failure["tc"]
            category = failure[:category] || failure["category"] || "runner-error"
            evidence = failure[:evidence] || failure["evidence"] || "See attempt report for details"
            tc ? "`#{tc}` (`#{category}`) - #{evidence}" : "`#{category}` - #{evidence}"
          end

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

              report_metadata = read_report_frontmatter(report_dir)

              {
                test_id: result.test_id,
                title: scenario.title,
                status: result.status,
                passed: reported_count(report_metadata, result, "passed"),
                failed: reported_count(report_metadata, result, "failed"),
                total: reported_count(report_metadata, result, "total"),
                test_cases: canonical_test_cases(report_metadata, result),
                report_dir_name: report_dir ? File.basename(report_dir) : nil,
                summary_content: summary_content,
                experience_content: experience_content,
                canonical_tc_source: !report_metadata.empty?
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

          def read_report_frontmatter(report_dir)
            return {} unless report_dir

            path = File.join(report_dir, "report.md")
            return {} unless File.exist?(path)

            content = File.read(path)
            match = content.match(/\A---\s*\n(.*?)\n---\s*\n/m)
            return {} unless match

            YAML.safe_load(match[1], permitted_classes: [Time, Date]) || {}
          rescue
            {}
          end

          def reported_count(report_metadata, result, kind)
            key = "tcs-#{kind}"
            fallback =
              case kind
              when "passed" then result.passed_count
              when "failed" then result.failed_count
              else result.total_count
              end
            report_metadata[key] || fallback
          end

          def canonical_test_cases(report_metadata, result)
            return result.test_cases if report_metadata.empty?

            failed_entries = Array(report_metadata["failed"]).filter_map do |entry|
              next unless entry.is_a?(Hash)

              id = entry["tc"] || entry[:tc]
              next unless id

              {
                id: id,
                description: "",
                status: "fail",
                notes: entry["evidence"] || entry[:evidence] || "See scenario report for details",
                category: entry["category"] || entry[:category] || "runner-error"
              }
            end

            failed_ids = failed_entries.map { |entry| entry[:id] }.to_set
            Array(report_metadata["canonical-failed-tcs"]).each do |tc_id|
              next if failed_ids.include?(tc_id)

              failed_entries << {
                id: tc_id,
                description: "",
                status: "fail",
                notes: "See scenario report for details",
                category: "runner-error"
              }
            end

            passed_entries = Array(report_metadata["passed"]).filter_map do |tc_id|
              next if failed_ids.include?(tc_id)

              {id: tc_id, description: "", status: "pass", notes: ""}
            end

            canonical = passed_entries + failed_entries
            canonical.empty? ? result.test_cases : canonical
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

          def build_report(results_data, package:, timestamp:, overall_status:, executed_at:, narrative_sections:, diagnostics:)
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
            parts << build_runner_diagnostics_section(diagnostics)
            parts << build_narrative_section("Friction Analysis", narrative_sections[:friction])
            parts << build_narrative_section("Improvement Suggestions", narrative_sections[:improvements])
            parts << build_narrative_section("Positive Observations", narrative_sections[:positive])
            parts << build_reports_section(results_data)
            parts.compact.join("\n")
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
              else
                parts << "- Exact failed TC mapping unavailable in aggregate view — see scenario report for canonical details."
              end

              if result[:report_dir_name]
                parts << ""
                parts << "**Report directory:** `#{result[:report_dir_name]}`"
              end
              parts << ""
            end

            parts.join("\n")
          end

          def build_runner_diagnostics_section(diagnostics)
            return nil unless diagnostics.is_a?(Hash) && diagnostics[:dirty_worktree]

            entries = Array(diagnostics[:new_tracked_entries]).map { |line| "- `#{line}`" }.join("\n")
            entries = "- No specific entries captured." if entries.empty?

            <<~SECTION
              ## Runner Diagnostics

              Suite execution introduced new tracked working-tree changes relative to the pre-run snapshot.

              #{entries}
            SECTION
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
