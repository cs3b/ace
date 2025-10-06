# frozen_string_literal: true

require "yaml"
require "pathname"

module Ace
  module Review
    module Molecules
      # Manages loading and resolving review presets from configuration
      class PresetManager
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
          # Check for configured path first
          configured_path = storage_config["base_path"]
          return expand_path_template(configured_path) if configured_path

          # Try to get from ace-taskflow
          release_path = get_release_path
          return release_path if release_path

          # Fallback
          "./reviews"
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

          # Use ace-core ConfigFinder to locate config in cascade
          if defined?(Ace::Core)
            require "ace/core"
            finder = Ace::Core::Molecules::ConfigFinder.new

            # Try review/config.yml first, then fallbacks
            config_patterns = [
              "review/config.yml",
              "review.yml"  # Fallback to old naming
            ]

            config_patterns.each do |pattern|
              path = finder.find_file(pattern)
              return path if path
            end

            # Legacy support for .coding-agent/code-review.yml
            legacy_path = File.join(project_root, ".coding-agent/code-review.yml")
            return legacy_path if File.exist?(legacy_path)
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
          # Use ace-core ConfigFinder to find preset in cascade
          if defined?(Ace::Core)
            require "ace/core"
            finder = Ace::Core::Molecules::ConfigFinder.new
            preset_file = finder.find_file("review/presets/#{preset_name}.yml")

            if preset_file && File.exist?(preset_file)
              content = File.read(preset_file)
              return YAML.safe_load(content, permitted_classes: [Symbol])
            end
          else
            # Fallback to direct path if ace-core not available
            preset_dir = File.join(project_root, ".ace/review/presets")
            preset_file = File.join(preset_dir, "#{preset_name}.yml")

            if File.exist?(preset_file)
              content = File.read(preset_file)
              return YAML.safe_load(content, permitted_classes: [Symbol])
            end
          end

          nil
        rescue StandardError => e
          warn "Failed to load preset from #{preset_name}: #{e.message}" if Ace::Review.debug?
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
          presets = []

          # Find all preset directories in cascade
          if defined?(Ace::Core)
            require "ace/core"
            finder = Ace::Core::Molecules::ConfigFinder.new
            traverser = Ace::Core::Molecules::DirectoryTraverser.new
            config_dirs = traverser.find_config_directories

            # Check each config directory for review/presets
            config_dirs.each do |dir|
              preset_dir = File.join(dir, "review/presets")
              next unless Dir.exist?(preset_dir)

              Dir.glob("#{preset_dir}/*.yml").each do |file|
                presets << File.basename(file, ".yml")
              end
            end

            # Check home directory
            home_preset_dir = File.expand_path("~/.ace/review/presets")
            if Dir.exist?(home_preset_dir)
              Dir.glob("#{home_preset_dir}/*.yml").each do |file|
                presets << File.basename(file, ".yml")
              end
            end
          else
            # Fallback to direct path if ace-core not available
            preset_dir = File.join(project_root, ".ace/review/presets")
            if Dir.exist?(preset_dir)
              Dir.glob("#{preset_dir}/*.yml").each do |file|
                presets << File.basename(file, ".yml")
              end
            end
          end

          presets.uniq
        rescue StandardError => e
          warn "Failed to find preset files: #{e.message}" if Ace::Review.debug?
          []
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
            release = `ace-taskflow release 2>/dev/null`.strip
            return release unless release.empty?
          end

          # Fallback to v.0.0.0
          "v.0.0.0"
        end

        def get_release_path
          return nil unless system("which ace-taskflow > /dev/null 2>&1")

          path = `ace-taskflow release --path reviews 2>/dev/null`.strip
          path.empty? ? nil : path
        end

        def expand_path_template(template)
          return template unless template

          # Keep existing %{release} expansion if user configured it
          release = current_release
          template.gsub("%{release}", release)
        end
      end
    end
  end
end