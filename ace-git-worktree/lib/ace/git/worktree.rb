# frozen_string_literal: true

require_relative "worktree/version"
require_relative "worktree/configuration"
require_relative "worktree/cli"

module Ace
  module Git
    module Worktree
      class Error < StandardError; end
      class TaskNotFoundError < Error; end
      class WorktreeExistsError < Error; end
      class GitError < Error; end
      class ConfigurationError < Error; end

      # Main entry point for the gem
      def self.root
        File.expand_path("../../../..", __FILE__)
      end

      # Access to configuration
      def self.configuration
        @configuration ||= Configuration.new
      end

      # Reset configuration (mainly for testing)
      def self.reset_configuration!
        @configuration = nil
      end
    end
  end
end