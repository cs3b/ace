# frozen_string_literal: true

require "ace/support/config"
require_relative "git/version"

module Ace
  module Git
    # Error handling pattern:
    # - Atoms: Pure functions, raise exceptions for invalid inputs
    # - Molecules: May return error hashes for "expected" errors (e.g., not in git repo)
    #   or raise exceptions for unexpected failures
    # - Organisms: Orchestrate molecules, propagate or wrap exceptions
    # - Commands: Catch exceptions and return exit codes (0=success, 1=error)
    #
    # All custom exceptions inherit from Ace::Git::Error for consistent catching.
    class Error < StandardError; end
    class GitError < Error; end
    class ConfigError < Error; end
    class GhNotInstalledError < Error; end
    class GhAuthenticationError < Error; end
    class PrNotFoundError < Error; end
    class TimeoutError < Error; end

    # Mutex for thread-safe config initialization
    @config_mutex = Mutex.new

    # Get configuration for ace-git
    # Follows ADR-022: Configuration Default and Override Pattern
    # Uses Ace::Support::Config.create() for configuration cascade resolution
    # Thread-safe: uses mutex for initialization
    # @return [Hash] merged configuration hash
    # @example Get current configuration
    #   config = Ace::Git.config
    #   puts config["default_branch"]  # => "main"
    # @example Access nested diff config
    #   exclude = Ace::Git.config["exclude_patterns"]
    def self.config
      # Fast path: return cached config if already initialized
      return @config if defined?(@config) && @config

      # Thread-safe initialization
      @config_mutex.synchronize do
        @config ||= load_config
      end
    end

    # Load configuration using Ace::Support::Config cascade
    # Resolves gem defaults from .ace-defaults/ and user overrides from .ace/
    # @return [Hash] Merged and transformed configuration
    def self.load_config
      gem_root = Gem.loaded_specs["ace-git"]&.gem_dir ||
        File.expand_path("../..", __dir__)

      resolver = Ace::Support::Config.create(
        config_dir: ".ace",
        defaults_dir: ".ace-defaults",
        gem_path: gem_root
      )

      # Resolve config for git namespace
      config = resolver.resolve_namespace("git")

      # Extract and flatten the git section for backward compatibility
      raw_config = config.data["git"] || config.data
      extract_git_config(raw_config)
    rescue Ace::Support::Config::YamlParseError => e
      warn "ace-git: YAML syntax error in configuration"
      warn "  #{e.message}"
      # Fall back to gem defaults instead of empty hash to prevent silent config erasure
      extract_git_config(load_gem_defaults_fallback(gem_root))
    rescue => e
      warn "ace-git: Failed to load configuration: #{e.message}"
      # Fall back to gem defaults instead of empty hash to prevent silent config erasure
      gem_root = Gem.loaded_specs["ace-git"]&.gem_dir ||
        File.expand_path("../..", __dir__)
      extract_git_config(load_gem_defaults_fallback(gem_root))
    end
    private_class_method :load_config

    # Load gem defaults directly as fallback when cascade resolution fails
    # This ensures configuration is never silently erased due to YAML errors
    # or user config issues
    # @param gem_root [String] Path to gem root directory
    # @return [Hash] Defaults hash or empty hash if defaults also fail
    def self.load_gem_defaults_fallback(gem_root)
      defaults_path = File.join(gem_root, ".ace-defaults", "git", "config.yml")

      return {} unless File.exist?(defaults_path)

      data = YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
      data["git"] || data
    rescue
      {} # Only return empty hash if even defaults fail to load
    end
    private_class_method :load_gem_defaults_fallback

    # Extract git configuration from YAML structure
    #
    # BACKWARD COMPATIBILITY NOTE:
    # This method flattens the nested `diff:` section to top-level keys.
    # This is required because the original default_config structure used flat keys
    # (e.g., `exclude_patterns`, `exclude_whitespace`) rather than nested `diff.exclude_patterns`.
    # The YAML config uses `git.diff.exclude_patterns` for clarity, but internally we flatten
    # to maintain compatibility with DiffConfig.from_hash and existing consumers.
    #
    # Example transformation:
    #   git:
    #     diff:
    #       exclude_patterns: ["*.log"]
    #   becomes:
    #     { "exclude_patterns" => ["*.log"] }
    #
    # Keys are kept as strings for consistency with YAML loading.
    # Use config["key"] or config.key?("key") for access.
    #
    # @param git_section [Hash] The git: section from YAML
    # @return [Hash] Flattened configuration with string keys
    def self.extract_git_config(git_section)
      return {} if git_section.nil? || git_section.empty?

      config = {}

      # Normalize keys to strings for consistency
      normalized = normalize_keys(git_section)

      # Copy top-level settings
      %w[default_branch remote verbose timeout network_timeout].each do |key|
        config[key] = normalized[key] if normalized.key?(key)
      end

      # Flatten diff: section to top-level for backward compatibility (see note above)
      diff_section = normalized["diff"]
      if diff_section.is_a?(Hash)
        normalize_keys(diff_section).each do |key, value|
          config[key] = value
        end
      end

      # Copy other sections as-is (rebase, pr, squash, status, lock_retry, etc.)
      %w[rebase pr squash status lock_retry].each do |key|
        config[key] = normalized[key] if normalized.key?(key)
      end

      config
    end

    # Normalize hash keys to strings for consistent access
    # @param hash [Hash] Hash with potentially mixed string/symbol keys
    # @return [Hash] Hash with string keys
    def self.normalize_keys(hash)
      return {} unless hash.is_a?(Hash)

      hash.transform_keys(&:to_s)
    end

    # Reset configuration cache (mainly for testing)
    # Thread-safe: uses mutex to prevent race conditions
    def self.reset_config!
      @config_mutex.synchronize do
        @config = nil
      end
    end

    # ---- Configuration Helper Methods (ADR-022 compliant) ----
    # These read from config instead of using hardcoded constants

    # Timeout for local git operations (diff, status, log)
    # @return [Integer] Timeout in seconds (default: 30)
    def self.git_timeout
      config["timeout"] || 30
    end

    # Timeout for network operations (gh CLI, remote operations)
    # @return [Integer] Timeout in seconds (default: 60)
    def self.network_timeout
      config["network_timeout"] || 60
    end

    # Number of recent commits to show in status output
    # @return [Integer] Limit (default: 3)
    def self.commits_limit
      config.dig("status", "commits_limit") || 3
    end

    # Number of recently merged PRs to show in status output
    # @return [Integer] Limit (default: 3)
    def self.merged_prs_limit
      config.dig("status", "merged_prs_limit") || 3
    end

    # Number of open PRs to show in status output
    # @return [Integer] Limit (default: 10)
    def self.open_prs_limit
      config.dig("status", "open_prs_limit") || 10
    end
  end
