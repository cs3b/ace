# frozen_string_literal: true

module Ace
  module LLM
    module ModelsDev
      module Models
        # Represents pricing information for a model (per million tokens)
        class PricingInfo
          attr_reader :input, :output, :reasoning, :cache_read, :cache_write

          # Initialize pricing info
          # @param input [Float, nil] Input cost per million tokens
          # @param output [Float, nil] Output cost per million tokens
          # @param reasoning [Float, nil] Reasoning cost per million tokens
          # @param cache_read [Float, nil] Cache read cost per million tokens
          # @param cache_write [Float, nil] Cache write cost per million tokens
          def initialize(input: nil, output: nil, reasoning: nil, cache_read: nil, cache_write: nil)
            @input = input
            @output = output
            @reasoning = reasoning
            @cache_read = cache_read
            @cache_write = cache_write
          end

          # Create from API hash
          # @param hash [Hash] Cost hash from API
          # @return [PricingInfo] Parsed pricing info
          def self.from_hash(hash)
            return new if hash.nil?

            new(
              input: hash["input"],
              output: hash["output"],
              reasoning: hash["reasoning"],
              cache_read: hash["cache_read"],
              cache_write: hash["cache_write"]
            )
          end

          # Convert to hash
          # @return [Hash] Pricing as hash
          def to_h
            {
              input: input,
              output: output,
              reasoning: reasoning,
              cache_read: cache_read,
              cache_write: cache_write
            }.compact
          end

          # Check if pricing data is available
          # @return [Boolean] true if any pricing data exists
          def available?
            input || output
          end

          # Calculate total cost for token counts
          # @param input_tokens [Integer] Input token count
          # @param output_tokens [Integer] Output token count
          # @param reasoning_tokens [Integer] Reasoning token count
          # @return [Float] Total cost in dollars
          def calculate(input_tokens:, output_tokens:, reasoning_tokens: 0)
            total = 0.0
            total += (input_tokens / 1_000_000.0) * input if input
            total += (output_tokens / 1_000_000.0) * output if output
            total += (reasoning_tokens / 1_000_000.0) * reasoning if reasoning && reasoning_tokens > 0
            total
          end
        end
      end
    end
  end
end
