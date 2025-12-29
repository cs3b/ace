# frozen_string_literal: true

require_relative "config/version"
require_relative "config/errors"

# Use ace-support-fs for path/project utilities
require "ace/support/fs"

# Load atoms first (no dependencies)
require_relative "config/atoms/deep_merger"
require_relative "config/atoms/yaml_parser"

# Load models (depend on atoms)
require_relative "config/models/cascade_path"
require_relative "config/models/config"

# Load molecules (depend on atoms, models)
require_relative "config/molecules/yaml_loader"
require_relative "config/molecules/config_finder"

# Load organisms (depend on molecules)
require_relative "config/organisms/config_resolver"
require_relative "config/organisms/virtual_config_resolver"

module Ace
  # Generic configuration cascade management
  #
  # Provides a reusable configuration cascade system with customizable
  # folder names, supporting project-level, user-level, and gem-level
  # configuration with deep merging and priority-based resolution.
  #
  # @example Basic usage with defaults
  #   config = Ace::Config.create
  #   config.get("key", "nested")
  #
  # @example Custom folder names
  #   config = Ace::Config.create(
  #     config_dir: ".my-app",
  #     defaults_dir: ".my-app-defaults"
  #   )
  #
  # @example With gem defaults
  #   config = Ace::Config.create(
  #     gem_path: __dir__,
  #     defaults_dir: ".ace-defaults"
  #   )
  #
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
      # Create a new configuration resolver with customizable options
      #
      # @param config_dir [String] User config folder name (default: ".ace")
      # @param defaults_dir [String] Gem defaults folder name (default: ".ace-defaults")
      # @param gem_path [String, nil] Optional gem root for defaults
      # @param merge_strategy [Symbol] Array merge strategy (:replace, :concat, :union)
      # @return [Organisms::ConfigResolver] Configuration resolver instance
      #
      # @example Create with defaults
      #   config = Ace::Config.create
      #   value = config.get("some", "key")
      #
      # @example Create with custom folders
      #   config = Ace::Config.create(
      #     config_dir: ".my-app",
      #     defaults_dir: ".my-app-defaults",
      #     gem_path: File.expand_path("..", __dir__)
      #   )
      #
      def create(
        config_dir: DEFAULT_CONFIG_DIR,
        defaults_dir: DEFAULT_DEFAULTS_DIR,
        gem_path: nil,
        merge_strategy: :replace
      )
        Organisms::ConfigResolver.new(
          config_dir: config_dir,
          defaults_dir: defaults_dir,
          gem_path: gem_path,
          merge_strategy: merge_strategy
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
      #   resolver = Ace::Config.virtual_resolver
      #   resolver.glob("presets/*.yml").each do |relative, absolute|
      #     puts "Found: #{relative} at #{absolute}"
      #   end
      #
      # @example Check if resource exists with gem defaults
      #   resolver = Ace::Config.virtual_resolver(
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
      end
    end
  end
end