end

# Require ATOM architecture components
require_relative "git/atoms/command_executor"
require_relative "git/atoms/pattern_filter"
require_relative "git/atoms/diff_parser"
require_relative "git/atoms/diff_numstat_parser"
require_relative "git/atoms/file_grouper"
require_relative "git/atoms/grouped_stats_formatter"
require_relative "git/atoms/date_resolver"
require_relative "git/atoms/task_pattern_extractor"
require_relative "git/atoms/pr_identifier_parser"
require_relative "git/atoms/repository_state_detector"
require_relative "git/atoms/repository_checker"
require_relative "git/atoms/git_scope_filter"
require_relative "git/atoms/time_formatter"
require_relative "git/atoms/status_formatter"
require_relative "git/atoms/lock_error_detector"
require_relative "git/atoms/stale_lock_cleaner"

require_relative "git/molecules/diff_generator"
require_relative "git/molecules/config_loader"
require_relative "git/molecules/diff_filter"
require_relative "git/molecules/branch_reader"
require_relative "git/molecules/pr_metadata_fetcher"
require_relative "git/molecules/recent_commits_fetcher"
require_relative "git/molecules/git_status_fetcher"

require_relative "git/organisms/diff_orchestrator"
require_relative "git/organisms/repo_status_loader"

require_relative "git/models/diff_result"
require_relative "git/models/diff_config"
require_relative "git/models/repo_status"
