# frozen_string_literal: true

require_relative "core/version"
require_relative "core/errors"

# Import ace-config for generic configuration cascade
require "ace/config"

# Import ace-support-fs for filesystem utilities (also re-exported by ace-config)
require "ace/support/fs"

# Ace-specific components
require_relative "core/organisms/environment_manager"
require_relative "core/config_discovery"

module Ace
  module Core
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
      DeepMerger = ::Ace::Config::Atoms::DeepMerger
      YamlParser = ::Ace::Config::Atoms::YamlParser

      # From ace-support-fs: path resolution utilities
      PathExpander = ::Ace::Support::Fs::Atoms::PathExpander
    end

    module Molecules
      # From ace-config: configuration discovery and loading
      ConfigFinder = ::Ace::Config::Molecules::ConfigFinder
      YamlLoader = ::Ace::Config::Molecules::YamlLoader

      # From ace-support-fs: filesystem traversal and project detection
      DirectoryTraverser = ::Ace::Support::Fs::Molecules::DirectoryTraverser
      ProjectRootFinder = ::Ace::Support::Fs::Molecules::ProjectRootFinder
    end

    module Organisms
      # Backward-compatible wrapper for ConfigResolver
      # Accepts old API (search_paths, file_patterns) and translates to new API
      class ConfigResolver < ::Ace::Config::Organisms::ConfigResolver
        # @param search_paths [Array<String>] DEPRECATED - use config_dir/defaults_dir instead
        # @param file_patterns [Array<String>] Optional file patterns
        # @param merge_strategy [Symbol] How to merge arrays (:replace, :concat, :union)
        # @param config_dir [String] User config folder name (default: ".ace")
        # @param defaults_dir [String] Gem defaults folder name (default: ".ace-defaults")
        # @param gem_path [String, nil] Gem root path for defaults
        def initialize(
          search_paths: nil,
          file_patterns: nil,
          merge_strategy: :replace,
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: nil
        )
          if search_paths
            warn "[DEPRECATION] Ace::Core::Organisms::ConfigResolver search_paths parameter is deprecated. " \
                 "Use config_dir and defaults_dir parameters instead."
            # When search_paths is provided, use it as the basis for resolution
            # This maintains backward compatibility for tests
            @legacy_search_paths = search_paths
            @legacy_file_patterns = file_patterns || ["*.yml", "*.yaml"]
            @legacy_merge_strategy = merge_strategy
          end

          super(
            config_dir: config_dir,
            defaults_dir: defaults_dir,
            gem_path: gem_path,
            file_patterns: file_patterns,
            merge_strategy: merge_strategy
          )
        end

        def resolve
          if @legacy_search_paths
            # Legacy resolution using explicit search paths
            resolve_legacy
          else
            super
          end
        end

        # Legacy method: find config paths in search paths
        def find_configs
          return super unless @legacy_search_paths

          result = []
          @legacy_search_paths.each_with_index do |search_path, idx|
            type = case idx
                   when 0 then :project
                   when 1 then :home
                   else :gem
                   end
            expanded_path = File.expand_path(search_path)

            @legacy_file_patterns.each do |pattern|
              potential_files = if pattern.include?("*")
                Dir.glob(File.join(expanded_path, pattern)).sort
              else
                [File.join(expanded_path, pattern)]
              end

              potential_files.each do |file|
                result << ::Ace::Config::Models::CascadePath.new(
                  path: file,
                  type: type,
                  exists: File.exist?(file)
                )
              end
            end
          end
          result
        end

        # Legacy method: resolve only configs of a specific type
        def resolve_type(type)
          return super(type) unless @legacy_search_paths

          type_index = case type
                       when :project, :local then 0
                       when :home, :user then 1
                       when :gem, :global then 2
                       else return nil
                       end

          return nil if type_index >= @legacy_search_paths.length

          search_path = @legacy_search_paths[type_index]
          expanded_path = File.expand_path(search_path)
          return nil unless Dir.exist?(expanded_path)

          all_configs = []
          @legacy_file_patterns.each do |pattern|
            Dir.glob(File.join(expanded_path, pattern)).sort.each do |file|
              config = ::Ace::Config::Molecules::YamlLoader.load_file(file)
              all_configs << config if config
            rescue ::Ace::Config::YamlParseError
              # Skip malformed
            end
          end

          return nil if all_configs.empty?

          merged = all_configs.reduce({}) do |acc, config|
            ::Ace::Config::Atoms::DeepMerger.merge(acc, config.data, array_strategy: @legacy_merge_strategy)
          end
          ::Ace::Config::Models::Config.new(merged, source: all_configs.first.source)
        end

        private

        def resolve_legacy
          all_configs = []

          @legacy_search_paths.each do |search_path|
            expanded_path = File.expand_path(search_path)
            next unless Dir.exist?(expanded_path)

            @legacy_file_patterns.each do |pattern|
              Dir.glob(File.join(expanded_path, pattern)).sort.each do |file|
                begin
                  config = ::Ace::Config::Molecules::YamlLoader.load_file(file)
                  all_configs << config if config
                rescue ::Ace::Config::YamlParseError
                  raise # Re-raise for test compatibility
                end
              end
            end
          end

          # Merge all configs (first has highest priority)
          if all_configs.empty?
            ::Ace::Config::Models::Config.new({}, source: "defaults")
          else
            merged = all_configs.reverse.reduce({}) do |acc, config|
              ::Ace::Config::Atoms::DeepMerger.merge(acc, config.data, array_strategy: @legacy_merge_strategy)
            end
            # Build cascade source showing all config paths
            cascade_source = all_configs.map(&:source).join(" -> ")
            ::Ace::Config::Models::Config.new(merged, source: cascade_source)
          end
        end
      end

      VirtualConfigResolver = ::Ace::Config::Organisms::VirtualConfigResolver
    end

    module Models
      # Re-export from ace-config
      CascadePath = ::Ace::Config::Models::CascadePath
      Config = ::Ace::Config::Models::Config
    end

    # Re-export errors for backward compatibility
    # Note: Ace::Core::Error and ace-specific errors remain in core/errors.rb
    # These are aliases for ace-config errors
    ConfigNotFoundError = ::Ace::Config::ConfigNotFoundError
    YamlParseError = ::Ace::Config::YamlParseError
    PathError = ::Ace::Config::PathError
    MergeStrategyError = ::Ace::Config::MergeStrategyError

    # Main module providing config cascade and environment management
    class << self
      # Resolve configuration with cascade using ace-config
      # @param search_paths [Array<String>] DEPRECATED - no longer used, will be removed in 1.0
      # @param file_patterns [Array<String>] DEPRECATED - no longer used, will be removed in 1.0
      # @return [Models::Config] Resolved configuration
      def config(search_paths: nil, file_patterns: nil)
        if search_paths || file_patterns
          warn "[DEPRECATION] Ace::Core.config search_paths and file_patterns parameters are deprecated " \
               "and ignored. Use Ace::Config.create(config_dir:, defaults_dir:) for custom paths."
        end

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
          # Use resolve_for instead of deprecated resolve_namespace
          patterns = if file
            ["#{namespace_or_keys}/#{file}.yml", "#{namespace_or_keys}/#{file}.yaml"]
          else
            ["#{namespace_or_keys}/*.yml", "#{namespace_or_keys}/*.yaml"]
          end
          config = resolver.resolve_for(patterns)
          keys.empty? ? config.data : config.get(*keys)
        else
          # Traditional key path lookup
          resolver.get(namespace_or_keys, *keys)
        end
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
        ::Ace::Config::Organisms::ConfigResolver.create_default(path)
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
        ::Ace::Config.reset_config!
        clear_env_cache
      end

      private

      # Cached resolver instance for performance
      # Avoids repeated filesystem traversal on every config/get call
      def cached_resolver
        @cached_resolver ||= ::Ace::Config.create(
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
