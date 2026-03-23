# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Pure functions for formatting repository status as various output formats
      # Extracted from Models::RepoStatus.to_markdown for ATOM purity
      module StatusFormatter
        class << self
          # Format repository status as markdown
          # @param status [Models::RepoStatus] Repository status
          # @return [String] Markdown-formatted output
          def to_markdown(status)
            lines = []
            lines << "# Repository Status"

            # 1. Position section (includes git status -sb)
            lines.concat(format_position_section(status))

            # 2. Recent commits section
            if status.has_recent_commits?
              lines.concat(format_recent_commits_section(status.recent_commits))
            end

            # 3. Current PR section (for current branch)
            if status.has_pr?
              lines.concat(format_current_pr_section(status.pr_metadata))
            end

            # 4. PR Activity section (other PRs)
            if status.has_pr_activity?
              lines.concat(format_pr_activity_section(status.pr_activity))
            end

            lines.join("\n")
          end

          # Format position section with raw git status -sb output
          # @param status [Models::RepoStatus] Repository status
          # @return [Array<String>] Lines of markdown
          def format_position_section(status)
            lines = []
            lines << ""

            # Header with optional task pattern
            header = "## Position"
            header += " (task: #{status.task_pattern})" if status.has_task_pattern?
            lines << header
            lines << ""

            # Raw git status -sb output
            if status.has_git_status?
              lines << status.git_status_sb
            elsif status.branch
              # Fallback if no git status available
              lines << "Branch: #{status.branch}#{" (detached HEAD)" if status.detached?}"
            end

            lines
          end

          # Format recent commits section
          # @param commits [Array<Hash>] Recent commits with :hash and :subject
          # @return [Array<String>] Lines of markdown
          def format_recent_commits_section(commits)
            lines = []
            lines << ""
            lines << "## Recent Commits"
            lines << ""
            commits.each do |commit|
              hash = commit[:hash] || commit["hash"]
              subject = commit[:subject] || commit["subject"]
              lines << "#{hash} #{subject}"
            end
            lines
          end

          # Format current PR section (highlighted for current branch)
          # @param pr_metadata [Hash] PR metadata
          # @return [Array<String>] Lines of markdown
          def format_current_pr_section(pr_metadata)
            lines = []
            lines << ""
            lines << "## Current PR"
            lines << ""

            # Main line: #85 [OPEN] Title
            main_line = "##{pr_metadata["number"]}"
            main_line += " [#{pr_metadata["state"]}]" if pr_metadata["state"]
            main_line += " #{pr_metadata["title"]}" if pr_metadata["title"]
            lines << main_line

            # Details line: Target: main | Author: @username | Draft/Not draft
            details = []
            details << "Target: #{pr_metadata["baseRefName"]}" if pr_metadata["baseRefName"]
            if pr_metadata["author"]
              author = pr_metadata.dig("author", "login") || pr_metadata["author"]
              details << "Author: @#{author}"
            end
            details << (pr_metadata["isDraft"] ? "Draft" : "Not draft") if pr_metadata.key?("isDraft")
            lines << "  #{details.join(" | ")}" unless details.empty?

            # URL line
            lines << "  #{pr_metadata["url"]}" if pr_metadata["url"]

            lines
          end

          # Format PR activity section
          # @param pr_activity [Hash, nil] PR activity with :merged and :open arrays
          #   Each PR in the arrays has string keys from JSON parsing: "number", "title", etc.
          # @return [Array<String>] Lines of markdown
          def format_pr_activity_section(pr_activity)
            lines = []
            lines << ""
            lines << "## PR Activity"
            lines << ""

            # Handle nil pr_activity for defensive programming
            return lines << "No recent PR activity" if pr_activity.nil?

            # pr_activity uses symbol keys (from RepoStatusLoader)
            # PR data within uses string keys (from JSON parsing)
            merged = pr_activity[:merged] || []
            open_prs = pr_activity[:open] || []

            unless merged.empty?
              lines << "Merged:"
              merged.each do |pr|
                title = pr["title"] || "(no title)"
                merged_ago = format_merged_time_compact(pr["mergedAt"])
                lines << "  ##{pr["number"]} #{title}#{merged_ago}"
              end
            end

            unless open_prs.empty?
              lines << "" unless merged.empty? # Add spacing between Merged and Open
              lines << "Open:"
              open_prs.each do |pr|
                title = pr["title"] || "(no title)"
                author = format_author(pr["author"])
                lines << "  ##{pr["number"]} #{title}#{author}"
              end
            end

            if merged.empty? && open_prs.empty?
              lines << "No recent PR activity"
            end

            lines
          end

          private

          # Format merged time as relative string (compact version)
          # @param merged_at [String, nil] ISO8601 timestamp
          # @return [String] Formatted string like " (1h ago)"
          def format_merged_time_compact(merged_at)
            return "" if merged_at.nil? || (merged_at.is_a?(String) && merged_at.empty?)

            relative = TimeFormatter.relative_time(merged_at)
            relative.empty? ? "" : " (#{relative})"
          end

          # Format author info
          # @param author [Hash, String, nil] Author data
          # @return [String] Formatted string like " (@username)"
          def format_author(author)
            return "" if author.nil?

            login = author.is_a?(Hash) ? author["login"] : author.to_s
            return "" if login.nil? || login.empty?

            " (@#{login})"
          end
        end
      end
    end
  end
end
