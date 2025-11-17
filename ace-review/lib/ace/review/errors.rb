# frozen_string_literal: true

module Ace
  module Review
    # Namespace for ace-review errors
    module Errors
      # Base error class for all ace-review errors
      class Error < StandardError; end

      # Raised when a required dependency is missing
      class MissingDependencyError < Error
        attr_reader :dependency_name, :install_command

        def initialize(dependency_name, install_command = nil)
          @dependency_name = dependency_name
          @install_command = install_command || "gem install #{dependency_name}"

          message = "Required gem '#{dependency_name}' not found.\n"
          message += "Install with: #{@install_command}"

          super(message)
        end
      end

      # Raised when ace-context fails to process context
      class ContextProcessingError < Error
        attr_reader :details

        def initialize(message, details = nil)
          @details = details
          super(message)
        end
      end

      # Raised when gh CLI is not installed
      class GhCliNotInstalledError < Error
        def initialize
          message = "GitHub CLI (gh) is not installed.\n"
          message += "Install with:\n"
          message += "  macOS: brew install gh\n"
          message += "  Linux: See https://cli.github.com/manual/installation\n"
          message += "  Windows: See https://cli.github.com/manual/installation"

          super(message)
        end
      end

      # Raised when user is not authenticated with GitHub
      class GhAuthenticationError < Error
        def initialize
          message = "GitHub authentication required.\n"
          message += "Run 'gh auth login' to authenticate with GitHub.\n"
          message += "Check status: gh auth status"

          super(message)
        end
      end

      # Raised when a PR is not found
      class PrNotFoundError < Error
        attr_reader :pr_identifier

        def initialize(pr_identifier, details = nil)
          @pr_identifier = pr_identifier
          message = "Pull request '#{pr_identifier}' not found."
          message += "\n#{details}" if details

          super(message)
        end
      end

      # Raised when attempting to post to a closed/merged PR
      class PrStateError < Error
        attr_reader :pr_number, :state

        def initialize(pr_number, state)
          @pr_number = pr_number
          @state = state

          message = "Cannot post comment to PR ##{pr_number}.\n"
          message += "PR is in '#{state}' state. Comments can only be posted to open PRs."

          super(message)
        end
      end

      # Raised when gh CLI encounters a network error
      class GhNetworkError < Error; end
    end
  end
end
