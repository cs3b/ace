# frozen_string_literal: true

require 'ace/core'

module Ace
  module Context
    module Molecules
      # Manages context presets from configuration
      class PresetManager
        def initialize(config = nil)
          @config = config || load_config
        end

        def list_presets
          presets = @config.dig('context', 'presets') || {}
          presets.map do |name, settings|
            {
              name: name,
              description: settings['description'] || "#{name} preset",
              include: settings['include'] || [],
              exclude: settings['exclude'] || [],
              output: settings['output']
            }
          end
        end

        def get_preset(name)
          presets = @config.dig('context', 'presets') || {}
          preset = presets[name]
          return nil unless preset

          {
            name: name,
            include: Array(preset['include']),
            exclude: Array(preset['exclude']),
            output: preset['output'],
            format: preset['format'] || 'markdown',
            cache: preset['cache'] != false,
            metadata: preset['metadata'] || {}
          }
        end

        def preset_exists?(name)
          presets = @config.dig('context', 'presets') || {}
          presets.key?(name)
        end

        private

        def load_config
          # Use ace-core's config resolver for the context namespace
          # First try to get config from cascade
          resolver = Ace::Core::Organisms::ConfigResolver.new(
            search_paths: ['.ace/context', '~/.ace/context'],
            file_patterns: ['config.yml', 'config.yaml', 'config/context.yml', 'config/context.yaml']
          )
          config = resolver.resolve

          # If no config found or empty, use gem defaults
          if config.to_h.empty? || config.to_h.dig('context', 'presets').nil?
            # Load gem's default config
            gem_config_path = File.expand_path('../../../../config/context.yml', __FILE__)
            if File.exist?(gem_config_path)
              require 'yaml'
              gem_config = YAML.load_file(gem_config_path)
              # Merge with any partial config
              config = deep_merge(gem_config, config.to_h)
            else
              config = default_config
            end
          else
            config = config.to_h
          end

          config
        rescue
          # Return default config if loading fails
          default_config
        end

        def deep_merge(hash1, hash2)
          hash1.merge(hash2) do |_key, old_val, new_val|
            if old_val.is_a?(Hash) && new_val.is_a?(Hash)
              deep_merge(old_val, new_val)
            else
              new_val
            end
          end
        end

        def default_config
          {
            'context' => {
              'presets' => {
                'default' => {
                  'include' => ['README.md', 'docs/**/*.md'],
                  'exclude' => ['**/node_modules/**', '**/vendor/**'],
                  'format' => 'markdown'
                }
              }
            }
          }
        end
      end
    end
  end
end