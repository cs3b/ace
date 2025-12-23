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
          # @option options [Integer] :timeout Timeout for PR fetch (default: 30)
          # @return [Models::RepoContext] Complete repository context
          def load(options = {})
            include_pr = options.fetch(:include_pr, true)
            timeout = options.fetch(:timeout, 30)

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

            # Fetch PR metadata if requested
            pr_metadata = nil
            if include_pr && !branch_info[:detached]
              pr_metadata = fetch_pr_metadata(timeout: timeout)
            end

            # Build and return context
            Models::RepoContext.from_data(
              branch_info: branch_info,
              task_pattern: task_pattern,
              pr_metadata: pr_metadata,
              repo_type: repo_type,
              repo_state: repo_state
            )
          end

          # Load context for a specific PR
          # @param pr_identifier [String] PR identifier
          # @param options [Hash] Options
          # @return [Models::RepoContext] Context with PR data
          def load_for_pr(pr_identifier, options = {})
            timeout = options.fetch(:timeout, 30)

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
            load(include_pr: false)
          end

          private

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
        end
      end
    end
  end
end
