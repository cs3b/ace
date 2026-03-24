# frozen_string_literal: true

require "json"
require_relative "../atoms/retry_with_backoff"

module Ace
  module Review
    module Molecules
      # Fetch PR comments and reviews via gh CLI
      class GhPrCommentFetcher
        # Known bot usernames to filter out
        BOT_PATTERNS = %w[
          dependabot
          github-actions
          renovate
          codecov
          sonarcloud
          snyk
          mergify
          greenkeeper
        ].freeze

        # GraphQL query limits
        # Note: These are hardcoded limits. PRs exceeding these will have truncated data.
        MAX_REVIEW_THREADS = 100
        MAX_COMMENTS_PER_THREAD = 50

        # GraphQL query template for fetching review threads
        REVIEW_THREADS_QUERY = <<~GRAPHQL
          query($owner: String!, $repo: String!, $number: Int!) {
            repository(owner: $owner, name: $repo) {
              pullRequest(number: $number) {
                reviewThreads(first: #{MAX_REVIEW_THREADS}) {
                  totalCount
                  pageInfo {
                    hasNextPage
                  }
                  nodes {
                    id
                    isResolved
                    path
                    line
                    comments(first: #{MAX_COMMENTS_PER_THREAD}) {
                      totalCount
                      pageInfo {
                        hasNextPage
                      }
                      nodes {
                        id
                        body
                        author { login }
                        createdAt
                      }
                    }
                  }
                }
              }
            }
          }
        GRAPHQL

        # Fetch PR comments and reviews
        #
        # @param pr_identifier [String] PR identifier (number, URL, or owner/repo#number)
        # @param options [Hash] Fetch options
        # @option options [Integer] :max_retries Maximum retry attempts (default: 3)
        # @option options [Integer] :initial_backoff Initial backoff in seconds (default: 1)
        # @option options [Integer] :timeout Timeout in seconds for gh CLI (default: 30)
        # @option options [Boolean] :include_resolved Include resolved review threads (default: false)
        # @option options [Boolean] :include_bots Include bot comments (default: false)
        # @return [Hash] Result with :success, :comments, :reviews, :review_threads, :error
        def self.fetch(pr_identifier, options = {})
          # Parse identifier to get gh CLI format using ace-git
          parsed = Ace::Git::Atoms::PrIdentifierParser.parse(pr_identifier)
          gh_format = parsed.gh_format

          # Default timeout for PR operations
          timeout = options[:timeout] || 30

          # Fetch comments and reviews as JSON
          # Fields: comments (issue-level), reviews (code review objects)
          fields = "comments,reviews,number,title,author"

          result = Ace::Review::Atoms::RetryWithBackoff.execute(options) do
            Ace::Review::Molecules::GhCliExecutor.execute("pr", ["view", gh_format, "--json", fields], timeout: timeout)
          end

          if result[:success]
            data = JSON.parse(result[:stdout])

            # Extract and structure comments
            comments = extract_comments(data, options)
            reviews = extract_reviews(data, options)

            # Fetch review threads via GraphQL (inline code comments)
            # Convert parsed to hash for fetch_review_threads which expects hash access
            review_threads = fetch_review_threads(parsed.to_h, options)

            {
              success: true,
              comments: comments,
              reviews: reviews,
              review_threads: review_threads,
              pr_number: data["number"],
              pr_title: data["title"],
              pr_author: data.dig("author", "login"),
              identifier: gh_format,
              parsed: parsed.to_h,
              raw_data: data
            }
          else
            handle_fetch_error(result, pr_identifier)
          end
        rescue JSON::ParserError => e
          {
            success: false,
            error: "Failed to parse PR comments: #{e.message}"
          }
        rescue Ace::Review::Errors::GhCliNotInstalledError, Ace::Review::Errors::GhAuthenticationError
          raise
        rescue => e
          {
            success: false,
            error: "Failed to fetch PR comments: #{e.message}"
          }
        end

        # Check if there are any meaningful comments
        #
        # @param result [Hash] Result from fetch
        # @return [Boolean] true if there are comments, reviews, or review threads worth reporting
        def self.has_comments?(result)
          return false unless result[:success]

          (result[:comments]&.any? || false) ||
            (result[:reviews]&.any? || false) ||
            (result[:review_threads]&.any? || false)
        end

        private

        # Extract and structure issue-level comments
        #
        # @param data [Hash] Parsed JSON from gh CLI
        # @param options [Hash] Fetch options
        # @return [Array<Hash>] Structured comments
        def self.extract_comments(data, options = {})
          comments = data["comments"] || []
          include_bots = options[:include_bots] || false

          comments.filter_map do |comment|
            author = comment.dig("author", "login") || "unknown"

            # Skip bot comments unless explicitly included
            next if !include_bots && bot_author?(author)

            # Skip empty comments
            body = comment["body"]&.strip
            next if body.nil? || body.empty?

            {
              type: "issue_comment",
              id: comment["id"] || "IC_#{comment["databaseId"]}",
              author: author,
              body: body,
              created_at: comment["createdAt"],
              url: comment["url"]
            }
          end
        end

        # Extract and structure code reviews
        #
        # @param data [Hash] Parsed JSON from gh CLI
        # @param options [Hash] Fetch options
        # @return [Array<Hash>] Structured reviews
        def self.extract_reviews(data, options = {})
          reviews = data["reviews"] || []
          include_bots = options[:include_bots] || false

          reviews.filter_map do |review|
            author = review.dig("author", "login") || "unknown"

            # Skip bot reviews unless explicitly included
            next if !include_bots && bot_author?(author)

            state = review["state"] || "COMMENTED"
            body = review["body"]&.strip

            # Include reviews with meaningful state even if body is empty
            # Approvals and change-requests signal important reviewer decisions
            has_meaningful_state = %w[APPROVED CHANGES_REQUESTED].include?(state)
            next if (body.nil? || body.empty?) && !has_meaningful_state

            # Set placeholder body for state-only reviews
            effective_body = if body.nil? || body.empty?
              case state
              when "APPROVED" then "(Approved without comment)"
              when "CHANGES_REQUESTED" then "(Changes requested without comment)"
              else body
              end
            else
              body
            end

            {
              type: "review",
              id: review["id"] || "PRR_#{review["databaseId"]}",
              author: author,
              state: state,
              body: effective_body,
              created_at: review["submittedAt"] || review["createdAt"],
              url: review["url"]
            }
          end
        end

        # Fetch review threads via GraphQL API
        #
        # @param parsed [Hash] Parsed PR identifier with :repo (owner/repo format), :number
        # @param options [Hash] Fetch options
        # @return [Array<Hash>] Structured review threads, empty array on failure
        def self.fetch_review_threads(parsed, options = {})
          repo_full = parsed[:repo]
          number = parsed[:number]

          # Try to discover repo from git remote if not provided in identifier
          if repo_full.nil? && number
            repo_full = discover_repo_from_remote(options)
          end

          # Skip if we still don't have repo info
          unless repo_full && number
            warn "Warning: Cannot fetch inline code comments - repository info not available. " \
                 "Use full PR format (owner/repo#number) or run from within a git repository."
            return []
          end

          # Parse owner/repo from combined format (e.g., "owner/repo")
          parts = repo_full.split("/", 2)
          unless parts.length == 2
            warn "Warning: Cannot fetch inline code comments - invalid repo format: #{repo_full}"
            return []
          end
          owner = parts[0]
          repo = parts[1]

          timeout = options[:timeout] || 30
          include_resolved = options[:include_resolved] || false

          # Execute GraphQL query
          result = Ace::Review::Atoms::RetryWithBackoff.execute(options) do
            Ace::Review::Molecules::GhCliExecutor.execute(
              "api",
              [
                "graphql",
                "-f", "query=#{REVIEW_THREADS_QUERY}",
                "-F", "owner=#{owner}",
                "-F", "repo=#{repo}",
                "-F", "number=#{number}"
              ],
              timeout: timeout
            )
          end

          return [] unless result[:success]

          data = JSON.parse(result[:stdout])

          # Check for GraphQL errors in response
          if data["errors"]
            error_messages = data["errors"].map { |e| e["message"] }.join("; ")
            warn "Warning: GraphQL errors fetching review threads: #{error_messages}"
          end

          extract_review_threads(data, include_resolved)
        rescue JSON::ParserError => e
          warn "Warning: Failed to parse review threads response: #{e.message}"
          []
        rescue => e
          warn "Warning: Failed to fetch review threads: #{e.message}"
          []
        end

        # Extract and structure review threads from GraphQL response
        #
        # @param data [Hash] Parsed GraphQL response
        # @param include_resolved [Boolean] Whether to include resolved threads
        # @return [Array<Hash>] Structured review threads
        def self.extract_review_threads(data, include_resolved = false)
          threads_data = data.dig("data", "repository", "pullRequest", "reviewThreads") || {}
          threads = threads_data["nodes"] || []

          # Warn if results are truncated
          check_pagination_limits(threads_data, threads)

          threads.filter_map do |thread|
            # Skip resolved threads unless explicitly included
            next if thread["isResolved"] && !include_resolved

            comments_data = thread["comments"] || {}
            comments = (comments_data["nodes"] || []).map do |comment|
              {
                id: comment["id"],
                author: comment.dig("author", "login") || "unknown",
                body: comment["body"]&.strip,
                created_at: comment["createdAt"]
              }
            end

            # Warn if thread comments are truncated
            if comments_data.dig("pageInfo", "hasNextPage")
              total = comments_data["totalCount"]
              warn "Warning: Thread #{thread["id"]} has #{total} comments, only #{MAX_COMMENTS_PER_THREAD} fetched"
            end

            # Skip threads with no comments
            next if comments.empty?

            {
              type: "review_thread",
              id: thread["id"],
              path: thread["path"],
              line: thread["line"],
              is_resolved: thread["isResolved"],
              comments: comments
            }
          end
        end

        # Check and warn about pagination limits
        #
        # @param threads_data [Hash] Review threads data from GraphQL response
        # @param threads [Array] Extracted thread nodes
        def self.check_pagination_limits(threads_data, threads)
          return unless threads_data.dig("pageInfo", "hasNextPage")

          total = threads_data["totalCount"]
          warn "Warning: PR has #{total} review threads, only #{MAX_REVIEW_THREADS} fetched. " \
               "Some comments may be missing."
        end

        # Check if author is a known bot
        #
        # @param author [String] GitHub username
        # @return [Boolean] true if author appears to be a bot
        def self.bot_author?(author)
          return false if author.nil?

          lowered = author.downcase
          BOT_PATTERNS.any? { |pattern| lowered.include?(pattern) } ||
            lowered.end_with?("[bot]") ||
            lowered.end_with?("-bot")
        end

        # Handle fetch errors and return appropriate error response
        #
        # @param result [Hash] gh CLI result
        # @param pr_identifier [String] Original PR identifier
        # @return [Hash] Error response
        def self.handle_fetch_error(result, pr_identifier)
          error_msg = result[:stderr].to_s

          # Check for specific error types
          if error_msg.include?("not found") || error_msg.include?("Could not resolve")
            raise Ace::Review::Errors::PrNotFoundError.new(pr_identifier, error_msg)
          elsif error_msg.include?("authentication") || error_msg.include?("Unauthorized")
            raise Ace::Review::Errors::GhAuthenticationError
          end

          # Generic error
          {
            success: false,
            error: "Failed to fetch PR comments: #{error_msg}"
          }
        end

        # Discover repository owner/name from git remote via gh CLI
        #
        # @param options [Hash] Fetch options
        # @option options [Integer] :timeout Timeout in seconds (default: 10)
        # @return [String, nil] "owner/name" format or nil if not a GitHub repo
        def self.discover_repo_from_remote(options = {})
          timeout = options[:timeout] || 10
          result = Ace::Review::Molecules::GhCliExecutor.execute(
            "repo",
            ["view", "--json", "owner,name"],
            timeout: timeout
          )
          return nil unless result[:success]

          data = JSON.parse(result[:stdout])
          owner = data.dig("owner", "login")
          name = data["name"]
          return nil unless owner && name

          "#{owner}/#{name}"
        rescue JSON::ParserError, StandardError
          nil
        end

        private_class_method :extract_comments, :extract_reviews, :fetch_review_threads,
          :extract_review_threads, :check_pagination_limits,
          :bot_author?, :handle_fetch_error, :discover_repo_from_remote
      end
    end
  end
end
