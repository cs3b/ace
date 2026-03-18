# frozen_string_literal: true

module Ace
  module Review
    module Molecules
      # Factory and interface for subject splitting strategies
      #
      # The SubjectStrategy module provides a factory method for creating
      # strategies that determine how review subjects are split or processed
      # before being sent to an LLM for review.
      #
      # Available strategies:
      # - :full - Pass-through strategy, no splitting (default)
      # - :chunked - Split by logical boundaries (future)
      # - :adaptive - Auto-select based on size (future)
      #
      # @example Factory usage
      #   strategy = SubjectStrategy.for(:full, config)
      #   strategy.can_handle?(subject_text, 128_000)
      #   #=> true
      #
      # @example Strategy lifecycle
      #   strategy = SubjectStrategy.for(:full)
      #   if strategy.can_handle?(subject, model_limit)
      #     units = strategy.prepare(subject, context)
      #     units.each { |unit| execute_review(unit) }
      #   end
      module SubjectStrategy
        # Registry of available strategy classes
        STRATEGIES = {
          full: "Ace::Review::Molecules::Strategies::FullStrategy",
          chunked: "Ace::Review::Molecules::Strategies::ChunkedStrategy",
          adaptive: "Ace::Review::Molecules::Strategies::AdaptiveStrategy"
        }.freeze

        # Factory method to create a strategy instance
        #
        # @param type [Symbol] Strategy type (:full, :chunked, :adaptive)
        # @param config [Hash] Optional configuration for the strategy
        # @return [Object] Strategy instance that responds to #can_handle? and #prepare
        # @raise [UnknownStrategyError] if strategy type is not recognized
        #
        # @example
        #   strategy = SubjectStrategy.for(:full)
        #   strategy = SubjectStrategy.for(:chunked, chunk_size: 50_000)
        def self.for(type, config = {})
          type_sym = type.to_sym
          class_name = STRATEGIES[type_sym]

          unless class_name
            available = STRATEGIES.keys.join(", ")
            raise Ace::Review::Errors::UnknownStrategyError,
                  "Unknown strategy type '#{type}'. Available strategies: #{available}"
          end

          # Lazy require the strategy class
          require_strategy(type_sym)

          # Get the class and instantiate
          klass = Object.const_get(class_name)
          klass.new(config)
        end

        # Check if a strategy type is available
        #
        # @param type [Symbol, String] Strategy type to check
        # @return [Boolean] true if strategy is available
        def self.available?(type)
          STRATEGIES.key?(type.to_sym)
        end

        # List available strategy types
        #
        # @return [Array<Symbol>] List of available strategy types
        def self.available_strategies
          STRATEGIES.keys
        end

        # Require the strategy file for a given type
        # @param type [Symbol] Strategy type
        # @api private
        def self.require_strategy(type)
          case type
          when :full
            require_relative "strategies/full_strategy"
          when :chunked
            require_relative "strategies/chunked_strategy"
          when :adaptive
            require_relative "strategies/adaptive_strategy"
          end
        end
        private_class_method :require_strategy
      end
    end
  end
end
