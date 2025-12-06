# frozen_string_literal: true

# Try to load ace-core if available
begin
  require "ace/core"
rescue LoadError
  # ace-core is optional for basic functionality
end

require_relative "models_dev/version"
require_relative "models_dev/errors"

# Atoms - Pure functions
require_relative "models_dev/atoms/cache_path_resolver"
require_relative "models_dev/atoms/api_fetcher"
require_relative "models_dev/atoms/json_parser"
require_relative "models_dev/atoms/file_reader"
require_relative "models_dev/atoms/file_writer"
require_relative "models_dev/atoms/model_filter"
require_relative "models_dev/atoms/provider_config_reader"
require_relative "models_dev/atoms/provider_config_writer"

# Models - Data structures
require_relative "models_dev/models/provider_info"
require_relative "models_dev/models/model_info"
require_relative "models_dev/models/pricing_info"
require_relative "models_dev/models/diff_result"

# Molecules - Composed operations
require_relative "models_dev/molecules/cache_manager"
require_relative "models_dev/molecules/model_validator"
require_relative "models_dev/molecules/cost_calculator"
require_relative "models_dev/molecules/diff_generator"
require_relative "models_dev/molecules/model_searcher"
require_relative "models_dev/molecules/provider_sync_diff"

# Organisms - Business logic
require_relative "models_dev/organisms/sync_orchestrator"
require_relative "models_dev/organisms/provider_sync_orchestrator"

# CLI subcommands (must be after molecules/organisms are loaded)
require_relative "models_dev/cli/cache_cli"
require_relative "models_dev/cli/providers_cli"
require_relative "models_dev/cli/models_cli"

module Ace
  module LLM
    module ModelsDev
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
