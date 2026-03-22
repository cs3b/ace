# frozen_string_literal: true

require "yaml"
require "ace/support/fs"

module Ace
  module Idea
    module Molecules
      # Loads and merges configuration for ace-idea from the cascade:
      # .ace-defaults/idea/config.yml (gem) -> ~/.ace/idea/config.yml (user) -> .ace/idea/config.yml (project)
      class IdeaConfigLoader
        DEFAULT_ROOT_DIR = ".ace-ideas"

        # Load configuration with cascade merge
        # @param gem_root [String] Path to the ace-idea gem root
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
          config = deep_merge(config, load_project_config)
          config
        end

        # Get the root directory for ideas
        # @param config [Hash] Configuration hash
        # @return [String] Absolute path to ideas root directory
        def self.root_dir(config = nil)
          config ||= load
          dir = config.dig("idea", "root_dir") || DEFAULT_ROOT_DIR

          # Make absolute if relative
          if dir.start_with?("/")
            dir
          else
            File.join(Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current, dir)
          end
        end

        private

        def load_defaults
          path = File.join(@gem_root, ".ace-defaults", "idea", "config.yml")
          load_yaml(path) || {}
        end

        def load_user_config
          path = File.join(Dir.home, ".ace", "idea", "config.yml")
          load_yaml(path) || {}
        end

        def load_project_config
          path = File.join(Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current, ".ace", "idea", "config.yml")
          load_yaml(path) || {}
        end

        def load_yaml(path)
          return nil unless File.exist?(path)

          YAML.safe_load_file(path, permitted_classes: [Date, Time, Symbol])
        rescue Errno::ENOENT
          nil
        rescue Psych::SyntaxError => e
          warn "Warning: ace-idea config parse error in #{path}: #{e.message}"
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
