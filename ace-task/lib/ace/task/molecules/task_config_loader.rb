# frozen_string_literal: true

require "yaml"
require "ace/support/fs"

module Ace
  module Task
    module Molecules
      # Loads and merges configuration for ace-task from the cascade:
      # .ace-defaults/task/config.yml (gem) -> ~/.ace/task/config.yml (user) -> .ace/task/config.yml (project)
      class TaskConfigLoader
        DEFAULT_ROOT_DIR = ".ace-tasks"

        # Load configuration with cascade merge
        # @param gem_root [String] Path to the ace-task gem root
        # @return [Hash] Merged configuration
        def self.load(gem_root: nil)
          gem_root ||= File.expand_path("../../../..", __dir__)
          new(gem_root: gem_root).load
        end

        def initialize(gem_root:)
          @gem_root = gem_root
        end

        # Load and merge configuration
        # @return [Hash] Merged configuration
        def load
          config = load_defaults
          config = deep_merge(config, load_user_config)
          deep_merge(config, load_project_config)
        end

        # Get the root directory for tasks
        # @param config [Hash] Configuration hash
        # @return [String] Absolute path to tasks root directory
        def self.root_dir(config = nil)
          config ||= load
          dir = config.dig("task", "root_dir") || DEFAULT_ROOT_DIR

          if dir.start_with?("/")
            dir
          else
            File.join(Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current, dir)
          end
        end

        # Resolve a named task store selected with `--in NAME`.
        # Stores are configured under task.stores; paths are relative to the
        # project root unless absolute. The store root becomes the manager
        # root, so it is resolved before any folder/destination validation.
        # @param config [Hash] Configuration hash
        # @param name [String] Store name from `--in`
        # @param project_root [String, nil] Base for relative paths (default: project root)
        # @return [String, nil] Absolute store root, or nil when the name is not configured
        def self.store_root(config, name, project_root: nil)
          stores = config.dig("task", "stores")
          return nil unless stores.is_a?(Hash)

          path = stores[name.to_s]
          return nil if path.nil? || path.to_s.strip.empty?

          path = path.to_s
          return File.expand_path(path) if path.start_with?("/")

          base = project_root || Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          File.expand_path(path, base)
        end

        # Names of all configured stores, used in CLI error hints.
        # @param config [Hash] Configuration hash
        # @return [Array<String>] Sorted store names
        def self.store_names(config)
          stores = config.dig("task", "stores")
          stores.is_a?(Hash) ? stores.keys.sort : []
        end

        private

        def load_defaults
          path = File.join(@gem_root, ".ace-defaults", "task", "config.yml")
          load_yaml(path) || {}
        end

        def load_user_config
          path = File.join(Dir.home, ".ace", "task", "config.yml")
          load_yaml(path) || {}
        end

        def load_project_config
          path = File.join(Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current, ".ace", "task", "config.yml")
          load_yaml(path) || {}
        end

        def load_yaml(path)
          return nil unless File.exist?(path)

          YAML.safe_load_file(path, permitted_classes: [Date, Time, Symbol])
        rescue Errno::ENOENT
          nil
        rescue Psych::SyntaxError => e
          warn "Warning: ace-task config parse error in #{path}: #{e.message}"
          nil
        end

        def deep_merge(base, override)
          return base unless override.is_a?(Hash)

          result = base.dup
          override.each do |key, value|
            result[key] = if result[key].is_a?(Hash) && value.is_a?(Hash)
              deep_merge(result[key], value)
            else
              value
            end
          end
          result
        end
      end
    end
  end
end
