# frozen_string_literal: true

require_relative "git_commit/version"

# Load ace-core and ace-llm
require "ace/core"
require "ace/llm"

# Require all components
require_relative "git_commit/atoms/git_executor"
require_relative "git_commit/molecules/diff_analyzer"
require_relative "git_commit/molecules/message_generator"
require_relative "git_commit/molecules/file_stager"
require_relative "git_commit/molecules/commit_summarizer"
require_relative "git_commit/organisms/commit_orchestrator"
require_relative "git_commit/models/commit_options"

module Ace
  module GitCommit
    class Error < StandardError; end
    class GitError < Error; end
    class ConfigurationError < Error; end
  end
end