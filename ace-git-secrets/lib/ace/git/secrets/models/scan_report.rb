# frozen_string_literal: true

require "json"
require "yaml"
require "fileutils"
require "ace/b36ts"

module Ace
  module Git
    module Secrets
      module Models
        # Represents a complete scan report with detected tokens and metadata
        class ScanReport
          attr_reader :tokens, :repository_path, :scanned_at, :scan_options,
            :commits_scanned, :detection_method, :scan_duration, :thread_count

          # @param tokens [Array<DetectedToken>] Detected tokens
          # @param repository_path [String] Path to scanned repository
          # @param scanned_at [Time] When scan was performed
          # @param scan_options [Hash] Options used for scanning
          # @param commits_scanned [Integer] Number of commits scanned
          # @param detection_method [String] Primary detection method used
          # @param scan_duration [Float, nil] Scan duration in seconds
          # @param thread_count [Integer, nil] Number of threads used for scanning
          def initialize(tokens: [], repository_path: nil, scanned_at: nil,
            scan_options: {}, commits_scanned: 0, detection_method: "ruby_patterns",
            scan_duration: nil, thread_count: nil)
            @tokens = tokens.freeze
            @repository_path = repository_path
            @scanned_at = scanned_at || Time.now
            @scan_options = scan_options.freeze
            @commits_scanned = commits_scanned
            @detection_method = detection_method
            @scan_duration = scan_duration
            @thread_count = thread_count
          end

          # Check if any tokens were detected
          # @return [Boolean]
          def clean?
            tokens.empty?
          end

          # Check if tokens were detected
          # @return [Boolean]
          def tokens_found?
            !clean?
          end

          # Total number of detected tokens
          # @return [Integer]
          def token_count
            tokens.size
          end

          # Get tokens by confidence level
          # @param level [String] Confidence level (high, medium, low)
          # @return [Array<DetectedToken>]
          def tokens_by_confidence(level)
            tokens.select { |t| t.confidence == level }
          end

          # Count of high confidence tokens
          # @return [Integer]
          def high_confidence_count
            tokens_by_confidence("high").size
          end

          # Count of medium confidence tokens
          # @return [Integer]
          def medium_confidence_count
            tokens_by_confidence("medium").size
          end

          # Count of low confidence tokens
          # @return [Integer]
          def low_confidence_count
            tokens_by_confidence("low").size
          end

          # Get unique token types found
          # @return [Array<String>]
          def token_types
            tokens.map(&:token_type).uniq.sort
          end

          # Get unique files with tokens
          # @return [Array<String>]
          def affected_files
            tokens.map(&:file_path).uniq.sort
          end

          # Get unique commits with tokens
          # @return [Array<String>]
          def affected_commits
            tokens.map(&:commit_hash).uniq
          end

          # Get tokens that can be revoked
          # @return [Array<DetectedToken>]
          def revocable_tokens
            tokens.select(&:revocable?)
          end

          # Summary statistics
          # @return [Hash]
          def summary
            {
              total_tokens: token_count,
              high_confidence: high_confidence_count,
              medium_confidence: medium_confidence_count,
              low_confidence: low_confidence_count,
              token_types: token_types,
              affected_files: affected_files.size,
              affected_commits: affected_commits.size,
              revocable: revocable_tokens.size,
              detection_method: detection_method
            }
          end

          # Convert to hash for serialization
          # @param include_raw [Boolean] Whether to include raw token values
          # @return [Hash]
          def to_h(include_raw: false)
            result = {
              scan_metadata: {
                repository: repository_path,
                scanned_at: scanned_at.iso8601,
                commits_scanned: commits_scanned,
                scan_duration_seconds: scan_duration&.round(2),
                thread_count: thread_count,
                detection_method: detection_method
              },
              scan_options: scan_options,
              summary: summary,
              tokens: tokens.map { |t| t.to_h(include_raw: include_raw) }
            }
            # Remove nil values from scan_metadata
            result[:scan_metadata].compact!
            result
          end

          # Serialize to JSON
          # @param include_raw [Boolean] Whether to include raw token values
          # @return [String]
          def to_json(include_raw: false)
            JSON.pretty_generate(to_h(include_raw: include_raw))
          end

          # Serialize to YAML
          # @param include_raw [Boolean] Whether to include raw token values
          # @return [String]
          def to_yaml(include_raw: false)
            to_h(include_raw: include_raw).to_yaml
          end

          # Format as table for CLI output
          # @return [String]
          def to_table
            return "No tokens detected. Repository is clean." if clean?

            lines = []
            lines << "Scan Report: #{repository_path}"
            lines << "=" * 60
            lines << "Scanned at: #{scanned_at}"
            lines << "Commits scanned: #{commits_scanned}"
            lines << "Detection method: #{detection_method}"
            lines << ""
            lines << "Summary:"
            lines << "  Total tokens: #{token_count}"
            lines << "  High confidence: #{high_confidence_count}"
            lines << "  Medium confidence: #{medium_confidence_count}"
            lines << "  Low confidence: #{low_confidence_count}"
            lines << ""
            lines << "Detected Tokens:"
            lines << "-" * 60

            tokens.each_with_index do |token, idx|
              lines << "#{idx + 1}. #{token.token_type} (#{token.confidence})"
              lines << "   Value: #{token.masked_value}"
              lines << "   Commit: #{token.short_commit}"
              lines << "   File: #{token.file_path}#{":#{token.line_number}" if token.line_number}"
              lines << "   Detected by: #{token.detected_by}"
              lines << ""
            end

            lines.join("\n")
          end

          # Save report to file in cache directory
          # @param format [Symbol] Output format (:json or :markdown)
          # @param directory [String, nil] Custom cache directory (defaults to .ace-local/git-secrets)
          # @param include_raw [Boolean] Include raw token values in JSON (default: true for machine-readable)
          # @param quiet [Boolean] Suppress security warning (default: false)
          # @return [String] Path to saved report file
          def save_to_file(format: :json, directory: nil, include_raw: true, quiet: false)
            cache_dir = directory || File.join(repository_path || ".", ".ace-local", "git-secrets")
            sessions_dir = File.join(cache_dir, "sessions")
            FileUtils.mkdir_p(sessions_dir)

            session_id = Ace::B36ts.encode(scanned_at)
            ext = (format == :markdown) ? "md" : "json"
            path = File.join(sessions_dir, "#{session_id}-report.#{ext}")

            # JSON format includes raw values by default for revoke/rewrite-history workflows
            # Markdown format never includes raw values (human-readable)
            content = (format == :markdown) ? to_markdown : to_json(include_raw: include_raw)
            File.write(path, content)

            # Security warning: remind user that raw secrets are written to disk
            if include_raw && tokens_found? && !quiet
              warn "SECURITY: Report contains raw token values. Delete after remediation: #{path}"
            end

            # Generate providers report for revocation workflow (only when tokens found)
            save_providers_report(sessions_dir, session_id) if tokens_found?

            path
          end

          # Save providers-grouped markdown report for revocation workflow
          # @param sessions_dir [String] Sessions directory to save report
          # @param session_id [String] Session ID prefix for filename
          # @return [String, nil] Path to saved report, or nil if no tokens
          def save_providers_report(sessions_dir, session_id)
            providers_content = to_providers_markdown
            return nil unless providers_content

            providers_path = File.join(sessions_dir, "#{session_id}-providers.md")
            File.write(providers_path, providers_content)
            providers_path
          rescue => e
            # Log error but don't fail main report save
            warn "Warning: Could not save providers report: #{e.message}"
            nil
          end

          # Generate concise summary for stdout
          # @param report_path [String, nil] Path to full report file
          # @return [String]
          def to_summary(report_path: nil)
            lines = []

            # Timing and thread info
            timing = scan_duration ? "in #{format_duration(scan_duration)}" : ""
            threads = thread_count ? " (#{thread_count} threads)" : ""
            lines << "Scan completed#{" " + timing unless timing.empty?}#{threads}"

            # Token counts
            lines << if clean?
              "No tokens detected. Repository is clean."
            else
              "Tokens found: #{token_count} (high: #{high_confidence_count}, medium: #{medium_confidence_count})"
            end

            # Report path
            lines << "Report saved: #{report_path}" if report_path

            lines.join("\n")
          end

          # Get unique tokens grouped by raw_value with all their locations
          # @return [Hash<String, Hash>] Map of raw_value => { token:, locations: [] }
          def deduplicated_tokens
            result = {}
            tokens.each do |token|
              if result.key?(token.raw_value)
                result[token.raw_value][:locations] << {
                  commit: token.short_commit,
                  file: token.file_path,
                  line: token.line_number
                }
              else
                result[token.raw_value] = {
                  token: token,
                  locations: [{
                    commit: token.short_commit,
                    file: token.file_path,
                    line: token.line_number
                  }]
                }
              end
            end
            result
          end

          # Format as providers-grouped markdown for revocation workflow
          # @return [String]
          def to_providers_markdown
            return nil if clean?

            deduped = deduplicated_tokens

            # Group by provider, with revocable providers first
            by_provider = deduped.values.group_by { |entry| entry[:token].provider_name }

            # Sort providers: revocable first, manual last
            provider_order = %w[GitHub AWS Anthropic OpenAI]
            sorted_providers = by_provider.keys.sort_by do |name|
              idx = provider_order.index(name)
              idx.nil? ? provider_order.size : idx
            end

            lines = []
            lines << "# Tokens to Revoke"
            lines << ""
            lines << "**Scan**: #{scanned_at.strftime("%Y-%m-%d %H:%M:%S")} | " \
                     "**Unique tokens**: #{deduped.size} | " \
                     "**Providers**: #{by_provider.size}"
            lines << ""

            sorted_providers.each do |provider_name|
              provider_tokens = by_provider[provider_name]
              lines << "## #{provider_name} (#{provider_tokens.size} token#{"s" if provider_tokens.size != 1})"
              lines << ""

              provider_tokens.each_with_index do |entry, idx|
                token = entry[:token]
                locations = entry[:locations]

                lines << "### #{idx + 1}. `#{token.masked_value}` (#{token.token_type})"
                lines << ""
                lines << "**Locations:**"
                locations.each do |loc|
                  line_suffix = loc[:line] ? ":#{loc[:line]}" : ""
                  lines << "- `#{loc[:commit]}` #{loc[:file]}#{line_suffix}"
                end
                lines << ""
              end
            end

            lines.join("\n")
          end

          # Format as markdown for file output
          # @return [String]
          def to_markdown
            lines = []
            lines << "# Security Scan Report"
            lines << ""
            lines << "## Scan Metadata"
            lines << ""
            lines << "| Field | Value |"
            lines << "|-------|-------|"
            lines << "| Repository | `#{repository_path}` |"
            lines << "| Scanned at | #{scanned_at.iso8601} |"
            lines << "| Commits scanned | #{commits_scanned} |"
            lines << "| Scan duration | #{scan_duration ? format_duration(scan_duration) : "N/A"} |"
            lines << "| Thread count | #{thread_count || "N/A"} |"
            lines << "| Detection method | #{detection_method} |"
            lines << ""
            lines << "## Summary"
            lines << ""
            lines << "| Metric | Count |"
            lines << "|--------|-------|"
            lines << "| Total tokens | #{token_count} |"
            lines << "| High confidence | #{high_confidence_count} |"
            lines << "| Medium confidence | #{medium_confidence_count} |"
            lines << "| Low confidence | #{low_confidence_count} |"
            lines << ""

            if tokens.any?
              lines << "## Detected Tokens"
              lines << ""

              tokens.each_with_index do |token, idx|
                lines << "### #{idx + 1}. #{token.token_type}"
                lines << ""
                lines << "- **Confidence**: #{token.confidence}"
                lines << "- **Value**: `#{token.masked_value}`"
                lines << "- **Commit**: #{token.short_commit}"
                lines << "- **File**: `#{token.file_path}#{":#{token.line_number}" if token.line_number}`"
                lines << "- **Detected by**: #{token.detected_by}"
                lines << ""
              end
            else
              lines << "No tokens detected. Repository is clean."
              lines << ""
            end

            lines.join("\n")
          end

          private

          # Format duration in human-readable form
          # @param seconds [Float]
          # @return [String]
          def format_duration(seconds)
            if seconds < 60
              "#{seconds.round(1)}s"
            else
              minutes = (seconds / 60).floor
              remaining_seconds = (seconds % 60).round
              "#{minutes}m #{remaining_seconds}s"
            end
          end
        end
      end
    end
  end
end
