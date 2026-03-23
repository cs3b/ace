# frozen_string_literal: true

require "open3"

module Ace
  module Git
    module Secrets
      module Molecules
        # Scans Git history for authentication tokens using gitleaks
        #
        # This is a thin wrapper around GitleaksRunner that adds:
        # - File exclusion filtering
        # - Confidence level filtering
        # - ScanReport generation
        #
        # Gitleaks is required - install with: brew install gitleaks
        class HistoryScanner
          attr_reader :repository_path, :gitleaks_runner, :exclusions

          # @param repository_path [String] Path to git repository
          # @param gitleaks_config [String, nil] Path to gitleaks config
          # @param exclusions [Array<String>, nil] Glob patterns for files to exclude
          def initialize(repository_path: ".", gitleaks_config: nil, exclusions: nil)
            @repository_path = File.expand_path(repository_path)
            @gitleaks_runner = Atoms::GitleaksRunner.new(config_path: gitleaks_config)
            @exclusions = exclusions || Ace::Git::Secrets.exclusions
          end

          # Scan repository history for tokens
          # @param since [String, nil] Start commit or date
          # @param min_confidence [String] Minimum confidence level
          # @return [Models::ScanReport]
          def scan(since: nil, min_confidence: "low")
            # Ensure gitleaks is available
            Atoms::GitleaksRunner.ensure_available!

            result = gitleaks_runner.scan_history(
              path: repository_path,
              since: since
            )

            detected_tokens = result[:findings].map do |f|
              # Apply exclusions
              next if excluded_file?(f[:file_path])

              Models::DetectedToken.new(
                token_type: f[:token_type],
                pattern_name: f[:pattern_name],
                confidence: f[:confidence],
                commit_hash: f[:commit_hash],
                file_path: f[:file_path],
                line_number: f[:line_number],
                raw_value: f[:matched_value],
                detected_by: "gitleaks"
              )
            end.compact

            # Filter by confidence
            detected_tokens = filter_by_confidence(detected_tokens, min_confidence)

            Models::ScanReport.new(
              tokens: detected_tokens,
              repository_path: repository_path,
              scanned_at: Time.now,
              scan_options: {since: since, min_confidence: min_confidence},
              commits_scanned: count_commits(since: since),
              detection_method: "gitleaks"
            )
          end

          # Scan only current files (no history)
          # @param min_confidence [String] Minimum confidence level
          # @return [Models::ScanReport]
          def scan_files(min_confidence: "low")
            # Ensure gitleaks is available
            Atoms::GitleaksRunner.ensure_available!

            result = gitleaks_runner.scan_files(path: repository_path)

            detected_tokens = result[:findings].map do |f|
              # Apply exclusions
              next if excluded_file?(f[:file_path])

              Models::DetectedToken.new(
                token_type: f[:token_type],
                pattern_name: f[:pattern_name],
                confidence: f[:confidence],
                commit_hash: "HEAD",
                file_path: f[:file_path],
                line_number: f[:line_number],
                raw_value: f[:matched_value],
                detected_by: "gitleaks"
              )
            end.compact

            detected_tokens = filter_by_confidence(detected_tokens, min_confidence)

            Models::ScanReport.new(
              tokens: detected_tokens,
              repository_path: repository_path,
              scanned_at: Time.now,
              scan_options: {files_only: true, min_confidence: min_confidence},
              commits_scanned: 0,
              detection_method: "gitleaks"
            )
          end

          private

          # Check if file path matches any exclusion pattern
          # @param path [String] File path to check
          # @return [Boolean] true if file should be excluded
          def excluded_file?(path)
            exclusions.any? do |pattern|
              File.fnmatch?(pattern, path, File::FNM_PATHNAME | File::FNM_EXTGLOB)
            end
          end

          # Count commits in repository
          # @param since [String, nil] Start commit or date
          # @return [Integer]
          def count_commits(since: nil)
            cmd = ["git", "-C", repository_path, "rev-list", "--count", "HEAD"]
            cmd.insert(-2, "--since=#{since}") if since

            output, status = Open3.capture2(*cmd, err: File::NULL)
            status.success? ? output.strip.to_i : 0
          rescue
            0
          end

          # Filter tokens by minimum confidence
          # @param tokens [Array<DetectedToken>]
          # @param min_confidence [String]
          # @return [Array<DetectedToken>]
          def filter_by_confidence(tokens, min_confidence)
            confidence_order = {"high" => 3, "medium" => 2, "low" => 1}

            unless confidence_order.key?(min_confidence)
              warn "Warning: Invalid confidence level '#{min_confidence}'. " \
                   "Valid values: high, medium, low. Defaulting to 'low'."
            end

            min_level = confidence_order[min_confidence] || 1

            tokens.select do |token|
              level = confidence_order[token.confidence] || 1
              level >= min_level
            end
          end
        end
      end
    end
  end
end
