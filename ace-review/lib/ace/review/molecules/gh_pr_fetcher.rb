# frozen_string_literal: true

require "json"
require_relative "../atoms/retry_with_backoff"

module Ace
  module Review
    module Molecules
      # Fetch PR diff and metadata via gh CLI
      class GhPrFetcher
        # Fetch PR diff content
        #
        # @param pr_identifier [String] PR identifier (number, URL, or owner/repo#number)
        # @param options [Hash] Fetch options
        # @option options [Integer] :max_retries Maximum retry attempts (default: 3)
        # @option options [Integer] :initial_backoff Initial backoff in seconds (default: 1)
        # @option options [Integer] :timeout Timeout in seconds for gh CLI (default: 30)
        # @return [Hash] Result with :success, :diff, :error
        def self.fetch_diff(pr_identifier, options = {})
          # Parse identifier to get gh CLI format using ace-git
          parsed = Ace::Git::Atoms::PrIdentifierParser.parse(pr_identifier)
          gh_format = parsed.gh_format

          # Default timeout for PR diff operations
          timeout = options[:timeout] || 30

          # Fetch diff with retry logic
          result = Ace::Review::Atoms::RetryWithBackoff.execute(options) do
            Ace::Review::Molecules::GhCliExecutor.execute("pr", ["diff", gh_format], timeout: timeout)
          end

          if result[:success]
            {
              success: true,
              diff: result[:stdout],
              identifier: gh_format,
              parsed: parsed.to_h
            }
          else
            handle_fetch_error(result, pr_identifier)
          end
        rescue Ace::Review::Errors::DiffTooLargeError
          # Fall back to local git diff when GitHub API rejects large diffs
          fetch_local_diff_fallback(pr_identifier, options)
        rescue Ace::Review::Errors::GhCliNotInstalledError, Ace::Review::Errors::GhAuthenticationError
          # Re-raise authentication and installation errors
          raise
        rescue StandardError => e
          {
            success: false,
            error: "Failed to fetch PR diff: #{e.message}"
          }
        end

        # Fetch PR metadata (state, draft status, title, etc.)
        #
        # @param pr_identifier [String] PR identifier
        # @param options [Hash] Fetch options
        # @option options [Integer] :timeout Timeout in seconds for gh CLI (default: 30)
        # @return [Hash] Result with :success, :metadata, :error
        def self.fetch_metadata(pr_identifier, options = {})
          # Parse identifier using ace-git
          parsed = Ace::Git::Atoms::PrIdentifierParser.parse(pr_identifier)
          gh_format = parsed.gh_format

          # Default timeout for PR operations
          timeout = options[:timeout] || 30

          # Fetch metadata as JSON
          fields = "number,state,isDraft,title,body,author,headRefName,baseRefName,url"

          result = Ace::Review::Atoms::RetryWithBackoff.execute(options) do
            Ace::Review::Molecules::GhCliExecutor.execute("pr", ["view", gh_format, "--json", fields], timeout: timeout)
          end

          if result[:success]
            metadata = JSON.parse(result[:stdout])
            {
              success: true,
              metadata: metadata,
              identifier: gh_format,
              parsed: parsed.to_h
            }
          else
            handle_fetch_error(result, pr_identifier)
          end
        rescue JSON::ParserError => e
          {
            success: false,
            error: "Failed to parse PR metadata: #{e.message}"
          }
        rescue Ace::Review::Errors::GhCliNotInstalledError, Ace::Review::Errors::GhAuthenticationError
          raise
        rescue StandardError => e
          {
            success: false,
            error: "Failed to fetch PR metadata: #{e.message}"
          }
        end

        # Fetch both diff and metadata in one call
        #
        # @param pr_identifier [String] PR identifier
        # @param options [Hash] Fetch options
        # @return [Hash] Result with :success, :diff, :metadata, :error
        def self.fetch_pr(pr_identifier, options = {})
          # Fetch diff and metadata
          diff_result = fetch_diff(pr_identifier, options)
          return diff_result unless diff_result[:success]

          metadata_result = fetch_metadata(pr_identifier, options)
          return metadata_result unless metadata_result[:success]

          {
            success: true,
            diff: diff_result[:diff],
            metadata: metadata_result[:metadata],
            identifier: diff_result[:identifier],
            parsed: diff_result[:parsed]
          }
        end

        # Handle fetch errors and return appropriate error response
        #
        # @param result [Hash] gh CLI result
        # @param pr_identifier [String] Original PR identifier
        # @return [Hash] Error response
        def self.handle_fetch_error(result, pr_identifier)
          error_msg = result[:stderr].to_s
          exit_code = result[:exit_code]

          # Check for diff too large (HTTP 406 / file limit exceeded)
          if exit_code == 1 && (error_msg.match?(/\bHTTP 406\b|Not Acceptable/) || error_msg.include?("exceeded the maximum"))
            raise Ace::Review::Errors::DiffTooLargeError.new(pr_identifier, error_msg)
          end

          # Check for specific error types
          if error_msg.include?("not found") || error_msg.include?("Could not resolve")
            raise Ace::Review::Errors::PrNotFoundError.new(pr_identifier, error_msg)
          elsif error_msg.include?("authentication") || error_msg.include?("Unauthorized")
            raise Ace::Review::Errors::GhAuthenticationError
          end

          # Generic error
          {
            success: false,
            error: "Failed to fetch PR: #{error_msg}"
          }
        end

        # Fetch local git diff as fallback when GitHub API rejects large diffs
        #
        # @param pr_identifier [String] PR identifier (used to fetch base branch)
        # @param options [Hash] Fetch options
        # @return [Hash] Result with :success, :diff, :fallback
        def self.fetch_local_diff_fallback(pr_identifier, options = {})
          temp_ref = nil

          # Fetch PR metadata to get base branch and PR number
          metadata_result = fetch_metadata(pr_identifier, options)
          unless metadata_result[:success]
            return {
              success: false,
              error: "Cannot fall back to local diff: failed to fetch PR metadata — #{metadata_result[:error]}"
            }
          end

          base_ref = metadata_result[:metadata]["baseRefName"]
          pull_number = metadata_result[:metadata]["number"] || metadata_result.dig(:parsed, "number")
          temp_ref = "refs/ace/review/pr-#{pull_number}-#{Process.pid}"

          fetch_result = run_local_command("git", "fetch", "--no-tags", "origin",
                                           "+refs/pull/#{pull_number}/head:#{temp_ref}")
          unless fetch_result[:success]
            return {
              success: false,
              error: "Cannot fall back to local diff: git fetch PR head failed — #{fetch_result[:stderr]}"
            }
          end

          # Find merge base
          merge_base_result = run_local_command("git", "merge-base", "origin/#{base_ref}", temp_ref)
          unless merge_base_result[:success]
            return {
              success: false,
              error: "Cannot fall back to local diff: git merge-base failed — #{merge_base_result[:stderr]}"
            }
          end

          merge_base = merge_base_result[:stdout].strip

          # Diff against the fetched PR head rather than the caller's checkout state.
          diff_result = run_local_command("git", "diff", merge_base, temp_ref)
          unless diff_result[:success]
            return {
              success: false,
              error: "Cannot fall back to local diff: git diff failed — #{diff_result[:stderr]}"
            }
          end

          {
            success: true,
            diff: diff_result[:stdout],
            identifier: metadata_result[:identifier],
            parsed: metadata_result[:parsed],
            fallback: :local_git_diff
          }
        ensure
          delete_temp_ref(temp_ref) if temp_ref
        end

        # Execute a local command and return structured result
        #
        # @param args [Array<String>] Command and arguments
        # @return [Hash] Result with :success, :stdout, :stderr
        def self.run_local_command(*args)
          require "open3"
          stdout, stderr, status = Open3.capture3(*args)
          {
            success: status.success?,
            stdout: stdout,
            stderr: stderr
          }
        rescue StandardError => e
          {
            success: false,
            stdout: "",
            stderr: e.message
          }
        end

        def self.delete_temp_ref(temp_ref)
          run_local_command("git", "update-ref", "-d", temp_ref)
        end

        private_class_method :handle_fetch_error, :fetch_local_diff_fallback, :run_local_command, :delete_temp_ref
      end
    end
  end
end
