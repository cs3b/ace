# frozen_string_literal: true

require "ace/git/github"
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
          parsed = Ace::Git::Github::PrIdentifier.parse(pr_identifier)
          gh_format = parsed.gh_format

          # Default timeout for PR diff operations
          timeout = options[:timeout] || 30

          # Fetch diff with retry logic
          result = Ace::Review::Atoms::RetryWithBackoff.execute(options) do
            Ace::Git::Github::CliExecutor.execute("pr", ["diff", *parsed.cli_target_args], timeout: timeout)
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
        rescue Ace::Review::Errors::GhCliNotInstalledError, Ace::Review::Errors::GhAuthenticationError,
          Ace::Git::ProviderCliMissingError, Ace::Git::ProviderAuthenticationError
          # Re-raise authentication and installation errors
          raise
        rescue => e
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
          parsed = Ace::Git::Github::PrIdentifier.parse(pr_identifier)
          gh_format = parsed.gh_format

          # Default timeout for PR operations
          timeout = options[:timeout] || 30

          # Fetch metadata as JSON
          fields = "number,state,isDraft,title,body,author,headRefName,headRefOid,baseRefName,baseRefOid,url,changedFiles"

          result = Ace::Review::Atoms::RetryWithBackoff.execute(options) do
            Ace::Git::Github::CliExecutor.execute("pr", ["view", *parsed.cli_target_args, "--json", fields], timeout: timeout)
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
        rescue Ace::Review::Errors::GhCliNotInstalledError, Ace::Review::Errors::GhAuthenticationError,
          Ace::Git::ProviderCliMissingError, Ace::Git::ProviderAuthenticationError
          raise
        rescue => e
          {
            success: false,
            error: "Failed to fetch PR metadata: #{e.message}"
          }
        end

        # Fetch a diff bracketed by stable PR metadata. The diff endpoint uses
        # the mutable PR ref, so a head/base change during retrieval must not
        # be attributed to the later SHA pair.
        #
        # @param pr_identifier [String] PR identifier
        # @param options [Hash] Fetch options
        # @return [Hash] Result with :success, :diff, :metadata, :error
        def self.fetch_pr(pr_identifier, options = {})
          2.times do
            before = fetch_metadata(pr_identifier, options)
            return before unless before[:success]

            diff_result = fetch_diff(pr_identifier, options)
            return diff_result unless diff_result[:success]

            inventory = fetch_file_inventory(before[:metadata], options)
            return inventory unless inventory[:success]

            after = fetch_metadata(pr_identifier, options)
            return after unless after[:success]

            if %w[headRefOid baseRefOid].all? { |key| before[:metadata][key] == after[:metadata][key] }
              metadata = after[:metadata].merge("files" => inventory[:files])
              return {
                success: true,
                diff: diff_result[:diff],
                metadata: metadata,
                identifier: diff_result[:identifier],
                parsed: diff_result[:parsed]
              }
            end
          end

          {success: false, error: "PR head/base changed while fetching diff; retry review on the current SHA"}
        end

        def self.fetch_file_inventory(metadata, options = {})
          match = metadata["url"].to_s.match(%r{\Ahttps://github\.com/([^/]+/[^/]+)/pull/(\d+)\z})
          return {success: false, error: "Cannot identify GitHub repository for PR file inventory"} unless match

          endpoint = "repos/#{match[1]}/pulls/#{match[2]}/files?per_page=100"
          result = Ace::Review::Atoms::RetryWithBackoff.execute(options) do
            Ace::Git::Github::CliExecutor.execute("api", [endpoint, "--paginate", "--jq", "[.[].filename]"],
              timeout: options[:timeout] || 30)
          end
          return {success: false, error: "Failed to fetch PR file inventory: #{result[:stderr]}"} unless result[:success]

          pages = result[:stdout].lines.map { |line| JSON.parse(line) }
          unless pages.any? && pages.all? { |page| page.is_a?(Array) }
            return {success: false, error: "Invalid PR file inventory response"}
          end

          files = pages.flatten(1)
          unless files.all? { |file| file.is_a?(String) }
            return {success: false, error: "Invalid PR file inventory entry"}
          end

          {success: true, files: files.map { |file| {"path" => file} }}
        rescue JSON::ParserError => e
          {success: false, error: "Invalid PR file inventory JSON: #{e.message}"}
        rescue Ace::Review::Errors::GhNetworkError => e
          {success: false, error: "Failed to fetch PR file inventory: #{e.message}"}
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
          base_temp_ref = nil

          # Fetch PR metadata to get base branch and PR number
          metadata_result = fetch_metadata(pr_identifier, options)
          unless metadata_result[:success]
            return {
              success: false,
              error: "Cannot fall back to local diff: failed to fetch PR metadata — #{metadata_result[:error]}"
            }
          end

          base_oid = metadata_result[:metadata]["baseRefOid"]
          head_oid = metadata_result[:metadata]["headRefOid"]
          unless [base_oid, head_oid].all? { |oid| oid.to_s.match?(/\A[0-9a-f]{40}\z/) }
            return {success: false, error: "Cannot fall back to local diff without exact PR head/base SHAs"}
          end
          pull_number = metadata_result[:metadata]["number"] || metadata_result.dig(:parsed, "number")
          temp_ref = "refs/ace/review/pr-#{pull_number}-#{Process.pid}"
          base_temp_ref = "#{temp_ref}-base"
          # A qualified PR can belong to a different repository from cwd.
          # Fetch both immutable revisions from that repository, never from
          # the caller's unrelated origin.
          repo = Ace::Git::Github::PrIdentifier.parse(pr_identifier).repo
          remote = repo ? "https://github.com/#{repo}.git" : "origin"

          fetch_result = run_local_command("git", "fetch", "--no-tags", remote,
            "+refs/pull/#{pull_number}/head:#{temp_ref}")
          unless fetch_result[:success]
            return {
              success: false,
              error: "Cannot fall back to local diff: git fetch PR head failed — #{fetch_result[:stderr]}"
            }
          end

          fetched_head = run_local_command("git", "rev-parse", temp_ref)
          unless fetched_head[:success] && fetched_head[:stdout].strip == head_oid
            return {success: false, error: "Fetched PR head differs from reviewed head SHA"}
          end

          base_fetch = run_local_command("git", "fetch", "--no-tags", remote, "+#{base_oid}:#{base_temp_ref}")
          unless base_fetch[:success]
            return {success: false, error: "Cannot fetch reviewed base SHA #{base_oid}: #{base_fetch[:stderr]}"}
          end

          # Find merge base
          merge_base_result = run_local_command("git", "merge-base", base_temp_ref, temp_ref)
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
          delete_temp_ref(base_temp_ref) if base_temp_ref
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
        rescue => e
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
