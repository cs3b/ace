# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module Organisms
        # Orchestrates security scanning and reporting
        # High-level workflow for detecting tokens in repositories
        #
        # Uses gitleaks for token detection with whitelist filtering,
        # formatted reporting, and actionable next steps.
        #
        # Requires gitleaks to be installed: brew install gitleaks
        class SecurityAuditor
          attr_reader :scanner, :output_format, :whitelist, :whitelisted_count, :whitelist_audit_log

          # @param repository_path [String] Path to git repository
          # @param gitleaks_config [String, nil] Path to gitleaks config file
          # @param output_format [String] Output format (table, json, yaml)
          # @param whitelist [Array<Hash>] Patterns/files to whitelist
          # @param exclusions [Array<String>, nil] Glob patterns for files to exclude
          def initialize(repository_path: ".", gitleaks_config: nil, output_format: "table",
            whitelist: [], exclusions: nil)
            @scanner = Molecules::HistoryScanner.new(
              repository_path: repository_path,
              gitleaks_config: gitleaks_config,
              exclusions: exclusions
            )
            @output_format = output_format
            @whitelist = whitelist || []
            @whitelisted_count = 0
            @whitelist_audit_log = []
          end

          # Run full security audit on repository
          # @param since [String, nil] Start commit or date
          # @param min_confidence [String] Minimum confidence level
          # @param output_path [String, nil] Path to save report
          # @param verbose [Boolean] Enable verbose output
          # @return [Models::ScanReport]
          def audit(since: nil, min_confidence: "low", output_path: nil, verbose: false)
            puts "Scanning Git history for authentication tokens..." if verbose

            start_time = Time.now

            report = scanner.scan(
              since: since,
              min_confidence: min_confidence
            )

            scan_duration = Time.now - start_time

            # Apply whitelist filtering
            report = apply_whitelist(report) if whitelist.any?

            # Add timing metadata to report
            report = add_timing_metadata(report, scan_duration)

            # Output results
            output_report(report, output_path)

            report
          end

          # Audit only current files (no history)
          # @param min_confidence [String] Minimum confidence level
          # @param output_path [String, nil] Path to save report
          # @return [Models::ScanReport]
          def audit_files(min_confidence: "low", output_path: nil)
            report = scanner.scan_files(min_confidence: min_confidence)
            output_report(report, output_path)
            report
          end

          # Get formatted output
          # @param report [Models::ScanReport]
          # @return [String]
          def format_report(report)
            case output_format
            when "json"
              report.to_json
            when "yaml"
              report.to_yaml
            else
              report.to_table
            end
          end

          # Print actionable next steps
          # @param report [Models::ScanReport]
          # @return [String]
          def next_steps(report)
            return "No tokens detected. Repository is clean." if report.clean?

            steps = []
            steps << "SECURITY ALERT: #{report.token_count} token(s) detected in repository"
            steps << ""
            steps << "Recommended next steps:"
            steps << "1. Review detected tokens to confirm they are real (not false positives)"
            steps << "2. Revoke tokens immediately: ace-git-secrets revoke"
            steps << "3. Remove tokens from history: ace-git-secrets rewrite-history"
            steps << "4. Force push the cleaned history: git push --force-with-lease"
            steps << "5. Notify affected team members to re-clone"
            steps << ""

            if report.revocable_tokens.any?
              steps << "Tokens that can be revoked via API: #{report.revocable_tokens.size}"
            end

            manual = report.tokens.reject(&:revocable?)
            if manual.any?
              steps << "Tokens requiring manual revocation: #{manual.size}"
              steps << "  Visit provider dashboards to revoke these manually."
            end

            steps.join("\n")
          end

          private

          # Output report to file or stdout
          def output_report(report, output_path)
            formatted = format_report(report)

            if output_path
              File.write(output_path, formatted)
              puts "Report saved to: #{output_path}"
            end

            formatted
          end

          # Apply whitelist filtering to scan report
          # @param report [Models::ScanReport] Original report
          # @return [Models::ScanReport] Filtered report
          def apply_whitelist(report)
            whitelisted_tokens = []
            filtered_tokens = report.tokens.reject do |token|
              is_whitelisted = whitelisted?(token)
              whitelisted_tokens << token if is_whitelisted
              is_whitelisted
            end

            # Track whitelisted count for display
            @whitelisted_count = whitelisted_tokens.size

            # Return new report with filtered tokens
            Models::ScanReport.new(
              tokens: filtered_tokens,
              repository_path: report.repository_path,
              scanned_at: report.scanned_at,
              scan_options: report.scan_options,
              commits_scanned: report.commits_scanned,
              detection_method: report.detection_method
            )
          end

          # Check if a token matches any whitelist entry
          # @param token [Models::DetectedToken] Token to check
          # @return [Boolean] true if whitelisted
          def whitelisted?(token)
            whitelist.any? do |entry|
              if matches_whitelist_entry?(token, entry)
                # Audit log for security review: track what was whitelisted and why
                @whitelist_audit_log << {
                  token_masked: token.masked_value,
                  token_type: token.token_type,
                  file_path: token.file_path,
                  matched_entry: entry,
                  reason: entry["reason"]
                }
                true
              else
                false
              end
            end
          end

          # Check if token matches a specific whitelist entry
          # @param token [Models::DetectedToken]
          # @param entry [Hash] Whitelist entry with :pattern or :file key
          # @return [Boolean]
          def matches_whitelist_entry?(token, entry)
            # Match by pattern (exact token value match)
            if entry["pattern"]
              return true if token.raw_value == entry["pattern"]
            end

            # Match by file path (glob pattern)
            # FNM_EXTGLOB enables ** to match across directories
            # FNM_DOTMATCH enables matching dotfiles like .env, .claude*
            if entry["file"]
              pattern = entry["file"]
              flags = File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_DOTMATCH
              return true if File.fnmatch?(pattern, token.file_path, flags)
            end

            false
          end

          # Add timing metadata to report
          # @param report [Models::ScanReport] Original report
          # @param scan_duration [Float] Scan duration in seconds
          # @return [Models::ScanReport] Report with timing metadata
          def add_timing_metadata(report, scan_duration)
            Models::ScanReport.new(
              tokens: report.tokens,
              repository_path: report.repository_path,
              scanned_at: report.scanned_at,
              scan_options: report.scan_options,
              commits_scanned: report.commits_scanned,
              detection_method: report.detection_method,
              scan_duration: scan_duration
            )
          end
        end
      end
    end
  end
end
