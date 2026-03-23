# frozen_string_literal: true

require "json"
require "open3"
require "tempfile"

module Ace
  module Git
    module Secrets
      module Atoms
        # Runner for gitleaks external tool
        # Handles gitleaks availability detection and execution
        #
        # Gitleaks is REQUIRED for ace-git-secrets. The gem focuses on
        # remediation (revocation, history rewriting) while delegating
        # detection to gitleaks which has 100+ actively maintained patterns.
        class GitleaksRunner
          # Error raised when gitleaks is not installed
          class GitleaksNotFoundError < StandardError; end

          attr_reader :config_path

          # @param config_path [String, nil] Path to gitleaks config file
          def initialize(config_path: nil)
            @config_path = config_path
          end

          # Check if gitleaks is available in PATH
          # @return [Boolean]
          def self.available?
            system("which gitleaks > /dev/null 2>&1")
          end

          # Ensure gitleaks is available, raising error if not
          # @raise [GitleaksNotFoundError] If gitleaks is not installed
          def self.ensure_available!
            return if available?

            raise GitleaksNotFoundError,
              "gitleaks is required but not installed. Install with: brew install gitleaks"
          end

          # Instance method for backward compatibility
          # @return [Boolean]
          def available?
            self.class.available?
          end

          # Get gitleaks version
          # @return [String, nil] Version string or nil if not available
          def version
            return nil unless available?

            stdout, _status = Open3.capture2("gitleaks version")
            stdout.strip
          rescue
            nil
          end

          # Check if gitleaks version is compatible (8.0+)
          # ace-git-secrets requires gitleaks 8.x for the `git` subcommand and JSON report format
          # @return [Boolean] true if version is compatible
          def compatible_version?
            ver = version
            return false unless ver

            # Extract major version from strings like "v8.18.4" or "8.18.4"
            match = ver.match(/v?(\d+)\./)
            return false unless match

            major = match[1].to_i
            major >= 8
          end

          # Ensure gitleaks version is compatible
          # @raise [GitleaksNotFoundError] If gitleaks is incompatible
          def self.ensure_compatible!
            runner = new
            return if runner.compatible_version?

            ver = runner.version || "unknown"
            raise GitleaksNotFoundError,
              "gitleaks version #{ver} is not compatible. Version 8.0+ is required. " \
              "Upgrade with: brew upgrade gitleaks"
          end

          # Run gitleaks scan on current files (no git history)
          # @param path [String] Path to scan
          # @param verbose [Boolean] Enable verbose output
          # @return [Hash] Scan results with :success, :findings, :output keys
          def scan_files(path: ".", verbose: false)
            run_gitleaks(path: path, no_git: true, verbose: verbose)
          end

          # Run gitleaks scan on git history
          # @param path [String] Path to repository
          # @param since [String, nil] Start commit for scanning
          # @param verbose [Boolean] Enable verbose output
          # @return [Hash] Scan results with :success, :findings, :output keys
          def scan_history(path: ".", since: nil, verbose: false)
            run_gitleaks(path: path, no_git: false, since: since, verbose: verbose)
          end

          private

          # Execute gitleaks command
          # @param path [String] Path to scan
          # @param no_git [Boolean] Whether to skip git history (scan files only)
          # @param since [String, nil] Start commit for git history scan
          # @param verbose [Boolean] Enable verbose output
          # @return [Hash] Results hash
          def run_gitleaks(path:, no_git: false, since: nil, verbose: false)
            unless available?
              return {
                success: false,
                skipped: true,
                message: "Gitleaks not installed - skipping. Install with: brew install gitleaks",
                findings: []
              }
            end

            # Use temp file for JSON report (gitleaks 8.x doesn't output JSON to stdout)
            Tempfile.create(["gitleaks-report", ".json"]) do |report_file|
              cmd = build_command(path: path, no_git: no_git, since: since, verbose: verbose, report_path: report_file.path)

              # Use array form to avoid shell injection - stderr captured separately
              _, stderr, status = Open3.capture3(*cmd)

              # Read JSON from temp file
              json_output = begin
                File.read(report_file.path)
              rescue
                ""
              end

              parse_results(json_output, stderr, status)
            end
          rescue => e
            {
              success: false,
              skipped: false,
              message: "Gitleaks execution failed: #{e.message}",
              findings: []
            }
          end

          # Build gitleaks command as array (safe from shell injection)
          # @return [Array<String>]
          def build_command(path:, no_git:, since:, verbose:, report_path:)
            # Use gitleaks git for history scanning, detect for file-only scanning
            cmd = if no_git
              ["gitleaks", "detect", "--no-git"]
            else
              ["gitleaks", "git"]
            end
            cmd << path
            cmd << "--report-format=json"
            cmd << "--report-path=#{report_path}"
            cmd << "--log-opts=--since=#{since}" if since && !no_git && valid_since_format?(since)
            if config_path
              cmd << "--config"
              cmd << config_path
            end
            cmd << "--verbose" if verbose
            cmd
          end

          # Validate since parameter format to prevent injection
          # Accepts: dates (YYYY-MM-DD, "30 days ago", etc.), commit SHAs (hex)
          # Rejects: anything with shell metacharacters or git option flags
          # @param since [String] The since parameter to validate
          # @return [Boolean] true if format is safe
          def valid_since_format?(since)
            return false if since.nil? || since.empty?

            # Reject if contains shell metacharacters or starts with dash (could be option)
            return false if since.match?(/[;|&$`\\<>]/)
            return false if since.start_with?("-")

            # Accept common formats:
            # - ISO dates: 2024-01-01
            # - Relative dates: "30 days ago", "2 weeks ago"
            # - Commit SHAs: abc123, abc123def456
            # - Git date strings: yesterday, last monday
            since.match?(/\A[\w\s\-:.,]+\z/)
          end

          # Parse gitleaks output
          # @param stdout [String] Standard output
          # @param stderr [String] Standard error
          # @param status [Process::Status] Exit status
          # @return [Hash]
          def parse_results(stdout, stderr, status)
            # Exit code 0 = no leaks found
            # Exit code 1 = leaks found
            # Exit code > 1 = error

            findings = []

            if stdout && !stdout.empty? && stdout.start_with?("[")
              begin
                findings = JSON.parse(stdout)
              rescue JSON::ParserError => e
                # Not valid JSON - gitleaks may have crashed or output unexpected text
                # Log debug info when DEBUG env is set
                if ENV["DEBUG"]
                  warn "[DEBUG] gitleaks JSON parse error: #{e.message}"
                  warn "[DEBUG] stdout (first 500 chars): #{stdout[0, 500].inspect}"
                  warn "[DEBUG] stderr: #{stderr.inspect}" unless stderr.to_s.empty?
                end
              end
            end

            {
              success: status.exitstatus <= 1,
              clean: status.exitstatus == 0,
              skipped: false,
              message: (status.exitstatus == 0) ? "No secrets detected" : "#{findings.size} secret(s) detected",
              findings: findings.map { |f| normalize_finding(f) },
              raw_output: stdout,
              stderr: stderr
            }
          end

          # Normalize gitleaks finding to our format
          # @param finding [Hash] Raw gitleaks finding
          # @return [Hash]
          def normalize_finding(finding)
            {
              pattern_name: finding["RuleID"] || finding["ruleID"] || "unknown",
              token_type: finding["RuleID"] || finding["ruleID"] || "unknown",
              confidence: "high", # Gitleaks findings are high confidence
              matched_value: finding["Secret"] || finding["secret"] || "",
              file_path: finding["File"] || finding["file"] || "",
              line_number: finding["StartLine"] || finding["startLine"],
              commit_hash: finding["Commit"] || finding["commit"] || "",
              description: finding["Description"] || finding["description"] || ""
            }
          end
        end
      end
    end
  end
end
