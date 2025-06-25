# frozen_string_literal: true

require_relative "usage_metadata"
require_relative "pricing"

module CodingAgentTools
  module Models
    # UsageMetadataWithCost extends UsageMetadata to include cost calculation
    # This maintains backward compatibility while adding cost tracking capabilities
    class UsageMetadataWithCost < UsageMetadata
      # Define the structure for usage metadata with cost information
      # @param cost_calculation [Models::Pricing::CostCalculation, nil] Cost breakdown for this usage
      # @param all other params - same as UsageMetadata
      def initialize(
        input_tokens:,
        output_tokens:,
        total_tokens:,
        took:,
        provider:,
        model:,
        timestamp:,
        finish_reason:,
        provider_specific: nil,
        safety_ratings: nil,
        cached_tokens: nil,
        cost_calculation: nil
      )
        # Set cost calculation before calling super to avoid frozen object modification
        @cost_calculation = cost_calculation

        super(
          input_tokens: input_tokens,
          output_tokens: output_tokens,
          total_tokens: total_tokens,
          took: took,
          provider: provider,
          model: model,
          timestamp: timestamp,
          finish_reason: finish_reason,
          provider_specific: provider_specific,
          safety_ratings: safety_ratings,
          cached_tokens: cached_tokens
        )

        # No need to call freeze again as super already does it
      end

      attr_reader :cost_calculation

      # Check if cost information is available
      # @return [Boolean] True if cost calculation exists
      def has_cost_info?
        !cost_calculation.nil?
      end

      # Get total cost in USD
      # @return [Float] Total cost, 0.0 if no cost info
      def total_cost
        return 0.0 unless has_cost_info?
        cost_calculation.total_cost.to_f
      end

      # Get input cost in USD
      # @return [Float] Input token cost, 0.0 if no cost info
      def input_cost
        return 0.0 unless has_cost_info?
        cost_calculation.input_cost.to_f
      end

      # Get output cost in USD
      # @return [Float] Output token cost, 0.0 if no cost info
      def output_cost
        return 0.0 unless has_cost_info?
        cost_calculation.output_cost.to_f
      end

      # Get cache cost in USD (creation + read)
      # @return [Float] Total cache cost, 0.0 if no cost info
      def cache_cost
        return 0.0 unless has_cost_info?
        (cost_calculation.cache_creation_cost + cost_calculation.cache_read_cost).to_f
      end

      # Calculate cost per token efficiency
      # @return [Float] Cost per token (total cost / total tokens)
      def cost_per_token
        return 0.0 if total_tokens.zero? || !has_cost_info?
        total_cost / total_tokens.to_f
      end

      # Calculate cost per second efficiency
      # @return [Float] Cost per second (total cost / execution time)
      def cost_per_second
        return 0.0 if took.zero? || !has_cost_info?
        total_cost / took
      end

      # Enhanced hash representation including cost data
      # @return [Hash] Hash representation with cost information
      def to_h
        base_hash = super

        if has_cost_info?
          base_hash[:cost] = cost_calculation.to_json_hash
        end

        base_hash
      end

      # Enhanced JSON representation including cost data
      # @return [Hash] JSON-compatible hash with cost information
      def to_json_hash
        to_h
      end

      # Format cost summary for display
      # @return [String] Human-readable cost summary
      def cost_summary
        return "Cost: N/A" unless has_cost_info?

        lines = []
        lines << "Cost Summary:"
        lines << "  Input: #{cost_calculation.format_cost(cost_calculation.input_cost)}"
        lines << "  Output: #{cost_calculation.format_cost(cost_calculation.output_cost)}"

        if cost_calculation.caching_used?
          lines << "  Cache Creation: #{cost_calculation.format_cost(cost_calculation.cache_creation_cost)}"
          lines << "  Cache Read: #{cost_calculation.format_cost(cost_calculation.cache_read_cost)}"
        end

        lines << "  Total: #{cost_calculation.formatted_total} USD"
        lines.join("\n")
      end

      # Create UsageMetadataWithCost from base UsageMetadata and CostCalculation
      # @param usage_metadata [UsageMetadata] Base usage metadata
      # @param cost_calculation [CostCalculation, nil] Cost calculation result
      # @return [UsageMetadataWithCost] Enhanced metadata with cost info
      def self.from_usage_metadata(usage_metadata, cost_calculation = nil)
        new(
          input_tokens: usage_metadata.input_tokens,
          output_tokens: usage_metadata.output_tokens,
          total_tokens: usage_metadata.total_tokens,
          took: usage_metadata.took,
          provider: usage_metadata.provider,
          model: usage_metadata.model,
          timestamp: usage_metadata.timestamp,
          finish_reason: usage_metadata.finish_reason,
          provider_specific: usage_metadata.provider_specific,
          safety_ratings: usage_metadata.safety_ratings,
          cached_tokens: usage_metadata.cached_tokens,
          cost_calculation: cost_calculation
        )
      end
    end
  end
end
