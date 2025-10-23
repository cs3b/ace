# frozen_string_literal: true

require "ace/core"
require_relative "git_diff/version"

module Ace
  module GitDiff
    class Error < StandardError; end
    class GitError < Error; end
    class ConfigError < Error; end

    # Get configuration for ace-git-diff using ace-core config cascade
    # @return [Hash] configuration hash
    def self.config
      @config ||= Ace::Core.config.get("ace", "git-diff") || default_config
    end

    # Default configuration when no config file is present
    # @return [Hash] default configuration
    def self.default_config
      {
        "exclude_patterns" => [
          "test/**/*",
          "spec/**/*",
          "**/*.lock",
          "vendor/**/*",
          "node_modules/**/*",
          "coverage/**/*",
          "**/fixtures/**/*"
        ],
        "exclude_whitespace" => true,
        "exclude_renames" => false,
        "exclude_moves" => false,
        "max_lines" => 10_000
      }
    end

    # Reset configuration cache (mainly for testing)
    def self.reset_config!
      @config = nil
    end
  end
end

# Require ATOM architecture components
require_relative "git_diff/atoms/command_executor"
require_relative "git_diff/atoms/pattern_filter"
require_relative "git_diff/atoms/diff_parser"
require_relative "git_diff/atoms/date_resolver"

require_relative "git_diff/molecules/diff_generator"
require_relative "git_diff/molecules/config_loader"
require_relative "git_diff/molecules/diff_filter"

require_relative "git_diff/organisms/diff_orchestrator"
require_relative "git_diff/organisms/integration_helper"

require_relative "git_diff/models/diff_result"
require_relative "git_diff/models/diff_config"
