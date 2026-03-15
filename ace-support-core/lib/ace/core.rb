# frozen_string_literal: true

require_relative "core/version"
require_relative "core/errors"

# Import ace-config for generic configuration cascade
require 'ace/support/config'

# Import ace-support-fs for filesystem utilities (also re-exported by ace-config)
require "ace/support/fs"

# Ace-specific components
require_relative "core/atoms/config_summary"
require_relative "core/atoms/command_executor"
require_relative "core/organisms/environment_manager"
require_relative "core/config_discovery"

# CLI infrastructure based on ace-support-cli
require_relative "core/cli/error"
require_relative "core/cli/base"
require_relative "core/cli/standard_options"
require_relative "core/cli/registry_dsl"
require_relative "core/cli/command_groups"
require_relative "core/cli/config_summary_mixin"
require_relative "core/cli/help_command"
require_relative "core/cli/default_routing"
require_relative "core/cli/help_router"
require_relative "core/cli/version_command"
require_relative "core/cli/help_concise"

module Ace
  module Core
    # Temporary constant compatibility for packages that still reference
    # Ace::Core::CLI::DryCli::* while migrating to Ace::Core::CLI::*.
    # Old require paths under ace/core/cli/dry_cli/* remain removed.
    module CLI
      module DryCli
        Base = ::Ace::Core::CLI::Base
        ConfigSummaryMixin = ::Ace::Core::CLI::ConfigSummaryMixin
        HelpCommand = ::Ace::Core::CLI::HelpCommand
        DefaultRouting = ::Ace::Core::CLI::DefaultRouting
        HelpRouter = ::Ace::Core::CLI::HelpRouter
        VersionCommand = ::Ace::Core::CLI::VersionCommand
        HelpConcise = ::Ace::Core::CLI::HelpConcise
        CommandGroups = ::Ace::Core::CLI::CommandGroups
        StandardOptions = ::Ace::Core::CLI::StandardOptions
      end
    end

    # Re-export ace-config and ace-support-fs classes for backward compatibility
    # This allows existing code using Ace::Core::* to continue working
    #
    # Dependency chain:
    #   ace-support-core
    #     └── ace-config (configuration cascade)
    #           └── ace-support-fs (filesystem utilities)
    #
    # Note: PathExpander, DirectoryTraverser, ProjectRootFinder originate from
    # ace-support-fs but are re-exported here for convenience.

    module Atoms
      # From ace-config: configuration parsing and merging
      DeepMerger = ::Ace::Support::Config::Atoms::DeepMerger
      YamlParser = ::Ace::Support::Config::Atoms::YamlParser

      # From ace-support-fs: path resolution utilities
      PathExpander = ::Ace::Support::Fs::Atoms::PathExpander
    end

    module Molecules
      # From ace-config: configuration discovery and loading
      ConfigFinder = ::Ace::Support::Config::Molecules::ConfigFinder
      YamlLoader = ::Ace::Support::Config::Molecules::YamlLoader

      # From ace-support-fs: filesystem traversal and project detection
      DirectoryTraverser = ::Ace::Support::Fs::Molecules::DirectoryTraverser
      ProjectRootFinder = ::Ace::Support::Fs::Molecules::ProjectRootFinder
    end

    module Organisms
      ConfigResolver = ::Ace::Support::Config::Organisms::ConfigResolver
      VirtualConfigResolver = ::Ace::Support::Config::Organisms::VirtualConfigResolver
    end

    module Models
      # Re-export from ace-config
      CascadePath = ::Ace::Support::Config::Models::CascadePath
      Config = ::Ace::Support::Config::Models::Config
    end

    # Re-export errors for backward compatibility
    # Note: Ace::Core::Error and ace-specific errors remain in core/errors.rb
    # These are aliases for ace-config errors
    ConfigNotFoundError = ::Ace::Support::Config::ConfigNotFoundError
    YamlParseError = ::Ace::Support::Config::YamlParseError
    PathError = ::Ace::Support::Config::PathError
    MergeStrategyError = ::Ace::Support::Config::MergeStrategyError

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
