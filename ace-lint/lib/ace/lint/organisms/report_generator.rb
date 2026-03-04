# frozen_string_literal: true

require "json"
require "fileutils"

module Ace
  module Lint
    module Organisms
      # Generates JSON and markdown report files from lint results
      # Reports are saved to .ace-local/lint/{compact_id}/
      #
      # Generated files:
      #   report.json - Full JSON data
      #   ok.md       - Files that passed (no issues)
      #   fixed.md    - Files that were auto-fixed (only when files were fixed)
      #   pending.md  - Files needing manual work (errors/warnings)
      #
      # Cache Cleanup:
      #   Reports accumulate in .ace-local/lint/ over time. To clean up old reports:
      #     rm -rf .ace-local/lint/
      #   Or selectively remove reports older than N days:
      #     find .ace-local/lint -type d -mtime +7 -exec rm -rf {} +
      #   The .ace-local/ directory is typically gitignored and safe to delete.
      class ReportGenerator
        # Expected cache directory pattern for validation
        EXPECTED_CACHE_PATTERN = File.join("", ".ace-local", "lint", "").freeze

        # Generate JSON report and markdown files from lint results
        # @param results [Array<Models::LintResult>] Lint results
        # @param project_root [String] Project root directory
        # @param options [Hash] Scan options used
        # @return [Hash] Result hash with :success, :dir, and :files keys
        def self.generate(results, project_root:, options: {})
          compact_id = Ace::B36ts.encode(Time.now.utc)
          report_dir = File.join(project_root, ".ace-local", "lint", compact_id)

          # Validate report_dir is within expected cache location
          expected_cache_root = File.join(project_root, ".ace-local", "lint")
          unless File.expand_path(report_dir).start_with?(File.expand_path(expected_cache_root))
            return {success: false, error: "Report directory outside expected cache location"}
          end

          FileUtils.mkdir_p(report_dir)

          # Generate JSON report (full data)
          report_path = File.join(report_dir, "report.json")
          report_data = build_report(results, compact_id: compact_id, options: options)
          File.write(report_path, JSON.pretty_generate(report_data))

          # Generate markdown reports based on results
          generated_files = {}

          # ok.md - passed files (no issues, not fixed, not skipped)
          passed = results.select { |r| r.success? && !r.formatted? && !r.skipped? && !r.has_warnings? }
          if passed.any?
            ok_path = File.join(report_dir, "ok.md")
            File.write(ok_path, build_ok_markdown(passed))
            generated_files[:ok] = {path: ok_path, count: passed.size}
          end

          # fixed.md - auto-fixed files
          fixed = results.select(&:formatted?)
          if fixed.any?
            fixed_path = File.join(report_dir, "fixed.md")
            File.write(fixed_path, build_fixed_markdown(fixed))
            generated_files[:fixed] = {path: fixed_path, count: fixed.size}
          end

          # pending.md - files with errors or warnings
          pending = results.select { |r| r.has_errors? || r.has_warnings? }
          if pending.any?
            pending_path = File.join(report_dir, "pending.md")
            issue_count = pending.sum { |r| r.error_count + r.warning_count }
            File.write(pending_path, build_pending_markdown(pending))
            generated_files[:pending] = {path: pending_path, count: issue_count}
          end

          {success: true, dir: report_dir, files: generated_files}
        rescue => e
          {success: false, error: e.message}
        end

        # Build markdown content for passed files
        # @param results [Array<Models::LintResult>] Passed lint results
        # @return [String] Markdown content
        def self.build_ok_markdown(results)
          lines = []
          lines << "# Lint: Passed Files"
          lines << ""
          lines << "Generated: #{Time.now.utc.iso8601}"
          lines << "Total: #{results.size} files"
          lines << ""
          results.each { |r| lines << "- #{r.file_path}" }
          lines.join("\n")
        end

        # Build markdown content for fixed files
        # @param results [Array<Models::LintResult>] Fixed lint results
        # @return [String] Markdown content
        def self.build_fixed_markdown(results)
          lines = []
          lines << "# Lint: Auto-Fixed Files"
          lines << ""
          lines << "Generated: #{Time.now.utc.iso8601}"
          lines << "Total: #{results.size} files"
          lines << ""
          lines << "These files were automatically formatted/fixed:"
          lines << ""
          results.each { |r| lines << "- #{r.file_path}" }
          lines.join("\n")
        end

        # Build markdown content for pending items
        # @param results [Array<Models::LintResult>] Lint results with issues
        # @return [String] Markdown content
        def self.build_pending_markdown(results)
          issue_count = results.sum { |r| r.error_count + r.warning_count }
          lines = []
          lines << "# Lint: Pending Issues"
          lines << ""
          lines << "Generated: #{Time.now.utc.iso8601}"
          lines << "Total: #{issue_count} issues in #{results.size} files"
          lines << ""

          results.each do |result|
            count = result.error_count + result.warning_count
            lines << "## #{result.file_path} (#{count} issues)"
            lines << ""
            result.errors.each { |e| lines << "- [ ] #{e}" }
            result.warnings.each { |w| lines << "- [ ] #{w}" }
            lines << ""
          end

          lines.join("\n")
        end

        # Build report data structure
        # @param results [Array<Models::LintResult>] Lint results
        # @param compact_id [String] Compact timestamp ID
        # @param options [Hash] Scan options
        # @return [Hash] Report data
        def self.build_report(results, compact_id:, options: {})
          {
            report_metadata: build_metadata(compact_id, options),
            summary: build_summary(results),
            results: categorize_results(results)
          }
        end

        # Build report metadata
        # @param compact_id [String] Compact timestamp ID
        # @param options [Hash] Scan options
        # @return [Hash] Metadata hash
        def self.build_metadata(compact_id, options)
          {
            generated_at: Time.now.utc.iso8601,
            compact_id: compact_id,
            ace_lint_version: Ace::Lint::VERSION,
            scan_options: sanitize_options(options)
          }
        end

        # Build summary statistics
        # @param results [Array<Models::LintResult>] Lint results
        # @return [Hash] Summary statistics
        def self.build_summary(results)
          fixed = results.count(&:formatted?)
          skipped = results.count(&:skipped?)
          failed = results.count(&:failed?)
          passed = results.count { |r| r.success? && !r.formatted? && !r.skipped? }

          {
            total_files: results.size,
            scanned: results.size - skipped,
            skipped: skipped,
            fixed: fixed,
            failed: failed,
            passed: passed,
            total_errors: results.sum(&:error_count),
            total_warnings: results.sum(&:warning_count)
          }
        end

        # Categorize results by status
        # @param results [Array<Models::LintResult>] Lint results
        # @return [Hash] Results grouped by category
        def self.categorize_results(results)
          {
            fixed: results.select(&:formatted?).map(&:to_h),
            failed: results.select(&:failed?).map(&:to_h),
            warnings_only: results.select { |r| r.success? && !r.formatted? && !r.skipped? && r.has_warnings? }.map(&:to_h),
            passed: results.select { |r| r.success? && !r.formatted? && !r.skipped? && !r.has_warnings? }.map(&:to_h),
            skipped: results.select(&:skipped?).map(&:to_h)
          }
        end

        # Sanitize options for JSON output
        # @param options [Hash] Raw options
        # @return [Hash] Sanitized options
        def self.sanitize_options(options)
          # Convert symbol keys to strings and filter relevant options
          # Use key? to preserve false values (user explicitly chose not to fix/format)
          result = {}
          result[:fix] = options[:fix] if options.key?(:fix)
          result[:format] = options[:format] if options.key?(:format)
          result[:type] = options[:type].to_s if options[:type]
          result[:validators] = options[:validators].map(&:to_s) if options[:validators]
          result
        end
      end
    end
  end
end
