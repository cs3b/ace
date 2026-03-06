# frozen_string_literal: true

module Ace
  module Review
    module Models
      # Represents a configured reviewer entity with focus areas and filtering capabilities.
      #
      # Reviewers are configured entities that transform from simple model names to
      # full-featured review participants with focus areas, file filtering, and
      # weighted contributions.
      #
      # @example Creating a reviewer from config
      #   reviewer = Reviewer.new(
      #     name: "code-fit",
      #     model: "google:gemini-2.5-pro",
      #     focus: "code_quality",
      #     prompt: {
      #       base: "prompt://base/system",
      #       sections: {
      #         reviewer_notes: {
      #           content: "Focus on SOLID principles..."
      #         }
      #       }
      #     },
      #     file_patterns: { include: ["lib/**/*.rb"], exclude: ["**/*_test.rb"] },
      #     weight: 1.0,
      #     critical: false
      #   )
      #
      # @example Creating from legacy model string
      #   reviewer = Reviewer.from_model_string("google:gemini-2.5-flash")
      #   # Creates a default reviewer with name "default"
      #
      class Reviewer
        # Default weight for reviewers (1.0 = full contribution)
        DEFAULT_WEIGHT = 1.0

        attr_reader :name, :model, :focus, :system_prompt_additions,
                    :file_patterns, :weight, :critical,
                    :provider, :provider_kind, :provider_options, :reviewer_type,
                    :provider_ref, :provider_index, :lane_id, :prompt, :provider_class

        # Initialize a new Reviewer from a configuration hash
        #
        # @param config [Hash] Configuration hash with reviewer settings
        # @option config [String] :name Human-readable name for the reviewer
        # @option config [String] :model LLM model identifier (e.g., "google:gemini-2.5-pro")
        # @option config [String] :focus Review focus area (e.g., "code_quality", "security")
        # @option config [Hash] :prompt Reviewer-owned prompt bundle rendered via ace-bundle
        # @option config [String] :system_prompt_additions Legacy compatibility field normalized into prompt.sections.reviewer_notes
        # @option config [Hash] :file_patterns File filtering patterns
        # @option config [Float] :weight Contribution weight (0.0-1.0, default: 1.0)
        # @option config [Boolean] :critical Whether findings are always highlighted
        def initialize(config = {})
          # Support both symbol and string keys
          config = normalize_keys(config)

          @name = config["name"]
          @model = config["model"]
          @focus = config["focus"]
          @system_prompt_additions = config["system_prompt_additions"]
          @file_patterns = normalize_file_patterns(config["file_patterns"])
          @weight = (config["weight"] || DEFAULT_WEIGHT).to_f
          @critical = config["critical"] || false
          @provider = config["provider"]
          @provider_kind = config["provider_kind"]
          @provider_options = config["provider_options"]
          @reviewer_type = config["reviewer_type"]
          @provider_ref = config["provider_ref"]
          @provider_index = config["provider_index"]
          @lane_id = config["lane_id"]
          @provider_class = config["provider_class"]
          @prompt = self.class.normalize_prompt_config(config["prompt"], @system_prompt_additions)

          validate!
        end

        # Create a Reviewer from a legacy model string
        #
        # @param model_string [String] Model identifier (e.g., "google:gemini-2.5-flash")
        # @param name [String, nil] Optional name (defaults to "default")
        # @return [Reviewer] New reviewer instance
        def self.from_model_string(model_string, name: nil)
          new(
            name: name || "default",
            model: model_string
          )
        end

        # Create Reviewers from legacy models array
        #
        # @param models [Array<String>] Array of model identifiers
        # @return [Array<Reviewer>] Array of reviewer instances
        def self.from_models_array(models)
          models.each_with_index.map do |model, index|
            from_model_string(model, name: "reviewer-#{index + 1}")
          end
        end

        # Create Reviewers from preset config.
        #
        # @param config [Hash] Preset configuration
        # @return [Array<Reviewer>] Array of reviewer instances
        def self.from_preset_config(config, default_provider_options: {})
          config = normalize_hash_keys(config)

          # New format: reviewers array
          if config["reviewers"].is_a?(Array) && config["reviewers"].any?
            return config["reviewers"].flat_map do |reviewer_definition|
              from_definition(reviewer_definition, default_provider_options: default_provider_options)
            end
          end

          if config["models"].is_a?(Array) && config["models"].any? || config["model"]
            raise ArgumentError,
                  "Preset defines legacy top-level model/models. Define reviewers: or pipeline:, or pass --model/--models."
          end

          # No reviewers configured
          []
        end

        def self.from_definition(definition, default_provider_options: {})
          definition = deep_stringify(definition)
          definition = {} unless definition.is_a?(Hash)

          reviewer_name = definition["name"].to_s.strip
          reviewer_name = "reviewer" if reviewer_name.empty?

          if definition.key?("provider") && !definition.key?("provider_class")
            raise ArgumentError, "Reviewer '#{reviewer_name}' uses removed field 'provider'. Use provider_class: llm or provider_class: tools-lint"
          end

          # New format: provider_class declares the class; provider is resolved by PresetManager.
          if definition["provider_class"]
            return [template_from_definition(definition)]
          end

          # Inline model: direct assignment without catalog (used by docs/spec style presets).
          if definition["model"] && !definition.key?("providers")
            return [inline_from_definition(definition)]
          end

          providers = Array(definition["providers"]).compact
          if providers.empty?
            raise ArgumentError, "Reviewer '#{reviewer_name}' must define provider_class:, model:, or providers: with at least one entry"
          end

          providers.each_with_index.map do |provider_entry, index|
            provider_ref = Models::ProviderRef.from_entry(provider_entry, default_options: default_provider_options)
            provider_slug = Atoms::SlugGenerator.generate(provider_ref.raw_ref)
            lane_id = "#{reviewer_name}-#{provider_slug}-#{index + 1}"

            merged_provider_options = provider_ref.options.merge(
              "raw_ref" => provider_ref.raw_ref,
              "kind" => provider_ref.kind,
              "target" => provider_ref.target
            )
            merged_provider_options["model"] = provider_ref.model if provider_ref.model

            new(
              "name" => reviewer_name,
              "model" => provider_ref.model_target,
              "focus" => definition["focus"],
              "system_prompt_additions" => definition["system_prompt_additions"],
              "prompt" => definition["prompt"],
              "file_patterns" => definition["file_patterns"],
              "weight" => definition["weight"],
              "critical" => definition["critical"],
              "provider" => provider_ref.raw_ref,
              "provider_ref" => provider_ref.to_h,
              "provider_index" => index,
              "lane_id" => lane_id,
              "provider_kind" => provider_ref.kind,
              "provider_options" => merged_provider_options,
              "reviewer_type" => provider_ref.tool? ? "tool" : "llm"
            )
          end
        end

        # Build a template reviewer from a definition with provider_class.
        # Template reviewers have no model or provider_ref; those are assigned by PresetManager.
        #
        # @param definition [Hash] reviewer definition with provider_class key
        # @return [Reviewer] template reviewer
        def self.template_from_definition(definition)
          definition = deep_stringify(definition)
          reviewer_name = definition["name"].to_s.strip
          reviewer_name = "reviewer" if reviewer_name.empty?

          provider_class = definition["provider_class"].to_s.strip
          unless %w[llm tools-lint].include?(provider_class)
            raise ArgumentError, "Reviewer '#{reviewer_name}' has unsupported provider_class '#{provider_class}'. Use: llm, tools-lint"
          end

          reviewer_type = provider_class == "llm" ? "llm" : "tool"

          new(
            "name" => reviewer_name,
            "focus" => definition["focus"],
            "system_prompt_additions" => definition["system_prompt_additions"],
            "prompt" => definition["prompt"],
            "file_patterns" => definition["file_patterns"],
            "weight" => definition["weight"],
            "critical" => definition["critical"],
            "provider_class" => provider_class,
            "reviewer_type" => reviewer_type
          )
        end

        # Build a resolved reviewer from a template and a catalog entry.
        # Called by PresetManager after catalog resolution.
        #
        # @param template [Reviewer] template reviewer (has provider_class, no model)
        # @param catalog_entry [Hash] resolved catalog entry (has "model" or "tool")
        # @param index [Integer] position within the expanded lane group
        # @return [Reviewer] fully resolved reviewer
        def self.from_catalog_entry(template, catalog_entry, index: 0, default_provider_options: {})
          entry = Reviewer.deep_stringify(catalog_entry)
          entry_name = entry["name"].to_s

          if template.provider_class == "llm"
            model = entry["model"].to_s
            raise ArgumentError, "Catalog entry '#{entry_name}' for LLM reviewer '#{template.name}' is missing model" if model.empty?

            raw_ref = "llm:#{entry_name}:#{model}"
            provider_ref_obj = Models::ProviderRef.from_ref(
              raw_ref,
              default_options: default_provider_options
            )
            provider_slug = Atoms::SlugGenerator.generate(raw_ref)
            lane_id = "#{template.name}-#{provider_slug}-#{index + 1}"

            merged_options = provider_ref_obj.options.merge(
              "raw_ref" => provider_ref_obj.raw_ref,
              "kind" => provider_ref_obj.kind,
              "target" => provider_ref_obj.target,
              "model" => provider_ref_obj.model
            )

            new(
              "name" => template.name,
              "model" => model,
              "focus" => template.focus,
              "system_prompt_additions" => template.system_prompt_additions,
              "prompt" => template.prompt,
              "file_patterns" => template.file_patterns,
              "weight" => template.weight,
              "critical" => template.critical,
              "provider" => raw_ref,
              "provider_ref" => provider_ref_obj.to_h,
              "provider_index" => index,
              "lane_id" => lane_id,
              "provider_kind" => "llm",
              "provider_options" => merged_options,
              "reviewer_type" => "llm",
              "provider_class" => template.provider_class
            )
          else
            # tools-lint
            tool_name = entry["tool"] || entry_name
            lane_id = "#{template.name}-#{Atoms::SlugGenerator.generate(tool_name)}-#{index + 1}"

            new(
              "name" => template.name,
              "model" => "tool:#{tool_name}",
              "focus" => template.focus,
              "file_patterns" => template.file_patterns,
              "weight" => template.weight,
              "critical" => template.critical,
              "provider" => "tool:#{tool_name}",
              "provider_ref" => { "kind" => "tool", "target" => tool_name, "raw_ref" => "tool:#{tool_name}" },
              "provider_index" => index,
              "lane_id" => lane_id,
              "provider_kind" => "tool",
              "provider_options" => { "raw_ref" => "tool:#{tool_name}", "kind" => "tool", "target" => tool_name },
              "reviewer_type" => "tool",
              "provider_class" => template.provider_class
            )
          end
        end

        private_class_method def self.inline_from_definition(definition)
          reviewer_name = definition["name"].to_s.strip
          reviewer_name = "reviewer" if reviewer_name.empty?

          new(
            "name" => reviewer_name,
            "model" => definition["model"],
            "focus" => definition["focus"],
            "system_prompt_additions" => definition["system_prompt_additions"],
            "prompt" => definition["prompt"],
            "file_patterns" => definition["file_patterns"],
            "weight" => definition["weight"],
            "critical" => definition["critical"],
            "reviewer_type" => "llm"
          )
        end

        def self.normalize_prompt_config(prompt, system_prompt_additions = nil)
          normalized_prompt = deep_stringify(prompt)
          normalized_prompt = {} unless normalized_prompt.is_a?(Hash)

          additions = system_prompt_additions.to_s.strip
          return normalized_prompt if additions.empty?

          sections = normalized_prompt["sections"]
          sections = deep_stringify(sections)
          sections = {} unless sections.is_a?(Hash)

          notes = sections["reviewer_notes"]
          notes = deep_stringify(notes)
          notes = {} unless notes.is_a?(Hash)

          existing_content = notes["content"].to_s.strip
          notes["title"] ||= "Reviewer Notes"
          notes["description"] ||= "Additional reviewer-specific instructions"
          notes["content"] = [existing_content, additions].reject(&:empty?).join("\n\n")

          sections["reviewer_notes"] = notes
          normalized_prompt["sections"] = sections
          normalized_prompt
        end

        # Filter subject content based on reviewer's file patterns
        #
        # Delegates to SubjectFilter molecule for actual filtering logic.
        #
        # @param subject [Hash] Subject configuration with files/diff/content
        # @return [Hash] Filtered subject (deep copy with only matching content)
        def filter_subject(subject)
          Molecules::SubjectFilter.filter(subject, file_patterns)
        end

        # Check if this reviewer has file patterns configured
        #
        # Delegates to SubjectFilter molecule.
        #
        # @return [Boolean] True if file patterns are configured
        def has_file_patterns?
          Molecules::SubjectFilter.has_patterns?(file_patterns)
        end

        # Check if a file path matches this reviewer's patterns
        #
        # Delegates to SubjectFilter molecule.
        #
        # @param file_path [String] File path to check
        # @return [Boolean] True if file matches (or no patterns configured)
        def matches_file?(file_path)
          Molecules::SubjectFilter.matches_file?(file_path, file_patterns)
        end

        # Convert to hash representation
        #
        # @return [Hash] Hash with string keys
        def to_h
          {
            "name" => name,
            "model" => model,
            "focus" => focus,
            "file_patterns" => file_patterns,
            "weight" => weight,
            "critical" => critical,
            "provider" => provider,
            "provider_kind" => provider_kind,
            "provider_options" => provider_options,
            "reviewer_type" => reviewer_type,
            "provider_ref" => provider_ref,
            "provider_index" => provider_index,
            "lane_id" => lane_id,
            "prompt" => prompt,
            "provider_class" => provider_class
          }.compact
        end

        # Check equality with another reviewer
        #
        # @param other [Reviewer] Other reviewer to compare
        # @return [Boolean] True if equal
        def ==(other)
          return false unless other.is_a?(Reviewer)

          name == other.name &&
            model == other.model &&
            focus == other.focus &&
            weight == other.weight &&
            critical == other.critical &&
            provider == other.provider &&
            provider_kind == other.provider_kind &&
            reviewer_type == other.reviewer_type &&
            lane_id == other.lane_id &&
            prompt == other.prompt
        end

        alias eql? ==

        # Hash code for use in hash tables
        #
        # @return [Integer] Hash code
        def hash
          [name, model, focus, weight, critical, provider, provider_kind,
            reviewer_type, lane_id, prompt].hash
        end

        private

        # Validate required fields
        def validate!
          effective_type = reviewer_type || (provider_class == "llm" ? "llm" : nil)
          if effective_type.to_s == "llm" && !prompt_present?(prompt)
            raise ArgumentError, "LLM reviewer '#{name || model}' must define a prompt."
          end

          # Model is required for fully-resolved reviewers; templates carry provider_class instead.
          unless provider_class
            raise ArgumentError, "Reviewer model is required" if model.nil? || model.to_s.strip.empty?
          end

          raise ArgumentError, "Reviewer weight must be between 0 and 1" if weight < 0 || weight > 1
        end

        # Normalize hash keys to strings (supports both symbol and string keys)
        def normalize_keys(hash)
          return {} unless hash.is_a?(Hash)
          hash.transform_keys(&:to_s)
        end

        # Class method for key normalization
        def self.normalize_hash_keys(hash)
          return {} unless hash.is_a?(Hash)
          hash.transform_keys(&:to_s)
        end

        def self.deep_stringify(value)
          case value
          when Hash
            value.each_with_object({}) do |(key, nested_value), index|
              index[key.to_s] = deep_stringify(nested_value)
            end
          when Array
            value.map { |item| deep_stringify(item) }
          else
            value
          end
        end

        # Normalize file patterns structure
        def normalize_file_patterns(patterns)
          return nil unless patterns.is_a?(Hash)

          normalized = normalize_keys(patterns)
          {
            "include" => Array(normalized["include"]),
            "exclude" => Array(normalized["exclude"])
          }
        end

        def prompt_present?(value)
          case value
          when Hash
            value.any?
          when String
            !value.strip.empty?
          else
            !value.nil?
          end
        end
      end
    end
  end
end
