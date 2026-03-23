# frozen_string_literal: true

require "open3"

# Define CommandTimeout if not available (for some Ruby installations)
unless Open3.const_defined?(:CommandTimeout)
  module Open3
    class CommandTimeout < StandardError; end
  end
end

# Core ace-git dependency for Git operations
require "ace/git"
require "ace/support/config"

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
    # - Integration with ace-task for task information
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
    #
    # @example Access timeout configuration
    #   Ace::Git::Worktree.default_timeout  # => 30
    #   Ace::Git::Worktree.max_timeout      # => 300
    module Worktree
      # Mutex for thread-safe config initialization
      @config_mutex = Mutex.new

      class << self
        # Get configuration for ace-git-worktree
        # Follows ADR-022: Configuration Default and Override Pattern
        # Uses Ace::Support::Config.create() for configuration cascade resolution
        # Thread-safe: uses mutex for initialization
        # @return [Hash] merged configuration hash
        # @example Get current configuration
        #   config = Ace::Git::Worktree.config
        #   puts config.dig("timeouts", "default")  # => 30
        def config
          # Fast path: return cached config if already initialized
          return @config if defined?(@config) && @config

          # Thread-safe initialization
          @config_mutex.synchronize do
            @config ||= load_config
          end
        end

        # Reset configuration cache (mainly for testing)
        # Thread-safe: uses mutex to prevent race conditions
        def reset_config!
          @config_mutex.synchronize do
            @config = nil
          end
        end

        # ---- Timeout Helper Methods (ADR-022 compliant) ----
        # These read from config instead of using hardcoded constants

        # Default timeout for general git operations
        # @return [Integer] Timeout in seconds (default: 30)
        def default_timeout
          config.dig("timeouts", "default") || 30
        end

        # Maximum allowed timeout for any operation
        # @return [Integer] Timeout in seconds (default: 300)
        def max_timeout
          config.dig("timeouts", "max") || 300
        end

        # Timeout for after_create hook commands
        # @return [Integer] Timeout in seconds (default: 30)
        def hook_timeout
          config.dig("timeouts", "hook") || 30
        end

        # Timeout for worktree list operations
        # @return [Integer] Timeout in seconds (default: 30)
        def list_timeout
          config.dig("timeouts", "list") || 30
        end

        # Timeout for git commit operations
        # @return [Integer] Timeout in seconds (default: 30)
        def commit_timeout
          config.dig("timeouts", "commit") || 30
        end

        # Timeout for worktree removal operations
        # @return [Integer] Timeout in seconds (default: 30)
        def remove_timeout
          config.dig("timeouts", "remove") || 30
        end

        private

        # Load configuration using Ace::Support::Config cascade
        # Resolves gem defaults from .ace-defaults/ and user overrides from .ace/
        # @return [Hash] Merged and transformed configuration
        def load_config
          gem_root = Gem.loaded_specs["ace-git-worktree"]&.gem_dir ||
            File.expand_path("../../../..", __dir__)

          resolver = Ace::Support::Config.create(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: gem_root
          )

          # Resolve config for git/worktree namespace
          config_result = resolver.resolve_namespace("git", filename: "worktree")

          # Extract and flatten the git.worktree section for backward compatibility
          raw_config = config_result.data
          extract_worktree_config(raw_config)
        rescue Ace::Support::Config::YamlParseError => e
          warn "ace-git-worktree: YAML syntax error in configuration"
          warn "  #{e.message}"
          # Fall back to gem defaults
          load_gem_defaults_fallback
        rescue => e
          warn "ace-git-worktree: Failed to load configuration: #{e.message}"
          load_gem_defaults_fallback
        end

        # Load gem defaults directly as fallback when cascade resolution fails
        # @return [Hash] Defaults hash or empty hash if defaults also fail
        def load_gem_defaults_fallback
          gem_root = Gem.loaded_specs["ace-git-worktree"]&.gem_dir ||
            File.expand_path("../../../..", __dir__)

          defaults_path = File.join(gem_root, ".ace-defaults", "git", "worktree.yml")

          return {} unless File.exist?(defaults_path)

          data = YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
          extract_worktree_config(data)
        rescue
          {} # Only return empty hash if even defaults fail to load
        end

        # Extract worktree configuration from YAML structure
        # Unwraps git.worktree nesting for easier access
        # @param raw_config [Hash] The raw YAML config
        # @return [Hash] Flattened worktree configuration
        def extract_worktree_config(raw_config)
          return {} if raw_config.nil? || raw_config.empty?

          # Handle git.worktree nesting
          if raw_config.key?("git") && raw_config["git"].is_a?(Hash)
            raw_config["git"]["worktree"] || raw_config["git"]
          elsif raw_config.key?("worktree") && raw_config["worktree"].is_a?(Hash)
            raw_config["worktree"]
          else
            raw_config
          end
        end
      end

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
