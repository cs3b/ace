# frozen_string_literal: true

require "fileutils"

module Ace
  module Support
    module Config
      module Organisms
        # Complete configuration cascade resolution
        class ConfigResolver
          attr_reader :config_dir, :defaults_dir, :gem_path
          attr_reader :file_patterns, :merge_strategy, :test_mode

          # Initialize config resolver with configurable options
          # @param config_dir [String] User config folder name (default: ".ace")
          # @param defaults_dir [String] Gem defaults folder name (default: ".ace-defaults")
          # @param gem_path [String, nil] Gem root path for defaults
          # @param file_patterns [Array<String>, nil] Patterns for config files
          # @param merge_strategy [Symbol] How to merge arrays (:replace, :concat, :union)
          # @param cache_namespaces [Boolean] Whether to cache resolve_namespace results (default: false)
          # @param test_mode [Boolean] Skip filesystem searches and return empty/mock config (default: false)
          # @param mock_config [Hash, nil] Mock config data to return in test mode
          def initialize(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: nil,
            file_patterns: nil,
            merge_strategy: :replace,
            cache_namespaces: false,
            test_mode: false,
            mock_config: nil
          )
            @config_dir = config_dir
            @defaults_dir = defaults_dir
            @gem_path = gem_path
            @file_patterns = file_patterns || Molecules::ConfigFinder::DEFAULT_FILE_PATTERNS
            @merge_strategy = merge_strategy
            @cache_namespaces = cache_namespaces
            @namespace_cache = {} if cache_namespaces
            @test_mode = test_mode
            @mock_config = mock_config || {}
          end

          # Check if test mode is active
          # @return [Boolean] True if test mode is active
          def test_mode?
            @test_mode == true
          end

          # Resolve configuration cascade (memoized)
          #
          # In test mode, returns mock config immediately without filesystem access.
          # @return [Models::Config] Merged configuration
          def resolve
            @resolved_config ||= test_mode? ? resolve_test_mode : resolve_without_cache
          end

          # Reset memoized configuration (useful for tests or dynamic reloading)
          def reset!
            @resolved_config = nil
            @namespace_cache&.clear
          end

          # Resolve and get value by key path (uses memoized resolve)
          # @param keys [Array<String,Symbol>] Key path
          # @return [Object] Value at key path
          def get(*keys)
            resolve.get(*keys)
          end

          # Resolve configuration for a namespace path (optionally memoized)
          #
          # Builds file patterns from path segments and automatically appends
          # .yml/.yaml extensions. This is a convenience wrapper around resolve_for.
          #
          # By default, resolve_namespace is NOT memoized to ensure fresh config reads.
          # To enable caching for performance in tight loops, initialize the resolver
          # with `cache_namespaces: true`.
          #
          # @param segments [Array<String>] Path segments (e.g., "docs", "config")
          # @param filename [String] Filename without extension (default: "config")
          # @return [Models::Config] Resolved configuration
          #
          # @example Single segment with default filename
          #   resolve_namespace("docs")
          #   # Resolves: ["docs/config.yml", "docs/config.yaml"]
          #
          # @example Multiple segments
          #   resolve_namespace("git", "worktree")
          #   # Resolves: ["git/worktree/config.yml", "git/worktree/config.yaml"]
          #
          # @example Custom filename
          #   resolve_namespace("lint", filename: "kramdown")
          #   # Resolves: ["lint/kramdown.yml", "lint/kramdown.yaml"]
          #
          # @example Root config with custom filename
          #   resolve_namespace(filename: "settings")
          #   # Resolves: ["settings.yml", "settings.yaml"]
          #
          # @example With caching enabled
          #   resolver = Ace::Support::Config.create(cache_namespaces: true)
          #   resolver.resolve_namespace("docs")  # reads from disk
          #   resolver.resolve_namespace("docs")  # returns cached result
          #
          # @see #resolve_file For pattern-based resolution
          # @see #resolve For default configuration cascade
          def resolve_namespace(*segments, filename: "config")
            # Sanitize segments:
            # - flatten: handle nested arrays like resolve_namespace(["git", "worktree"])
            # - compact: remove nil values
            # - stringify + strip: handle symbols and whitespace
            # - reject empty: filter out empty strings after stripping
            clean_segments = segments.flatten.compact.map(&:to_s).map(&:strip).reject(&:empty?)

            # Security: Validate segments don't contain path traversal or absolute paths
            validate_namespace_segments!(clean_segments)

            # Strip .yml/.yaml extension if user accidentally included it
            clean_filename = filename.to_s.sub(/\.ya?ml\z/i, "")

            # Security: Reject empty filenames (e.g., filename: ".yml" becomes empty after stripping)
            if clean_filename.empty?
              raise ArgumentError, "Invalid filename: #{filename.inspect} (filename cannot be empty)"
            end

            # Security: Validate filename doesn't contain path traversal
            validate_namespace_segments!([clean_filename])

            # Check cache if enabled
            if @cache_namespaces
              cache_key = [clean_segments, clean_filename].hash
              return @namespace_cache[cache_key] if @namespace_cache.key?(cache_key)
            end

            # Generate both .yml and .yaml patterns using File.join for cross-platform compatibility
            patterns = if clean_segments.empty?
              ["#{clean_filename}.yml", "#{clean_filename}.yaml"]
            else
              base_path = File.join(*clean_segments)
              [File.join(base_path, "#{clean_filename}.yml"), File.join(base_path, "#{clean_filename}.yaml")]
            end

            result = resolve_file(patterns)

            # Store in cache if enabled
            if @cache_namespaces
              cache_key = [clean_segments, clean_filename].hash
              @namespace_cache[cache_key] = result
            end

            result
          end

          # Resolve configuration for specific file patterns (not memoized)
          #
          # Unlike `resolve`, this method always re-reads files to support
          # different pattern sets. Use `resolve` for repeated access to
          # the same configuration.
          #
          # In test mode, returns mock config immediately without filesystem access.
          #
          # @param patterns [Array<String>, String] File patterns to search for
          # @return [Models::Config] Resolved configuration
          def resolve_file(patterns)
            # Short-circuit in test mode
            return resolve_test_mode if test_mode?

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

          # @deprecated Use {#resolve_file} instead
          # @param patterns [Array<String>, String] File patterns to search for
          # @return [Models::Config] Resolved configuration
          def resolve_for(patterns)
            warn "[DEPRECATED] resolve_for() is deprecated. Use resolve_file() instead.", uplevel: 1
            resolve_file(patterns)
          end

          # Get config from specific type
          #
          # In test mode, returns mock config immediately without filesystem access.
          #
          # @param type [Symbol] Config type (:local, :home, :gem)
          # @return [Models::Config, nil] Config from that type
          def resolve_type(type)
            # Short-circuit in test mode
            return resolve_test_mode if test_mode?

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
          #
          # In test mode, returns an empty array without filesystem access.
          #
          # @return [Array<Models::CascadePath>] All potential config paths
          def find_configs
            # Short-circuit in test mode
            return [] if test_mode?

            build_finder.find_all
          end

          private

          # Internal: resolve in test mode (no filesystem access)
          # @return [Models::Config] Mock configuration
          def resolve_test_mode
            Models::Config.new(
              @mock_config,
              source: "test_mode",
              merge_strategy: merge_strategy
            )
          end

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

          # Validate namespace segments for security
          # Delegates to Atoms::PathValidator for the actual validation
          # @param segments [Array<String>] Segments to validate
          # @raise [ArgumentError] If any segment contains invalid characters
          def validate_namespace_segments!(segments)
            Atoms::PathValidator.validate_segments!(segments)
          end

          # Create default config structure
          # @param path [String] Where to create config
          # @return [Models::Config] Created configuration
          def self.create_default(path = "./.ace/settings.yml")
            default_config = {
              "config" => {
                "version" => Ace::Support::Config::VERSION,
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
end
