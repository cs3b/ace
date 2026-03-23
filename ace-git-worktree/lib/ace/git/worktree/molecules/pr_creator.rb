# frozen_string_literal: true

require "json"
require "open3"

module Ace
  module Git
    module Worktree
      module Molecules
        # PR creator molecule
        #
        # Creates draft pull requests on GitHub using the gh CLI.
        # Provides a simple interface for creating PRs with graceful degradation
        # when gh CLI is unavailable or not authenticated.
        #
        # @example Create a draft PR
        #   creator = PrCreator.new
        #   result = creator.create_draft(
        #     branch: "125-upstream-setup",
        #     base: "main",
        #     title: "125 - upstream-setup-and-pr-creation"
        #   )
        #   result[:pr_number] # => 456
        #   result[:pr_url] # => "https://github.com/owner/repo/pull/456"
        #
        # @example Handle unavailable gh CLI
        #   creator = PrCreator.new
        #   unless creator.gh_available?
        #     puts "gh CLI not available"
        #   end
        class PrCreator
          # Error raised when gh CLI is not available
          class GhNotAvailableError < StandardError; end

          # Error raised when gh CLI is not authenticated
          class GhNotAuthenticatedError < StandardError; end

          # Error raised on network/timeout issues
          class NetworkError < StandardError; end

          # Error raised when PR already exists
          class PrAlreadyExistsError < StandardError; end

          # Initialize a new PrCreator
          #
          # @param timeout [Integer] Timeout in seconds (default: 30)
          def initialize(timeout: 30)
            @timeout = timeout
          end

          # Create a draft pull request
          #
          # @param branch [String] Head branch for the PR
          # @param base [String] Base branch to merge into
          # @param title [String] PR title
          # @param body [String, nil] PR body/description
          # @return [Hash] Result hash with :success, :pr_number, :pr_url, :error
          #
          # @example
          #   result = creator.create_draft(branch: "feature", base: "main", title: "Add feature")
          #   result[:success] # => true
          #   result[:pr_number] # => 123
          #   result[:pr_url] # => "https://github.com/owner/repo/pull/123"
          def create_draft(branch:, base:, title:, body: nil)
            # Check gh availability and authentication
            unless gh_available?
              return error_result("gh CLI is not installed")
            end

            unless gh_authenticated?
              return error_result("gh CLI is not authenticated. Run: gh auth login")
            end

            # Check if PR already exists for this branch
            existing_pr = find_existing_pr(branch: branch)
            if existing_pr
              return {
                success: true,
                pr_number: existing_pr[:number],
                pr_url: existing_pr[:url],
                existing: true,
                message: "PR already exists for branch"
              }
            end

            # Build gh command
            cmd = ["gh", "pr", "create", "--draft", "--head", branch, "--base", base, "--title", title]
            cmd += ["--body", body || title]

            # Execute command
            stdout, stderr, status = execute_with_timeout(cmd, @timeout)

            if status.success?
              # Parse PR URL from output
              pr_url = stdout.strip
              pr_number = extract_pr_number(pr_url)

              {
                success: true,
                pr_number: pr_number,
                pr_url: pr_url,
                existing: false,
                error: nil
              }
            else
              handle_creation_error(stderr)
            end
          rescue => e
            error_result("Unexpected error: #{e.message}")
          end

          # Check if gh CLI is available (cached)
          #
          # @return [Boolean] true if gh is installed and accessible
          def gh_available?
            return @gh_available unless @gh_available.nil?

            @gh_available = system("which gh > /dev/null 2>&1")
          end

          # Check if gh CLI is authenticated (cached)
          #
          # @return [Boolean] true if gh is authenticated
          def gh_authenticated?
            return @gh_authenticated unless @gh_authenticated.nil?

            _, _stderr, status = Open3.capture3("gh", "auth", "status")
            @gh_authenticated = status.success?
          rescue
            @gh_authenticated = false
          end

          # Find an existing PR for a branch
          #
          # @param branch [String] Branch name to search for
          # @return [Hash, nil] PR info hash or nil if not found
          #
          # @example
          #   pr = creator.find_existing_pr(branch: "feature-branch")
          #   pr[:number] # => 123
          #   pr[:url] # => "https://github.com/owner/repo/pull/123"
          def find_existing_pr(branch:)
            return nil unless gh_available?

            # Search for open PRs with this head branch
            cmd = [
              "gh", "pr", "list",
              "--head", branch,
              "--state", "open",
              "--json", "number,url",
              "--limit", "1"
            ]

            stdout, _stderr, status = execute_with_timeout(cmd, @timeout)
            return nil unless status.success?

            prs = JSON.parse(stdout)
            return nil if prs.empty?

            pr = prs.first
            {
              number: pr["number"],
              url: pr["url"]
            }
          rescue JSON::ParserError
            nil
          rescue
            nil
          end

          # Get helpful error message when gh CLI is unavailable
          #
          # @return [String] User-friendly error message with installation guidance
          def gh_not_available_message
            <<~MESSAGE
              gh CLI is required for PR creation but is not installed.

              Install gh CLI:
              - macOS: brew install gh
              - Linux: See https://github.com/cli/cli#installation
              - Windows: See https://github.com/cli/cli#installation

              After installation, authenticate with: gh auth login
            MESSAGE
          end

          private

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
            raise NetworkError, "Request timed out after #{timeout} seconds"
          end

          # Extract PR number from URL
          #
          # @param url [String] PR URL
          # @return [Integer, nil] PR number or nil if not parseable
          def extract_pr_number(url)
            return nil unless url

            match = url.match(%r{/pull/(\d+)})
            match ? match[1].to_i : nil
          end

          # Handle PR creation error
          #
          # @param stderr [String] Error output from gh
          # @return [Hash] Error result hash
          def handle_creation_error(stderr)
            error_msg = stderr.downcase

            if error_msg.include?("already exists") || error_msg.include?("pull request already exists")
              error_result("A PR already exists for this branch")
            elsif error_msg.include?("authentication") || error_msg.include?("not logged in")
              error_result("GitHub CLI not authenticated. Run: gh auth login")
            elsif error_msg.include?("network") || error_msg.include?("connection")
              error_result("Network error. Check your connection and try again.")
            elsif error_msg.include?("repository not found") || error_msg.include?("not a git repository")
              error_result("Not in a git repository or repository not found on GitHub")
            elsif error_msg.include?("branch") && error_msg.include?("not found")
              error_result("Branch not found on remote. Push the branch first.")
            else
              error_result("GitHub CLI error: #{stderr.strip}")
            end
          end

          # Create an error result hash
          #
          # @param message [String] Error message
          # @return [Hash] Error result
          def error_result(message)
            {
              success: false,
              pr_number: nil,
              pr_url: nil,
              error: message
            }
          end
        end
      end
    end
  end
end
