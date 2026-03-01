# frozen_string_literal: true

require "yaml"

module Ace
  module Retro
    module Molecules
      # Loads and merges configuration for ace-retro from the cascade:
      # .ace-defaults/retro/config.yml (gem) -> ~/.ace/retro/config.yml (user) -> .ace/retro/config.yml (project)
      class RetroConfigLoader
        DEFAULT_ROOT_DIR = ".ace-retros"

        # Load configuration with cascade merge
        # @param gem_root [String] Path to the ace-retro gem root
        # @return [Hash] Merged configuration
        def self.load(gem_root: nil)
          gem_root ||= File.expand_path("../../../..", __dir__)
          # lib/ace/retro/molecules/ → 4 levels up to gem root
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
          config = deep_merge(config, load_project_config)
          config
        end

        # Get the root directory for retros
        # @param config [Hash] Configuration hash
        # @return [String] Absolute path to retros root directory
        def self.root_dir(config = nil)
          config ||= load
          dir = config.dig("retro", "root_dir") || DEFAULT_ROOT_DIR

          if dir.start_with?("/")
            dir
          else
            File.join(Dir.pwd, dir)
          end
        end

        private

        def load_defaults
          path = File.join(@gem_root, ".ace-defaults", "retro", "config.yml")
          load_yaml(path) || {}
        end

        def load_user_config
          path = File.join(Dir.home, ".ace", "retro", "config.yml")
          load_yaml(path) || {}
        end

        def load_project_config
          path = File.join(Dir.pwd, ".ace", "retro", "config.yml")
          load_yaml(path) || {}
        end

        def load_yaml(path)
          return nil unless File.exist?(path)

          YAML.safe_load_file(path, permitted_classes: [Date, Time, Symbol])
        rescue Errno::ENOENT
          nil
        rescue Psych::SyntaxError => e
          warn "Warning: ace-retro config parse error in #{path}: #{e.message}"
          nil
        end

        def deep_merge(base, override)
          return base unless override.is_a?(Hash)

          result = base.dup
          override.each do |key, value|
            if result[key].is_a?(Hash) && value.is_a?(Hash)
              result[key] = deep_merge(result[key], value)
            else
              result[key] = value
            end
          end
          result
        end
      end
    end
  end
end
