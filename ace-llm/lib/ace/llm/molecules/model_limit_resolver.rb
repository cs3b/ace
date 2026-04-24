# frozen_string_literal: true

require "ace/support/models"
require_relative "client_registry"
require_relative "provider_model_parser"

module Ace
  module LLM
    module Molecules
      # Resolves model context/output limits against the expanded concrete target.
      class ModelLimitResolver
        DEFAULT_CONTEXT_LIMIT = 200_000

        ResolveResult = Struct.new(
          :provider,
          :model,
          :context_limit,
          :output_limit,
          :source,
          :original_target,
          keyword_init: true
        ) do
          def full_model
            return nil if provider.to_s.empty? || model.to_s.empty?

            "#{provider}:#{model}"
          end
        end

        def self.resolve(target, **kwargs)
          new(**kwargs).resolve(target)
        end

        def initialize(registry: nil, parser: nil)
          @registry = registry || ClientRegistry.new
          @parser = parser || ProviderModelParser.new(registry: @registry)
        end

        def resolve(target)
          original_target = target.to_s
          return fallback_result(original_target) if original_target.strip.empty?

          parsed = @parser.parse(original_target)
          return fallback_result(original_target) if parsed.invalid?

          provider_config = @registry.get_provider(parsed.provider)
          return fallback_result(original_target, provider: parsed.provider, model: parsed.model) unless provider_config

          limits = Ace::Support::Models::Atoms::ProviderConfigReader.extract_limits(provider_config)
          default_limits = limits["default"] || {}
          model_limits = limits.dig("models", parsed.model) || {}
          merged_limits = default_limits.merge(model_limits)

          ResolveResult.new(
            provider: parsed.provider,
            model: parsed.model,
            context_limit: merged_limits["context"] || DEFAULT_CONTEXT_LIMIT,
            output_limit: merged_limits["output"],
            source: limit_source(default_limits, model_limits),
            original_target: original_target
          )
        rescue
          fallback_result(original_target)
        end

        private

        def limit_source(default_limits, model_limits)
          return :model_override if model_limits.any?
          return :provider_default if default_limits.any?

          :fallback
        end

        def fallback_result(original_target, provider: nil, model: nil)
          ResolveResult.new(
            provider: provider,
            model: model,
            context_limit: DEFAULT_CONTEXT_LIMIT,
            output_limit: nil,
            source: :fallback,
            original_target: original_target
          )
        end
      end
    end
  end
end
