# frozen_string_literal: true

module Ace
  module Git
    module Models
      # Data structure representing repository status
      # Includes branch info, task pattern, PR metadata, and repository state
      class RepoStatus
        attr_reader :branch, :tracking, :ahead, :behind, :task_pattern,
          :pr_metadata, :pr_activity, :git_status_sb, :recent_commits,
          :repository_type, :repository_state

        # @param branch [String] Current branch name
        # @param tracking [String, nil] Remote tracking branch
        # @param ahead [Integer] Commits ahead of remote
        # @param behind [Integer] Commits behind remote
        # @param task_pattern [String, nil] Detected task pattern from branch
        # @param pr_metadata [Hash, nil] PR metadata if available
        # @param pr_activity [Hash, nil] PR activity (merged and open PRs)
        # @param git_status_sb [String, nil] Output of git status -sb
        # @param recent_commits [Array, nil] Recent commits array
        # @param repository_type [Symbol] :normal, :detached, :bare, :worktree, :not_git
        # @param repository_state [Symbol] :clean, :dirty, :rebasing, :merging
        def initialize(
          branch:,
          tracking: nil,
          ahead: 0,
          behind: 0,
          task_pattern: nil,
          pr_metadata: nil,
          pr_activity: nil,
          git_status_sb: nil,
          recent_commits: nil,
          repository_type: :normal,
          repository_state: :clean
        )
          @branch = branch
          @tracking = tracking
          @ahead = ahead
          @behind = behind
          @task_pattern = task_pattern
          @pr_metadata = pr_metadata
          @pr_activity = pr_activity
          @git_status_sb = git_status_sb
          @recent_commits = recent_commits
          @repository_type = repository_type
          @repository_state = repository_state
        end

        # Check if branch is detached
        # @return [Boolean] True if detached HEAD
        def detached?
          branch == "HEAD" || repository_type == :detached
        end

        # Check if tracking remote
        # @return [Boolean] True if has tracking branch
        def tracking?
          !tracking.nil? && !tracking.empty?
        end

        # Check if up to date with remote
        # @return [Boolean] True if no ahead/behind
        def up_to_date?
          ahead == 0 && behind == 0
        end

        # Check if has associated PR
        # @return [Boolean] True if PR metadata present
        def has_pr?
          !pr_metadata.nil? && !pr_metadata.empty?
        end

        # Check if has detected task pattern
        # @return [Boolean] True if task pattern found
        def has_task_pattern?
          !task_pattern.nil? && !task_pattern.empty?
        end

        # Check if has PR activity data
        # @return [Boolean] True if any merged or open PRs present
        def has_pr_activity?
          return false if pr_activity.nil?

          merged = pr_activity[:merged] || pr_activity["merged"] || []
          open = pr_activity[:open] || pr_activity["open"] || []
          !merged.empty? || !open.empty?
        end

        # Check if has recent commits data
        # @return [Boolean] True if recent commits present
        def has_recent_commits?
          !recent_commits.nil? && !recent_commits.empty?
        end

        # Check if has git status output
        # @return [Boolean] True if git status output present
        def has_git_status?
          !git_status_sb.nil? && !git_status_sb.empty?
        end

        # Check if repository is clean
        # @return [Boolean] True if no uncommitted changes
        def clean?
          repository_state == :clean
        end

        # Count dirty files from git status output
        # @return [Integer] Number of dirty files (non-branch lines in git status -sb)
        def dirty_file_count
          return 0 unless has_git_status?

          git_status_sb.lines.count { |l| !l.start_with?("##") }
        end

        # Get tracking status description
        # @return [String] Human-readable status
        def tracking_status
          return "no tracking branch" unless tracking?

          if up_to_date?
            "up to date"
          elsif ahead > 0 && behind > 0
            "#{ahead} ahead, #{behind} behind"
          elsif ahead > 0
            "#{ahead} ahead"
          else
            "#{behind} behind"
          end
        end

        # Convert to hash
        # @return [Hash] Hash representation
        def to_h
          {
            branch: branch,
            tracking: tracking,
            ahead: ahead,
            behind: behind,
            up_to_date: up_to_date?,
            task_pattern: task_pattern,
            pr_metadata: pr_metadata,
            pr_activity: pr_activity,
            git_status_sb: git_status_sb,
            recent_commits: recent_commits,
            repository_type: repository_type,
            repository_state: repository_state,
            detached: detached?,
            has_pr: has_pr?,
            has_pr_activity: has_pr_activity?,
            has_recent_commits: has_recent_commits?,
            has_git_status: has_git_status?,
            has_task_pattern: has_task_pattern?,
            clean: clean?,
            dirty_files: dirty_file_count
          }
        end

        # Convert to JSON
        # @return [String] JSON representation
        def to_json(*args)
          to_h.to_json(*args)
        end

        # Generate markdown output
        # @return [String] Markdown-formatted status
        # @note Delegates to Atoms::StatusFormatter for ATOM pattern compliance
        def to_markdown
          Atoms::StatusFormatter.to_markdown(self)
        end

        # Create from loaded data
        # @param branch_info [Hash] Branch information
        # @param task_pattern [String, nil] Detected task pattern
        # @param pr_metadata [Hash, nil] PR metadata
        # @param pr_activity [Hash, nil] PR activity (merged and open PRs)
        # @param git_status_sb [String, nil] Output of git status -sb
        # @param recent_commits [Array, nil] Recent commits array
        # @param repo_type [Symbol] Repository type
        # @param repo_state [Symbol] Repository state
        # @return [RepoStatus] New instance
        def self.from_data(branch_info:, task_pattern: nil, pr_metadata: nil,
          pr_activity: nil, git_status_sb: nil, recent_commits: nil,
          repo_type: :normal, repo_state: :clean)
          new(
            branch: branch_info[:name] || branch_info["name"],
            tracking: branch_info[:tracking] || branch_info["tracking"],
            ahead: branch_info[:ahead] || branch_info["ahead"] || 0,
            behind: branch_info[:behind] || branch_info["behind"] || 0,
            task_pattern: task_pattern,
            pr_metadata: pr_metadata,
            pr_activity: pr_activity,
            git_status_sb: git_status_sb,
            recent_commits: recent_commits,
            repository_type: repo_type,
            repository_state: repo_state
          )
        end
      end
    end
  end
end
