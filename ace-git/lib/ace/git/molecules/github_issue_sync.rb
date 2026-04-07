# frozen_string_literal: true

require "json"
require "open3"

module Ace
  module Git
    module Molecules
      # Synchronize ACE task linkage metadata to GitHub issues.
      class GithubIssueSync
        class OwnershipConflict < StandardError; end

        STICKY_MARKER = "<!-- ace-task:tracked -->"
        TRACKED_LABEL = "ace:tracked"
        TERMINAL_STATUSES = %w[done completed shipped closed cancelled skipped archived].freeze

        def self.sync_task(task_id:, task_title:, task_status:, task_path:, issue_ids:, reason:, previous: nil,
          current_issue_ids: nil)
          current_ids = if current_issue_ids.nil?
            Array(issue_ids).map(&:to_i).uniq
          else
            Array(current_issue_ids).map(&:to_i).uniq
          end

          issue_ids.each do |issue_id|
            sync_issue(
              issue_id: issue_id.to_i,
              task_id: task_id,
              task_title: task_title,
              task_status: task_status,
              task_path: task_path,
              reason: reason,
              previous: previous,
              currently_linked: current_ids.include?(issue_id.to_i)
            )
          end

          {success: true, synced: issue_ids.length, issues: issue_ids}
        end

        def self.sync_issue(issue_id:, task_id:, task_title:, task_status:, task_path:, reason:, previous:,
          currently_linked:)
          issue = fetch_issue(issue_id)
          sticky = find_sticky_comment(issue["comments"] || [])

          lines = tracked_lines(sticky&.dig("body"))
          validate_link!(issue_id: issue_id, task_id: task_id, previous_task_id: previous&.[](:id), lines: lines) if currently_linked
          lines = remove_previous_line(lines, previous)
          lines = upsert_line(lines, task_id: task_id, task_title: task_title, task_path: task_path) if currently_linked
          if lines.empty?
            cleanup_tracking_artifacts(issue_id: issue_id, sticky: sticky, labels: issue["labels"] || [])
            return {success: true, issue: issue_id, reason: reason}
          end

          body = render_body(lines)

          if sticky
            update_comment(issue_id: issue_id, comment_id: sticky["id"], body: body)
          else
            create_comment(issue_id: issue_id, body: body)
          end

          ensure_label(issue_id, issue["labels"] || [])
          if currently_linked
            sync_lifecycle(
              issue_id: issue_id,
              issue_state: issue["state"],
              task_status: task_status
            )
          end

          {success: true, issue: issue_id, reason: reason}
        end

        def self.cleanup_tracking_artifacts(issue_id:, sticky:, labels:)
          delete_comment(issue_id: issue_id, comment_id: sticky["id"]) if sticky
          remove_label(issue_id, labels)
        end

        def self.fetch_issue(issue_id)
          result = GhCliExecutor.execute("issue", ["view", issue_id.to_s, "--json", "state,comments,labels"])
          raise "Failed to fetch issue #{issue_id}: #{result[:stderr]}" unless result[:success]

          JSON.parse(result[:stdout])
        rescue JSON::ParserError => e
          raise "Failed to parse issue #{issue_id} response: #{e.message}"
        end

        def self.find_sticky_comment(comments)
          comments.find { |comment| comment["body"].to_s.include?(STICKY_MARKER) }
        end

        def self.tracked_lines(body)
          body.to_s.lines.map(&:rstrip).select { |line| line.start_with?("Tracked in ace-task: ") }
        end

        def self.remove_previous_line(lines, previous)
          return lines unless previous.is_a?(Hash)

          previous_id = previous[:id] || previous["id"]
          return lines unless previous_id

          lines.reject { |line| extract_task_id(line) == previous_id.to_s }
        end

        def self.upsert_line(lines, task_id:, task_title:, task_path:)
          filtered = lines.reject { |line| extract_task_id(line) == task_id.to_s }
          filtered << tracked_line(task_id: task_id, task_title: task_title, task_path: task_path)
          filtered.uniq.sort
        end

        def self.tracked_line(task_id:, task_title:, task_path:)
          "Tracked in ace-task: [#{task_id}](#{task_url(task_path)})"
        end

        def self.extract_task_id(line)
          match = line.match(/\[([^\]]+)\]\(/)
          match ? match[1] : nil
        end

        def self.render_body(lines)
          ([STICKY_MARKER] + lines).join("\n")
        end

        def self.create_comment(issue_id:, body:)
          GhCliExecutor.execute("issue", ["comment", issue_id.to_s, "--body", body]).tap do |result|
            raise "Failed to create sticky comment for issue #{issue_id}: #{result[:stderr]}" unless result[:success]
          end
        end

        def self.update_comment(issue_id:, comment_id:, body:)
          GhCliExecutor.execute("api", [
            "repos/{owner}/{repo}/issues/comments/#{comment_id}",
            "--method", "PATCH",
            "--field", "body=#{body}"
          ]).tap do |result|
            raise "Failed to update sticky comment for issue #{issue_id}: #{result[:stderr]}" unless result[:success]
          end
        end

        def self.delete_comment(issue_id:, comment_id:)
          GhCliExecutor.execute("api", [
            "repos/{owner}/{repo}/issues/comments/#{comment_id}",
            "--method", "DELETE"
          ]).tap do |result|
            raise "Failed to delete sticky comment for issue #{issue_id}: #{result[:stderr]}" unless result[:success]
          end
        end

        def self.ensure_label(issue_id, labels)
          return if labels.any? { |label| label["name"] == TRACKED_LABEL }

          result = GhCliExecutor.execute("issue", ["edit", issue_id.to_s, "--add-label", TRACKED_LABEL])
          raise "Failed to add #{TRACKED_LABEL} label to issue #{issue_id}: #{result[:stderr]}" unless result[:success]
        end

        def self.remove_label(issue_id, labels)
          return unless labels.any? { |label| label["name"] == TRACKED_LABEL }

          result = GhCliExecutor.execute("issue", ["edit", issue_id.to_s, "--remove-label", TRACKED_LABEL])
          raise "Failed to remove #{TRACKED_LABEL} label from issue #{issue_id}: #{result[:stderr]}" unless result[:success]
        end

        def self.validate_link!(issue_id:, task_id:, previous_task_id: nil, lines: nil)
          issue = fetch_issue(issue_id)
          sticky = find_sticky_comment(issue["comments"] || [])
          lines ||= tracked_lines(sticky&.dig("body"))
          owners = lines.map { |line| extract_task_id(line) }.compact.uniq
          return true if owners.empty?
          return true if owners == [task_id.to_s]
          return true if previous_task_id && owners == [previous_task_id.to_s]

          raise OwnershipConflict, "GitHub issue ##{issue_id} is already owned by task #{owners.first}"
        end

        def self.sync_lifecycle(issue_id:, issue_state:, task_status:)
          terminal = TERMINAL_STATUSES.include?(task_status.to_s.downcase)
          issue_open = issue_state.to_s.upcase == "OPEN"

          if terminal && issue_open
            close_result = GhCliExecutor.execute("issue", ["close", issue_id.to_s])
            raise "Failed to close issue #{issue_id}: #{close_result[:stderr]}" unless close_result[:success]
          elsif !terminal && !issue_open
            reopen_result = GhCliExecutor.execute("issue", ["reopen", issue_id.to_s])
            raise "Failed to reopen issue #{issue_id}: #{reopen_result[:stderr]}" unless reopen_result[:success]
          end
        end

        def self.task_url(task_path)
          return task_path.to_s if task_path.to_s.empty?

          repo_root = repo_root_path
          relative = if repo_root && task_path.start_with?(repo_root + "/")
            task_path.delete_prefix(repo_root + "/")
          else
            task_path.to_s
          end

          repo_slug = github_repo_slug
          return relative unless repo_slug

          "https://github.com/#{repo_slug}/blob/HEAD/#{relative}"
        end

        def self.repo_root_path
          stdout, _stderr, status = Open3.capture3("git", "rev-parse", "--show-toplevel")
          return nil unless status.success?

          stdout.strip
        rescue
          nil
        end

        def self.github_repo_slug
          stdout, _stderr, status = Open3.capture3("git", "remote", "get-url", "origin")
          return nil unless status.success?

          url = stdout.strip
          return Regexp.last_match(1) if url.match(%r{github\.com[:/](.+?)(?:\.git)?$})

          nil
        rescue
          nil
        end

        private_class_method :sync_issue, :fetch_issue, :find_sticky_comment, :tracked_lines, :remove_previous_line,
          :upsert_line, :tracked_line, :extract_task_id, :render_body, :create_comment, :update_comment, :delete_comment,
          :ensure_label, :remove_label, :cleanup_tracking_artifacts, :sync_lifecycle, :task_url, :repo_root_path,
          :github_repo_slug
      end

      # Backward-compatible alias for early integration experiments.
      IssueSync = GithubIssueSync
    end
  end
end
