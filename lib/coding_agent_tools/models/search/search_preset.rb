# frozen_string_literal: true

module CodingAgentTools
  module Models
    module Search
      # SearchPreset represents a saved search configuration
      # This is a model - pure data structure with no behavior
      class SearchPreset
        attr_reader :name, :description, :options, :variables, :created_at, :updated_at

        # @param name [String] Preset name
        # @param description [String] Preset description
        # @param options [Hash] Search option overrides
        # @param variables [Hash] Variable definitions with defaults
        # @param created_at [Time] Creation timestamp
        # @param updated_at [Time] Last update timestamp
        def initialize(name:, description: "", options: {}, variables: {},
          created_at: Time.now, updated_at: Time.now)
          @name = name
          @description = description
          @options = options
          @variables = variables
          @created_at = created_at
          @updated_at = updated_at
        end

        # Apply preset to base options with variable substitution
        # @param base_options [SearchOptions] Base search options
        # @param variable_values [Hash] Values for variables
        # @return [SearchOptions] Options with preset applied
        def apply_to(base_options, variable_values = {})
          # Merge variable defaults with provided values
          resolved_vars = @variables.merge(variable_values)

          # Substitute variables in options
          resolved_options = substitute_variables(@options, resolved_vars)

          # Merge with base options
          base_options.merge(resolved_options)
        end

        # Get list of variable names
        # @return [Array<String>] Variable names
        def variable_names
          @variables.keys
        end

        # Check if preset has variables
        # @return [Boolean] True if preset defines variables
        def has_variables?
          !@variables.empty?
        end

        # Convert to hash representation
        # @return [Hash] Hash representation of preset
        def to_h
          {
            name: @name,
            description: @description,
            options: @options,
            variables: @variables,
            created_at: @created_at,
            updated_at: @updated_at
          }
        end

        # Convert to YAML-friendly hash for saving
        # @return [Hash] YAML-friendly hash
        def to_yaml_h
          {
            "name" => @name,
            "description" => @description,
            "options" => stringify_keys(@options),
            "variables" => stringify_keys(@variables),
            "created_at" => @created_at.iso8601,
            "updated_at" => @updated_at.iso8601
          }
        end

        # Create preset from hash
        # @param hash [Hash] Hash representation
        # @return [SearchPreset] New preset instance
        def self.from_h(hash)
          new(
            name: hash[:name] || hash["name"],
            description: hash[:description] || hash["description"] || "",
            options: hash[:options] || hash["options"] || {},
            variables: hash[:variables] || hash["variables"] || {},
            created_at: parse_time(hash[:created_at] || hash["created_at"]) || Time.now,
            updated_at: parse_time(hash[:updated_at] || hash["updated_at"]) || Time.now
          )
        end

        # Create preset from YAML hash
        # @param yaml_hash [Hash] YAML hash
        # @return [SearchPreset] New preset instance
        def self.from_yaml_h(yaml_hash)
          new(
            name: yaml_hash["name"],
            description: yaml_hash["description"] || "",
            options: symbolize_keys(yaml_hash["options"] || {}),
            variables: symbolize_keys(yaml_hash["variables"] || {}),
            created_at: parse_time(yaml_hash["created_at"]) || Time.now,
            updated_at: parse_time(yaml_hash["updated_at"]) || Time.now
          )
        end

        # Validate preset
        # @return [Array<String>] Array of validation errors
        def validate
          errors = []

          errors << "Name cannot be empty" if @name.nil? || @name.strip.empty?
          errors << "Name must be alphanumeric with underscores/hyphens" unless valid_name?
          errors << "Options must be a hash" unless @options.is_a?(Hash)
          errors << "Variables must be a hash" unless @variables.is_a?(Hash)

          # Validate variable names
          @variables.each_key do |var_name|
            unless var_name.is_a?(String) || var_name.is_a?(Symbol)
              errors << "Variable name #{var_name} must be string or symbol"
            end
          end

          errors
        end

        # Check if preset is valid
        # @return [Boolean] True if preset is valid
        def valid?
          validate.empty?
        end

        # Update preset with new values
        # @param updates [Hash] Updates to apply
        # @return [SearchPreset] New preset instance with updates
        def update(updates)
          new_attributes = to_h.merge(updates)
          new_attributes[:updated_at] = Time.now

          self.class.new(**new_attributes)
        end

        private

        # Check if name is valid
        # @return [Boolean] True if name is valid
        def valid_name?
          @name.match?(/\A[a-zA-Z0-9_-]+\z/)
        end

        # Substitute variables in a nested structure
        # @param obj [Object] Object to process
        # @param variables [Hash] Variable values
        # @return [Object] Object with variables substituted
        def substitute_variables(obj, variables)
          case obj
          when Hash
            obj.transform_values { |v| substitute_variables(v, variables) }
          when Array
            obj.map { |v| substitute_variables(v, variables) }
          when String
            substitute_string_variables(obj, variables)
          else
            obj
          end
        end

        # Substitute variables in a string
        # @param str [String] String to process
        # @param variables [Hash] Variable values
        # @return [String] String with variables substituted
        def substitute_string_variables(str, variables)
          result = str.dup

          variables.each do |var_name, value|
            # Support both ${var} and $var syntax
            result.gsub!(/\$\{#{var_name}\}/, value.to_s)
            result.gsub!(/\$#{var_name}\b/, value.to_s)
          end

          result
        end

        # Convert hash keys to strings
        # @param hash [Hash] Hash to process
        # @return [Hash] Hash with string keys
        def stringify_keys(hash)
          hash.transform_keys(&:to_s)
        end

        # Convert hash keys to symbols
        # @param hash [Hash] Hash to process
        # @return [Hash] Hash with symbol keys
        def self.symbolize_keys(hash)
          hash.transform_keys(&:to_sym)
        end

        # Parse time string
        # @param time_str [String, Time] Time to parse
        # @return [Time, nil] Parsed time or nil
        def self.parse_time(time_str)
          case time_str
          when Time
            time_str
          when String
            Time.parse(time_str)
          end
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
