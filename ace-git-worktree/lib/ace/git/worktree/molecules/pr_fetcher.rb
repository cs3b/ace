# frozen_string_literal: true

require "json"
require "open3"

module Ace
  module Git
    module Worktree
      module Molecules
        # PR fetcher molecule
        #
        # Fetches pull request data from GitHub using the gh CLI.
        # Provides a simple interface for retrieving PR information.
        #
        # @example Fetch PR data
        #   fetcher = PrFetcher.new
        #   pr = fetcher.fetch(26)
        #   pr[:title] # => "Add authentication feature"
        #
        # @example Handle non-existent PR
        #   pr = fetcher.fetch(999)
        #   pr # => nil
        class PrFetcher
          # Error raised when gh CLI is not available
          class GhNotAvailableError < StandardError; end

          # Error raised when PR is not found
          class PrNotFoundError < StandardError; end

          # Error raised on network/timeout issues
          class NetworkError < StandardError; end

          # Initialize a new PrFetcher
          #
          # @param timeout [Integer] Timeout in seconds (default: 30)
          # @param max_retries [Integer] Maximum number of retry attempts for transient failures (default: 2)
          def initialize(timeout: 30, max_retries: 2)
            @timeout = timeout
            @max_retries = max_retries
          end

          # Fetch PR data by number
          #
          # @param pr_number [Integer, String] PR number
          # @return [Hash, nil] PR data hash or nil if not found
          # @raise [GhNotAvailableError] if gh CLI is not installed
          # @raise [PrNotFoundError] if PR doesn't exist
          # @raise [NetworkError] if network request fails
          #
          # @example
          #   fetcher = PrFetcher.new
          #   pr = fetcher.fetch(26)
          #   pr[:number] # => 26
          #   pr[:title] # => "Add authentication feature"
          #   pr[:head_branch] # => "feature/auth"
          #   pr[:base_branch] # => "main"
          def fetch(pr_number)
            verify_gh_available!

            # Validate input
            pr_num = validate_pr_number(pr_number)
            return nil unless pr_num

            # Fetch PR data via gh CLI
            fetch_via_gh(pr_num)
          rescue GhNotAvailableError, PrNotFoundError, NetworkError
            raise
          rescue StandardError => e
            raise NetworkError, "Failed to fetch PR: #{e.message}"
          end

          # Check if gh CLI is available (cached)
          #
          # @return [Boolean] true if gh is installed and accessible
          def gh_available?
            return @gh_available unless @gh_available.nil?

            @gh_available = system("which gh > /dev/null 2>&1")
          end

          # Verify gh CLI is available, raise error if not
          #
          # @raise [GhNotAvailableError] if gh is not available
          # @return [void]
          def verify_gh_available!
            return if gh_available?

            raise GhNotAvailableError, gh_not_available_message
          end

          # Get helpful error message when gh CLI is unavailable
          #
          # @return [String] User-friendly error message with installation guidance
          def gh_not_available_message
            <<~MESSAGE
              gh CLI is required for PR worktrees but is not installed.

              Install gh CLI:
              - macOS: brew install gh
              - Linux: See https://github.com/cli/cli#installation
              - Windows: See https://github.com/cli/cli#installation

              After installation, authenticate with: gh auth login
            MESSAGE
          end

          private

          # Validate PR number
          #
          # @param pr_number [Integer, String] PR number to validate
          # @return [Integer, nil] Validated PR number or nil if invalid
          def validate_pr_number(pr_number)
            # Convert to string and strip whitespace
            pr_str = pr_number.to_s.strip

            # Check if it's a positive integer
            return nil unless pr_str.match?(/^\d+$/)

            num = pr_str.to_i
            return nil if num <= 0 || num > 999999 # Reasonable upper bound

            num
          end

          # Fetch PR data via gh CLI with retry logic
          #
          # @param pr_number [Integer] Valid PR number
          # @return [Hash] PR data hash
          # @raise [PrNotFoundError] if PR doesn't exist
          # @raise [NetworkError] if network request fails after retries
          def fetch_via_gh(pr_number)
            attempt = 0
            last_error = nil

            loop do
              begin
                return fetch_via_gh_once(pr_number)
              rescue PrNotFoundError
                # Don't retry for PR not found (permanent error)
                raise
              rescue NetworkError => e
                attempt += 1
                last_error = e

                # If we've exhausted retries, raise the last error
                if attempt > @max_retries
                  raise last_error
                end

                # Wait with exponential backoff before retry
                sleep(calculate_retry_delay(attempt))
                # Retry the request
              end
            end
          end

          # Calculate retry delay using exponential backoff
          #
          # @param attempt [Integer] Current attempt number (1-based)
          # @return [Integer] Delay in seconds (1s, 2s, 4s, 8s, ...)
          def calculate_retry_delay(attempt)
            2**(attempt - 1)
          end

          # Fetch PR data via gh CLI (single attempt)
          #
          # @param pr_number [Integer] Valid PR number
          # @return [Hash] PR data hash
          # @raise [PrNotFoundError] if PR doesn't exist
          # @raise [NetworkError] if network request fails
          def fetch_via_gh_once(pr_number)
            # Get repository context for better error messages
            repo_name = get_repository_name

            # Fields to fetch from GitHub
            fields = %w[
              number
              headRefName
              baseRefName
              title
              headRepositoryOwner
              isCrossRepository
            ]

            # Build gh command
            cmd = ["gh", "pr", "view", pr_number.to_s, "--json", fields.join(",")]

            # Execute with timeout
            stdout, stderr, status = execute_with_timeout(cmd, @timeout)

            # Handle errors
            unless status.success?
              handle_gh_error(pr_number, stderr, repo_name)
            end

            # Parse JSON response
            parse_pr_json(stdout, pr_number)
          rescue JSON::ParserError => e
            raise NetworkError, "Failed to parse GitHub response: #{e.message}"
          end

          # Execute command with timeout
          #
          # @param cmd [Array<String>] Command and arguments
          # @param timeout [Integer] Timeout in seconds
          # @return [Array<String, String, Process::Status>] stdout, stderr, status
          def execute_with_timeout(cmd, timeout)
            require "timeout"

            Timeout.timeout(timeout) do
              Open3.capture3(*cmd)
            end
          rescue Timeout::Error
            raise NetworkError, "Request timed out after #{timeout} seconds. Check your network connection."
          end

          # Get repository name for error messages
          #
          # @return [String, nil] Repository name (e.g., "owner/repo") or nil if not available
          def get_repository_name
            return @repository_name if defined?(@repository_name)

            # Try to get repo name from gh CLI
            stdout, _stderr, status = Open3.capture3("gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner")
            @repository_name = status.success? ? stdout.strip : nil
          rescue StandardError
            @repository_name = nil
          end

          # Handle gh CLI errors
          #
          # @param pr_number [Integer] PR number
          # @param stderr [String] Error output from gh
          # @param repo_name [String, nil] Repository name for context
          # @raise [PrNotFoundError, NetworkError] Appropriate error based on stderr
          def handle_gh_error(pr_number, stderr, repo_name = nil)
            error_msg = stderr.downcase

            if error_msg.include?("could not resolve to a pullrequest") ||
               error_msg.include?("not found") ||
               error_msg.include?("no pull requests")
              repo_context = repo_name ? " in #{repo_name}" : " in this repository"
              raise PrNotFoundError, "PR ##{pr_number} not found#{repo_context}"
            elsif error_msg.include?("authentication") || error_msg.include?("auth")
              raise NetworkError, "GitHub CLI not authenticated. Run: gh auth login"
            elsif error_msg.include?("network") || error_msg.include?("connection")
              raise NetworkError, "Network error. Check your connection and try again."
            else
              raise NetworkError, "GitHub CLI error: #{stderr}"
            end
          end

          # Parse PR JSON response
          #
          # @param json_str [String] JSON string from gh CLI
          # @param pr_number [Integer] PR number for validation
          # @return [Hash] Parsed PR data
          # @raise [NetworkError] if data is invalid
          def parse_pr_json(json_str, pr_number)
            data = JSON.parse(json_str)

            # Validate required fields
            required = ["number", "headRefName", "baseRefName", "title"]
            missing = required - data.keys
            unless missing.empty?
              raise NetworkError, "Invalid PR data: missing fields #{missing.join(', ')}"
            end

            # Convert to our internal format
            {
              number: data["number"],
              title: data["title"],
              head_branch: data["headRefName"],
              base_branch: data["baseRefName"],
              is_cross_repository: data["isCrossRepository"] || false,
              head_repository_owner: data.dig("headRepositoryOwner", "login")
            }
          end
        end
      end
    end
  end
end
