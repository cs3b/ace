# frozen_string_literal: true

module Ace
  module Git
    module Models
      # Data structure representing repository context
      # Includes branch info, task pattern, PR metadata, and repository state
      class RepoContext
        attr_reader :branch, :tracking, :ahead, :behind, :task_pattern,
                    :pr_metadata, :repository_type, :repository_state

        # @param branch [String] Current branch name
        # @param tracking [String, nil] Remote tracking branch
        # @param ahead [Integer] Commits ahead of remote
        # @param behind [Integer] Commits behind remote
        # @param task_pattern [String, nil] Detected task pattern from branch
        # @param pr_metadata [Hash, nil] PR metadata if available
        # @param repository_type [Symbol] :normal, :detached, :bare, :worktree, :not_git
        # @param repository_state [Symbol] :clean, :dirty, :rebasing, :merging
        def initialize(
          branch:,
          tracking: nil,
          ahead: 0,
          behind: 0,
          task_pattern: nil,
          pr_metadata: nil,
          repository_type: :normal,
          repository_state: :clean
        )
          @branch = branch
          @tracking = tracking
          @ahead = ahead
          @behind = behind
          @task_pattern = task_pattern
          @pr_metadata = pr_metadata
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

        # Check if repository is clean
        # @return [Boolean] True if no uncommitted changes
        def clean?
          repository_state == :clean
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
            repository_type: repository_type,
            repository_state: repository_state,
            detached: detached?,
            has_pr: has_pr?,
            has_task_pattern: has_task_pattern?,
            clean: clean?
          }
        end

        # Convert to JSON
        # @return [String] JSON representation
        def to_json(*args)
          to_h.to_json(*args)
        end

        # Generate markdown output
        # @return [String] Markdown-formatted context
        # @note Delegates to Atoms::ContextFormatter for ATOM pattern compliance
        def to_markdown
          Atoms::ContextFormatter.to_markdown(self)
        end

        # Create from loaded data
        # @param branch_info [Hash] Branch information
        # @param task_pattern [String, nil] Detected task pattern
        # @param pr_metadata [Hash, nil] PR metadata
        # @param repo_type [Symbol] Repository type
        # @param repo_state [Symbol] Repository state
        # @return [RepoContext] New instance
        def self.from_data(branch_info:, task_pattern: nil, pr_metadata: nil,
                           repo_type: :normal, repo_state: :clean)
          new(
            branch: branch_info[:name] || branch_info["name"],
            tracking: branch_info[:tracking] || branch_info["tracking"],
            ahead: branch_info[:ahead] || branch_info["ahead"] || 0,
            behind: branch_info[:behind] || branch_info["behind"] || 0,
            task_pattern: task_pattern,
            pr_metadata: pr_metadata,
            repository_type: repo_type,
            repository_state: repo_state
          )
        end
      end
    end
  end
end
