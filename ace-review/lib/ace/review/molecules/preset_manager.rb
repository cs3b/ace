# frozen_string_literal: true

require "yaml"
require "pathname"
require "set"
require_relative '../atoms/preset_validator'

module Ace
  module Review
    module Molecules
      # Manages loading and resolving review presets from configuration
      class PresetManager
        attr_reader :config_path, :config, :project_root

        # Metadata keys that are added during composition and should be stripped before use
        COMPOSITION_METADATA_KEYS = %w[success composed composed_from].freeze

        def initialize(config_path: nil, project_root: nil)
          @project_root = project_root || find_project_root
          @config_path = resolve_config_path(config_path)
          @config = load_configuration
          @preset_cache = {}  # Final preset cache (after merging with defaults)
          @composition_cache = {}  # Intermediate composition cache (before defaults merge)
        end

        # Load a specific preset by name
        # Cached results are returned immediately to avoid redundant composition
        def load_preset(preset_name)
          return nil unless preset_name

          # Check cache first (composition can be expensive for deeply nested presets)
          return @preset_cache[preset_name] if @preset_cache.key?(preset_name)

          # Load with composition support
          result = load_preset_with_composition(preset_name)

          # Handle composition errors
          unless result && result["success"]
            # Log composition failure for debugging
            if result && result["error"]
              warn "Failed to compose preset '#{preset_name}': #{result['error']}" if Ace::Review.debug?
            end
            return nil
          end

          # Extract preset data (remove composition metadata)
          preset = strip_composition_metadata(result)

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
        # Supports bundle: (new) and context: (old) keys for backward compatibility
        def default_context
          config&.dig("defaults", "bundle") ||
            config&.dig("defaults", "context") ||
            Ace::Review.get("defaults", "bundle") ||
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

          # Resolve models with backward compatibility
          models_config = resolve_models_config(preset, overrides)

          # Support both bundle: (new) and context: (old) keys
          preset_context = preset["bundle"] || preset["context"]

          {
            description: preset["description"],
            # Extract prompt composition for ace-bundle frontmatter (but let ace-bundle process it)
            system_prompt: preset["system_prompt"] || preset["prompt_composition"],
            # Preserve instructions field for section-based context generation
            instructions: preset["instructions"],
            context: resolve_context_config(preset_context, overrides[:context]),
            subject: resolve_subject_config(preset["subject"], overrides[:subject]),
            models: models_config,
            # Keep model for backward compatibility (first model in array)
            model: models_config.first,
            output_format: overrides[:output_format] || preset["output_format"] || default_output_format
          }
        end

        # Get storage configuration (user config only, no defaults)
        def storage_config
          config&.dig("storage") || {}
        end

        # Get the base path for storing reviews
        def review_base_path
          # 1. Check for configured path first (user config only)
          configured_path = storage_config["base_path"]
          return expand_path_template(configured_path) if configured_path

          # 2. Fallback to cache directory
          File.join(project_root, ".cache/ace-review/sessions")
        end

        # Load a preset with composition support
        # Returns fully composed preset data with all dependent presets merged
        # Composition order: base presets first, then composing preset (last wins for scalars)
        # Uses intermediate caching to avoid redundant composition of shared dependencies
        def load_preset_with_composition(name, visited = Set.new)
          start_time = Time.now if Ace::Review.debug?

          # Check circular dependency first (before cache to prevent caching incomplete compositions)
          validation = Atoms::PresetValidator.check_circular_dependency(name, visited.to_a)
          unless validation[:success]
            return {
              "error" => validation[:error],
              "success" => false
            }
          end

          # Check composition cache (enables intermediate caching for shared base presets)
          if @composition_cache.key?(name)
            warn "[COMPOSITION] Cache hit for '#{name}'" if Ace::Review.debug?
            return @composition_cache[name].dup
          end

          # Load preset from file or config
          preset = load_preset_from_file(name) || load_preset_from_config(name)
          unless preset
            return {
              "error" => "Preset '#{name}' not found. Available presets: #{available_presets.join(', ')}",
              "success" => false
            }
          end

          # Mark this preset as visited
          new_visited = visited.dup.add(name)

          # Extract preset references
          preset_refs = Atoms::PresetValidator.extract_preset_references(preset)

          # If no references, return preset as-is
          if preset_refs.empty?
            # Ensure consistent string keys
            result = deep_stringify_keys(preset)
            result["success"] = true
            return result
          end

          # Load all referenced presets recursively
          composed_presets = []
          errors = []

          preset_refs.each do |ref_name|
            composed = load_preset_with_composition(ref_name, new_visited)
            if composed["success"]
              composed_presets << composed
            else
              errors << composed["error"]
            end
          end

          # If there were errors loading dependencies, return error
          if errors.any?
            return {
              "error" => "Failed to load preset dependencies: #{errors.join(', ')}",
              "success" => false,
              "partial_presets" => composed_presets
            }
          end

          # Strip metadata from composed presets before merging
          clean_composed = composed_presets.map { |p| strip_composition_metadata(p) }

          # Merge all composed presets with current preset
          # Order: dependencies first, then current preset (last wins for scalars)
          merged = merge_preset_data(clean_composed + [preset])

          # Ensure consistent string keys and add composition metadata
          merged = deep_stringify_keys(merged)
          merged["success"] = true
          merged["composed"] = true
          merged["composed_from"] = preset_refs + [name]

          # Cache the composed result for future reuse (enables intermediate caching)
          @composition_cache[name] = merged.dup

          # Log composition performance metrics in debug mode
          if Ace::Review.debug?
            elapsed = Time.now - start_time
            depth = visited.size + 1
            ref_count = preset_refs.size
            warn "[COMPOSITION] Composed '#{name}' in #{(elapsed * 1000).round(2)}ms (depth: #{depth}, refs: #{ref_count})"
          end

          merged
        end

        private

        # Strip composition metadata from a preset hash (deep recursive)
        # Removes internal keys used for composition tracking: success, composed, composed_from
        # Recursively processes nested hashes and arrays to ensure complete metadata removal
        # @param preset_hash [Hash] Preset data with potential metadata
        # @return [Hash] Preset data without composition metadata at any nesting level
        def strip_composition_metadata(preset_hash)
          result = preset_hash.reject { |k, _| COMPOSITION_METADATA_KEYS.include?(k) }

          # Recursively strip metadata from nested structures
          result.transform_values do |value|
            case value
            when Hash
              strip_composition_metadata(value)
            when Array
              value.map { |item| item.is_a?(Hash) ? strip_composition_metadata(item) : item }
            else
              value
            end
          end
        end

        # Merge multiple preset data structures
        # Arrays are concatenated and deduplicated (first occurrence wins)
        # Hashes are deep merged recursively
        # Scalars follow "last wins" strategy
        # Uses centralized DeepMerger from ace-support-config for consistency
        def merge_preset_data(presets)
          return presets.first if presets.size == 1

          # Use DeepMerger with :union strategy to concatenate and deduplicate arrays
          Ace::Support::Config::Atoms::DeepMerger.merge_all(presets, array_strategy: :union)
        end

        def find_project_root
          # Use ace-config for project root discovery
          Ace::Support::Config.find_project_root || Dir.pwd
        end

        def resolve_config_path(custom_path)
          if custom_path
            path = Pathname.new(custom_path)
            return path.absolute? ? custom_path : File.join(project_root, custom_path)
          end

          # Use ace-config ConfigFinder to locate config in cascade
          finder = Ace::Support::Config.finder

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

          # Fallback to .ace/review/config.yml for tests and standalone usage
          fallback_path = File.join(project_root, ".ace/review/config.yml")
          return fallback_path if File.exist?(fallback_path)

          nil
        end

        def load_configuration
          return {} unless config_path && File.exist?(config_path)

          content = File.read(config_path)
          config_data = YAML.safe_load(content, permitted_classes: [Symbol]) || {}
          deep_stringify_keys(config_data)
        rescue StandardError => e
          warn "Failed to load configuration from #{config_path}: #{e.message}" if Ace::Review.debug?
          {}
        end

        def load_preset_from_file(preset_name)
          # Validate preset name for security before any filesystem access
          validation = Atoms::PresetValidator.validate_preset_name(preset_name)
          unless validation[:success]
            raise ArgumentError, validation[:error]
          end

          # Use ace-config ConfigFinder to find preset in cascade
          finder = Ace::Support::Config.finder
          preset_file = finder.find_file("review/presets/#{preset_name}.yml")

          if preset_file && File.exist?(preset_file)
            content = File.read(preset_file)
            preset_data = YAML.safe_load(content, permitted_classes: [Symbol])
            return deep_stringify_keys(preset_data)
          end

          # Fallback to .ace/review/presets for tests and standalone usage
          preset_dir = File.join(project_root, ".ace/review/presets")
          preset_file = File.join(preset_dir, "#{preset_name}.yml")

          if File.exist?(preset_file)
            content = File.read(preset_file)
            preset_data = YAML.safe_load(content, permitted_classes: [Symbol])
            return deep_stringify_keys(preset_data)
          end

          nil
        rescue ArgumentError
          # Re-raise validation errors (don't suppress security checks)
          raise
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

          # Find all preset directories in cascade using ace-support-fs
          require "ace/support/fs"
          traverser = Ace::Support::Fs::Molecules::DirectoryTraverser.new
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

          # Also check project fallback
          preset_dir = File.join(project_root, ".ace/review/presets")
          if Dir.exist?(preset_dir)
            Dir.glob("#{preset_dir}/*.yml").each do |file|
              presets << File.basename(file, ".yml")
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

        def resolve_system_prompt_composition(composition, overrides)
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

        # Resolve models configuration with backward compatibility
        # Priority: override models > override model > preset models > preset model > default
        def resolve_models_config(preset, overrides)
          # If override provides models array, use it
          if overrides[:models].is_a?(Array) && overrides[:models].any?
            return overrides[:models]
          end

          # If override provides single model, wrap in array
          if overrides[:model]
            return [overrides[:model]]
          end

          # If preset has models array, use it
          if preset["models"].is_a?(Array) && preset["models"].any?
            return preset["models"]
          end

          # If preset has single model, wrap in array
          if preset["model"]
            return [preset["model"]]
          end

          # Fallback to default model
          [default_model]
        end

        def current_release
          "v.0.0.0"
        end

        def get_release_path
          nil
        end

        def expand_path_template(template)
          return template unless template

          # Keep existing %{release} expansion if user configured it
          release = current_release
          template.gsub("%{release}", release)
        end

        # Recursively convert all hash keys to strings
        #
        # YAML.safe_load with permitted_classes: [Symbol] can return hashes with
        # both string and symbol keys. This normalizes all keys to strings for
        # consistent access patterns throughout the codebase.
        #
        # @param value [Object] Value to stringify (Hash, Array, or other)
        # @return [Object] Value with all hash keys stringified
        #
        # @example Simple hash
        #   deep_stringify_keys({a: 1, b: 2})
        #   #=> {"a" => 1, "b" => 2}
        #
        # @example Nested hash
        #   deep_stringify_keys({a: {b: {c: 1}}})
        #   #=> {"a" => {"b" => {"c" => 1}}}
        #
        # @example Hash in array
        #   deep_stringify_keys([{a: 1}, {b: 2}])
        #   #=> [{"a" => 1}, {"b" => 2}]
        #
        # @api private
        def deep_stringify_keys(value)
          case value
          when Hash
            value.each_with_object({}) do |(k, v), result|
              result[k.to_s] = deep_stringify_keys(v)
            end
          when Array
            value.map { |v| deep_stringify_keys(v) }
          else
            value
          end
        end
      end
    end
  end
end