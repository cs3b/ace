# frozen_string_literal: true

require_relative "../../atoms/token_estimator"

module Ace
  module Review
    module Molecules
      module Strategies
        # Full strategy - passes subject through without splitting
        #
        # The simplest strategy that sends the entire subject as a single
        # review unit. Suitable when the subject fits within the model's
        # context window (with safety margin for prompts and output).
        #
        # @example Basic usage
        #   strategy = FullStrategy.new
        #   if strategy.can_handle?(subject, 128_000)
        #     units = strategy.prepare(subject, context)
        #     # units = [{ content: subject, metadata: { strategy: :full, ... } }]
        #   end
        class FullStrategy
          # Default safety margin - reserve this percentage of context for prompts and output
          # Subject should fit within (1 - margin) of the model's limit
          # Can be overridden via config[:headroom]
          DEFAULT_CONTEXT_MARGIN = 0.15

          # @param config [Hash] Strategy configuration
          # @option config [Float] :headroom Override the default context margin (0.0-1.0)
          def initialize(config = {})
            # Normalize keys to symbols for consistent access (supports YAML string keys)
            @config = normalize_config_keys(config)
            @context_margin = @config[:headroom] || DEFAULT_CONTEXT_MARGIN
          end

          private

          # Normalize config keys to symbols for consistent access
          #
          # @param config [Hash] Configuration with symbol or string keys
          # @return [Hash] Configuration with symbol keys
          def normalize_config_keys(config)
            return {} unless config.is_a?(Hash)
            config.transform_keys(&:to_sym)
          end

          public

          # Check if this strategy can handle the given subject
          #
          # Returns true if the estimated token count of the subject fits
          # within the model's context limit (with safety margin).
          #
          # @param subject [String] The review subject text
          # @param model_context_limit [Integer] Model's token limit
          # @return [Boolean] true if subject fits within safe context window
          #
          # @example
          #   strategy.can_handle?("small code", 128_000)  #=> true
          #   strategy.can_handle?(huge_codebase, 8_000)   #=> false
          def can_handle?(subject, model_context_limit)
            return false if subject.nil? || subject.empty?
            return false if model_context_limit.nil? || model_context_limit <= 0

            estimated_tokens = Ace::Review::Atoms::TokenEstimator.estimate(subject)
            safe_limit = (model_context_limit * (1 - @context_margin)).to_i
            estimated_tokens < safe_limit
          end

          # Prepare the subject for review
          #
          # For the full strategy, this simply wraps the entire subject
          # in a single review unit with appropriate metadata.
          #
          # @param subject [String] The review subject text
          # @param context [Hash] Review context (see below)
          # @option context [String] :system_prompt Base system prompt for the reviewer
          # @option context [String] :user_prompt User instructions or focus areas
          # @option context [String] :model Model identifier
          # @option context [Integer] :model_context_limit Token limit for the model
          # @option context [Hash] :preset Full preset configuration
          # @option context [Array<String>] :file_list List of files being reviewed
          # @return [Array<Hash>] Array with single review unit
          #
          # @example Return format
          #   [{
          #     content: "full subject...",
          #     metadata: {
          #       strategy: :full,
          #       chunk_index: 0,
          #       total_chunks: 1
          #     }
          #   }]
          def prepare(subject, context = {})
            [{
              content: subject,
              metadata: {
                strategy: :full,
                chunk_index: 0,
                total_chunks: 1
              }
            }]
          end

          # Strategy name for logging and debugging
          #
          # @return [Symbol] :full
          def strategy_name
            :full
          end
        end
      end
    end
  end
end
