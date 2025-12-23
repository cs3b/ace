# frozen_string_literal: true

require "ace/core"
require "yaml"
require_relative "git/version"

module Ace
  module Git
    # Default timeouts for commands
    # Local git operations (diff, status, etc.) - faster, less likely to hang
    DEFAULT_GIT_TIMEOUT = 30
    # Network operations (gh CLI, remote operations) - may need more time
    DEFAULT_NETWORK_TIMEOUT = 60

    # Backward compatibility alias - used by CommandExecutor, DiffConfig
    DEFAULT_TIMEOUT = DEFAULT_GIT_TIMEOUT

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
    # Priority: user config (from cascade) merged over gem defaults
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
        @config ||= Ace::Core::Atoms::DeepMerger.merge(default_config, user_config)
      end
    end

    # User configuration from ace-core cascade
    # Flattened to match default_config structure (see extract_git_config)
    # @return [Hash] user configuration (may be empty)
    # @example Check for user overrides
    #   if Ace::Git.user_config["verbose"]
    #     puts "Verbose mode enabled by user"
    #   end
    def self.user_config
      raw_config = Ace::Core.config.get("ace", "git") || {}
      # Flatten user config to match default_config structure
      # This ensures nested diff: keys are merged correctly
      extract_git_config(raw_config)
    end

    # Load gem defaults from .ace.example/git/config.yml
    # Per ADR-022: gem MUST include .ace.example/ - missing file is a packaging error
    # @return [Hash] Default configuration from gem
    # @raise [RuntimeError] If default config file is missing (gem packaging error)
    # @example Get defaults without user overrides
    #   defaults = Ace::Git.default_config
    #   puts defaults["exclude_whitespace"]  # => true
    def self.default_config
      @default_config ||= load_gem_defaults
    end

    # Load defaults from .ace.example/git/config.yml
    # Handles both development (relative path) and installed gem (Gem.loaded_specs) scenarios
    # @return [Hash] Default configuration
    def self.load_gem_defaults
      # Try to find gem root via RubyGems for installed gems, fallback to relative path for dev
      gem_spec = Gem.loaded_specs["ace-git"]
      gem_root = gem_spec ? gem_spec.gem_dir : File.expand_path("../..", __dir__)
      default_file = File.join(gem_root, ".ace.example", "git", "config.yml")

      unless File.exist?(default_file)
        raise "Default config not found: #{default_file}. " \
              "This is a gem packaging error - .ace.example/ must be included in the gem."
      end

      content = YAML.load_file(default_file)
      extract_git_config(content&.dig("git") || {})
    end

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
      %w[default_branch remote verbose timeout].each do |key|
        config[key] = normalized[key] if normalized.key?(key)
      end

      # Flatten diff: section to top-level for backward compatibility (see note above)
      diff_section = normalized["diff"]
      if diff_section.is_a?(Hash)
        normalize_keys(diff_section).each do |key, value|
          config[key] = value
        end
      end

      # Copy other sections as-is (rebase, pr, squash, etc.)
      %w[rebase pr squash].each do |key|
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
    def self.reset_config!
      @config = nil
      @default_config = nil
    end
  end
end

# Require ATOM architecture components
require_relative "git/atoms/command_executor"
require_relative "git/atoms/pattern_filter"
require_relative "git/atoms/diff_parser"
require_relative "git/atoms/date_resolver"
require_relative "git/atoms/task_pattern_extractor"
require_relative "git/atoms/pr_identifier_parser"
require_relative "git/atoms/repository_state_detector"
require_relative "git/atoms/repository_checker"
require_relative "git/atoms/git_scope_filter"
require_relative "git/atoms/context_formatter"

require_relative "git/molecules/diff_generator"
require_relative "git/molecules/config_loader"
require_relative "git/molecules/diff_filter"
require_relative "git/molecules/branch_reader"
require_relative "git/molecules/pr_metadata_fetcher"

require_relative "git/organisms/diff_orchestrator"
require_relative "git/organisms/repo_context_loader"

require_relative "git/models/diff_result"
require_relative "git/models/diff_config"
require_relative "git/models/repo_context"
