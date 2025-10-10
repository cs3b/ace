# frozen_string_literal: true

require "bigdecimal"
require_relative "pricing_fetcher"
require_relative "models/pricing"

module CodingAgentTools
  # CostTracker provides comprehensive cost tracking for LLM usage
  # Integrates with LiteLLM pricing data for authoritative cost calculations
  class CostTracker
    class CostTrackingError < StandardError; end

    class ModelNotFoundError < CostTrackingError; end

    def initialize(pricing_fetcher: nil)
      @pricing_fetcher = pricing_fetcher || PricingFetcher.new
    end

    attr_reader :pricing_fetcher

    # Calculate cost for LLM usage with token breakdown
    # @param model_id [String] Model identifier (e.g., "claude-3-5-sonnet", "gpt-4o")
    # @param input_tokens [Integer] Number of input tokens
    # @param output_tokens [Integer] Number of output tokens
    # @param cache_creation_tokens [Integer] Number of cache creation tokens (default: 0)
    # @param cache_read_tokens [Integer] Number of cache read tokens (default: 0)
    # @return [Models::Pricing::CostCalculation] Detailed cost breakdown
    # @raise [ModelNotFoundError] If model pricing is not available
    def calculate_cost(model_id:, input_tokens: 0, output_tokens: 0, cache_creation_tokens: 0, cache_read_tokens: 0)
      pricing_data = get_model_pricing(model_id)

      unless pricing_data
        raise ModelNotFoundError,
          "Pricing data not found for model: #{model_id}. Use CostTracker#available_models to see supported models."
      end

      pricing_info = Models::Pricing::PricingInfo.from_litellm(pricing_data)

      pricing_info.calculate_cost(
        input_tokens: input_tokens,
        output_tokens: output_tokens,
        cache_creation_tokens: cache_creation_tokens,
        cache_read_tokens: cache_read_tokens
      )
    end

    # Calculate cost from usage metadata
    # @param usage_metadata [Models::UsageMetadata] Usage metadata object
    # @return [Models::Pricing::CostCalculation] Cost calculation result
    # @raise [ModelNotFoundError] If model pricing is not available
    def calculate_cost_from_metadata(usage_metadata)
      calculate_cost(
        model_id: usage_metadata.model,
        input_tokens: usage_metadata.input_tokens,
        output_tokens: usage_metadata.output_tokens,
        cache_creation_tokens: 0, # Most providers don't distinguish cache creation vs read
        cache_read_tokens: usage_metadata.cached_tokens || 0
      )
    end

    # Check if model pricing is available
    # @param model_id [String] Model identifier
    # @return [Boolean] True if pricing data exists
    def has_pricing_for_model?(model_id)
      @pricing_fetcher.has_model_pricing?(model_id)
    end

    # Get list of all models with available pricing
    # @return [Array<String>] List of supported model identifiers
    def available_models
      @pricing_fetcher.available_models
    end

    # Get pricing information for a model
    # @param model_id [String] Model identifier
    # @return [Models::Pricing::PricingInfo, nil] Pricing info or nil if not found
    def get_pricing_info(model_id)
      pricing_data = get_model_pricing(model_id)
      return nil unless pricing_data

      Models::Pricing::PricingInfo.from_litellm(pricing_data)
    end

    # Refresh pricing data from LiteLLM
    # @return [Hash] Fresh pricing data
    def refresh_pricing_data!
      @pricing_fetcher.refresh!
    end

    # Get pricing cache information
    # @return [Hash] Cache metadata
    def pricing_cache_info
      @pricing_fetcher.cache_info
    end

    # Handle free/local models (like LMStudio) that have no cost
    # @param model_id [String] Model identifier
    # @return [Boolean] True if model is free/local
    def free_model?(model_id)
      # LMStudio models are always free since they run locally
      return true if model_id&.include?("lmstudio") || model_id&.include?("local")

      # Some Google models are free in certain tiers
      return true if model_id == "gemini-1.5-flash" # Free tier model

      false
    end

    # Create zero-cost calculation for free models
    # @return [Models::Pricing::CostCalculation] Zero cost calculation
    def zero_cost_calculation
      Models::Pricing::CostCalculation.new(
        input_cost: BigDecimal(0),
        output_cost: BigDecimal(0),
        cache_creation_cost: BigDecimal(0),
        cache_read_cost: BigDecimal(0),
        total_cost: BigDecimal(0),
        currency: "USD"
      )
    end

    # Calculate cost with automatic fallback for free models
    # @param model_id [String] Model identifier
    # @param input_tokens [Integer] Number of input tokens
    # @param output_tokens [Integer] Number of output tokens
    # @param cache_creation_tokens [Integer] Number of cache creation tokens
    # @param cache_read_tokens [Integer] Number of cache read tokens
    # @return [Models::Pricing::CostCalculation] Cost calculation (zero for free models)
    def calculate_cost_with_fallback(model_id:, input_tokens: 0, output_tokens: 0, cache_creation_tokens: 0,
      cache_read_tokens: 0)
      return zero_cost_calculation if free_model?(model_id)

      begin
        calculate_cost(
          model_id: model_id,
          input_tokens: input_tokens,
          output_tokens: output_tokens,
          cache_creation_tokens: cache_creation_tokens,
          cache_read_tokens: cache_read_tokens
        )
      rescue ModelNotFoundError
        # If pricing data is missing, return zero cost with warning
        # This allows the system to continue functioning even when pricing data is incomplete
        zero_cost_calculation
      end
    end

    # Get model search suggestions when model is not found
    # @param model_id [String] Model identifier that wasn't found
    # @return [Array<String>] List of similar model names
    def get_model_suggestions(model_id)
      all_models = available_models
      normalized_input = model_id.downcase.gsub(/[-_]/, "")

      # Find models that contain similar substrings
      suggestions = all_models.select do |model|
        normalized_model = model.downcase.gsub(/[-_]/, "")
        normalized_model.include?(normalized_input) || normalized_input.include?(normalized_model)
      end

      suggestions.first(5) # Return top 5 suggestions
    end

    private

    # Get pricing data for model with fuzzy matching
    # @param model_id [String] Model identifier
    # @return [Hash, nil] Raw LiteLLM pricing data
    def get_model_pricing(model_id)
      @pricing_fetcher.get_model_pricing(model_id)
    end
  end
end
