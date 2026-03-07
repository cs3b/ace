# frozen_string_literal: true

require_relative "client_registry"
require_relative "llm_alias_resolver"

module Ace
  module LLM
    module Molecules
      # ProviderModelParser handles parsing and validation of provider:model syntax
      # for the unified LLM query interface.
      class ProviderModelParser
        THINKING_LEVELS = %w[low medium high xhigh].freeze

        # Result object for parsed provider:model combinations.
        ParseResult = Struct.new(:provider, :model, :preset, :thinking_level, :valid, :error, :original_input) do
          def valid?
            valid
          end

          def invalid?
            !valid?
          end

          def to_s
            thinking_suffix = thinking_level ? ":#{thinking_level}" : ""
            preset_suffix = preset ? "@#{preset}" : ""
            "#{provider}:#{model}#{thinking_suffix}#{preset_suffix}"
          end
        end

        attr_reader :alias_resolver, :registry

        def initialize(alias_resolver: nil, registry: nil)
          @alias_resolver = alias_resolver || LlmAliasResolver.new
          @registry = registry || ClientRegistry.new
        end

        # Parse a provider:model string or alias.
        def parse(input)
          return create_error_result(input, "Input cannot be nil or empty") if input.nil? || input.strip.empty?

          original_input = input.strip
          provider_target, preset_name, preset_error = split_preset_suffix(original_input)
          return create_error_result(original_input, preset_error) if preset_error
          return create_error_result(original_input, "Invalid target: provider/model portion cannot be empty") if provider_target.empty?

          resolved_input = @alias_resolver.resolve(provider_target)
          parts = resolved_input.split(":", 2)

          if parts.length == 1
            provider = normalize_provider(parts[0])
            unless supported_providers.include?(provider)
              return create_error_result(original_input, provider_validation_error(provider, supported_providers))
            end

            model = default_model_for(provider)
            return ParseResult.new(provider, model, preset_name, nil, true, nil, original_input)
          end

          provider = normalize_provider(parts[0])
          model_with_suffix = parts[1].strip
          unless supported_providers.include?(provider)
            return create_error_result(original_input, provider_validation_error(provider, supported_providers))
          end

          model, thinking_level, thinking_error = split_thinking_suffix(model_with_suffix)
          return create_error_result(original_input, thinking_error) if thinking_error
          return create_error_result(original_input, "Invalid target: model cannot be empty") if model.to_s.strip.empty?

          ParseResult.new(provider, model, preset_name, thinking_level, true, nil, original_input)
        end

        def supported_providers
          @registry.available_providers
        end

        def default_model_for(provider)
          models = @registry.models_for_provider(provider)
          models&.first
        end

        def dynamic_aliases
          return {} unless @alias_resolver

          global = @alias_resolver.available_aliases[:global] || {}
          providers = @alias_resolver.available_aliases[:providers] || {}

          flattened = {}
          providers.each do |provider, aliases|
            aliases.each do |alias_name, model|
              flattened["#{provider}:#{alias_name}"] = "#{provider}:#{model}"
            end
          end

          global.merge(flattened)
        end

        private

        def normalize_provider(provider)
          provider.strip.downcase.gsub(/[-_]/, "")
        end

        def split_preset_suffix(input)
          provider_target, preset_name = input.split("@", 2)
          return [input, nil, nil] unless input.include?("@")

          trimmed_preset = preset_name.to_s.strip
          if trimmed_preset.empty?
            return [provider_target.to_s.strip, nil, "Invalid target: preset name cannot be empty (e.g., model@ro)"]
          end

          [provider_target.to_s.strip, trimmed_preset, nil]
        end

        def split_thinking_suffix(model_input)
          trimmed = model_input.to_s.strip
          base, separator, suffix = trimmed.rpartition(":")
          return [trimmed, nil, nil] if separator.empty?

          normalized_level = suffix.to_s.strip.downcase
          return [trimmed, nil, nil] unless THINKING_LEVELS.include?(normalized_level)

          if base.to_s.strip.empty?
            return [trimmed, nil, "Invalid target: model cannot be empty before thinking level"]
          end

          [base.strip, normalized_level, nil]
        end

        def create_error_result(input, error)
          ParseResult.new(nil, nil, nil, nil, false, error, input)
        end

        def provider_validation_error(provider, supported_providers)
          return unknown_provider_error(provider, supported_providers) unless inactive_provider?(provider)

          active = Ace::LLM.configuration.active_provider_names
          active_display = active.empty? ? "(none)" : active.join(", ")
          <<~MSG.strip
            Provider '#{provider}' is inactive. It exists but is not in llm.providers.active.
            To enable it, add '#{provider}' to llm.providers.active in your config.
            Active providers: #{active_display}
          MSG
        end

        def unknown_provider_error(provider, supported_providers)
          "Unknown provider: #{provider}. Supported providers: #{supported_providers.join(", ")}"
        end

        def inactive_provider?(provider)
          Ace::LLM.configuration.provider_inactive?(provider)
        rescue StandardError
          false
        end
      end
    end
  end
end
