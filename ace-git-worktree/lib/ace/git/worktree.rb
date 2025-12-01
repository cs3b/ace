# frozen_string_literal: true

require "open3"

# Define CommandTimeout if not available (for some Ruby installations)
unless Open3.const_defined?(:CommandTimeout)
  module Open3
    class CommandTimeout < StandardError; end
  end
end

require_relative "worktree/version"

module Ace
  module Git
    # Main module for ace-git-worktree gem
    #
    # This gem provides task-aware git worktree management capabilities
    # integrated with the ACE task management system.
    #
    # Key features:
    # - Task-aware worktree creation with automatic metadata lookup
    # - Integration with ace-taskflow for task information
    # - Configuration-driven naming conventions
    # - Automated environment setup (mise trust)
    # - Support for traditional worktree operations
    #
    # @example Task-aware worktree creation
    #   require 'ace/git/worktree'
    #
    #   # Create a worktree for a task
    #   orchestrator = Ace::Git::Worktree::TaskWorktreeOrchestrator.new
    #   result = orchestrator.create_for_task("081")
    #
    # @example Traditional worktree creation
    #   manager = Ace::Git::Worktree::WorktreeManager.new
    #   result = manager.create("feature-branch")
    module Worktree
      # Load all the core components
      require_relative "worktree/configuration"
      require_relative "worktree/models/worktree_config"
      require_relative "worktree/models/worktree_info"
      require_relative "worktree/models/worktree_metadata"

      require_relative "worktree/atoms/git_command"
      require_relative "worktree/atoms/path_expander"
      require_relative "worktree/atoms/slug_generator"

      require_relative "worktree/molecules/config_loader"
      require_relative "worktree/molecules/task_fetcher"
      require_relative "worktree/molecules/pr_fetcher"
      require_relative "worktree/molecules/pr_creator"
      require_relative "worktree/molecules/task_committer"
      require_relative "worktree/molecules/task_pusher"
      require_relative "worktree/molecules/task_status_updater"
      require_relative "worktree/molecules/worktree_creator"
      require_relative "worktree/molecules/worktree_lister"
      require_relative "worktree/molecules/worktree_remover"
      require_relative "worktree/molecules/hook_executor"

      require_relative "worktree/organisms/task_worktree_orchestrator"
      require_relative "worktree/organisms/worktree_manager"

      require_relative "worktree/commands/create_command"
      require_relative "worktree/commands/list_command"
      require_relative "worktree/commands/switch_command"
      require_relative "worktree/commands/remove_command"
      require_relative "worktree/commands/prune_command"
      require_relative "worktree/commands/config_command"

      require_relative "worktree/cli"
    end
  end
end