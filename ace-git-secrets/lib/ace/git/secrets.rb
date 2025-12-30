# frozen_string_literal: true

require_relative "secrets/version"

# Load ace-core for config management
require "ace/core"

# Models
require_relative "secrets/models/detected_token"
require_relative "secrets/models/revocation_result"
require_relative "secrets/models/scan_report"

# Atoms
require_relative "secrets/atoms/gitleaks_runner"
require_relative "secrets/atoms/service_api_client"

# Molecules
require_relative "secrets/molecules/history_scanner"
require_relative "secrets/molecules/git_rewriter"
require_relative "secrets/molecules/token_revoker"

# Organisms
require_relative "secrets/organisms/security_auditor"
require_relative "secrets/organisms/history_cleaner"
require_relative "secrets/organisms/release_gate"

# Commands
require_relative "secrets/commands/scan_command"
require_relative "secrets/commands/rewrite_command"
require_relative "secrets/commands/revoke_command"
require_relative "secrets/commands/check_release_command"

# CLI
require_relative "secrets/cli"

module Ace
  module Git
    module Secrets
      class Error < StandardError; end
      class GitRewriteError < Error; end
      class RevocationError < Error; end

      # Mutex for thread-safe config loading
      @config_mutex = Mutex.new

      # Load ace-git-secrets configuration using ace-core config cascade
      # Follows ADR-022: Load defaults from .ace-defaults/, merge user overrides from .ace/
      #
      # @note Thread Safety: This method is thread-safe via Mutex synchronization.
      #   The config is loaded once and cached for subsequent calls.
      #   IMPORTANT: Config MUST be preloaded via CLI.start before parallel operations
      #   begin. When using ace-git-secrets as a library (not via CLI), call
      #   Ace::Git::Secrets.config explicitly before spawning any threads that
      #   perform scanning or revocation. Failure to preload may result in race
      #   conditions during config initialization under concurrent load.
      #
      # @return [Hash] Configuration hash
      def self.config
        @config_mutex.synchronize do
          @config ||= begin
            # Load defaults from .ace-defaults/git-secrets/config.yml
            defaults = load_example_config

            # Load user overrides from .ace/git-secrets/config.yml
            # ADR-022: Uses resolve_for to find files, then extracts "git-secrets" key
            resolver = Ace::Core::Organisms::ConfigResolver.new
            resolved = resolver.resolve_for(["git-secrets/config.yml", "git-secrets/config.yaml"])
            user_config = resolved.get("git-secrets") || resolved.data || {}

            # Deep merge user config over defaults
            # Uses ace-support-core's DeepMerger for consistency across gems
            Ace::Core::Atoms::DeepMerger.merge(defaults, user_config)
          rescue StandardError => e
            warn "Warning: Could not load ace-git-secrets config: #{e.message}"
            fallback_defaults
          end
        end
      end

      # Load defaults from .ace-defaults/git-secrets/config.yml
      # ADR-022: .ace-defaults/ is the single source of truth for defaults
      # @return [Hash] Default configuration from example file
      def self.load_example_config
        gem_root = File.expand_path("../../..", __dir__)
        example_path = File.join(gem_root, ".ace-defaults", "git-secrets", "config.yml")

        # ADR-022: Missing .ace-defaults/ file is a packaging error, not a fallback case
        unless File.exist?(example_path)
          raise Error, "Default config not found: #{example_path}. " \
                       "This is a gem packaging error - .ace-defaults/ must be included in the gem."
        end

        require "yaml"
        YAML.safe_load(File.read(example_path), permitted_classes: [], permitted_symbols: [], aliases: false) || {}
      end

      # Fallback defaults when config loading fails
      # Note: Should rarely be used - .ace-defaults/ should always be present
      # @return [Hash] Minimal fallback configuration
      def self.fallback_defaults
        {
          "exclusions" => [],
          "whitelist" => [],
          "output" => {
            "format" => "table",
            "mask_tokens" => true
          }
        }
      end

      # Get file exclusions from config
      # ADR-022: Exclusions come from .ace-defaults/, merged with user config
      # @return [Array<String>] Glob patterns for files to exclude
      def self.exclusions
        config["exclusions"] || []
      end

      # Resolve gitleaks config path with cascade
      # Checks: .ace/git-secrets/gitleaks.toml -> .ace-defaults/git-secrets/gitleaks.toml
      #
      # @note Thread Safety: This method uses the same mutex as config to ensure
      #   thread-safe initialization. Like config, it should be preloaded before
      #   spawning threads (the CLI does this automatically via CLI.start).
      # @note Environment Variable: Set ACE_GITLEAKS_CONFIG_PATH to override
      #   automatic config discovery (useful for testing).
      # @return [String, nil] Path to gitleaks config, or nil if not found
      def self.gitleaks_config_path
        @config_mutex.synchronize do
          @gitleaks_config_path ||= begin
            # Check environment variable override first (useful for testing)
            env_path = ENV["ACE_GITLEAKS_CONFIG_PATH"]
            if env_path && File.exist?(env_path)
              env_path
            else
              # Check user config first (project .ace/)
              user_path = find_user_gitleaks_config
              if user_path && File.exist?(user_path)
                user_path
              else
                # Fall back to gem defaults
                gem_root = File.expand_path("../../..", __dir__)
                example_path = File.join(gem_root, ".ace-defaults", "git-secrets", "gitleaks.toml")
                File.exist?(example_path) ? example_path : nil
              end
            end
          end
        end
      end

      # Find user gitleaks config in project .ace/ directory
      # @return [String, nil] Path to user gitleaks config
      def self.find_user_gitleaks_config
        # Search from current dir upward for .ace/git-secrets/gitleaks.toml
        dir = Dir.pwd
        while dir != "/"
          config_path = File.join(dir, ".ace", "git-secrets", "gitleaks.toml")
          return config_path if File.exist?(config_path)
          dir = File.dirname(dir)
        end
        nil
      end

      # Check if gitleaks is available in PATH
      # @return [Boolean] true if gitleaks is available
      def self.gitleaks_available?
        @gitleaks_available ||= system("which gitleaks > /dev/null 2>&1")
      end

      # Reset config cache
      # Useful for testing to ensure clean state between tests.
      # Thread-safe - uses mutex to reset all cached values atomically.
      # @return [void]
      def self.reset_config!
        @config_mutex.synchronize do
          @config = nil
          @gitleaks_config_path = nil
        end
        @gitleaks_available = nil
      end
    end
  end
end
