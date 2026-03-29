# frozen_string_literal: true

require_relative "client_registry"
require_relative "llm_alias_resolver"
require_relative "role_resolver"

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
          @role_resolver = RoleResolver.new(registry: @registry)
        end

        # Parse a provider:model string or alias.
        def parse(input)
          return create_error_result(input, "Input cannot be nil or empty") if input.nil? || input.strip.empty?

          original_input = input.strip
          if role_reference?(original_input)
            return parse_role_reference(original_input)
          end

          parse_standard_target(original_input)
        rescue Ace::LLM::ConfigurationError => e
          create_error_result(original_input, e.message)
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

        def parse_role_reference(original_input)
          role_target, caller_preset, preset_error = split_preset_suffix(original_input)
          return create_error_result(original_input, preset_error) if preset_error

          role_value = role_target.sub(/\Arole:/, "")
          role_name, caller_thinking, thinking_error = split_thinking_suffix(role_value)
          return create_error_result(original_input, thinking_error) if thinking_error
          return create_error_result(original_input, "Invalid target: role name cannot be empty") if role_name.to_s.strip.empty?

          resolved_selector = @role_resolver.resolve(role_name)
          resolved_parse = parse_standard_target(resolved_selector)
          return resolved_parse if resolved_parse.invalid?

          ParseResult.new(
            resolved_parse.provider,
            resolved_parse.model,
            caller_preset || resolved_parse.preset,
            caller_thinking || resolved_parse.thinking_level,
            true,
            nil,
            original_input
          )
        end

        def parse_standard_target(original_input)
          provider_target, preset_name, preset_error = split_preset_suffix(original_input)
          return create_error_result(original_input, preset_error) if preset_error

          provider_target = @alias_resolver.resolve(provider_target).to_s.strip
          return create_error_result(original_input, "Invalid target: provider/model portion cannot be empty") if provider_target.empty?

          parts = provider_target.split(":", 2)

          if parts.length == 1
            provider = normalize_provider(parts[0])
            unless supported_providers.include?(provider)
              return create_error_result(original_input, provider_validation_error(provider, supported_providers))
            end

            model = default_model_for(provider)
            return ParseResult.new(provider, model, preset_name, nil, true, nil, original_input)
          end

          provider = normalize_provider(parts[0])
          model_with_suffix = parts[1].to_s.strip
          unless supported_providers.include?(provider)
            return create_error_result(original_input, provider_validation_error(provider, supported_providers))
          end

          model_alias, thinking_level, thinking_error = split_thinking_suffix(model_with_suffix)
          return create_error_result(original_input, thinking_error) if thinking_error
          return create_error_result(original_input, "Invalid target: model cannot be empty") if model_alias.to_s.strip.empty?

          resolved_model_input = @alias_resolver.resolve("#{parts[0]}:#{model_alias}")
          resolved_parts = resolved_model_input.split(":", 2)

          return create_error_result(original_input, "Invalid target: provider/model resolution produced invalid model format: #{resolved_model_input}") if resolved_parts.length != 2

          resolved_provider = normalize_provider(resolved_parts[0])
          model = resolved_parts[1].to_s

          unless model && !model.empty?
            return create_error_result(original_input, "Invalid target: resolved model cannot be empty")
          end

          ParseResult.new(resolved_provider, model, preset_name, thinking_level, true, nil, original_input)
        end

        def role_reference?(input)
          input.to_s.strip.start_with?("role:")
        end

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
        rescue
          false
        end
      end
    end
  end
end
