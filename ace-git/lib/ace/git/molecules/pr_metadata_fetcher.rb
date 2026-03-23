# frozen_string_literal: true

require "json"

module Ace
  module Git
    module Molecules
      # Fetch PR metadata via gh CLI
      # Consolidated from ace-bundle GhPrExecutor and ace-review GhPrFetcher
      class PrMetadataFetcher
        # Error message patterns from gh CLI
        PR_NOT_FOUND_PATTERN = /not found|Could not resolve/i
        AUTH_ERROR_PATTERN = /authentication|Unauthorized|not logged in|auth login/i

        # Valid characters for PR identifiers (owner/repo#number format)
        # Allows: alphanumeric, hyphens, underscores, dots, forward slashes, hash, at, colon
        # This prevents shell metacharacters from reaching command execution
        VALID_IDENTIFIER_PATTERN = /\A[\w\/.\-#@:]+\z/

        # Fields to fetch for PR metadata
        # Extracted as constant for maintainability
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
        ].freeze

        class << self
          # Check if gh CLI is installed
          # @return [Boolean] True if gh is installed
          def gh_installed?
            result = Atoms::CommandExecutor.execute("gh", "--version")
            result[:success]
          end

          # Check if gh CLI is authenticated
          # @return [Boolean] True if authenticated
          def gh_authenticated?
            result = Atoms::CommandExecutor.execute("gh", "auth", "status")
            result[:success]
          end

          # Fetch PR diff content
          # @param identifier [String] PR identifier (number, URL, or owner/repo#number)
          # @param timeout [Integer] Timeout in seconds (default from config)
          # @return [Hash] Result with :success, :diff, :error
          def fetch_diff(identifier, timeout: Ace::Git.network_timeout)
            parsed = Atoms::PrIdentifierParser.parse(identifier)
            raise ArgumentError, "Invalid PR identifier: #{identifier}" if parsed.nil?

            # Validate identifier characters before command execution (defense in depth)
            validate_identifier_characters(parsed.gh_format)

            result = execute_gh_command(["gh", "pr", "diff", parsed.gh_format], timeout: timeout)

            if result[:success]
              {
                success: true,
                diff: result[:output],
                identifier: parsed.gh_format,
                source: build_source_label(parsed)
              }
            else
              handle_error(result[:error], parsed.gh_format)
            end
          rescue Errno::ENOENT
            raise Ace::Git::GhNotInstalledError, "GitHub CLI (gh) not installed. Install with: brew install gh"
          end

          # Fetch PR metadata (state, draft status, title, etc.)
          # @param identifier [String] PR identifier
          # @param timeout [Integer] Timeout in seconds (default from config)
          # @return [Hash] Result with :success, :metadata, :error
          def fetch_metadata(identifier, timeout: Ace::Git.network_timeout)
            parsed = Atoms::PrIdentifierParser.parse(identifier)
            raise ArgumentError, "Invalid PR identifier: #{identifier}" if parsed.nil?

            # Validate identifier characters before command execution (defense in depth)
            validate_identifier_characters(parsed.gh_format)

            result = execute_gh_command(
              ["gh", "pr", "view", parsed.gh_format, "--json", PR_FIELDS.join(",")],
              timeout: timeout
            )

            if result[:success]
              metadata = JSON.parse(result[:output])
              {
                success: true,
                metadata: metadata,
                identifier: parsed.gh_format,
                parsed: {number: parsed.number, repo: parsed.repo}
              }
            else
              handle_error(result[:error], parsed.gh_format)
            end
          rescue JSON::ParserError => e
            {
              success: false,
              error: "Failed to parse PR metadata: #{e.message}"
            }
          rescue Errno::ENOENT
            raise Ace::Git::GhNotInstalledError, "GitHub CLI (gh) not installed. Install with: brew install gh"
          end

          # Fetch both diff and metadata
          # @param identifier [String] PR identifier
          # @param timeout [Integer] Timeout in seconds (default from config)
          # @return [Hash] Result with :success, :diff, :metadata, :error
          def fetch_pr(identifier, timeout: Ace::Git.network_timeout)
            diff_result = fetch_diff(identifier, timeout: timeout)
            return diff_result unless diff_result[:success]

            metadata_result = fetch_metadata(identifier, timeout: timeout)
            return metadata_result unless metadata_result[:success]

            {
              success: true,
              diff: diff_result[:diff],
              metadata: metadata_result[:metadata],
              identifier: diff_result[:identifier],
              source: diff_result[:source]
            }
          end

          # Find PR number for current branch
          # @param timeout [Integer] Timeout in seconds (default from config)
          # @return [String|nil] PR number or nil
          def find_pr_for_branch(timeout: Ace::Git.network_timeout)
            result = execute_gh_command(
              ["gh", "pr", "view", "--json", "number"],
              timeout: timeout
            )

            return nil unless result[:success]

            data = JSON.parse(result[:output])
            data["number"]&.to_s
          rescue JSON::ParserError, Errno::ENOENT
            nil
          end

          # Fetch recently merged PRs
          # @param limit [Integer] Maximum number of PRs to return (default from config)
          # @param timeout [Integer] Timeout in seconds
          # @return [Hash] Result with :success, :prs array, or :error
          def fetch_recently_merged(limit: Ace::Git.merged_prs_limit, timeout: Ace::Git.network_timeout)
            result = execute_gh_command(
              ["gh", "pr", "list", "--state", "merged", "--limit", limit.to_s,
                "--json", "number,title,mergedAt,author"],
              timeout: timeout
            )

            if result[:success]
              prs = JSON.parse(result[:output])
              {success: true, prs: prs}
            else
              {success: false, error: result[:error], prs: []}
            end
          rescue JSON::ParserError => e
            {success: false, error: "Failed to parse merged PRs: #{e.message}", prs: []}
          rescue Errno::ENOENT
            {success: false, error: "GitHub CLI (gh) not installed", prs: []}
          end

          # Fetch open PRs
          # @param exclude_branch [String, nil] Branch name to exclude from results
          # @param limit [Integer] Maximum number of PRs to return (default from config)
          # @param timeout [Integer] Timeout in seconds
          # @return [Hash] Result with :success, :prs array, or :error
          def fetch_open_prs(exclude_branch: nil, limit: Ace::Git.open_prs_limit, timeout: Ace::Git.network_timeout)
            result = execute_gh_command(
              ["gh", "pr", "list", "--state", "open", "--limit", limit.to_s,
                "--json", "number,title,author,headRefName"],
              timeout: timeout
            )

            if result[:success]
              prs = JSON.parse(result[:output])
              # Filter out current branch if specified
              if exclude_branch
                prs = prs.reject { |pr| pr["headRefName"] == exclude_branch }
              end
              {success: true, prs: prs}
            else
              {success: false, error: result[:error], prs: []}
            end
          rescue JSON::ParserError => e
            {success: false, error: "Failed to parse open PRs: #{e.message}", prs: []}
          rescue Errno::ENOENT
            {success: false, error: "GitHub CLI (gh) not installed", prs: []}
          end

          # Fetch all recent PRs in a single call for optimal performance
          # Returns open, merged, and closed PRs - caller filters by state locally
          # @param limit [Integer] Maximum PRs to fetch (default: 15, enough for typical use)
          # @param timeout [Integer] Timeout in seconds
          # @return [Hash] Result with :success, :prs array, or :error
          def fetch_all_prs(limit: 15, timeout: Ace::Git.network_timeout)
            result = execute_gh_command(
              ["gh", "pr", "list", "--state", "all", "--limit", limit.to_s,
                "--json", "number,title,state,mergedAt,author,headRefName,isDraft,baseRefName,url"],
              timeout: timeout
            )

            if result[:success]
              prs = JSON.parse(result[:output])
              {success: true, prs: prs}
            else
              {success: false, error: result[:error], prs: []}
            end
          rescue JSON::ParserError => e
            {success: false, error: "Failed to parse PR list: #{e.message}", prs: []}
          rescue Errno::ENOENT
            {success: false, error: "GitHub CLI (gh) not installed", prs: []}
          end

          private

          # Environment variables for consistent gh CLI output across all locales
          GH_ENV = {"LC_ALL" => "C"}.freeze

          # Execute gh command with timeout via CommandExecutor
          # @param args [Array<String>] Command arguments
          # @param timeout [Integer] Timeout in seconds
          # @return [Hash] Result with :success, :output, :error, :exit_code
          def execute_gh_command(args, timeout:)
            # Delegate to CommandExecutor with LC_ALL=C for consistent output format
            # regardless of user's locale settings
            result = Atoms::CommandExecutor.execute(*args, timeout: timeout, env: GH_ENV)

            # Check for timeout (CommandExecutor returns exit_code: -1 with timeout message)
            if result[:exit_code] == -1 && result[:error]&.include?("timed out")
              raise Ace::Git::TimeoutError, "gh command timed out after #{timeout}s: #{args.join(" ")}"
            end

            result
          end

          def build_source_label(parsed)
            if parsed.repo
              "pr:#{parsed.repo}##{parsed.number}"
            else
              "pr:#{parsed.number}"
            end
          end

          # Validate identifier characters to prevent shell metacharacter injection
          # Defense in depth - Open3.capture3 with array args is already safe,
          # but this adds explicit validation as a secondary security layer
          # @param identifier [String] Identifier to validate
          # @raise [ArgumentError] If identifier contains invalid characters
          def validate_identifier_characters(identifier)
            return if identifier.nil? || identifier.empty?

            unless identifier.match?(VALID_IDENTIFIER_PATTERN)
              raise ArgumentError, "Invalid identifier characters: #{identifier}"
            end
          end

          def handle_error(error_message, identifier)
            error_str = error_message.to_s

            if error_str.match?(PR_NOT_FOUND_PATTERN)
              raise Ace::Git::PrNotFoundError, "PR not found: #{identifier}"
            elsif error_str.match?(AUTH_ERROR_PATTERN)
              raise Ace::Git::GhAuthenticationError, "Not authenticated with GitHub. Run: gh auth login"
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
