# frozen_string_literal: true

module Ace
  module Assign
    module Atoms
      # Pure functions for expanding preset templates into step definitions.
      #
      # Handles `expansion:` directives in preset YAML files to generate
      # hierarchical step structures from parameter arrays.
      #
      # Supports:
      # - `batch-parent`: Creates a parent container step that auto-completes
      # - `foreach`: Iterates over array parameter to create child steps
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
      # @example Generated steps for taskrefs: [148, 149, 150]
      #   [
      #     { number: "010", name: "batch-tasks", instructions: "..." },
      #     { number: "010.01", name: "work-on-148", parent: "010", context: "fork", ... },
      #     { number: "010.02", name: "work-on-149", parent: "010", context: "fork", ... },
      #     { number: "010.03", name: "work-on-150", parent: "010", context: "fork", ... }
      #   ]
      module PresetExpander
        # Expand a preset configuration into concrete steps.
        #
        # @param preset [Hash] Parsed preset YAML with optional expansion section
        # @param parameters [Hash] Parameter values including arrays for foreach
        # @return [Array<Hash>] Expanded steps ready for job.yaml
        def self.expand(preset, parameters = {})
          parameters = normalize_taskref_alias(parameters)
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
          parameters = normalize_taskref_alias(parameters)
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

        # Normalize single-task shorthand onto batch parameter name.
        #
        # Canonical batch presets now use taskrefs; callers may still pass
        # taskref for single-task usage.
        def self.normalize_taskref_alias(parameters)
          params = (parameters || {}).dup
          return params unless params["taskrefs"].nil? || params["taskrefs"] == ""

          taskref = params["taskref"]
          return params if taskref.nil? || taskref.to_s.strip.empty?

          params["taskrefs"] = [taskref.to_s]
          params
        end
        private_class_method :normalize_taskref_alias

        # Build the batch parent step.
        #
        # @param config [Hash] batch-parent configuration
        # @param parameters [Hash] Parameter values for substitution
        # @return [Hash] Parent step definition
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

        # Build child steps from foreach template.
        #
        # @param template [Hash] child-template configuration
        # @param items [Array<String>] Items to iterate over
        # @param parameters [Hash] Additional parameter values
        # @return [Array<Hash>] Generated child steps
        def self.build_foreach_children(template, items, parameters)
          parent_number = template["parent"] || "010"
          steps = []

          items.each_with_index do |item, index|
            # Build child number: parent.01, parent.02, etc.
            child_number = "#{parent_number}.#{format('%02d', index + 1)}"

            # Create merged parameters with {{item}} available
            item_params = parameters.merge("item" => item)
            raw_step = template.dup
            raw_step["number"] = child_number
            raw_step["parent"] = parent_number
            raw_step["name"] ||= "item-#{item}"
            raw_step["instructions"] ||= ""
            step = substitute_parameters(raw_step, item_params)

            steps << step
          end

          steps
        end
        private_class_method :build_foreach_children

        # Substitute parameters in a step definition.
        #
        # @param step [Hash] Step configuration
        # @param parameters [Hash] Parameter values
        # @return [Hash] Step with substituted values
        def self.substitute_parameters(step, parameters)
          substitute_value(step, parameters)
        end
        private_class_method :substitute_parameters

        def self.substitute_value(value, parameters)
          case value
          when Hash
            value.each_with_object({}) do |(key, nested), result|
              result[key] = substitute_value(nested, parameters)
            end
          when Array
            value.map { |item| substitute_value(item, parameters) }
          when String
            substitute_string(value, parameters)
          else
            value
          end
        end
        private_class_method :substitute_value

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
