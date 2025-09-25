# frozen_string_literal: true

module Ace
  module LLM
    module Atoms
      # ProviderConfigValidator validates provider configuration structure and content
      class ProviderConfigValidator
        # Required fields for any provider configuration
        REQUIRED_FIELDS = %w[name class gem].freeze

        # Optional fields with expected types
        OPTIONAL_FIELDS = {
          "models" => Array,
          "api_key" => [Hash, NilClass],
          "capabilities" => Array,
          "default_options" => Hash,
          "endpoint" => String,
          "version" => String,
          "aliases" => Hash
        }.freeze

        # Valid capability values
        VALID_CAPABILITIES = %w[
          text_generation
          streaming
          function_calling
          vision
          embeddings
          code_generation
          chat_completion
        ].freeze

        # Validation result
        ValidationResult = Struct.new(:valid, :errors, :warnings) do
          def valid?
            valid
          end

          def invalid?
            !valid
          end
        end

        # Validate a provider configuration
        # @param config [Hash] Provider configuration to validate
        # @return [ValidationResult] Validation result with errors and warnings
        def validate(config)
          errors = []
          warnings = []

          # Check that config is a Hash
          unless config.is_a?(Hash)
            errors << "Configuration must be a Hash, got #{config.class}"
            return ValidationResult.new(false, errors, warnings)
          end

          # Validate required fields
          REQUIRED_FIELDS.each do |field|
            if config[field].nil? || config[field].to_s.strip.empty?
              errors << "Missing required field: '#{field}'"
            end
          end

          # Validate field types
          validate_field_types(config, errors, warnings)

          # Validate specific field content
          validate_name(config["name"], errors) if config["name"]
          validate_class(config["class"], errors) if config["class"]
          validate_gem(config["gem"], errors) if config["gem"]
          validate_models(config["models"], warnings) if config["models"]
          validate_api_key(config["api_key"], errors, warnings) if config["api_key"]
          validate_capabilities(config["capabilities"], warnings) if config["capabilities"]
          validate_default_options(config["default_options"], warnings) if config["default_options"]
          validate_aliases(config["aliases"], errors, warnings) if config["aliases"]

          # Return validation result
          ValidationResult.new(errors.empty?, errors, warnings)
        end

        # Validate a batch of configurations
        # @param configs [Array<Hash>] Array of provider configurations
        # @return [Hash] Map of config name to validation result
        def validate_batch(configs)
          results = {}

          configs.each do |config|
            name = config["name"] || "unnamed"
            results[name] = validate(config)
          end

          results
        end

        private

        # Validate field types match expected types
        def validate_field_types(config, errors, warnings)
          config.each do |field, value|
            next if REQUIRED_FIELDS.include?(field)
            next unless OPTIONAL_FIELDS.key?(field)

            expected_types = Array(OPTIONAL_FIELDS[field])
            unless expected_types.any? { |type| value.is_a?(type) }
              errors << "Field '#{field}' must be #{expected_types.join(' or ')}, got #{value.class}"
            end
          end

          # Warn about unknown fields
          unknown_fields = config.keys - REQUIRED_FIELDS - OPTIONAL_FIELDS.keys
          unless unknown_fields.empty?
            warnings << "Unknown fields in configuration: #{unknown_fields.join(', ')}"
          end
        end

        # Validate provider name format
        def validate_name(name, errors)
          unless name.is_a?(String) && name.match?(/\A[a-z0-9_-]+\z/i)
            errors << "Provider name must contain only letters, numbers, hyphens, and underscores"
          end
        end

        # Validate class name format
        def validate_class(class_name, errors)
          unless class_name.is_a?(String) && class_name.match?(/\A[A-Z][A-Za-z0-9_]*(::[A-Z][A-Za-z0-9_]*)*\z/)
            errors << "Class must be a valid Ruby class name (e.g., 'Ace::LLM::Organisms::GoogleClient')"
          end
        end

        # Validate gem name format
        def validate_gem(gem_name, errors)
          unless gem_name.is_a?(String) && gem_name.match?(/\A[a-z0-9][a-z0-9_-]*\z/)
            errors << "Gem name must be a valid RubyGems name"
          end
        end

        # Validate models array
        def validate_models(models, warnings)
          if models.empty?
            warnings << "No models specified for provider"
          end

          models.each do |model|
            unless model.is_a?(String) && !model.strip.empty?
              warnings << "Invalid model entry: #{model.inspect} (must be non-empty string)"
            end
          end
        end

        # Validate API key configuration
        def validate_api_key(api_key_config, errors, warnings)
          if api_key_config.is_a?(Hash)
            # Check for valid configuration keys
            valid_keys = %w[env value required description]
            unknown_keys = api_key_config.keys - valid_keys

            unless unknown_keys.empty?
              warnings << "Unknown API key configuration keys: #{unknown_keys.join(', ')}"
            end

            # Must have either env or value
            unless api_key_config["env"] || api_key_config["value"]
              errors << "API key configuration must specify either 'env' or 'value'"
            end

            # Warn if using direct value
            if api_key_config["value"]
              warnings << "Using direct API key value in configuration is not recommended for security"
            end

            # Validate env var name format
            if api_key_config["env"] && !api_key_config["env"].match?(/\A[A-Z][A-Z0-9_]*\z/)
              warnings << "Environment variable name should be uppercase with underscores"
            end
          else
            errors << "API key configuration must be a Hash"
          end
        end

        # Validate capabilities array
        def validate_capabilities(capabilities, warnings)
          invalid_capabilities = capabilities - VALID_CAPABILITIES

          unless invalid_capabilities.empty?
            warnings << "Unknown capabilities: #{invalid_capabilities.join(', ')}. " \
                      "Valid capabilities: #{VALID_CAPABILITIES.join(', ')}"
          end
        end

        # Validate default options
        def validate_default_options(options, warnings)

          # Validate temperature range
          if options["temperature"]
            temp = options["temperature"]
            if temp.is_a?(Numeric)
              if temp < 0.0 || temp > 2.0
                warnings << "Temperature should be between 0.0 and 2.0, got #{temp}"
              end
            else
              warnings << "Temperature must be a number, got #{temp.class}"
            end
          end

          # Validate max_tokens
          if options["max_tokens"]
            max_tokens = options["max_tokens"]
            if max_tokens.is_a?(Integer)
              if max_tokens <= 0
                warnings << "max_tokens must be positive, got #{max_tokens}"
              end
            else
              warnings << "max_tokens must be an integer, got #{max_tokens.class}"
            end
          end
        end

        # Validate aliases structure
        def validate_aliases(aliases, errors, warnings)
          unless aliases.is_a?(Hash)
            errors << "Aliases must be a Hash, got #{aliases.class}"
            return
          end

          # Check for valid sections
          valid_sections = %w[global model]
          unknown_sections = aliases.keys - valid_sections
          unless unknown_sections.empty?
            warnings << "Unknown alias sections: #{unknown_sections.join(', ')}. Valid sections: global, model"
          end

          # Validate global aliases if present
          if aliases["global"]
            unless aliases["global"].is_a?(Hash)
              errors << "Global aliases must be a Hash, got #{aliases["global"].class}"
            else
              aliases["global"].each do |key, value|
                unless value.is_a?(String)
                  errors << "Global alias '#{key}' must be a String, got #{value.class}"
                end
              end
            end
          end

          # Validate model aliases if present
          if aliases["model"]
            unless aliases["model"].is_a?(Hash)
              errors << "Model aliases must be a Hash, got #{aliases["model"].class}"
            else
              aliases["model"].each do |key, value|
                unless value.is_a?(String)
                  errors << "Model alias '#{key}' must be a String, got #{value.class}"
                end
              end
            end
          end
        end
      end
    end
  end
end