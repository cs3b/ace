# frozen_string_literal: true

require "pathname"

module Ace
  module Lint
    module Atoms
      # Locates configuration files for validators with precedence rules
      # Precedence: explicit path > .ace/lint/ > native config > gem defaults
      # Results are cached to avoid repeated filesystem I/O (thread-safe)
      class ConfigLocator
        # Native config file names for each tool
        NATIVE_CONFIGS = {
          standardrb: [".standard.yml"],
          rubocop: [".rubocop.yml"]
        }.freeze

        # Default config paths within gem defaults directory
        GEM_DEFAULT_CONFIGS = {
          standardrb: nil, # StandardRB uses its own defaults
          rubocop: ".rubocop.yml"
        }.freeze

        # Thread-safe class-level cache for config lookup results
        @config_cache = {}
        @cache_mutex = Mutex.new

        # Locate config file for a validator
        # @param tool [String, Symbol] Validator name (e.g., :standardrb, :rubocop)
        # @param project_root [String] Project root directory
        # @param explicit_path [String, nil] Explicit config path from user config
        # @return [Hash] { path: String|nil, source: Symbol }
        #   source: :explicit, :ace_config, :native, :gem_defaults, :none
        def self.locate(tool, project_root:, explicit_path: nil)
          tool_sym = tool.to_s.downcase.to_sym

          # 1. Explicit path takes highest precedence (not cached)
          if explicit_path && !explicit_path.empty?
            full_path = resolve_path(explicit_path, project_root)
            return {path: full_path, source: :explicit, exists: File.exist?(full_path)}
          end

          # Build cache key (exclude explicit_path from caching as it may vary)
          cache_key = "#{tool_sym}:#{project_root}"

          # Thread-safe cache lookup and population
          @cache_mutex.synchronize do
            # Return cached result if available
            return @config_cache[cache_key].dup if @config_cache.key?(cache_key)

            # 2. Check .ace/lint/ directory
            ace_config = find_ace_config(tool_sym, project_root)
            if ace_config
              @config_cache[cache_key] = ace_config
              return ace_config.dup
            end

            # 3. Check for native config in project root
            native_config = find_native_config(tool_sym, project_root)
            if native_config
              @config_cache[cache_key] = native_config
              return native_config.dup
            end

            # 4. Fall back to gem defaults
            gem_config = find_gem_default_config(tool_sym)
            if gem_config
              @config_cache[cache_key] = gem_config
              return gem_config.dup
            end

            result = {path: nil, source: :none, exists: false}
            @config_cache[cache_key] = result
            result
          end
        end

        # Resolve a potentially relative path
        # @param path [String] Path to resolve
        # @param base [String] Base directory for relative paths
        # @return [String] Resolved absolute path
        def self.resolve_path(path, base)
          return path if Pathname.new(path).absolute?

          File.expand_path(path, base)
        end

        # Find config in .ace/lint/ directory
        # @param tool [Symbol] Validator name
        # @param project_root [String] Project root directory
        # @return [Hash, nil] Config info or nil if not found
        def self.find_ace_config(tool, project_root)
          ace_lint_dir = File.join(project_root, ".ace", "lint")
          return nil unless File.directory?(ace_lint_dir)

          # Try tool-specific config names
          config_names = native_config_names(tool)
          config_names.each do |name|
            path = File.join(ace_lint_dir, name)
            return {path: path, source: :ace_config, exists: true} if File.exist?(path)
          end

          nil
        end
        private_class_method :find_ace_config

        # Find native config in project root
        # @param tool [Symbol] Validator name
        # @param project_root [String] Project root directory
        # @return [Hash, nil] Config info or nil if not found
        def self.find_native_config(tool, project_root)
          config_names = native_config_names(tool)
          config_names.each do |name|
            path = File.join(project_root, name)
            return {path: path, source: :native, exists: true} if File.exist?(path)
          end

          nil
        end
        private_class_method :find_native_config

        # Find gem default config
        # @param tool [Symbol] Validator name
        # @return [Hash, nil] Config info or nil if not found
        def self.find_gem_default_config(tool)
          config_file = GEM_DEFAULT_CONFIGS[tool]
          return nil unless config_file

          # Try Gem.loaded_specs first (installed gem)
          gem_root = ::Gem.loaded_specs["ace-lint"]&.gem_dir

          # Fallback for development environments (e.g., mono-repo)
          gem_root ||= File.expand_path("../../..", __dir__) if __dir__

          return nil unless gem_root

          path = File.join(gem_root, ".ace-defaults", "lint", config_file)
          return {path: path, source: :gem_defaults, exists: true} if File.exist?(path)

          nil
        end
        private_class_method :find_gem_default_config

        # Get native config file names for a tool
        # @param tool [Symbol] Validator name
        # @return [Array<String>] List of possible config file names
        def self.native_config_names(tool)
          NATIVE_CONFIGS[tool] || []
        end
        private_class_method :native_config_names

        # Reset config cache (for testing)
        # @return [void]
        def self.reset_cache!
          @cache_mutex.synchronize do
            @config_cache = {}
          end
        end
      end
    end
  end
end
