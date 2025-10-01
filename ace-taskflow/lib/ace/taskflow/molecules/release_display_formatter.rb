# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Pure logic for formatting release display
      # Unit testable - no I/O
      class ReleaseDisplayFormatter
        # Generate a progress bar from statistics
        # @param stats [Hash] Statistics hash with :total and :statuses
        # @param width [Integer] Width of progress bar in characters
        # @return [String] Progress bar string
        def self.progress_bar(stats, width: 20)
          total = stats[:total] || 0
          return "□" * width if total == 0

          done = stats.dig(:statuses, "done") || 0
          percentage = (done.to_f / total * 100).round
          filled = (percentage * width / 100.0).round
          empty = width - filled

          "█" * filled + "░" * empty
        end

        # Calculate completion percentage
        # @param stats [Hash] Statistics hash
        # @return [Integer] Percentage (0-100)
        def self.completion_percentage(stats)
          total = stats[:total] || 0
          return 0 if total == 0

          done = stats.dig(:statuses, "done") || 0
          (done.to_f / total * 100).round
        end

        # Format progress summary line
        # @param stats [Hash] Statistics hash
        # @return [String] Formatted progress line
        def self.format_progress_summary(stats)
          total = stats[:total] || 0
          return "Progress: No tasks" if total == 0

          done = stats.dig(:statuses, "done") || 0
          percentage = completion_percentage(stats)
          bar = progress_bar(stats)

          "Progress: #{bar} #{percentage}% (#{done}/#{total})"
        end

        # Format status breakdown lines
        # @param stats [Hash] Statistics hash
        # @return [Array<String>] Array of formatted status lines
        def self.format_status_breakdown(stats)
          statuses = stats[:statuses] || {}
          lines = []

          done = statuses["done"] || 0
          in_progress = statuses["in-progress"] || 0
          pending = statuses["pending"] || 0
          blocked = statuses["blocked"] || 0

          lines << "  ✓ Done: #{done}" if done > 0
          lines << "  ⚡ In Progress: #{in_progress}" if in_progress > 0
          lines << "  ○ Pending: #{pending}" if pending > 0
          lines << "  ⊘ Blocked: #{blocked}" if blocked > 0

          lines
        end

        # Format complete statistics display
        # @param stats [Hash] Statistics hash
        # @return [String] Complete formatted output
        def self.format_statistics(stats)
          lines = []
          lines << format_progress_summary(stats)
          lines << "Status breakdown:"
          lines.concat(format_status_breakdown(stats))
          lines.join("\n")
        end

        # Format validation result
        # @param result [Hash] Validation result with :valid, :issues, :statistics
        # @return [Hash] Formatted output with :header, :issues, :stats
        def self.format_validation_result(result)
          {
            header: result[:valid] ? "✓ Release validation: PASSED" : "✗ Release validation: FAILED",
            issues: result[:issues]&.map { |issue| "  - #{issue}" } || [],
            stats: format_statistics(result[:statistics] || {})
          }
        end

        # Format release info header
        # @param release [Hash] Release data
        # @return [Array<String>] Formatted header lines
        def self.format_release_header(release)
          [
            "Release: #{release[:name]}",
            "Status: #{release[:status]}",
            "Path: #{release[:path]}"
          ]
        end

        # Format release with statistics
        # @param release [Hash] Release data
        # @return [String] Complete formatted output
        def self.format_release_display(release)
          lines = format_release_header(release)
          lines << ""
          lines << format_statistics(release[:statistics] || {})
          lines.join("\n")
        end

        # Format multiple active releases summary
        # @param releases [Array<Hash>] Array of release data
        # @param show_primary [Boolean] Mark first as primary
        # @return [String] Formatted list
        def self.format_active_releases_list(releases, show_primary: true)
          return "No active releases found." if releases.empty?

          lines = ["Active Releases (#{releases.size}):", ""]

          releases.each_with_index do |release, index|
            primary = (show_primary && index == 0) ? " (primary)" : ""
            lines << "  #{release[:name]}#{primary}"
            lines << "    Path: #{release[:path]}"
            lines << "    Progress: #{progress_bar(release[:statistics] || {})}"
            lines << ""
          end

          lines.join("\n")
        end
      end
    end
  end
end
