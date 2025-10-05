# frozen_string_literal: true

require "yaml"
require "pathname"

module Ace
  module Review
    module Molecules
      # Manages loading and resolving review presets from configuration
      class PresetManager
        DEFAULT_CONFIG_PATHS = [
          ".ace/review/code.yml",
          ".ace/review.yml", # Fallback
          ".coding-agent/code-review.yml" # Legacy support
        ].freeze

        attr_reader :config_path, :config, :project_root

        def initialize(config_path: nil, project_root: nil)
          @project_root = project_root || find_project_root
          @config_path = resolve_config_path(config_path)
          @config = load_configuration
          @preset_cache = {}
        end

        # Load a specific preset by name
        def load_preset(preset_name)
          return nil unless preset_name

          # Check cache first
          return @preset_cache[preset_name] if @preset_cache.key?(preset_name)

          # Try preset files first
          preset = load_preset_from_file(preset_name) || load_preset_from_config(preset_name)
          return nil unless preset

          # Merge with defaults and cache
          @preset_cache[preset_name] = merge_with_defaults(preset)
        end

        # Get list of available preset names
        def available_presets
          presets = []

          # Add presets from main config
          presets.concat(config_presets) if config

          # Add presets from preset directory
          presets.concat(file_presets)

          # Add default presets if no config exists
          presets.concat(Ace::Review.default_presets.keys) if presets.empty?

          presets.uniq.sort
        end

        # Check if a preset exists
        def preset_exists?(preset_name)
          available_presets.include?(preset_name.to_s)
        end

        # Get the default model from configuration
        def default_model
          config&.dig("defaults", "model") ||
            Ace::Review.get("defaults", "model")
        end

        # Get the default context from configuration
        def default_context
          config&.dig("defaults", "context") ||
            Ace::Review.get("defaults", "context")
        end

        # Get the default output format
        def default_output_format
          config&.dig("defaults", "output_format") ||
            Ace::Review.get("defaults", "output_format") ||
            "markdown"
        end

        # Resolve a preset configuration into actionable components
        def resolve_preset(preset_name, overrides = {})
          preset = load_preset(preset_name)
          return nil unless preset

          {
            description: preset["description"],
            prompt_composition: resolve_prompt_composition(preset["prompt_composition"], overrides),
            context: resolve_context_config(preset["context"], overrides[:context]),
            subject: resolve_subject_config(preset["subject"], overrides[:subject]),
            model: overrides[:model] || preset["model"] || default_model,
            output_format: overrides[:output_format] || preset["output_format"] || default_output_format
          }
        end

        # Get storage configuration
        def storage_config
          config&.dig("storage") || Ace::Review.get("storage") || {}
        end

        # Get the base path for storing reviews
        def review_base_path
          path_template = storage_config["base_path"] || ".ace-taskflow/%{release}/reviews"

          # Replace placeholders
          path_template.gsub("%{release}", current_release)
        end

        private

        def find_project_root
          # Try ace-core first
          if defined?(Ace::Core)
            require "ace/core"
            discovery = Ace::Core::ConfigDiscovery.new
            return discovery.project_root if discovery.project_root
          end

          # Fallback to current directory
          Dir.pwd
        end

        def resolve_config_path(custom_path)
          if custom_path
            path = Pathname.new(custom_path)
            return path.absolute? ? custom_path : File.join(project_root, custom_path)
          end

          # Try each default path
          DEFAULT_CONFIG_PATHS.each do |default_path|
            full_path = File.join(project_root, default_path)
            return full_path if File.exist?(full_path)
          end

          nil
        end

        def load_configuration
          return {} unless config_path && File.exist?(config_path)

          content = File.read(config_path)
          YAML.safe_load(content, permitted_classes: [Symbol]) || {}
        rescue StandardError => e
          warn "Failed to load configuration from #{config_path}: #{e.message}" if Ace::Review.debug?
          {}
        end

        def load_preset_from_file(preset_name)
          preset_dir = File.join(project_root, ".ace/review/presets")
          preset_file = File.join(preset_dir, "#{preset_name}.yml")

          return nil unless File.exist?(preset_file)

          content = File.read(preset_file)
          YAML.safe_load(content, permitted_classes: [Symbol])
        rescue StandardError => e
          warn "Failed to load preset from #{preset_file}: #{e.message}" if Ace::Review.debug?
          nil
        end

        def load_preset_from_config(preset_name)
          return nil unless config && config["presets"]
          config["presets"][preset_name.to_s]
        end

        def config_presets
          config["presets"]&.keys || []
        end

        def file_presets
          preset_dir = File.join(project_root, ".ace/review/presets")
          return [] unless Dir.exist?(preset_dir)

          Dir.glob("#{preset_dir}/*.yml").map do |file|
            File.basename(file, ".yml")
          end
        end

        def merge_with_defaults(preset)
          defaults = config&.dig("defaults") || {}
          deep_merge(defaults, preset)
        end

        def deep_merge(base, override)
          return override unless base.is_a?(Hash) && override.is_a?(Hash)

          base.merge(override) do |_key, base_val, override_val|
            deep_merge(base_val, override_val)
          end
        end

        def resolve_prompt_composition(composition, overrides)
          return {} unless composition

          result = composition.dup

          # Apply overrides
          result["base"] = overrides[:prompt_base] if overrides[:prompt_base]
          result["format"] = overrides[:prompt_format] if overrides[:prompt_format]

          if overrides[:prompt_focus]
            result["focus"] = overrides[:prompt_focus].split(",").map(&:strip)
          elsif overrides[:add_focus]
            result["focus"] ||= []
            result["focus"].concat(overrides[:add_focus].split(",").map(&:strip))
            result["focus"].uniq!
          end

          if overrides[:prompt_guidelines]
            result["guidelines"] = overrides[:prompt_guidelines].split(",").map(&:strip)
          end

          result
        end

        def resolve_context_config(preset_context, override_context)
          return override_context if override_context
          preset_context || default_context
        end

        def resolve_subject_config(preset_subject, override_subject)
          return override_subject if override_subject
          preset_subject
        end

        def current_release
          # Try to get current release from ace-taskflow
          if system("which ace-taskflow > /dev/null 2>&1")
            release = `ace-taskflow release --current 2>/dev/null`.strip
            return release unless release.empty?
          end

          # Fallback to v.0.0.0
          "v.0.0.0"
        end
      end
    end
  end
end