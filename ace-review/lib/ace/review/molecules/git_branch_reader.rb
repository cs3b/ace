# frozen_string_literal: true

require "open3"

module Ace
  module Review
    module Molecules
      # Reads current git branch name
      # This is a molecule because it performs I/O (git command execution)
      #
      # Adapted from ace-prompt's GitBranchReader
      class GitBranchReader
        # Get current git branch name
        # @return [String|nil] branch name, "HEAD" (detached), or nil if not in git repo
        def self.current_branch
          stdout, _stderr, status = Open3.capture3("git", "rev-parse", "--abbrev-ref", "HEAD")
          return nil unless status.success?

          branch = stdout.strip
          branch.empty? ? nil : branch
        rescue StandardError
          nil
        end
      end
    end
  end
end
