# frozen_string_literal: true

module Ace
  module Assign
    module Atoms
      # Pure functions for expanding preset templates into phase definitions.
      #
      # Handles `expansion:` directives in preset YAML files to generate
      # hierarchical phase structures from parameter arrays.
      #
      # Supports:
      # - `batch-parent`: Creates a parent container phase that auto-completes
      # - `foreach`: Iterates over array parameter to create child phases
      # - `child-template`: Template for generating foreach children
      #
      # @example Preset with expansion
      #   expansion:
      #     batch-parent:
      #       name: batch-tasks
      #       number: "010"
      #       instructions: "Batch container - auto-completes when children done."
      #     foreach: taskrefs
      #     child-template:
      #       name: "work-on-{{item}}"
      #       parent: "010"
      #       context: fork
      #       instructions: "Implement task {{item}}"
      #
      # @example Generated phases for taskrefs: [148, 149, 150]
      #   [
      #     { number: "010", name: "batch-tasks", instructions: "..." },
      #     { number: "010.01", name: "work-on-148", parent: "010", context: "fork", ... },
      #     { number: "010.02", name: "work-on-149", parent: "010", context: "fork", ... },
      #     { number: "010.03", name: "work-on-150", parent: "010", context: "fork", ... }
      #   ]
      module PresetExpander
        # Expand a preset configuration into concrete phases.
        #
        # @param preset [Hash] Parsed preset YAML with optional expansion section
        # @param parameters [Hash] Parameter values including arrays for foreach
        # @return [Array<Hash>] Expanded phases ready for job.yaml
        def self.expand(preset, parameters = {})
          expansion = preset["expansion"]
          base_steps = preset["steps"] || []

          # If no expansion section, return base steps with parameter substitution
          unless expansion
            return base_steps.map { |step| substitute_parameters(step, parameters) }
          end

          expanded_steps = []

          # Process batch-parent if present
          if expansion["batch-parent"]
            parent_step = build_batch_parent(expansion["batch-parent"], parameters)
            expanded_steps << parent_step
          end

          # Process foreach expansion if present
          if expansion["foreach"] && expansion["child-template"]
            foreach_param = expansion["foreach"]
            items = normalize_array_parameter(parameters[foreach_param])

            unless items.empty?
              child_steps = build_foreach_children(
                expansion["child-template"],
                items,
                parameters
              )
              expanded_steps.concat(child_steps)
            end
          end

          # Add remaining base steps with parameter substitution
          base_steps.each do |step|
            expanded_step = substitute_parameters(step, parameters)
            expanded_steps << expanded_step
          end

          expanded_steps
        end

        # Parse array parameter from various input formats.
        #
        # @param value [String, Array, nil] Parameter value
        # @return [Array<String>] Normalized array of values
        def self.parse_array_parameter(value)
          return [] if value.nil?
          return value.map(&:to_s) if value.is_a?(Array)

          value_str = value.to_s.strip
          return [] if value_str.empty?

          # Check for range pattern (e.g., "148-152")
          if value_str.match?(/^\d+-\d+$/)
            start_num, end_num = value_str.split("-").map(&:to_i)
            return (start_num..end_num).map(&:to_s)
          end

          # Check for comma-separated values
          if value_str.include?(",")
            return value_str.split(",").map(&:strip)
          end

          # Check for pattern (contains * or ?)
          if value_str.match?(/[*?]/)
            # Return pattern as single-element array for later resolution
            return [value_str]
          end

          # Single value
          [value_str]
        end

        # Validate preset parameters against requirements.
        #
        # @param preset [Hash] Preset configuration
        # @param parameters [Hash] Provided parameter values
        # @return [Array<String>] List of validation errors (empty if valid)
        def self.validate_parameters(preset, parameters)
          errors = []
          param_defs = preset["parameters"] || {}

          param_defs.each do |name, config|
            next unless config["required"]

            value = parameters[name]
            if value.nil? || (value.respond_to?(:empty?) && value.empty?)
              errors << "Required parameter '#{name}' is missing"
            end
          end

          errors
        end

        # Check if a preset has expansion directives.
        #
        # @param preset [Hash] Preset configuration
        # @return [Boolean] True if preset uses expansion
        def self.has_expansion?(preset)
          !preset["expansion"].nil?
        end

        # Get the foreach parameter name from preset expansion.
        #
        # @param preset [Hash] Preset configuration
        # @return [String, nil] Name of the foreach parameter
        def self.foreach_parameter(preset)
          preset.dig("expansion", "foreach")
        end

        private

        # Normalize array parameter value.
        #
        # @param value [Object] Raw parameter value
        # @return [Array<String>] Normalized array
        def self.normalize_array_parameter(value)
          parse_array_parameter(value)
        end
        private_class_method :normalize_array_parameter

        # Build the batch parent phase.
        #
        # @param config [Hash] batch-parent configuration
        # @param parameters [Hash] Parameter values for substitution
        # @return [Hash] Parent phase definition
        def self.build_batch_parent(config, parameters)
          step = {
            "number" => config["number"] || "010",
            "name" => substitute_string(config["name"] || "batch-tasks", parameters),
            "instructions" => substitute_string(config["instructions"] || "", parameters)
          }

          step["skill"] = config["skill"] if config["skill"]
          step["context"] = config["context"] if config["context"]

          step
        end
        private_class_method :build_batch_parent

        # Build child phases from foreach template.
        #
        # @param template [Hash] child-template configuration
        # @param items [Array<String>] Items to iterate over
        # @param parameters [Hash] Additional parameter values
        # @return [Array<Hash>] Generated child phases
        def self.build_foreach_children(template, items, parameters)
          parent_number = template["parent"] || "010"
          steps = []

          items.each_with_index do |item, index|
            # Build child number: parent.01, parent.02, etc.
            child_number = "#{parent_number}.#{format('%02d', index + 1)}"

            # Create merged parameters with {{item}} available
            item_params = parameters.merge("item" => item)

            # Handle instructions substitution for both string and array formats
            template_instructions = template["instructions"] || ""
            instructions = if template_instructions.is_a?(Array)
              template_instructions.map { |i| substitute_string(i, item_params) }
            else
              substitute_string(template_instructions, item_params)
            end

            step = {
              "number" => child_number,
              "name" => substitute_string(template["name"] || "item-#{item}", item_params),
              "parent" => parent_number,
              "instructions" => instructions
            }

            step["skill"] = template["skill"] if template["skill"]
            step["context"] = template["context"] if template["context"]

            steps << step
          end

          steps
        end
        private_class_method :build_foreach_children

        # Substitute parameters in a phase definition.
        #
        # @param step [Hash] Phase configuration
        # @param parameters [Hash] Parameter values
        # @return [Hash] Phase with substituted values
        def self.substitute_parameters(step, parameters)
          result = step.dup

          result["name"] = substitute_string(result["name"], parameters) if result["name"]
          result["instructions"] = substitute_string(result["instructions"], parameters) if result["instructions"]

          # Handle array instructions
          if result["instructions"].is_a?(Array)
            result["instructions"] = result["instructions"].map { |i| substitute_string(i, parameters) }
          end

          result
        end
        private_class_method :substitute_parameters

        # Substitute {{placeholder}} tokens in a string.
        #
        # @param text [String, nil] Text with placeholders
        # @param parameters [Hash] Parameter values
        # @return [String] Text with substituted values
        def self.substitute_string(text, parameters)
          return "" if text.nil?
          return text unless text.is_a?(String)

          result = text.dup
          parameters.each do |key, value|
            # Handle array values by joining with comma
            display_value = value.is_a?(Array) ? value.join(", ") : value.to_s
            result = result.gsub("{{#{key}}}", display_value)
          end
          result
        end
        private_class_method :substitute_string
      end
    end
  end
end
