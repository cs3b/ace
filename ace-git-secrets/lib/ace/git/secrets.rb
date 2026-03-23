# frozen_string_literal: true

require_relative "secrets/version"

# Load ace-config for configuration cascade management
require "ace/support/config"

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

      # Load ace-git-secrets configuration using ace-config cascade
      # Follows ADR-022: Load defaults from .ace-defaults/, merge user overrides from .ace/
      # Uses Ace::Support::Config.create() for configuration cascade resolution
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
            gem_root = Gem.loaded_specs["ace-git-secrets"]&.gem_dir ||
              File.expand_path("../../..", __dir__)

            resolver = Ace::Support::Config.create(
              config_dir: ".ace",
              defaults_dir: ".ace-defaults",
              gem_path: gem_root
            )

            # Resolve config for git-secrets namespace
            config = resolver.resolve_namespace("git-secrets")

            # Extract git-secrets section if present
            config.data["git-secrets"] || config.data
          rescue => e
            warn "Warning: Could not load ace-git-secrets config: #{e.message}"
            fallback_defaults
          end
        end
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
