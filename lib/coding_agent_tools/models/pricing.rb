# frozen_string_literal: true

module CodingAgentTools
  module Models
    module Pricing
      # PricingInfo represents pricing data for a specific LLM model
      # This mirrors the LiteLLM JSON schema structure and follows ATOM architecture
      class PricingInfo
        # Initialize pricing information for a model
        # @param input_cost_per_token [Float] Cost per input token
        # @param output_cost_per_token [Float] Cost per output token
        # @param cache_creation_input_token_cost [Float, nil] Cost per cache creation token
        # @param cache_read_input_token_cost [Float, nil] Cost per cache read token
        # @param max_tokens [Integer, nil] Maximum token limit
        # @param max_input_tokens [Integer, nil] Maximum input token limit
        # @param max_output_tokens [Integer, nil] Maximum output token limit
        # @param input_cost_per_pixel [Float, nil] Cost per input pixel (for vision models)
        # @param mode [String] Model mode/type
        # @param supports_function_calling [Boolean] Whether model supports function calling
        # @param supports_parallel_function_calling [Boolean] Whether model supports parallel function calls
        # @param supports_vision [Boolean] Whether model supports vision/image inputs
        def initialize(
          input_cost_per_token:,
          output_cost_per_token:,
          cache_creation_input_token_cost: nil,
          cache_read_input_token_cost: nil,
          max_tokens: nil,
          max_input_tokens: nil,
          max_output_tokens: nil,
          input_cost_per_pixel: nil,
          mode: "chat",
          supports_function_calling: false,
          supports_parallel_function_calling: false,
          supports_vision: false
        )
          @input_cost_per_token = input_cost_per_token
          @output_cost_per_token = output_cost_per_token
          @cache_creation_input_token_cost = cache_creation_input_token_cost
          @cache_read_input_token_cost = cache_read_input_token_cost
          @max_tokens = max_tokens
          @max_input_tokens = max_input_tokens
          @max_output_tokens = max_output_tokens
          @input_cost_per_pixel = input_cost_per_pixel
          @mode = mode
          @supports_function_calling = supports_function_calling
          @supports_parallel_function_calling = supports_parallel_function_calling
          @supports_vision = supports_vision

          freeze
        end

        attr_reader :input_cost_per_token, :output_cost_per_token,
          :cache_creation_input_token_cost, :cache_read_input_token_cost,
          :max_tokens, :max_input_tokens, :max_output_tokens,
          :input_cost_per_pixel, :mode,
          :supports_function_calling, :supports_parallel_function_calling,
          :supports_vision

        # Check if model supports caching
        # @return [Boolean] True if cache pricing is available
        def supports_caching?
          !cache_creation_input_token_cost.nil? || !cache_read_input_token_cost.nil?
        end

        # Calculate cost for given token usage
        # @param input_tokens [Integer] Number of input tokens
        # @param output_tokens [Integer] Number of output tokens
        # @param cache_creation_tokens [Integer] Number of cache creation tokens
        # @param cache_read_tokens [Integer] Number of cache read tokens
        # @return [CostCalculation] Detailed cost breakdown
        def calculate_cost(input_tokens: 0, output_tokens: 0, cache_creation_tokens: 0, cache_read_tokens: 0)
          input_cost = BigDecimal(input_tokens.to_s) * BigDecimal(input_cost_per_token.to_s)
          output_cost = BigDecimal(output_tokens.to_s) * BigDecimal(output_cost_per_token.to_s)

          cache_creation_cost = if cache_creation_input_token_cost && cache_creation_tokens > 0
            BigDecimal(cache_creation_tokens.to_s) * BigDecimal(cache_creation_input_token_cost.to_s)
          else
            BigDecimal(0)
          end

          cache_read_cost = if cache_read_input_token_cost && cache_read_tokens > 0
            BigDecimal(cache_read_tokens.to_s) * BigDecimal(cache_read_input_token_cost.to_s)
          else
            BigDecimal(0)
          end

          total_cost = input_cost + output_cost + cache_creation_cost + cache_read_cost

          CostCalculation.new(
            input_cost: input_cost,
            output_cost: output_cost,
            cache_creation_cost: cache_creation_cost,
            cache_read_cost: cache_read_cost,
            total_cost: total_cost,
            currency: "USD"
          )
        end

        # Convert to hash representation
        # @return [Hash] Hash representation
        def to_h
          {
            input_cost_per_token: input_cost_per_token,
            output_cost_per_token: output_cost_per_token,
            cache_creation_input_token_cost: cache_creation_input_token_cost,
            cache_read_input_token_cost: cache_read_input_token_cost,
            max_tokens: max_tokens,
            max_input_tokens: max_input_tokens,
            max_output_tokens: max_output_tokens,
            input_cost_per_pixel: input_cost_per_pixel,
            mode: mode,
            supports_function_calling: supports_function_calling,
            supports_parallel_function_calling: supports_parallel_function_calling,
            supports_vision: supports_vision
          }.compact
        end

        # Create PricingInfo from LiteLLM data structure
        # @param litellm_data [Hash] Raw LiteLLM pricing data
        # @return [PricingInfo] New pricing info instance
        def self.from_litellm(litellm_data)
          new(
            input_cost_per_token: litellm_data["input_cost_per_token"] || 0.0,
            output_cost_per_token: litellm_data["output_cost_per_token"] || 0.0,
            cache_creation_input_token_cost: litellm_data["cache_creation_input_token_cost"],
            cache_read_input_token_cost: litellm_data["cache_read_input_token_cost"],
            max_tokens: litellm_data["max_tokens"],
            max_input_tokens: litellm_data["max_input_tokens"],
            max_output_tokens: litellm_data["max_output_tokens"],
            input_cost_per_pixel: litellm_data["input_cost_per_pixel"],
            mode: litellm_data["mode"] || "chat",
            supports_function_calling: litellm_data["supports_function_calling"] || false,
            supports_parallel_function_calling: litellm_data["supports_parallel_function_calling"] || false,
            supports_vision: litellm_data["supports_vision"] || false
          )
        end
      end

      # CostCalculation represents the result of a cost calculation
      # This provides detailed breakdown of costs by token type
      class CostCalculation
        def initialize(input_cost:, output_cost:, cache_creation_cost:, cache_read_cost:, total_cost:, currency: "USD")
          @input_cost = input_cost
          @output_cost = output_cost
          @cache_creation_cost = cache_creation_cost
          @cache_read_cost = cache_read_cost
          @total_cost = total_cost
          @currency = currency

          freeze
        end

        attr_reader :input_cost, :output_cost, :cache_creation_cost, :cache_read_cost, :total_cost, :currency

        # Check if caching was used
        # @return [Boolean] True if any cache costs are non-zero
        def caching_used?
          cache_creation_cost > 0 || cache_read_cost > 0
        end

        # Format cost for display (6 decimal places precision)
        # @param cost [BigDecimal] Cost value
        # @return [String] Formatted cost string
        def format_cost(cost)
          "$#{cost.round(6).to_f}"
        end

        # Format total cost for display
        # @return [String] Formatted total cost
        def formatted_total
          format_cost(total_cost)
        end

        # Convert to hash representation matching ccusage format
        # @return [Hash] Cost breakdown hash
        def to_h
          {
            input: input_cost.to_f.round(6),
            output: output_cost.to_f.round(6),
            cache_creation: cache_creation_cost.to_f.round(6),
            cache_read: cache_read_cost.to_f.round(6),
            total: total_cost.to_f.round(6),
            currency: currency
          }
        end

        # JSON representation
        # @return [Hash] JSON-compatible hash
        def to_json_hash
          to_h
        end
      end
    end
  end
end
