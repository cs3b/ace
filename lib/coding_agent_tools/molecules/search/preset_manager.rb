# frozen_string_literal: true

require "yaml"
require "json"

module CodingAgentTools
  module Molecules
    module Search
      # Manages search presets from configuration files
      class PresetManager
        DEFAULT_CONFIG_PATHS = [
          ".search-presets.yml",
          ".search-presets.yaml",
          ".search-presets.json",
          "~/.config/coding-agent-tools/search-presets.yml",
          "~/.coding-agent-tools/search-presets.yml"
        ].freeze

        # Initialize preset manager
        # @param config_paths [Array<String>] Paths to search for preset configs
        def initialize(config_paths: DEFAULT_CONFIG_PATHS)
          @config_paths = config_paths.map { |p| File.expand_path(p) }
          @presets = {}
          load_presets
        end

        # Get a preset by name
        # @param name [String, Symbol] Preset name
        # @return [Hash, nil] Preset configuration or nil if not found
        def get(name)
          @presets[name.to_s]
        end

        # List all available presets
        # @return [Array<String>] Preset names
        def list
          @presets.keys.sort
        end

        # Check if preset exists
        # @param name [String, Symbol] Preset name
        # @return [Boolean] True if preset exists
        def exists?(name)
          @presets.key?(name.to_s)
        end

        # Merge preset with options
        # @param preset_name [String, Symbol] Name of preset to use
        # @param options [Hash] Options to merge with preset
        # @return [Hash] Merged configuration
        def merge_with_options(preset_name, options = {})
          preset = get(preset_name)
          return options unless preset
          
          # Deep merge preset with options, with options taking precedence
          deep_merge(preset, options)
        end

        # Apply variable substitution to preset
        # @param preset [Hash] Preset configuration
        # @param variables [Hash] Variables to substitute
        # @return [Hash] Preset with variables substituted
        def apply_variables(preset, variables = {})
          return preset unless variables.any?
          
          preset_json = JSON.generate(preset)
          
          # Replace ${VAR} patterns with variable values
          variables.each do |key, value|
            preset_json.gsub!("${#{key}}", value.to_s)
          end
          
          # Replace ${ENV:VAR} patterns with environment variables
          preset_json.gsub!(/\$\{ENV:([^}]+)\}/) do |_match|
            ENV[$1] || ""
          end
          
          JSON.parse(preset_json)
        end

        # Save preset to user config
        # @param name [String] Preset name
        # @param config [Hash] Preset configuration
        # @param path [String, nil] Path to save to (defaults to user config)
        # @return [Boolean] Success status
        def save(name, config, path: nil)
          path ||= File.expand_path("~/.config/coding-agent-tools/search-presets.yml")
          
          # Ensure directory exists
          FileUtils.mkdir_p(File.dirname(path))
          
          # Load existing presets from file
          existing = if File.exist?(path)
                      YAML.load_file(path) || {}
                    else
                      {}
                    end
          
          # Add/update preset
          existing[name.to_s] = config
          
          # Write back to file
          File.write(path, YAML.dump(existing))
          
          # Reload presets
          load_presets
          true
        rescue => e
          false
        end

        # Delete preset from user config
        # @param name [String] Preset name
        # @param path [String, nil] Path to delete from
        # @return [Boolean] Success status
        def delete(name, path: nil)
          path ||= File.expand_path("~/.config/coding-agent-tools/search-presets.yml")
          
          return false unless File.exist?(path)
          
          # Load existing presets
          existing = YAML.load_file(path) || {}
          
          # Remove preset
          return false unless existing.delete(name.to_s)
          
          # Write back to file
          File.write(path, YAML.dump(existing))
          
          # Reload presets
          load_presets
          true
        rescue => e
          false
        end

        private

        # Load presets from all config paths
        def load_presets
          @presets = {}
          
          # Load from each config path
          @config_paths.each do |path|
            next unless File.exist?(path)
            
            begin
              content = load_config_file(path)
              @presets.merge!(content) if content.is_a?(Hash)
            rescue => e
              # Silently skip invalid configs
            end
          end
          
          # Add built-in presets
          add_builtin_presets
        end

        # Load config file based on extension
        def load_config_file(path)
          case File.extname(path)
          when ".json"
            JSON.parse(File.read(path))
          when ".yml", ".yaml"
            YAML.load_file(path)
          else
            {}
          end
        end

        # Add built-in presets
        def add_builtin_presets
          @presets["todo"] ||= {
            "pattern" => "TODO|FIXME|HACK|XXX|NOTE",
            "type" => "content",
            "case_insensitive" => false
          }
          
          @presets["ruby"] ||= {
            "glob" => "*.rb",
            "type" => "file"
          }
          
          @presets["tests"] ||= {
            "glob" => "*_spec.rb",
            "type" => "file"
          }
          
          @presets["recent"] ||= {
            "since" => "1 week ago",
            "type" => "file"
          }
          
          @presets["git-changes"] ||= {
            "scope" => "changed",
            "type" => "file"
          }
        end

        # Deep merge two hashes
        def deep_merge(hash1, hash2)
          hash1.merge(hash2) do |key, old_val, new_val|
            if old_val.is_a?(Hash) && new_val.is_a?(Hash)
              deep_merge(old_val, new_val)
            else
              new_val
            end
          end
        end
      end
    end
  end
end