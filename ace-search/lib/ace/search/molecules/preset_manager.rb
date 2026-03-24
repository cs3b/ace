# frozen_string_literal: true

require "ace/support/config"

module Ace
  module Search
    module Molecules
      # Manages search presets from .ace/search/presets/*.yml files
      # This is a molecule - composed operation using ace-config for config loading
      class PresetManager
        def initialize
          @project_root = Ace::Support::Config.find_project_root || Dir.pwd
          @presets = {}
          load_presets
        end

        # Get a preset by name
        def get(name)
          @presets[name.to_s]
        end

        # List all available presets
        def list
          @presets.keys.sort
        end

        # Check if preset exists
        def exists?(name)
          @presets.key?(name.to_s)
        end

        # Merge preset with options
        # Uses Config.merge() for consistent merge strategy support
        def merge_with_options(preset_name, options = {})
          preset = get(preset_name)
          return options unless preset

          # Wrap preset in Config object to use Config.merge() consistently
          # This enables future per-key merge strategies via _merge directive
          Ace::Support::Config::Models::Config.new(preset, source: "preset:#{preset_name}")
            .merge(options)
            .to_h
        end

        private

        # Load presets from .ace/search/presets/*.yml
        def load_presets
          preset_dirs = find_preset_directories

          preset_dirs.each do |dir|
            load_presets_from_directory(dir)
          end
        end

        # Find preset directories in configuration cascade
        def find_preset_directories
          dirs = []

          # Check project .ace/search/presets/
          project_preset_dir = File.join(@project_root, ".ace/search/presets")
          dirs << project_preset_dir if Dir.exist?(project_preset_dir)

          # Check home ~/.ace/search/presets/
          home_preset_dir = File.expand_path("~/.ace/search/presets")
          dirs << home_preset_dir if Dir.exist?(home_preset_dir)

          # Check gem example presets
          gem_root = File.expand_path("../../../../..", __FILE__)
          gem_preset_dir = File.join(gem_root, ".ace-defaults/search/presets")
          dirs << gem_preset_dir if Dir.exist?(gem_preset_dir)

          dirs
        end

        # Load all preset files from a directory
        def load_presets_from_directory(dir)
          Dir.glob(File.join(dir, "*.{yml,yaml}")).each do |file|
            load_preset_file(file)
          end
        end

        # Load a single preset file
        def load_preset_file(file)
          data = Ace::Support::Config::Atoms::YamlParser.parse(File.read(file))
          preset_name = data["name"] || data[:name] || File.basename(file, ".*")

          # Remove metadata keys, rest are options
          preset_options = data.reject { |k, _v| ["name", "description", :name, :description].include?(k) }

          @presets[preset_name] = preset_options
        rescue => e
          warn "Failed to load preset from #{file}: #{e.message}"
        end
      end
    end
  end
end
