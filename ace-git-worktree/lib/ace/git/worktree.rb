# frozen_string_literal: true

require_relative "worktree/version"
require_relative "worktree/configuration"
require_relative "worktree/cli"

# Require all atoms
require_relative "worktree/atoms/git_command"
require_relative "worktree/atoms/path_expander"
require_relative "worktree/atoms/slug_generator"

# Require all models
require_relative "worktree/models/worktree_config"
require_relative "worktree/models/worktree_info"
require_relative "worktree/models/task_metadata"
require_relative "worktree/models/worktree_metadata"

# Require all molecules
require_relative "worktree/molecules/task_fetcher"
require_relative "worktree/molecules/task_status_updater"
require_relative "worktree/molecules/task_committer"
require_relative "worktree/molecules/worktree_creator"
require_relative "worktree/molecules/worktree_lister"
require_relative "worktree/molecules/worktree_remover"
require_relative "worktree/molecules/mise_trustor"

# Require all organisms
require_relative "worktree/organisms/task_worktree_orchestrator"
require_relative "worktree/organisms/worktree_manager"

# Note: Commands are loaded on demand by the CLI

module Ace
  module Git
    module Worktree
      # Define module namespaces
      module Atoms; end
      module Models; end
      module Molecules; end
      module Organisms; end
      module Commands; end

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