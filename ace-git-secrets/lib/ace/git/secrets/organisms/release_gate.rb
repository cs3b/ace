# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module Organisms
        # Pre-release security gate
        # Blocks releases if tokens are detected in history
        #
        # Requires gitleaks to be installed: brew install gitleaks
        class ReleaseGate
          attr_reader :scanner, :strict_mode

          # @param repository_path [String] Path to git repository
          # @param gitleaks_config [String, nil] Path to gitleaks config file
          # @param strict [Boolean] Fail on medium confidence matches too
          # @param exclusions [Array<String>, nil] Glob patterns for files to exclude
          def initialize(repository_path: ".", gitleaks_config: nil, strict: false, exclusions: nil)
            @scanner = Molecules::HistoryScanner.new(
              repository_path: repository_path,
              gitleaks_config: gitleaks_config,
              exclusions: exclusions
            )
            @strict_mode = strict
          end

          # Run pre-release security check
          # @return [Hash] Result with :passed, :message, :report keys
          def check
            min_confidence = strict_mode ? "medium" : "high"

            report = scanner.scan(min_confidence: min_confidence)

            if report.clean?
              {
                passed: true,
                exit_code: 0,
                message: "Pre-release security check: PASSED",
                summary: "No authentication tokens detected in Git history.",
                report: report
              }
            else
              {
                passed: false,
                exit_code: 1,
                message: "Pre-release security check: FAILED",
                summary: failure_summary(report),
                report: report,
                remediation: remediation_steps(report)
              }
            end
          end

          # Format result for CI output
          # @param result [Hash] Check result
          # @param format [String] Output format (table, json)
          # @return [String]
          def format_result(result, format: "table")
            case format
            when "json"
              require "json"
              JSON.pretty_generate({
                passed: result[:passed],
                message: result[:message],
                token_count: result[:report].token_count,
                tokens: result[:report].tokens.map { |t| t.to_h }
              })
            else
              format_table_result(result)
            end
          end

          private

          def failure_summary(report)
            lines = []
            lines << "#{report.token_count} authentication token(s) detected in Git history."
            lines << ""
            lines << "Summary by type:"

            report.token_types.each do |type|
              count = report.tokens.count { |t| t.token_type == type }
              lines << "  - #{type}: #{count}"
            end

            lines << ""
            lines << "Release blocked until tokens are removed."

            lines.join("\n")
          end

          def remediation_steps(report)
            <<~STEPS
              To fix this issue:

              1. Review detected tokens:
                 ace-git-secrets scan

              2. Revoke compromised tokens immediately:
                 ace-git-secrets revoke

              3. Remove tokens from Git history:
                 ace-git-secrets rewrite-history

              4. Force push cleaned history:
                 git push --force-with-lease

              5. Re-run this check:
                 ace-git-secrets check-release
            STEPS
          end

          def format_table_result(result)
            lines = []
            lines << "=" * 60
            lines << result[:message]
            lines << "=" * 60
            lines << ""
            lines << result[:summary]

            unless result[:passed]
              lines << ""
              lines << "-" * 60
              lines << result[:remediation]
            end

            lines.join("\n")
          end
        end
      end
    end
  end
end
