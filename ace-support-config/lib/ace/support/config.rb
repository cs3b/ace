# frozen_string_literal: true

require_relative "config/version"
require_relative "config/errors"

# Use ace-support-fs for path/project utilities
require "ace/support/fs"

# Load atoms first (no dependencies)
require_relative "config/atoms/deep_merger"
require_relative "config/atoms/path_validator"
require_relative "config/atoms/path_rule_matcher"
require_relative "config/atoms/yaml_parser"

# Load models (depend on atoms)
require_relative "config/models/cascade_path"
require_relative "config/models/config"
require_relative "config/models/config_group"

# Load molecules (depend on atoms, models)
require_relative "config/molecules/yaml_loader"
require_relative "config/molecules/config_finder"
require_relative "config/molecules/file_config_resolver"
require_relative "config/molecules/project_config_scanner"

# Load organisms (depend on molecules)
require_relative "config/organisms/config_resolver"
require_relative "config/organisms/virtual_config_resolver"
require_relative "config/organisms/config_initializer"
require_relative "config/organisms/config_diff"
require_relative "config/models/config_templates"

module Ace
  # Generic configuration cascade management
  #
  # Provides a reusable configuration cascade system with customizable
  # folder names, supporting project-level, user-level, and gem-level
  # configuration with deep merging and priority-based resolution.
  #
  # @example Basic usage with defaults
  #   config = Ace::Support::Config.create
  #   config.get("key", "nested")
  #
  # @example Custom folder names
  #   config = Ace::Support::Config.create(
  #     config_dir: ".my-app",
  #     defaults_dir: ".my-app-defaults"
  #   )
  #
  # @example With gem defaults
  #   config = Ace::Support::Config.create(
  #     gem_path: __dir__,
  #     defaults_dir: ".ace-defaults"
  #   )
  #
  # @example Test mode (skip filesystem searches)
  #   Ace::Support::Config.test_mode = true
  #   config = Ace::Support::Config.create  # Returns empty config immediately
  #
  #   # Or with mock data
  #   Ace::Support::Config.default_mock = { "key" => "value" }
  #   config = Ace::Support::Config.create  # Returns mock config
  #
  module Support
    module Config
      # Default folder name for user configuration
      DEFAULT_CONFIG_DIR = ".ace"

      # Default folder name for gem defaults
      DEFAULT_DEFAULTS_DIR = ".ace-defaults"

      # Default project root markers
      DEFAULT_PROJECT_MARKERS = %w[
        .git
        Gemfile
        package.json
        Cargo.toml
        pyproject.toml
        go.mod
        .hg
        .svn
        Rakefile
        Makefile
      ].freeze

      class << self
        # Thread-local test mode state
        # Uses Thread.current for true thread isolation in parallel test environments
        # @return [Boolean, nil] Whether test mode is enabled
        def test_mode
          Thread.current[:ace_config_test_mode]
        end

        # Set thread-local test mode state
        # @param value [Boolean, nil] Whether test mode is enabled
        def test_mode=(value)
          Thread.current[:ace_config_test_mode] = value
        end

        # Thread-local mock configuration data to return in test mode
        # @return [Hash, nil] Mock configuration data
        def default_mock
          Thread.current[:ace_config_default_mock]
        end

        # Set thread-local mock configuration data
        # @param value [Hash, nil] Mock configuration data
        def default_mock=(value)
          Thread.current[:ace_config_default_mock] = value
        end

        # Check if test mode is active
        #
        # Test mode is active when:
        # 1. Ace::Support::Config.test_mode is explicitly set to true
        # 2. ACE_CONFIG_TEST_MODE environment variable is set to "1" or "true" (case-insensitive)
        #
        # Note: We intentionally do NOT auto-detect based on Minitest being loaded,
        # as that would break tests that need to test real filesystem access
        # (like ace-config's own tests). Use explicit opt-in instead.
        #
        # Note: ENV lookup is intentionally NOT memoized to allow dynamic control
        # of test_mode via environment variable changes at runtime.
        #
        # @return [Boolean] True if test mode is active
        def test_mode?
          # Note: test_mode (without ?) is the thread-local getter defined above,
          # not a recursive call - it reads from Thread.current[:ace_config_test_mode]
          return true if test_mode == true

          env_value = ENV["ACE_CONFIG_TEST_MODE"]
          return false if env_value.nil?
          return true if env_value == "1"
          return true if env_value.casecmp("true").zero?

          false
        end

        # Create a new configuration resolver with customizable options
        #
        # @param config_dir [String] User config folder name (default: ".ace")
        # @param defaults_dir [String] Gem defaults folder name (default: ".ace-defaults")
        # @param gem_path [String, nil] Optional gem root for defaults
        # @param merge_strategy [Symbol] Array merge strategy (:replace, :concat, :union)
        # @param cache_namespaces [Boolean] Whether to cache resolve_namespace results (default: false)
        # @param test_mode [Boolean, nil] Force test mode on/off (default: nil = auto-detect)
        # @param mock_config [Hash, nil] Mock config data for test mode (default: nil = use default_mock)
        # @return [Organisms::ConfigResolver] Configuration resolver instance
        #
        # @example Create with defaults
        #   config = Ace::Support::Config.create
        #   value = config.get("some", "key")
        #
        # @example Create with custom folders
        #   config = Ace::Support::Config.create(
        #     config_dir: ".my-app",
        #     defaults_dir: ".my-app-defaults",
        #     gem_path: File.expand_path("..", __dir__)
        #   )
        #
        # @example Create with namespace caching for performance
        #   config = Ace::Support::Config.create(cache_namespaces: true)
        #   config.resolve_namespace("my_gem")  # reads from disk
        #   config.resolve_namespace("my_gem")  # returns cached result
        #
        # @example Test mode with mock config
        #   config = Ace::Support::Config.create(test_mode: true, mock_config: { "key" => "value" })
        #   config.resolve.get("key")  # => "value"
        #
        def create(
          config_dir: DEFAULT_CONFIG_DIR,
          defaults_dir: DEFAULT_DEFAULTS_DIR,
          gem_path: nil,
          merge_strategy: :replace,
          cache_namespaces: false,
          test_mode: nil,
          mock_config: nil
        )
          # Determine effective test mode
          effective_test_mode = test_mode.nil? ? test_mode? : test_mode

          Organisms::ConfigResolver.new(
            config_dir: config_dir,
            defaults_dir: defaults_dir,
            gem_path: gem_path,
            merge_strategy: merge_strategy,
            cache_namespaces: cache_namespaces,
            test_mode: effective_test_mode,
            mock_config: mock_config || default_mock
          )
        end

        # Create a configuration finder for lower-level access
        #
        # @param config_dir [String] Config folder name
        # @param defaults_dir [String] Defaults folder name
        # @param gem_path [String, nil] Gem root path
        # @return [Molecules::ConfigFinder] Configuration finder instance
        def finder(config_dir: DEFAULT_CONFIG_DIR, defaults_dir: DEFAULT_DEFAULTS_DIR, gem_path: nil)
          Molecules::ConfigFinder.new(
            config_dir: config_dir,
            defaults_dir: defaults_dir,
            gem_path: gem_path
          )
        end

        # Create a path expander with explicit context
        #
        # @param source_dir [String] Source document directory
        # @param project_root [String] Project root directory
        # @return [Ace::Support::Fs::Atoms::PathExpander] Path expander instance
        def path_expander(source_dir:, project_root:)
          Ace::Support::Fs::Atoms::PathExpander.new(source_dir: source_dir, project_root: project_root)
        end

        # Find project root from a starting path
        #
        # @param start_path [String, nil] Path to start searching from
        # @param markers [Array<String>] Project root markers
        # @return [String, nil] Project root path or nil
        def find_project_root(start_path: nil, markers: DEFAULT_PROJECT_MARKERS)
          Ace::Support::Fs::Molecules::ProjectRootFinder.find(start_path: start_path, markers: markers)
        end

        # Create a virtual config resolver for path-based lookups
        #
        # VirtualConfigResolver provides a "virtual filesystem" view where nearest
        # config file wins. Useful for finding presets and resources across the
        # configuration cascade without loading/merging YAML content.
        #
        # @param config_dir [String] Config folder name (default: ".ace")
        # @param defaults_dir [String] Defaults folder name (default: ".ace-defaults")
        # @param start_path [String, nil] Starting path for traversal (default: Dir.pwd)
        # @param gem_path [String, nil] Gem root path for defaults (lowest priority)
        # @return [Organisms::VirtualConfigResolver] Virtual resolver instance
        #
        # @example Find preset files across cascade
        #   resolver = Ace::Support::Config.virtual_resolver
        #   resolver.glob("presets/*.yml").each do |relative, absolute|
        #     puts "Found: #{relative} at #{absolute}"
        #   end
        #
        # @example Check if resource exists with gem defaults
        #   resolver = Ace::Support::Config.virtual_resolver(
        #     config_dir: ".my-app",
        #     gem_path: File.expand_path("..", __dir__)
        #   )
        #   if resolver.exists?("templates/default.md")
        #     path = resolver.resolve_path("templates/default.md")
        #   end
        #
        def virtual_resolver(
          config_dir: DEFAULT_CONFIG_DIR,
          defaults_dir: DEFAULT_DEFAULTS_DIR,
          start_path: nil,
          gem_path: nil
        )
          Organisms::VirtualConfigResolver.new(
            config_dir: config_dir,
            defaults_dir: defaults_dir,
            start_path: start_path,
            gem_path: gem_path
          )
        end

        # Reset all cached configuration state
        #
        # Per ADR-022, this method allows test isolation by clearing all cached
        # state in the configuration system.
        #
        # @return [void]
        def reset_config!
          Ace::Support::Fs::Molecules::ProjectRootFinder.clear_cache!
          Thread.current[:ace_config_test_mode] = nil
          Thread.current[:ace_config_default_mock] = nil
        end
      end
    end
  end
end
