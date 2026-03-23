# frozen_string_literal: true

require_relative "git_commit/version"

# Load ace-config and ace-llm
require "ace/support/config"
require "ace/llm"

# Require all components
require_relative "git_commit/atoms/git_executor"
require_relative "git_commit/atoms/gitignore_checker"
require_relative "git_commit/molecules/diff_analyzer"
require_relative "git_commit/molecules/message_generator"
require_relative "git_commit/molecules/file_stager"
require_relative "git_commit/molecules/path_resolver"
require_relative "git_commit/molecules/commit_grouper"
require_relative "git_commit/molecules/commit_summarizer"
require_relative "git_commit/molecules/split_commit_executor"
require_relative "git_commit/organisms/commit_orchestrator"
require_relative "git_commit/models/commit_options"
require_relative "git_commit/models/commit_group"
require_relative "git_commit/models/split_commit_result"
require_relative "git_commit/models/stage_result"
require_relative "git_commit/cli"

module Ace
  module GitCommit
    class Error < StandardError; end
    class GitError < Error; end
    class ConfigurationError < Error; end

    # Alias the default scope name constant from ace-support-config for convenience
    DEFAULT_SCOPE_NAME = Ace::Support::Config::Models::ConfigGroup::DEFAULT_SCOPE_NAME

    # Check if debug mode is enabled
    # @return [Boolean] True if debug mode is enabled
    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end
  end
end
