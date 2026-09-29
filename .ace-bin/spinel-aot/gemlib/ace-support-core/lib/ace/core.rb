# frozen_string_literal: true

require_relative "core/version"
require_relative "core/errors"

# Import ace-config for generic configuration cascade
require "ace/support/config"

# Import ace-support-fs for filesystem utilities (also re-exported by ace-config)
require "ace/support/fs"

# Ace-specific components
require_relative "core/atoms/config_summary"
require_relative "core/atoms/command_executor"
require_relative "core/organisms/environment_manager"
require_relative "core/config_discovery"

# CLI infrastructure — main classes now live in ace-support-cli
require "ace/support/cli"
require_relative "core/cli/config_summary_mixin"

module Ace
  module Core
    # Main module providing config cascade and environment management
    class << self
      # Resolve configuration with cascade using ace-config
      # @return [Models::Config] Resolved configuration
      def config
        cached_resolver.resolve
      end

      # Get configuration value by key path or namespace
      # @param namespace_or_keys [String, Symbol, Array] Namespace name or key path
      # @param file [String, nil] Optional file name for namespace
      # @param keys [Array<String,Symbol>] Additional key path after namespace
      # @return [Object] Configuration value
      def get(namespace_or_keys, *keys, file: nil)
        resolver = cached_resolver

        # If first arg looks like a namespace, resolve it
        if namespace_or_keys.is_a?(String) && namespace_or_keys.match?(/^[a-z]+$/)
          config = if file
            # Use resolve_namespace for single-file case (cleaner API)
            resolver.resolve_namespace(namespace_or_keys, filename: file)
          else
            # Use resolve_file for glob pattern case (resolve_namespace doesn't support globs)
            resolver.resolve_file(namespace_glob_patterns(namespace_or_keys))
          end
          keys.empty? ? config.data : config.get(*keys)
        else
          # Traditional key path lookup
          resolver.get(namespace_or_keys, *keys)
        end
      end

      # Build glob patterns for all YAML files in a namespace directory
      # @param namespace [String] Namespace name
      # @return [Array<String>] Glob patterns for .yml and .yaml files
      # @api private
      def namespace_glob_patterns(namespace)
        ["#{namespace}/*.yml", "#{namespace}/*.yaml"]
      end

      # Load environment variables
      # @param root [String] Project root path
      # @return [Hash] Loaded variables
      def load_environment(root: Dir.pwd)
        manager = Organisms::EnvironmentManager.new(root_path: root)
        manager.load
      end

      # Create default configuration
      # @param path [String] Where to create config
      # @return [Models::Config] Created config
      def create_default_config(path = "./.ace/core/config.yml")
        ::Ace::Support::Config::Organisms::ConfigResolver.create_default(path)
      end

      # Get environment manager
      # @param root [String] Project root
      # @return [Organisms::EnvironmentManager] Environment manager
      def environment(root: Dir.pwd)
        Organisms::EnvironmentManager.new(root_path: root)
      end

      # Get environment variable from cascade without polluting ENV
      # First checks ENV, then loads from .ace/.env cascade
      # @param key [String] Environment variable name
      # @param default [Object] Default value if not found
      # @return [String, Object] Variable value or default
      def get_env(key, default = nil)
        # Check ENV first for already-set variables
        return ENV[key] if ENV.key?(key) && !ENV[key].to_s.empty?

        # Load from cascade (cached for performance)
        cascade_vars[key] || default
      end

      # Clear the cascade cache (useful for testing or reloading)
      def clear_env_cache
        @cascade_vars = nil
      end

      # Reset all cached configuration state
      # Per ADR-022, this method allows test isolation
      def reset_config!
        @cached_resolver = nil
        ::Ace::Support::Config.reset_config!
        clear_env_cache
      end

      private

      # Cached resolver instance for performance
      # Avoids repeated filesystem traversal on every config/get call
      def cached_resolver
        @cached_resolver ||= ::Ace::Support::Config.create(
          config_dir: ".ace",
          defaults_dir: resolve_defaults_dir,
          gem_path: gem_root_path
        )
      end

      # Defaults directory for gem configuration
      def resolve_defaults_dir
        ".ace-defaults"
      end

      # Get gem root path for loading bundled defaults
      def gem_root_path
        spec = ::Gem.loaded_specs["ace-support-core"]
        spec&.gem_dir || File.expand_path("../../..", __dir__)
      end

      # Cached cascade variables
      def cascade_vars
        @cascade_vars ||= begin
          require_relative "core/molecules/env_loader"
          Molecules::EnvLoader.load_cascade
        end
      end
    end
  end
end
