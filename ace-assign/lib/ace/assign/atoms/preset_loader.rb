# frozen_string_literal: true

require "yaml"

module Ace
  module Assign
    module Atoms
      # Loads assign presets from project overrides first, then gem defaults.
      module PresetLoader
        def self.load(preset_name)
          name = preset_name.to_s.strip
          raise Ace::Support::Cli::Error, "Preset name cannot be empty" if name.empty?

          path = resolve_path(name)
          raise Ace::Support::Cli::Error, "Preset '#{name}' not found" unless path

          data = YAML.safe_load_file(path, aliases: true)
          unless data.is_a?(Hash)
            raise Ace::Support::Cli::Error, "Preset '#{name}' is invalid"
          end

          data
        rescue Psych::SyntaxError => e
          raise Ace::Support::Cli::Error, "Invalid YAML in preset '#{name}': #{e.message}"
        end

        def self.resolve_path(name)
          project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          gem_root = Gem.loaded_specs["ace-assign"]&.gem_dir || File.expand_path("../../../..", __dir__)

          project_path = File.join(project_root, ".ace", "assign", "presets", "#{name}.yml")
          default_path = File.join(gem_root, ".ace-defaults", "assign", "presets", "#{name}.yml")

          return project_path if File.exist?(project_path)
          return default_path if File.exist?(default_path)

          nil
        end
        private_class_method :resolve_path
      end
    end
  end
end
