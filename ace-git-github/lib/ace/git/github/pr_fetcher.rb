# frozen_string_literal: true

require "json"

module Ace
  module Git
    module Github
      # Fetch pull request data via the GitHub CLI (`gh`).
      #
      # Owns all `gh pr` invocation and output parsing for ACE. Failures are
      # classified with the shared provider taxonomy; there is no fallback to
      # any other transport.
      module PrFetcher
        # Error message patterns from the `gh` CLI
        PR_NOT_FOUND_PATTERN = /not found|Could not resolve/i
        AUTH_ERROR_PATTERN = /authentication|Unauthorized|not logged in|auth login/i

        # Valid characters for PR identifiers (owner/repo#number format)
        VALID_IDENTIFIER_PATTERN = /\A[\w\/.\-#@:]+\z/

        # Fields to fetch for PR metadata
        PR_FIELDS = %w[
          number
          state
          isDraft
          title
          author
          headRefName
          baseRefName
          url
          isCrossRepository
          headRepositoryOwner
          headRefOid
          mergeCommit
        ].freeze

        LIST_FIELDS = "number,title,state,mergedAt,author,headRefName,isDraft,baseRefName,url,headRefOid,mergeCommit"

        class << self
          # @return [Boolean] true when the `gh` binary is installed
          def installed?(runner: nil)
            CliExecutor.installed?(runner: runner)
          end

          # @return [Boolean] true when the `gh` CLI is authenticated
          def authenticated?(runner: nil)
            CliExecutor.authenticated?(runner: runner)
          end

          # Fetch PR diff content.
          #
          # @param identifier [String] PR identifier (number, URL, or owner/repo#number)
          # @param timeout [Integer] Timeout in seconds
          # @param runner [Proc, nil] injectable command runner for tests
          # @return [Hash] Result with :success, :diff, :identifier, :source
          def fetch_diff(identifier, timeout: Ace::Git.network_timeout, runner: nil)
            parsed = PrIdentifier.parse(identifier)
            raise ArgumentError, "Invalid PR identifier: #{identifier}" if parsed.nil?

            validate_identifier_characters(parsed.gh_format)

            result = CliExecutor.execute("pr", ["diff", *parsed.cli_target_args], timeout: timeout, runner: runner)

            if result[:success]
              {
                success: true,
                diff: result[:stdout],
                identifier: parsed.gh_format,
                source: build_source_label(parsed)
              }
            else
              handle_error(result[:stderr], parsed.gh_format)
            end
          end

          # Fetch PR metadata (state, draft status, title, etc.).
          #
          # @param identifier [String] PR identifier
          # @param timeout [Integer] Timeout in seconds
          # @param runner [Proc, nil] injectable command runner for tests
          # @return [Hash] Result with :success, :metadata, :identifier, :parsed
          def fetch_metadata(identifier, timeout: Ace::Git.network_timeout, runner: nil)
            parsed = PrIdentifier.parse(identifier)
            raise ArgumentError, "Invalid PR identifier: #{identifier}" if parsed.nil?

            validate_identifier_characters(parsed.gh_format)

            result = CliExecutor.execute(
              "pr", ["view", *parsed.cli_target_args, "--json", PR_FIELDS.join(",")],
              timeout: timeout, runner: runner
            )

            if result[:success]
              metadata = JSON.parse(result[:stdout])
              {
                success: true,
                metadata: metadata,
                identifier: parsed.gh_format,
                parsed: {number: parsed.number, repo: parsed.repo}
              }
            else
              handle_error(result[:stderr], parsed.gh_format)
            end
          rescue JSON::ParserError => e
            raise Ace::Git::ProviderMalformedOutputError, "Failed to parse PR metadata: #{e.message}"
          end

          # Fetch both diff and metadata.
          #
          # @param identifier [String] PR identifier
          # @param timeout [Integer] Timeout in seconds
          # @param runner [Proc, nil] injectable command runner for tests
          # @return [Hash] Result with :success, :diff, :metadata, :identifier, :source
          def fetch_pr(identifier, timeout: Ace::Git.network_timeout, runner: nil)
            diff_result = fetch_diff(identifier, timeout: timeout, runner: runner)
            return diff_result unless diff_result[:success]

            metadata_result = fetch_metadata(identifier, timeout: timeout, runner: runner)
            return metadata_result unless metadata_result[:success]

            {
              success: true,
              diff: diff_result[:diff],
              metadata: metadata_result[:metadata],
              identifier: diff_result[:identifier],
              source: diff_result[:source]
            }
          end

          # Find PR number for the current branch.
          #
          # @param timeout [Integer] Timeout in seconds
          # @param runner [Proc, nil] injectable command runner for tests
          # @return [String, nil] PR number or nil
          def find_pr_for_branch(timeout: Ace::Git.network_timeout, runner: nil)
            result = CliExecutor.execute("pr", ["view", "--json", "number"], timeout: timeout, runner: runner)

            return nil unless result[:success]

            JSON.parse(result[:stdout])["number"]&.to_s
          rescue JSON::ParserError
            nil
          end

          # Fetch recently merged PRs.
          #
          # @param limit [Integer] Maximum number of PRs to return
          # @param timeout [Integer] Timeout in seconds
          # @param runner [Proc, nil] injectable command runner for tests
          # @return [Hash] Result with :success, :prs array, or :error
          def fetch_recently_merged(limit: Ace::Git.merged_prs_limit, timeout: Ace::Git.network_timeout, runner: nil)
            result = CliExecutor.execute(
              "pr", ["list", "--state", "merged", "--limit", limit.to_s, "--json", "number,title,mergedAt,author"],
              timeout: timeout, runner: runner
            )

            list_result(result, parse_error_prefix: "Failed to parse merged PRs")
          end

          # Fetch open PRs.
          #
          # @param exclude_branch [String, nil] Branch name to exclude from results
          # @param limit [Integer] Maximum number of PRs to return
          # @param timeout [Integer] Timeout in seconds
          # @param runner [Proc, nil] injectable command runner for tests
          # @return [Hash] Result with :success, :prs array, or :error
          def fetch_open_prs(exclude_branch: nil, limit: Ace::Git.open_prs_limit, timeout: Ace::Git.network_timeout, runner: nil)
            result = CliExecutor.execute(
              "pr", ["list", "--state", "open", "--limit", limit.to_s, "--json", "number,title,author,headRefName"],
              timeout: timeout, runner: runner
            )

            parsed = list_result(result, parse_error_prefix: "Failed to parse open PRs")
            return parsed unless parsed[:success] && exclude_branch

            parsed.merge(prs: parsed[:prs].reject { |pr| pr["headRefName"] == exclude_branch })
          end

          # Fetch all recent PRs in a single call (open, merged, closed).
          #
          # @param limit [Integer] Maximum PRs to fetch
          # @param timeout [Integer] Timeout in seconds
          # @param runner [Proc, nil] injectable command runner for tests
          # @return [Hash] Result with :success, :prs array, or :error
          def fetch_all_prs(limit: 15, timeout: Ace::Git.network_timeout, runner: nil)
            result = CliExecutor.execute(
              "pr", ["list", "--state", "all", "--limit", limit.to_s, "--json", LIST_FIELDS],
              timeout: timeout, runner: runner
            )

            list_result(result, parse_error_prefix: "Failed to parse PR list")
          end

          private

          def list_result(result, parse_error_prefix:)
            if result[:success]
              begin
                {success: true, prs: JSON.parse(result[:stdout])}
              rescue JSON::ParserError => e
                raise Ace::Git::ProviderMalformedOutputError, "#{parse_error_prefix}: #{e.message}"
              end
            else
              {success: false, error: result[:stderr], prs: []}
            end
          end

          def build_source_label(parsed)
            if parsed.repo
              "pr:#{parsed.repo}##{parsed.number}"
            else
              "pr:#{parsed.number}"
            end
          end

          # Validate identifier characters to prevent shell metacharacter injection
          def validate_identifier_characters(identifier)
            return if identifier.nil? || identifier.empty?

            unless identifier.match?(VALID_IDENTIFIER_PATTERN)
              raise ArgumentError, "Invalid identifier characters: #{identifier}"
            end
          end

          def handle_error(error_message, identifier)
            error_str = error_message.to_s

            if error_str.match?(PR_NOT_FOUND_PATTERN)
              raise Ace::Git::ProviderObjectNotFoundError, "PR not found: #{identifier}"
            elsif error_str.match?(AUTH_ERROR_PATTERN)
              raise Ace::Git::ProviderAuthenticationError, "Not authenticated with GitHub. Run: gh auth login"
            else
              {
                success: false,
                error: "gh pr command failed: #{error_str}"
              }
            end
          end
        end
      end
    end
  end
end
