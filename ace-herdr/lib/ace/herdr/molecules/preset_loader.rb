# frozen_string_literal: true

require "yaml"
require "ace/support/config"

module Ace
  module Herdr
    module Molecules
      # Finds and loads herdr workspace/tab YAML presets across the ADR-022
      # config cascade:
      #   1. project .ace/herdr/ (highest priority)
      #   2. user ~/.ace/herdr/
      #   3. gem .ace-defaults/herdr/ (lowest priority)
      class PresetLoader
        PRESET_TYPES = %w[workspaces tabs].freeze

        # @param gem_root [String] Gem root directory for defaults
        # @param start_path [String, nil] Starting path for cascade traversal
        def initialize(gem_root: Ace::Herdr.gem_root, start_path: nil)
          @resolver = Ace::Support::Config.virtual_resolver(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            start_path: start_path,
            gem_path: gem_root
          )
        end

        # Load a preset by type and name
        #
        # @param type [String] Preset type: "workspaces" or "tabs"
        # @param name [String] Preset name (without .yml extension)
        # @return [Hash, nil] Parsed YAML hash, or nil when unknown
        def load(type, name)
          absolute_path = @resolver.resolve_path("herdr/#{type}/#{name}.yml")
          return nil unless absolute_path && File.exist?(absolute_path)

          YAML.safe_load_file(absolute_path, permitted_classes: [Date], aliases: true) || {}
        end

        # List available preset names for a type, merged across the cascade
        #
        # @param type [String] Preset type: "workspaces" or "tabs"
        # @return [Array<String>] Preset names (without .yml extension)
        def list(type)
          @resolver.glob("herdr/#{type}/*.yml").keys
            .map { |relative_path| File.basename(relative_path, ".yml") }
            .sort.uniq
        end

        # List all preset types and their presets
        #
        # @return [Hash<String, Array<String>>] Map of type => preset names
        def list_all
          PRESET_TYPES.each_with_object({}) do |type, result|
            presets = list(type)
            result[type] = presets unless presets.empty?
          end
        end

        # Create a lookup proc for PresetResolver
        #
        # @param type [String] Preset type to look up
        # @return [Proc] Proc that takes a name and returns a preset hash
        def to_lookup(type)
          ->(name) { load(type, name) }
        end
      end
    end
  end
end
