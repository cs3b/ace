# frozen_string_literal: true

require 'ace/core'
require 'yaml'
require_relative 'template_discoverer'

module Ace
  module Context
    module Molecules
      # Manages context presets from configuration
      class PresetManager
        def initialize(config: nil, config_path: nil, enable_discovery: true)
          @config = config || load_config(config_path)
          @enable_discovery = enable_discovery
          @discovered_presets = discover_presets if @enable_discovery
          @all_presets = merge_presets
        end

        def list_presets
          # Return merged presets (configured + discovered)
          @all_presets.values.map do |preset|
            preset.dup  # Return a copy to prevent external modification
          end
        end

        def get_preset(name)
          # Get from merged presets
          preset = @all_presets[name.to_s] || @all_presets[name.to_sym]
          preset&.dup  # Return a copy to prevent external modification
        end

        def preset_exists?(name)
          @all_presets.key?(name.to_s) || @all_presets.key?(name.to_sym)
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

        # Discover presets from template files
        def discover_presets
          return {} unless @enable_discovery

          settings = get_settings
          discoverer = TemplateDiscoverer.new(settings: settings)
          discovered = discoverer.discover_templates

          # Convert array to hash keyed by name
          discovered.each_with_object({}) do |preset, hash|
            hash[preset[:name]] = preset
          end
        end

        # Merge configured and discovered presets
        def merge_presets
          merged = {}

          # First, add discovered presets
          if @discovered_presets
            @discovered_presets.each do |name, preset|
              merged[name.to_s] = preset
            end
          end

          # Then, add/override with configured presets (they have priority)
          configured = load_configured_presets
          configured.each do |preset|
            name = preset[:name].to_s
            # Remove discovered flag if overriding
            preset.delete(:discovered) if merged[name]
            merged[name] = preset
          end

          merged
        end

        # Load configured presets from config
        def load_configured_presets
          # Support both new (.ace) and old (.coding-agent) formats
          if @config.dig('context', 'presets')
            # New format
            presets = @config.dig('context', 'presets') || {}
            presets.map do |name, settings|
              {
                name: name.to_s,
                description: settings['description'] || "#{name} preset",
                include: settings['include'] || [],
                exclude: settings['exclude'] || [],
                output: settings['output'],
                template: settings['template'],
                chunk_limit: settings['chunk_limit'],
                format: settings['format'] || 'markdown',
                cache: settings['cache'] != false,
                metadata: settings['metadata'] || {}
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

        def load_config(config_path = nil)
          if config_path
            # Load specific config file for backward compatibility
            return YAML.load_file(config_path) if File.exist?(config_path)
            return default_config
          end

          # Try new locations first
          resolver = Ace::Core::Organisms::ConfigResolver.new(
            search_paths: ['.ace', '.ace/context', '~/.ace/context'],
            file_patterns: ['context.yml', 'context.yaml', 'config.yml', 'config.yaml']
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