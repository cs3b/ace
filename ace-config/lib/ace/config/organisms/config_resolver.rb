# frozen_string_literal: true

require "fileutils"

module Ace
  module Config
    module Organisms
      # Complete configuration cascade resolution
      class ConfigResolver
        attr_reader :config_dir, :defaults_dir, :gem_path
        attr_reader :file_patterns, :merge_strategy

        # Initialize config resolver with configurable options
        # @param config_dir [String] User config folder name (default: ".ace")
        # @param defaults_dir [String] Gem defaults folder name (default: ".ace-defaults")
        # @param gem_path [String, nil] Gem root path for defaults
        # @param file_patterns [Array<String>, nil] Patterns for config files
        # @param merge_strategy [Symbol] How to merge arrays (:replace, :concat, :union)
        def initialize(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: nil,
          file_patterns: nil,
          merge_strategy: :replace
        )
          @config_dir = config_dir
          @defaults_dir = defaults_dir
          @gem_path = gem_path
          @file_patterns = file_patterns || Molecules::ConfigFinder::DEFAULT_FILE_PATTERNS
          @merge_strategy = merge_strategy
        end

        # Resolve configuration cascade (memoized)
        # @return [Models::Config] Merged configuration
        def resolve
          @resolved_config ||= resolve_without_cache
        end

        # Reset memoized configuration (useful for tests or dynamic reloading)
        def reset!
          @resolved_config = nil
        end

        # Resolve and get value by key path (uses memoized resolve)
        # @param keys [Array<String,Symbol>] Key path
        # @return [Object] Value at key path
        def get(*keys)
          resolve.get(*keys)
        end

        # Resolve configuration for specific file patterns (not memoized)
        #
        # Unlike `resolve`, this method always re-reads files to support
        # different pattern sets. Use `resolve` for repeated access to
        # the same configuration.
        #
        # @param patterns [Array<String>, String] File patterns to search for
        # @return [Models::Config] Resolved configuration
        def resolve_for(patterns)
          # Create finder with specified patterns
          finder = Molecules::ConfigFinder.new(
            config_dir: config_dir,
            defaults_dir: defaults_dir,
            gem_path: gem_path,
            file_patterns: Array(patterns)
          )

          cascade_paths = finder.find_all.select(&:exists)

          if cascade_paths.empty?
            return Models::Config.new({}, source: "no_config_found", merge_strategy: merge_strategy)
          end

          # Load and merge configs
          configs = cascade_paths.map do |cascade_path|
            Molecules::YamlLoader.load_file(cascade_path.path)
          end

          merged_data = configs.reverse.reduce({}) do |result, config|
            Atoms::DeepMerger.merge(
              result,
              config.data,
              array_strategy: merge_strategy
            )
          end

          sources = cascade_paths.map(&:path).join(" -> ")
          Models::Config.new(
            merged_data,
            source: sources,
            merge_strategy: merge_strategy
          )
        end

        # Get config from specific type
        # @param type [Symbol] Config type (:local, :home, :gem)
        # @return [Models::Config, nil] Config from that type
        def resolve_type(type)
          finder = build_finder

          paths = finder.find_by_type(type).select(&:exists)
          return nil if paths.empty?

          # Merge configs of same type
          configs = paths.map do |path|
            Molecules::YamlLoader.load_file(path.path)
          end

          merged_data = configs.reduce({}) do |result, config|
            Atoms::DeepMerger.merge(
              result,
              config.data,
              array_strategy: merge_strategy
            )
          end

          Models::Config.new(
            merged_data,
            source: "#{type}_configs",
            merge_strategy: merge_strategy
          )
        end

        # Find config files
        # @return [Array<Models::CascadePath>] All potential config paths
        def find_configs
          build_finder.find_all
        end

        private

        # Internal: resolve configuration cascade without caching
        # @return [Models::Config] Merged configuration
        def resolve_without_cache
          finder = build_finder

          cascade_paths = finder.find_all.select(&:exists)

          if cascade_paths.empty?
            return Models::Config.new({}, source: "defaults", merge_strategy: merge_strategy)
          end

          # Load all configs in cascade order
          configs = cascade_paths.map do |cascade_path|
            Molecules::YamlLoader.load_file(cascade_path.path)
          end

          # Merge in reverse order (lowest priority first)
          merged_data = configs.reverse.reduce({}) do |result, config|
            Atoms::DeepMerger.merge(
              result,
              config.data,
              array_strategy: merge_strategy
            )
          end

          sources = cascade_paths.map(&:path).join(" -> ")
          Models::Config.new(
            merged_data,
            source: sources,
            merge_strategy: merge_strategy
          )
        end

        # Build a ConfigFinder with current settings
        def build_finder
          Molecules::ConfigFinder.new(
            config_dir: config_dir,
            defaults_dir: defaults_dir,
            gem_path: gem_path,
            file_patterns: file_patterns
          )
        end

        # Create default config structure
        # @param path [String] Where to create config
        # @return [Models::Config] Created configuration
        def self.create_default(path = "./.ace/settings.yml")
          default_config = {
            "config" => {
              "version" => Ace::Config::VERSION,
              "cascade" => {
                "enabled" => true,
                "merge_strategy" => :replace
              }
            }
          }

          # Ensure directory exists
          dir = File.dirname(path)
          FileUtils.mkdir_p(dir)

          # Save config
          config = Models::Config.new(default_config, source: path)
          Molecules::YamlLoader.save_file(config, path)

          config
        end
      end
    end
  end
end
