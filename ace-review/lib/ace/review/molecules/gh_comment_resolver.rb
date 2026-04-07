# frozen_string_literal: true

require "json"

module Ace
  module Review
    module Molecules
      # Resolve PR comments by replying and/or resolving threads
      # Used by the review-pr workflow to mark feedback as addressed
      class GhCommentResolver
        # Reply to a PR with a comment indicating a fix
        #
        # @param pr_identifier [String] PR identifier (number, URL, or owner/repo#number)
        # @param commit_sha [String] Commit SHA that addresses the feedback
        # @param message [String, nil] Optional custom message (default: "Fixed in {sha}")
        # @param options [Hash] Options
        # @option options [Integer] :timeout Timeout in seconds (default: 30)
        # @return [Hash] Result with :success, :comment_url, :error
        def self.reply(pr_identifier, commit_sha, message: nil, options: {})
          # Guard: require either commit_sha or custom message
          if (commit_sha.nil? || commit_sha.to_s.strip.empty?) && (message.nil? || message.strip.empty?)
            return {success: false, error: "Commit SHA or message required"}
          end

          # Parse identifier using ace-git
          parsed = Ace::Git::Atoms::PrIdentifierParser.parse(pr_identifier)
          gh_format = parsed.gh_format

          # Build message
          short_sha = commit_sha.to_s[0..6]
          body = message || "Fixed in #{short_sha}"

          # Default timeout
          timeout = options[:timeout] || 30

          # Post comment using gh CLI
          result = Ace::Git::Molecules::GhCliExecutor.execute(
            "pr",
            ["comment", gh_format, "--body", body],
            timeout: timeout
          )

          if result[:success]
            # Try to extract comment URL from output
            comment_url = extract_comment_url(result[:stdout])
            {
              success: true,
              comment_url: comment_url,
              message: body
            }
          else
            {
              success: false,
              error: "Failed to post reply: #{result[:stderr]}"
            }
          end
        rescue Ace::Review::Errors::GhCliNotInstalledError, Ace::Review::Errors::GhAuthenticationError,
          Ace::Git::GhNotInstalledError, Ace::Git::GhAuthenticationError
          raise
        rescue => e
          {
            success: false,
            error: "Failed to post reply: #{e.message}"
          }
        end

        # Valid thread ID pattern (GitHub GraphQL node IDs)
        # PRRT_ = Pull Request Review Thread
        THREAD_ID_PATTERN = /\APRRT_[A-Za-z0-9_-]+\z/

        # Resolve a review thread by thread ID using GitHub GraphQL API
        #
        # Note: This requires the thread's node ID (starts with "PRRT_")
        # which can be obtained from the GhPrCommentFetcher results
        #
        # @param thread_id [String] GraphQL node ID of the review thread (e.g., "PRRT_abc123")
        # @param options [Hash] Options
        # @option options [Integer] :timeout Timeout in seconds (default: 30)
        # @return [Hash] Result with :success, :resolved, :error
        def self.resolve_thread(thread_id, options: {})
          return {success: false, error: "Thread ID required"} if thread_id.nil? || thread_id.empty?

          # Validate thread_id format to prevent GraphQL injection
          unless thread_id.match?(THREAD_ID_PATTERN)
            return {success: false, error: "Invalid thread ID format. Expected PRRT_xxx pattern."}
          end

          # Default timeout
          timeout = options[:timeout] || 30

          # Build and execute GraphQL mutation
          mutation = build_resolve_thread_mutation(thread_id)

          # Execute via gh api graphql
          result = Ace::Git::Molecules::GhCliExecutor.execute(
            "api",
            ["graphql", "-f", "query=#{mutation}"],
            timeout: timeout
          )

          if result[:success]
            begin
              response = JSON.parse(result[:stdout])
              is_resolved = response.dig("data", "resolveReviewThread", "thread", "isResolved")

              if is_resolved
                {success: true, resolved: true}
              elsif response["errors"]
                {success: false, error: response["errors"].first["message"]}
              else
                {success: false, error: "Thread not resolved"}
              end
            rescue JSON::ParserError => e
              {success: false, error: "Failed to parse response: #{e.message}"}
            end
          else
            {
              success: false,
              error: "Failed to resolve thread: #{result[:stderr]}"
            }
          end
        rescue Ace::Review::Errors::GhCliNotInstalledError, Ace::Review::Errors::GhAuthenticationError,
          Ace::Git::GhNotInstalledError, Ace::Git::GhAuthenticationError
          raise
        rescue => e
          {
            success: false,
            error: "Failed to resolve thread: #{e.message}"
          }
        end

        # Reply to PR and resolve thread in one operation
        #
        # @param pr_identifier [String] PR identifier
        # @param thread_id [String, nil] Thread ID to resolve (optional)
        # @param commit_sha [String] Commit SHA that addresses the feedback
        # @param message [String, nil] Optional custom message
        # @param options [Hash] Options
        # @return [Hash] Result with :success, :reply_result, :resolve_result, :error
        def self.reply_and_resolve(pr_identifier, commit_sha, thread_id: nil, message: nil, options: {})
          results = {success: true}

          # Step 1: Reply with commit reference
          reply_result = reply(pr_identifier, commit_sha, message: message, options: options)
          results[:reply_result] = reply_result

          unless reply_result[:success]
            results[:success] = false
            results[:error] = reply_result[:error]
            return results
          end

          # Step 2: Resolve thread if thread_id provided
          if thread_id && !thread_id.empty?
            resolve_result = resolve_thread(thread_id, options: options)
            results[:resolve_result] = resolve_result

            # Thread resolution failure is not fatal - reply succeeded
            unless resolve_result[:success]
              results[:partial] = true
              results[:warning] = "Reply posted but thread not resolved: #{resolve_result[:error]}"
            end
          end

          results
        end

        private

        # Build GraphQL mutation for resolving a review thread
        #
        # @param thread_id [String] Thread ID (validated before calling)
        # @return [String] GraphQL mutation query
        def self.build_resolve_thread_mutation(thread_id)
          <<~GRAPHQL
            mutation {
              resolveReviewThread(input: {threadId: "#{thread_id}"}) {
                thread {
                  isResolved
                }
              }
            }
          GRAPHQL
        end

        # Extract comment URL from gh CLI output
        #
        # @param output [String] gh CLI stdout
        # @return [String, nil] Comment URL or nil
        def self.extract_comment_url(output)
          return nil if output.nil? || output.empty?

          # gh pr comment outputs the URL of the created comment
          output.strip if output.include?("github.com")
        end

        private_class_method :build_resolve_thread_mutation, :extract_comment_url
      end
    end
  end
end
