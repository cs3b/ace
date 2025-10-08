# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../lib/ace/llm/atoms/provider_config_validator"

module Ace
  module LLM
    class TestProviderConfigValidator < Minitest::Test
      def setup
        @validator = Atoms::ProviderConfigValidator.new
      end

      def test_valid_configuration
        config = {
          "name" => "test-provider",
          "class" => "TestProvider::Client",
          "gem" => "test-provider-gem",
          "models" => ["model1", "model2"],
          "api_key" => {
            "env" => "TEST_API_KEY",
            "required" => true
          }
        }

        result = @validator.validate(config)
        assert result.valid?
        assert_empty result.errors
      end

      def test_missing_required_fields
        config = {
          "name" => "test"
          # Missing 'class' and 'gem'
        }

        result = @validator.validate(config)
        refute result.valid?
        assert_includes result.errors.join(" "), "Missing required field: 'class'"
        assert_includes result.errors.join(" "), "Missing required field: 'gem'"
      end

      def test_invalid_name_format
        config = {
          "name" => "test provider!", # Invalid characters
          "class" => "TestProvider::Client",
          "gem" => "test-gem"
        }

        result = @validator.validate(config)
        refute result.valid?
        assert_includes result.errors.join(" "), "Provider name must contain only"
      end

      def test_invalid_class_format
        config = {
          "name" => "test",
          "class" => "not::a::Valid::class", # Starts with lowercase
          "gem" => "test-gem"
        }

        result = @validator.validate(config)
        refute result.valid?
        assert_includes result.errors.join(" "), "valid Ruby class name"
      end

      def test_invalid_gem_format
        config = {
          "name" => "test",
          "class" => "Test::Client",
          "gem" => "Test-Gem" # Should be lowercase
        }

        result = @validator.validate(config)
        refute result.valid?
        assert_includes result.errors.join(" "), "valid RubyGems name"
      end

      def test_empty_models_warning
        config = {
          "name" => "test",
          "class" => "Test::Client",
          "gem" => "test-gem",
          "models" => []
        }

        result = @validator.validate(config)
        assert result.valid?
        assert_includes result.warnings.join(" "), "No models specified"
      end

      def test_invalid_model_entry
        config = {
          "name" => "test",
          "class" => "Test::Client",
          "gem" => "test-gem",
          "models" => ["valid-model", nil, "", 123]
        }

        result = @validator.validate(config)
        assert result.valid?
        assert result.warnings.any? { |w| w.include?("Invalid model entry") }
      end

      def test_api_key_with_env
        config = {
          "name" => "test",
          "class" => "Test::Client",
          "gem" => "test-gem",
          "api_key" => {
            "env" => "TEST_API_KEY",
            "required" => true
          }
        }

        result = @validator.validate(config)
        assert result.valid?
        assert_empty result.errors
      end

      def test_api_key_with_direct_value_warning
        config = {
          "name" => "test",
          "class" => "Test::Client",
          "gem" => "test-gem",
          "api_key" => {
            "value" => "direct-api-key-123"
          }
        }

        result = @validator.validate(config)
        assert result.valid?
        assert_includes result.warnings.join(" "), "not recommended for security"
      end

      def test_api_key_missing_env_or_value
        config = {
          "name" => "test",
          "class" => "Test::Client",
          "gem" => "test-gem",
          "api_key" => {
            "required" => true
          }
        }

        result = @validator.validate(config)
        refute result.valid?
        assert_includes result.errors.join(" "), "must specify either 'env' or 'value'"
      end

      def test_invalid_capabilities
        config = {
          "name" => "test",
          "class" => "Test::Client",
          "gem" => "test-gem",
          "capabilities" => ["text_generation", "invalid_capability"]
        }

        result = @validator.validate(config)
        assert result.valid?
        assert_includes result.warnings.join(" "), "Unknown capabilities"
      end

      def test_temperature_validation
        # Valid temperature
        config1 = {
          "name" => "test",
          "class" => "Test::Client",
          "gem" => "test-gem",
          "default_options" => {
            "temperature" => 0.7
          }
        }

        result1 = @validator.validate(config1)
        assert result1.valid?

        # Invalid temperature (too high)
        config2 = {
          "name" => "test",
          "class" => "Test::Client",
          "gem" => "test-gem",
          "default_options" => {
            "temperature" => 3.0
          }
        }

        result2 = @validator.validate(config2)
        assert result2.valid?
        assert_includes result2.warnings.join(" "), "Temperature should be between"
      end

      def test_max_tokens_validation
        # Valid max_tokens
        config1 = {
          "name" => "test",
          "class" => "Test::Client",
          "gem" => "test-gem",
          "default_options" => {
            "max_tokens" => 1000
          }
        }

        result1 = @validator.validate(config1)
        assert result1.valid?

        # Invalid max_tokens (negative)
        config2 = {
          "name" => "test",
          "class" => "Test::Client",
          "gem" => "test-gem",
          "default_options" => {
            "max_tokens" => -100
          }
        }

        result2 = @validator.validate(config2)
        assert result2.valid?
        assert_includes result2.warnings.join(" "), "max_tokens must be positive"
      end

      def test_unknown_fields_warning
        config = {
          "name" => "test",
          "class" => "Test::Client",
          "gem" => "test-gem",
          "unknown_field" => "value",
          "another_unknown" => 123
        }

        result = @validator.validate(config)
        assert result.valid?
        assert_includes result.warnings.join(" "), "Unknown fields"
        assert_includes result.warnings.join(" "), "unknown_field"
        assert_includes result.warnings.join(" "), "another_unknown"
      end

      def test_validate_batch
        configs = [
          {
            "name" => "valid",
            "class" => "Valid::Client",
            "gem" => "valid-gem"
          },
          {
            "name" => "invalid",
            "class" => "Invalid"
            # Missing gem
          }
        ]

        results = @validator.validate_batch(configs)

        assert results["valid"].valid?
        refute results["invalid"].valid?
      end
    end
  end
end