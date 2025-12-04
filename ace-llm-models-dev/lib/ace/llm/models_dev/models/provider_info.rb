# frozen_string_literal: true

module Ace
  module LLM
    module ModelsDev
      module Models
        # Represents information about a provider
        class ProviderInfo
          attr_reader :id, :name, :env_keys, :npm_package, :api_url, :doc_url, :models

          # Initialize provider info
          def initialize(attrs = {})
            @id = attrs[:id]
            @name = attrs[:name]
            @env_keys = attrs[:env_keys] || []
            @npm_package = attrs[:npm_package]
            @api_url = attrs[:api_url]
            @doc_url = attrs[:doc_url]
            @models = attrs[:models] || {}
          end

          # Create from API hash
          # @param hash [Hash] Provider hash from API
          # @return [ProviderInfo] Parsed provider info
          def self.from_hash(hash)
            provider_id = hash["id"]
            models_hash = hash["models"] || {}

            models = models_hash.transform_values do |model_hash|
              ModelInfo.from_hash(model_hash, provider_id: provider_id)
            end

            new(
              id: provider_id,
              name: hash["name"],
              env_keys: Array(hash["env"]),
              npm_package: hash["npm"],
              api_url: hash["api"],
              doc_url: hash["doc"],
              models: models
            )
          end

          # Get model by ID
          # @param model_id [String] Model ID
          # @return [ModelInfo, nil] Model info or nil
          def model(model_id)
            models[model_id]
          end

          # List all model IDs
          # @return [Array<String>] Model IDs
          def model_ids
            models.keys
          end

          # Count models
          # @return [Integer] Number of models
          def model_count
            models.size
          end

          # Convert to hash
          # @return [Hash]
          def to_h
            {
              id: id,
              name: name,
              env_keys: env_keys,
              npm_package: npm_package,
              api_url: api_url,
              doc_url: doc_url,
              model_count: model_count,
              models: models.transform_values(&:to_h)
            }
          end
        end
      end
    end
  end
end
