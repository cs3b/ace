# frozen_string_literal: true

require_relative "token_estimator"
require_relative "context_limit_resolver"

module Ace
  module Review
    module Atoms
      # Checks the complete rendered prompt before any model receives it.
      # An over-budget packet must be respecified as a coherent review scope;
      # silently truncating a diff cannot produce a complete review.
      module PromptBudget
        DEFAULT_INPUT_LIMIT = 128_000
        DEFAULT_SYSTEM_LIMIT = 30_000
        DEFAULT_CONTEXT_LIMIT = 30_000
        OUTPUT_RESERVE = 8_192
        ESTIMATE_SAFETY_FACTOR = 1.25

        def self.check(system_prompt:, user_prompt:, models:, config: {}, subject: nil, instruction_tokens: nil)
          settings = config || {}
          input_limit = integer_limit(settings, "input_max_tokens", DEFAULT_INPUT_LIMIT)
          raise ArgumentError, "input_max_tokens cannot exceed 128000" if input_limit > DEFAULT_INPUT_LIMIT
          system_limit = integer_limit(settings, "system_max_tokens", DEFAULT_SYSTEM_LIMIT)
          raise ArgumentError, "system_max_tokens cannot exceed 30000" if system_limit > DEFAULT_SYSTEM_LIMIT
          context_limit = integer_limit(settings, "context_max_tokens", DEFAULT_CONTEXT_LIMIT)
          raise ArgumentError, "context_max_tokens cannot exceed 30000" if context_limit > DEFAULT_CONTEXT_LIMIT
          system_tokens = conservative_estimate(system_prompt)
          user_tokens = conservative_estimate(user_prompt)
          total_tokens = system_tokens + user_tokens
          # The context ceiling covers all non-diff user input, including
          # instructions that also have their own ceiling. A proposed preset
          # cannot relabel project documents as instructions to evade it.
          context_tokens = subject ? [user_tokens - conservative_estimate(subject), 0].max : nil

          errors = []
          all_instruction_tokens = system_tokens + instruction_tokens.to_i
          errors << "review instructions ~#{all_instruction_tokens} tokens exceeds #{system_limit}" if all_instruction_tokens > system_limit
          errors << "non-diff review context ~#{context_tokens} tokens exceeds #{context_limit}" if context_tokens && context_tokens > context_limit
          errors << "complete prompt ~#{total_tokens} tokens exceeds #{input_limit}" if total_tokens > input_limit

          eligible_models = []
          ineligible_models = {}
          Array(models).each do |model|
            limits = ContextLimitResolver.resolve_details(model)
            reserve = [limits.respond_to?(:output_limit) ? limits.output_limit.to_i : 0, OUTPUT_RESERVE].max
            available = limits.context_limit - reserve
            if total_tokens > available
              ineligible_models[model] = available
            else
              eligible_models << model
            end
          end
          if Array(models).any? && eligible_models.empty?
            errors << "complete prompt ~#{total_tokens} tokens exceeds every configured model input allowance: #{ineligible_models.map { |model, allowance| "#{model}=#{allowance}" }.join(", ")}"
          end

          {success: errors.empty?, errors: errors, system_tokens: system_tokens,
           user_tokens: user_tokens, total_tokens: total_tokens, input_limit: input_limit,
           context_tokens: context_tokens, context_limit: context_limit,
           instruction_tokens: all_instruction_tokens,
           eligible_models: eligible_models, ineligible_models: ineligible_models}
        end

        def self.conservative_estimate(text)
          (TokenEstimator.estimate(text) * ESTIMATE_SAFETY_FACTOR).ceil
        end
        private_class_method :conservative_estimate

        def self.integer_limit(settings, key, default)
          value = settings[key] || settings[key.to_sym] || default
          raise ArgumentError, "#{key} must be a positive integer" unless value.is_a?(Integer) && value.positive?

          value
        end
        private_class_method :integer_limit
      end
    end
  end
end
