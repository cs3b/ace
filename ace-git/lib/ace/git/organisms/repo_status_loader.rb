# frozen_string_literal: true

module Ace
  module Git
    module Organisms
      # Orchestrates loading complete repository status
      # Combines branch info, task pattern detection, and PR evidence
      #
      # PR enrichment is provider-optional: it resolves the default forge
      # server and its registered provider via the core contract. With no
      # server configured, no provider registered, or a classified provider
      # failure, status stays purely local and the PR sections are skipped.
      class RepoStatusLoader
        class << self
          # Load complete repository status
          # @param options [Hash] Options for status loading
          # @option options [Boolean] :include_pr Whether to fetch PR evidence (default: true)
          # @option options [Boolean] :include_pr_activity Whether to fetch PR activity (default: true)
          # @option options [Boolean] :include_commits Whether to fetch recent commits (default: true)
          # @option options [Integer] :commits_limit Number of recent commits to fetch (default: 3)
          # @option options [Integer] :timeout Timeout for network operations like PR fetch (default: network_timeout)
          # @return [Models::RepoStatus] Complete repository status
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
              return Models::RepoStatus.new(
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

            # Fetch PR evidence (metadata and activity) via the provider contract
            pr_metadata = nil
            pr_activity = nil
            if !branch_info[:detached]
              pr_sections = fetch_pr_sections(
                current_branch: branch_info[:name],
                include_metadata: include_pr,
                include_activity: include_pr_activity,
                timeout: timeout
              )
              pr_metadata = pr_sections[:pr_metadata]
              pr_activity = pr_sections[:pr_activity]
            end

            # Build and return status
            Models::RepoStatus.from_data(
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

          # Load status for a specific PR
          # @param pr_identifier [String] PR identifier
          # @param options [Hash] Options
          # @return [Models::RepoStatus] Status with PR data
          def load_for_pr(pr_identifier, options = {})
            timeout = options.fetch(:timeout, Ace::Git.network_timeout)

            # Get basic status (skip PR activity since we're fetching a specific PR)
            status = load(include_pr: false, include_pr_activity: false)

            # Fetch specific PR evidence
            pr_metadata = resolve_pr_metadata(pr_identifier, timeout: timeout)

            # Return status with PR data
            Models::RepoStatus.from_data(
              branch_info: {
                name: status.branch,
                tracking: status.tracking,
                ahead: status.ahead,
                behind: status.behind
              },
              task_pattern: status.task_pattern,
              pr_metadata: pr_metadata,
              repo_type: status.repository_type,
              repo_state: status.repository_state
            )
          end

          # Load minimal status (branch only, no PR)
          # @return [Models::RepoStatus] Minimal status
          def load_minimal
            load(include_pr: false, include_pr_activity: false, include_commits: false)
          end

          private

          # Resolve a specific PR via the provider contract
          # @return [ProviderPullRequest, nil] PR evidence or nil
          def resolve_pr_metadata(pr_identifier, timeout:)
            provider = active_provider(timeout: timeout)
            return nil unless provider

            provider.pull_request(number: pr_identifier)
          rescue Ace::Git::Error
            # Classified provider failure: keep status local, skip PR evidence
            nil
          end

          # Fetch PR evidence sections via the provider contract
          # @return [Hash] {:pr_metadata => ProviderPullRequest, :pr_activity => Hash}
          def fetch_pr_sections(current_branch:, include_metadata:, include_activity:, timeout:)
            provider = active_provider(timeout: timeout)
            return {pr_metadata: nil, pr_activity: nil} unless provider

            metadata = include_metadata ? provider.pull_request_for_branch(branch: current_branch) : nil
            activity = include_activity ? fetch_activity(provider, current_branch: current_branch) : nil

            {pr_metadata: metadata, pr_activity: activity}
          rescue Ace::Git::Error
            # Classified provider failure: keep status local, skip PR evidence
            {pr_metadata: nil, pr_activity: nil}
          end

          # Build merged/open activity lists from recent PR evidence
          def fetch_activity(provider, current_branch:)
            prs = provider.recent_pull_requests(limit: 30)
            merged = prs
              .select { |pr| pr.state == :merged }
              .first(Ace::Git.merged_prs_limit)
            open_prs = prs
              .select { |pr| pr.state == :open && pr.head_ref != current_branch }
              .first(Ace::Git.open_prs_limit)

            return nil if merged.empty? && open_prs.empty?

            {merged: merged, open: open_prs}
          end

          # Resolve the default server's registered provider, or nil.
          # Resolution failures are classified; enrichment is optional, so any
          # of them simply skips the PR sections.
          def active_provider(timeout:)
            server = ServerRegistry.resolve_default
            return nil unless server

            Providers.for(server, timeout: timeout)
          rescue Ace::Git::Error
            nil
          end

          # Fetch git status in short branch format
          # @return [String, nil] Git status output or nil
          def fetch_git_status
            result = Molecules::GitStatusFetcher.fetch_status_sb
            result[:success] ? result[:output] : nil
          rescue
            nil
          end

          # Fetch recent commits
          # @param limit [Integer] Number of commits to fetch
          # @return [Array, nil] Array of commit hashes or nil
          def fetch_recent_commits(limit:)
            result = Molecules::RecentCommitsFetcher.fetch(limit: limit)
            result[:success] ? result[:commits] : nil
          rescue
            nil
          end
        end
      end
    end
  end
end
