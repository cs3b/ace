# frozen_string_literal: true

module CodingAgentTools
  module Models
    # LlmModelInfo represents an AI model with its metadata including pricing information
    # This is a pure data structure following ATOM architecture - no external IO
    LlmModelInfo = Struct.new(:id, :name, :description, :default, :context_size, :max_output_tokens, :pricing_info,
      keyword_init: true) do
      # Check if this is the default model
      # @return [Boolean]
      def default?
        default
      end

      # String representation for display
      # @return [String]
      def to_s
        output = []
        output << "ID: #{id}"
        output << "Name: #{name}"
        output << "Description: #{description}"
        output << "Context Size: #{format_context_size}" if context_size
        output << "Max Output: #{format_max_output_tokens}" if max_output_tokens
        output << 'Status: Default model' if default?

        if has_pricing?
          output << "Pricing: Input $#{pricing_info.input_cost_per_token}/token, Output $#{pricing_info.output_cost_per_token}/token"
        end

        output.join("\n")
      end

      # Hash representation
      # @return [Hash]
      def to_h
        base_hash = {
          id: id,
          name: name,
          description: description,
          default: default,
          context_size: context_size,
          max_output_tokens: max_output_tokens
        }

        base_hash[:pricing] = pricing_info.to_h if has_pricing?
        base_hash
      end

      # JSON representation
      # @return [Hash] JSON-compatible hash
      def to_json_hash
        to_h
      end

      # Equality comparison
      # @param other [LlmModelInfo]
      # @return [Boolean]
      def ==(other)
        return false unless other.is_a?(LlmModelInfo)

        id == other.id &&
          name == other.name &&
          description == other.description &&
          default == other.default &&
          context_size == other.context_size &&
          max_output_tokens == other.max_output_tokens &&
          pricing_info == other.pricing_info
      end

      # Hash code for using as hash keys
      # @return [Integer]
      def hash
        [id, name, description, default, context_size, max_output_tokens, pricing_info].hash
      end

      # Format context size for human-readable display
      # @return [String]
      def format_context_size
        return 'Unknown' if context_size.nil?

        if context_size >= 1_000_000
          "#{(context_size / 1_000_000.0).round(1)}M tokens"
        elsif context_size >= 1_000
          "#{(context_size / 1_000.0).round(1)}K tokens"
        else
          "#{context_size} tokens"
        end
      end

      # Format max output tokens for human-readable display
      # @return [String]
      def format_max_output_tokens
        return 'Unknown' if max_output_tokens.nil?

        if max_output_tokens >= 1_000_000
          "#{(max_output_tokens / 1_000_000.0).round(1)}M tokens"
        elsif max_output_tokens >= 1_000
          "#{(max_output_tokens / 1_000.0).round(1)}K tokens"
        else
          "#{max_output_tokens} tokens"
        end
      end

      # Check if pricing information is available
      # @return [Boolean]
      def has_pricing?
        !pricing_info.nil?
      end

      # Calculate cost for given token usage
      # @param input_tokens [Integer] Number of input tokens
      # @param output_tokens [Integer] Number of output tokens
      # @param cache_creation_tokens [Integer] Number of cache creation tokens (default: 0)
      # @param cache_read_tokens [Integer] Number of cache read tokens (default: 0)
      # @return [CostCalculation, nil] Cost calculation or nil if no pricing info
      def calculate_cost(input_tokens: 0, output_tokens: 0, cache_creation_tokens: 0, cache_read_tokens: 0)
        return nil unless has_pricing?

        pricing_info.calculate_cost(
          input_tokens: input_tokens,
          output_tokens: output_tokens,
          cache_creation_tokens: cache_creation_tokens,
          cache_read_tokens: cache_read_tokens
        )
      end

      # Check if model supports caching features
      # @return [Boolean] True if caching is supported
      def supports_caching?
        has_pricing? && pricing_info.supports_caching?
      end

      # Get input cost per token
      # @return [Float, nil] Cost per input token or nil if no pricing
      def input_cost_per_token
        has_pricing? ? pricing_info.input_cost_per_token : nil
      end

      # Get output cost per token
      # @return [Float, nil] Cost per output token or nil if no pricing
      def output_cost_per_token
        has_pricing? ? pricing_info.output_cost_per_token : nil
      end

      alias_method :eql?, :==
    end
  end
end
