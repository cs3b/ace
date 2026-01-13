# frozen_string_literal: true

require "ace/core"

require_relative "version"
require_relative "errors"

# Atoms - Pure functions
require_relative "atoms/cache_path_resolver"
require_relative "atoms/api_fetcher"
require_relative "atoms/json_parser"
require_relative "atoms/file_reader"
require_relative "atoms/file_writer"
require_relative "atoms/model_filter"
require_relative "atoms/provider_config_reader"
require_relative "atoms/provider_config_writer"
require_relative "atoms/model_name_canonicalizer"

# Models - Data structures
require_relative "models/provider_info"
require_relative "models/model_info"
require_relative "models/pricing_info"
require_relative "models/diff_result"

# Molecules - Composed operations
require_relative "molecules/cache_manager"
require_relative "molecules/model_validator"
require_relative "molecules/cost_calculator"
require_relative "molecules/diff_generator"
require_relative "molecules/model_searcher"
require_relative "molecules/provider_sync_diff"

# Organisms - Business logic
require_relative "organisms/sync_orchestrator"
require_relative "organisms/provider_sync_orchestrator"

module Ace
  module Support
    module Models
      API_URL = "https://models.dev/api.json"

      class << self
        # Get the default cache directory
        # @return [String] Path to cache directory
        def cache_dir
          Atoms::CachePathResolver.resolve
        end

        # Sync models from API
        # @param force [Boolean] Force sync even if cache is fresh
        # @return [Hash] Sync result with stats
        def sync(force: false)
          Organisms::SyncOrchestrator.new.sync(force: force)
        end

        # Validate a model exists
        # @param model_id [String] Model ID in format provider:model
        # @return [Boolean] true if valid
        # @raise [ModelNotFoundError] if model doesn't exist
        def validate(model_id)
          Molecules::ModelValidator.new.validate(model_id)
        end

        # Validate a model exists (returns boolean, no exception)
        # @param model_id [String] Model ID in format provider:model
        # @return [Boolean] true if valid, false otherwise
        def valid?(model_id)
          validate(model_id)
          true
        rescue ModelNotFoundError, ProviderNotFoundError
          false
        end

        # Calculate cost for a query
        # @param model_id [String] Model ID
        # @param input_tokens [Integer] Input token count
        # @param output_tokens [Integer] Output token count
        # @param reasoning_tokens [Integer] Reasoning token count (optional)
        # @return [Hash] Cost breakdown
        def cost(model_id, input_tokens:, output_tokens:, reasoning_tokens: 0)
          Molecules::CostCalculator.new.calculate(
            model_id,
            input_tokens: input_tokens,
            output_tokens: output_tokens,
            reasoning_tokens: reasoning_tokens
          )
        end

        # Get diff between cached versions
        # @return [Models::DiffResult] Changes since last sync
        def diff
          Molecules::DiffGenerator.new.generate
        end
      end
    end
  end
end
