# frozen_string_literal: true

require "yaml"
require "ace/support/config"

module Ace
  module Tmux
    module Molecules
      # Finds and loads YAML presets across the ACE config cascade
      #
      # Uses VirtualConfigResolver to discover presets from:
      #   1. Project .ace/tmux/ (highest priority)
      #   2. User ~/.ace/tmux/
      #   3. Gem .ace-defaults/tmux/ (lowest priority)
      class PresetLoader
        PRESET_TYPES = %w[sessions windows panes].freeze

        # @param gem_root [String] Gem root directory for defaults
        # @param start_path [String, nil] Starting path for cascade traversal
        def initialize(gem_root:, start_path: nil)
          @resolver = Ace::Support::Config.virtual_resolver(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            start_path: start_path,
            gem_path: gem_root
          )
        end

        # Load a preset by type and name
        #
        # @param type [String] Preset type: "sessions", "windows", or "panes"
        # @param name [String] Preset name (without .yml extension)
        # @return [Hash, nil] Parsed YAML hash, or nil if not found
        def load(type, name)
          relative_path = "tmux/#{type}/#{name}.yml"
          absolute_path = @resolver.resolve_path(relative_path)
          return nil unless absolute_path && File.exist?(absolute_path)

          YAML.safe_load_file(absolute_path, permitted_classes: [Date], aliases: true) || {}
        end

        # List available presets for a type
        #
        # @param type [String] Preset type: "sessions", "windows", or "panes"
        # @return [Array<String>] Preset names (without .yml extension)
        def list(type)
          pattern = "tmux/#{type}/*.yml"
          @resolver.glob(pattern).keys.map do |relative_path|
            File.basename(relative_path, ".yml")
          end.sort.uniq
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
