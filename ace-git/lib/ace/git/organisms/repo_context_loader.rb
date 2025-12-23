# frozen_string_literal: true

module Ace
  module Git
    module Organisms
      # Orchestrates loading complete repository context
      # Combines branch info, task pattern detection, and PR metadata
      class RepoContextLoader
        class << self
          # Load complete repository context
          # @param options [Hash] Options for context loading
          # @option options [Boolean] :include_pr Whether to fetch PR metadata (default: true)
          # @option options [Boolean] :include_pr_activity Whether to fetch PR activity (default: true)
          # @option options [Boolean] :include_commits Whether to fetch recent commits (default: true)
          # @option options [Integer] :commits_limit Number of recent commits to fetch (default: 3)
          # @option options [Integer] :timeout Timeout for network operations like PR fetch (default: network_timeout)
          # @return [Models::RepoContext] Complete repository context
          def load(options = {})
            include_pr = options.fetch(:include_pr, true)
            include_pr_activity = options.fetch(:include_pr_activity, true)
            include_commits = options.fetch(:include_commits, true)
            commits_limit = options.fetch(:commits_limit, Ace::Git.commits_limit)
            timeout = options.fetch(:timeout, Ace::Git.network_timeout)

            # Get repository type and state
            repo_type = Atoms::RepositoryChecker.repository_type
            repo_state = Atoms::RepositoryStateDetector.detect

            # Check if we can proceed
            unless Atoms::RepositoryChecker.usable?
              return Models::RepoContext.new(
                branch: nil,
                repository_type: repo_type,
                repository_state: repo_state
              )
            end

            # Get branch information
            branch_info = Molecules::BranchReader.full_info

            # Extract task pattern from branch name
            task_pattern = nil
            if branch_info[:name] && branch_info[:name] != "HEAD"
              task_pattern = Atoms::TaskPatternExtractor.extract(branch_info[:name])
            end

            # Fetch git status (always, it's fast and local)
            git_status_sb = fetch_git_status

            # Fetch recent commits if requested
            recent_commits = nil
            if include_commits && commits_limit > 0
              recent_commits = fetch_recent_commits(limit: commits_limit)
            end

            # Fetch PR metadata if requested
            pr_metadata = nil
            if include_pr && !branch_info[:detached]
              pr_metadata = fetch_pr_metadata(timeout: timeout)
            end

            # Fetch PR activity if requested
            pr_activity = nil
            if include_pr_activity && !branch_info[:detached]
              pr_activity = fetch_pr_activity(
                current_branch: branch_info[:name],
                timeout: timeout
              )
            end

            # Build and return context
            Models::RepoContext.from_data(
              branch_info: branch_info,
              task_pattern: task_pattern,
              pr_metadata: pr_metadata,
              pr_activity: pr_activity,
              git_status_sb: git_status_sb,
              recent_commits: recent_commits,
              repo_type: repo_type,
              repo_state: repo_state
            )
          end

          # Load context for a specific PR
          # @param pr_identifier [String] PR identifier
          # @param options [Hash] Options
          # @return [Models::RepoContext] Context with PR data
          def load_for_pr(pr_identifier, options = {})
            timeout = options.fetch(:timeout, Ace::Git.network_timeout)

            # Get basic context
            context = load(include_pr: false)

            # Fetch specific PR metadata
            begin
              result = Molecules::PrMetadataFetcher.fetch_metadata(pr_identifier, timeout: timeout)
              pr_metadata = result[:success] ? result[:metadata] : nil
            rescue Ace::Git::Error
              pr_metadata = nil
            end

            # Return context with PR data
            Models::RepoContext.from_data(
              branch_info: {
                name: context.branch,
                tracking: context.tracking,
                ahead: context.ahead,
                behind: context.behind
              },
              task_pattern: context.task_pattern,
              pr_metadata: pr_metadata,
              repo_type: context.repository_type,
              repo_state: context.repository_state
            )
          end

          # Load minimal context (branch only, no PR)
          # @return [Models::RepoContext] Minimal context
          def load_minimal
            load(include_pr: false, include_pr_activity: false, include_commits: false)
          end

          private

          # Fetch git status in short branch format
          # @return [String, nil] Git status output or nil
          def fetch_git_status
            result = Atoms::GitStatusFetcher.fetch_status_sb
            result[:success] ? result[:output] : nil
          rescue StandardError
            nil
          end

          # Fetch recent commits
          # @param limit [Integer] Number of commits to fetch
          # @return [Array, nil] Array of commit hashes or nil
          def fetch_recent_commits(limit:)
            result = Molecules::RecentCommitsFetcher.fetch(limit: limit)
            result[:success] ? result[:commits] : nil
          rescue StandardError
            nil
          end

          # Fetch PR metadata for current branch
          # @param timeout [Integer] Timeout in seconds
          # @return [Hash, nil] PR metadata or nil
          def fetch_pr_metadata(timeout:)
            # First try to find PR for current branch
            pr_number = Molecules::PrMetadataFetcher.find_pr_for_branch(timeout: timeout)
            return nil unless pr_number

            # Then fetch full metadata
            result = Molecules::PrMetadataFetcher.fetch_metadata(pr_number, timeout: timeout)
            result[:success] ? result[:metadata] : nil
          rescue Ace::Git::GhNotInstalledError, Ace::Git::GhAuthenticationError
            # gh not available, skip PR metadata
            nil
          rescue Ace::Git::PrNotFoundError
            # No PR for this branch
            nil
          rescue Ace::Git::TimeoutError
            # Timeout, skip PR metadata
            nil
          rescue StandardError
            # Any other error, skip PR metadata
            nil
          end

          # Fetch PR activity (recently merged and open PRs)
          # @param current_branch [String] Current branch name to exclude from open PRs
          # @param timeout [Integer] Timeout in seconds
          # @return [Hash, nil] PR activity with :merged and :open arrays (symbol keys), or nil
          #   Each PR in the arrays has string keys from JSON parsing: "number", "title", etc.
          def fetch_pr_activity(current_branch:, timeout:)
            merged_result = Molecules::PrMetadataFetcher.fetch_recently_merged(
              limit: Ace::Git.merged_prs_limit,
              timeout: timeout
            )
            open_result = Molecules::PrMetadataFetcher.fetch_open_prs(
              exclude_branch: current_branch,
              timeout: timeout
            )

            # Return nil if both failed
            return nil unless merged_result[:success] || open_result[:success]

            # Use symbol keys for outer hash, string keys for PR data (from JSON)
            # This is documented behavior - consumers should access via pr_activity[:merged]
            # and individual PRs via pr["number"], pr["title"], etc.
            {
              merged: merged_result[:success] ? merged_result[:prs] : [],
              open: open_result[:success] ? open_result[:prs] : []
            }
          rescue StandardError
            # Any error, skip PR activity
            nil
          end
        end
      end
    end
  end
end
