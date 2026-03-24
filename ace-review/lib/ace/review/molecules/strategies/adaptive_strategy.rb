# frozen_string_literal: true

require_relative "../../atoms/token_estimator"
require_relative "../../atoms/context_limit_resolver"
require_relative "full_strategy"
require_relative "chunked_strategy"

module Ace
  module Review
    module Molecules
      module Strategies
        # Adaptive strategy - auto-selects full or chunked based on model capabilities
        #
        # This strategy analyzes the subject size and model context limit to
        # automatically select the most appropriate underlying strategy:
        # - Full strategy when subject fits within model context (with headroom)
        # - Chunked strategy when subject exceeds available context
        #
        # @example Basic usage
        #   strategy = AdaptiveStrategy.new
        #   units = strategy.prepare(subject, context)
        #   # Automatically uses full or chunked based on size
        #
        # @example With custom headroom
        #   strategy = AdaptiveStrategy.new(headroom: 0.20)  # 20% headroom
        #   units = strategy.prepare(subject, context)
        class AdaptiveStrategy
          # Default headroom percentage for system prompt and output
          DEFAULT_HEADROOM = 0.15

          # @param config [Hash] Strategy configuration
          # @option config [Float] :headroom Fraction to reserve (default: 0.15)
          # @option config [Integer] :max_tokens_per_chunk Max tokens per chunk for chunked strategy
          # @option config [Boolean] :include_change_summary Include file summary in chunks
          def initialize(config = {})
            # Normalize keys to symbols for consistent access (supports YAML string keys)
            @config = normalize_config_keys(config)
            @headroom = @config[:headroom] || DEFAULT_HEADROOM
            @logger = @config[:logger]
          end

          # Check if this strategy can handle the given subject
          #
          # Adaptive strategy can always handle any subject by delegating
          # to the appropriate underlying strategy.
          #
          # @param subject [String] The review subject text
          # @param model_context_limit [Integer] Model's token limit
          # @return [Boolean] Always returns true (can handle any subject)
          def can_handle?(subject, model_context_limit)
            return false if subject.nil? || subject.empty?
            return false if model_context_limit.nil? || model_context_limit <= 0

            true
          end

          # Prepare the subject for review by selecting and delegating to appropriate strategy
          #
          # Analyzes the subject size against model context limit and selects:
          # - FullStrategy if subject fits within available context
          # - ChunkedStrategy if subject exceeds available context
          #
          # @param subject [String] The review subject text
          # @param context [Hash] Review context
          # @option context [String] :model Model identifier for context limit lookup
          # @option context [Integer] :model_context_limit Explicit context limit (overrides model lookup)
          # @return [Array<Hash>] Array of review units from selected strategy
          def prepare(subject, context = {})
            model = context[:model] || context["model"]
            explicit_limit = context[:model_context_limit] || context["model_context_limit"]

            # Resolve model context limit
            model_limit = explicit_limit || Atoms::ContextLimitResolver.resolve(model)

            # Select and delegate to appropriate strategy
            selected = select_strategy(subject, model_limit, model)
            selected.prepare(subject, context)
          end

          # Strategy name for logging and debugging
          #
          # @return [Symbol] :adaptive
          def strategy_name
            :adaptive
          end

          # Select the appropriate strategy based on subject size and model limit
          #
          # @param subject [String] The review subject text
          # @param model_limit [Integer] Model's context limit in tokens
          # @param model [String, nil] Model identifier for logging
          # @return [Object] Strategy instance (FullStrategy or ChunkedStrategy)
          def select_strategy(subject, model_limit, model = nil)
            estimated_tokens = Atoms::TokenEstimator.estimate(subject)
            available = (model_limit * (1 - @headroom)).to_i

            if estimated_tokens < available
              log_selection(
                model: model,
                subject_tokens: estimated_tokens,
                model_limit: model_limit,
                available: available,
                selected: :full,
                reason: "subject fits within available context"
              )
              build_full_strategy
            else
              log_selection(
                model: model,
                subject_tokens: estimated_tokens,
                model_limit: model_limit,
                available: available,
                selected: :chunked,
                reason: "subject exceeds available context"
              )
              build_chunked_strategy
            end
          end

          private

          # Normalize config keys to symbols for consistent access
          #
          # Recursively normalizes top-level keys and the :chunking nested hash.
          #
          # @param config [Hash] Configuration with symbol or string keys
          # @return [Hash] Configuration with symbol keys
          def normalize_config_keys(config)
            return {} unless config.is_a?(Hash)

            normalized = config.transform_keys(&:to_sym)

            # Also normalize nested :chunking config if present
            if normalized[:chunking].is_a?(Hash)
              normalized[:chunking] = normalized[:chunking].transform_keys(&:to_sym)
            end

            normalized
          end

          # Build a full strategy instance with current config
          # @return [FullStrategy]
          def build_full_strategy
            FullStrategy.new(@config)
          end

          # Build a chunked strategy instance with current config
          # @return [ChunkedStrategy]
          def build_chunked_strategy
            chunked_config = @config.dup
            # Pass through chunking-specific options
            chunking = @config[:chunking]
            if chunking
              chunked_config[:max_tokens_per_chunk] = chunking[:max_tokens_per_chunk]
              chunked_config[:include_change_summary] = chunking[:include_change_summary]
            end
            ChunkedStrategy.new(chunked_config)
          end

          # Log strategy selection for debugging and tuning
          #
          # @param details [Hash] Selection details
          def log_selection(details)
            message = format_log_message(details)

            if @logger
              @logger.info(message)
            elsif Ace::Review.respond_to?(:debug?) && Ace::Review.debug?
              warn message
            end
          end

          # Format log message for strategy selection
          #
          # @param details [Hash] Selection details
          # @return [String] Formatted log message
          def format_log_message(details)
            parts = [
              "[ace-review] Strategy selection:",
              "model=#{details[:model] || "unknown"}",
              "subject_tokens=#{details[:subject_tokens]}",
              "model_limit=#{details[:model_limit]}",
              "available=#{details[:available]}",
              "selected=#{details[:selected]}",
              "reason='#{details[:reason]}'"
            ]
            parts.join(" ")
          end
        end
      end
    end
  end
end
