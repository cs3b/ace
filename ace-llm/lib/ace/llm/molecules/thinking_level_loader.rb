# frozen_string_literal: true

require "ace/support/config"
require_relative "config_loader"

module Ace
  module LLM
    module Molecules
      # Loads provider-scoped thinking-level overrides from llm/thinking/*.yml.
      class ThinkingLevelLoader
        ALLOWED_LEVELS = %w[low medium high xhigh].freeze

        class << self
          def load_for_provider(provider, level)
            normalized_provider = normalize_provider_name(provider)
            normalized_level = normalize_level(level)
            thinking_hash = resolve_level("#{normalized_provider}/#{normalized_level}")

            if thinking_hash.nil? || thinking_hash.empty?
              raise ConfigurationError,
                    "Thinking level '#{normalized_level}' not found for provider '#{normalized_provider}'. " \
                    "Define .ace/llm/thinking/#{normalized_provider}/#{normalized_level}.yml"
            end

            thinking_hash
          rescue ConfigurationError
            raise
          rescue StandardError => e
            raise ConfigurationError,
                  "Failed to load thinking level '#{normalized_level}' for provider '#{normalized_provider}': #{e.message}"
          end

          private

          def config_resolver
            Ace::Support::Config.create(
              config_dir: ".ace",
              defaults_dir: ".ace-defaults",
              gem_path: ConfigLoader.gem_root
            )
          end

          def normalize_provider_name(provider)
            normalized_provider = provider.to_s.strip.downcase.gsub(/[-_]/, "")
            raise ConfigurationError, "Provider name cannot be empty" if normalized_provider.empty?

            normalized_provider
          end

          def normalize_level(level)
            normalized_level = level.to_s.strip.downcase
            raise ConfigurationError, "Thinking level cannot be empty" if normalized_level.empty?
            unless ALLOWED_LEVELS.include?(normalized_level)
              raise ConfigurationError,
                    "Unsupported thinking level '#{normalized_level}'. Supported levels: #{ALLOWED_LEVELS.join(", ")}"
            end

            normalized_level
          end

          def resolve_level(level_path)
            config = config_resolver.resolve_namespace("llm", filename: "thinking/#{level_path}")
            thinking_hash = deep_stringify_keys(config.to_h)
            thinking_hash.is_a?(Hash) ? thinking_hash : {}
          end

          def deep_stringify_keys(value)
            case value
            when Hash
              value.each_with_object({}) do |(k, v), result|
                result[k.to_s] = deep_stringify_keys(v)
              end
            when Array
              value.map { |item| deep_stringify_keys(item) }
            else
              value
            end
          end
        end
      end
    end
  end
end
