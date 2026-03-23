# frozen_string_literal: true

module Ace
  module Support
    module Models
      # Base error class for ace-support-models gem
      class Error < StandardError; end

      # Network-related errors
      class NetworkError < Error; end

      # API response errors
      class ApiError < Error
        attr_reader :status_code

        def initialize(message, status_code: nil)
          @status_code = status_code
          super(message)
        end
      end

      # Cache-related errors
      class CacheError < Error; end

      # Validation errors
      class ValidationError < Error; end

      # Model not found error
      class ModelNotFoundError < ValidationError
        attr_reader :model_id, :suggestions

        def initialize(model_id, suggestions: [])
          @model_id = model_id
          @suggestions = suggestions
          message = "Model '#{model_id}' not found"
          message += ". Did you mean: #{suggestions.join(", ")}?" if suggestions.any?
          super(message)
        end
      end

      # Configuration errors
      class ConfigError < Error; end

      # Provider not found error
      class ProviderNotFoundError < ValidationError
        attr_reader :provider_id

        def initialize(provider_id)
          @provider_id = provider_id
          super("Provider '#{provider_id}' not found")
        end
      end
    end
  end
end
