# frozen_string_literal: true

require 'ace/core'
require 'yaml'

module Ace
  module Context
    module Molecules
      # Manages context presets from configuration
      class PresetManager
        def initialize(config: nil, config_path: nil)
          @config = config || load_config(config_path)
        end

        def list_presets
          # Support both new (.ace) and old (.coding-agent) formats
          if @config.dig('context', 'presets')
            # New format
            presets = @config.dig('context', 'presets') || {}
            presets.map do |name, settings|
              {
                name: name,
                description: settings['description'] || "#{name} preset",
                include: settings['include'] || [],
                exclude: settings['exclude'] || [],
                output: settings['output'],
                template: settings['template'],
                chunk_limit: settings['chunk_limit'],
                format: settings['format'] || 'markdown'
              }
            end
          elsif @config['presets']
            # Old format (.coding-agent/context.yml)
            presets = @config['presets'] || {}
            presets.map do |name, settings|
              {
                name: name.to_s,
                description: settings['description'],
                template: settings['template'],
                output: settings['output'],
                chunk_limit: settings['chunk_limit'],
                format: 'markdown-xml'
              }
            end
          else
            []
          end
        end

        def get_preset(name)
          # Support both new and old formats
          if @config.dig('context', 'presets')
            # New format
            presets = @config.dig('context', 'presets') || {}
            preset = presets[name] || presets[name.to_s] || presets[name.to_sym]
            return nil unless preset

            {
              name: name,
              include: Array(preset['include']),
              exclude: Array(preset['exclude']),
              output: preset['output'],
              template: preset['template'],
              format: preset['format'] || 'markdown',
              chunk_limit: preset['chunk_limit'],
              cache: preset['cache'] != false,
              metadata: preset['metadata'] || {}
            }
          elsif @config['presets']
            # Old format
            presets = @config['presets'] || {}
            preset = presets[name] || presets[name.to_s] || presets[name.to_sym]
            return nil unless preset

            {
              name: name,
              template: preset['template'],
              output: preset['output'],
              chunk_limit: preset['chunk_limit'],
              description: preset['description'],
              format: 'markdown-xml'
            }
          else
            nil
          end
        end

        def preset_exists?(name)
          if @config.dig('context', 'presets')
            presets = @config.dig('context', 'presets') || {}
            presets.key?(name) || presets.key?(name.to_s) || presets.key?(name.to_sym)
          elsif @config['presets']
            presets = @config['presets'] || {}
            presets.key?(name) || presets.key?(name.to_s) || presets.key?(name.to_sym)
          else
            false
          end
        end

        # Get configuration settings (for old format compatibility)
        def get_settings
          @config['settings'] || {}
        end

        # Get security configuration (for old format compatibility)
        def get_security_config
          @config['security'] || {}
        end

        private

        def load_config(config_path = nil)
          if config_path
            # Load specific config file for backward compatibility
            return YAML.load_file(config_path) if File.exist?(config_path)
            return default_config
          end

          # Try new locations first
          resolver = Ace::Core::Organisms::ConfigResolver.new(
            search_paths: ['.ace', '.ace/context', '~/.ace/context'],
            file_patterns: ['context.yml', 'context.yaml']
          )
          config = resolver.resolve

          # If no config found, try old locations for backward compatibility
          if config.to_h.empty? || (!config.to_h.dig('context', 'presets') && !config.to_h['presets'])
            old_paths = [
              '.coding-agent/context.yml',
              '.coding-agent/context.yaml'
            ]

            old_paths.each do |path|
              if File.exist?(path)
                return YAML.load_file(path)
              end
            end

            # No config found anywhere, use defaults
            config = default_config
          else
            config = config.to_h
          end

          config
        rescue => e
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