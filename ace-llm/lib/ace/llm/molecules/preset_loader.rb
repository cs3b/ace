# frozen_string_literal: true

require "ace/support/config"
require_relative "config_loader"

module Ace
  module LLM
    module Molecules
      # Loads named execution presets from llm/presets/*.yml via config cascade.
      class PresetLoader
        class << self
          def load(name)
            preset_name = normalize_preset_name(name)
            preset_hash = resolve_preset(preset_name)
            if preset_hash.nil? || preset_hash.empty?
              raise ConfigurationError,
                    "Preset '#{preset_name}' not found. Define .ace/llm/presets/#{preset_name}.yml"
            end

            preset_hash
          rescue ConfigurationError
            raise
          rescue StandardError => e
            raise ConfigurationError, "Failed to load preset '#{preset_name}': #{e.message}"
          end

          def load_for_provider(provider, preset_name)
            normalized_provider = normalize_provider_name(provider)
            normalized_preset_name = normalize_preset_name(preset_name)

            global_preset = resolve_preset(normalized_preset_name)
            provider_preset = resolve_preset("#{normalized_provider}/#{normalized_preset_name}")

            if global_preset.empty? && provider_preset.empty?
              raise ConfigurationError,
                    "Preset '#{normalized_preset_name}' not found for provider '#{normalized_provider}'. " \
                    "Define .ace/llm/presets/#{normalized_preset_name}.yml or " \
                    ".ace/llm/presets/#{normalized_provider}/#{normalized_preset_name}.yml"
            end

            Ace::Support::Config::Models::Config.wrap(
              global_preset,
              provider_preset,
              source: "llm_preset_overlay"
            )
          rescue ConfigurationError
            raise
          rescue StandardError => e
            raise ConfigurationError,
                  "Failed to load preset '#{normalized_preset_name}' for provider '#{normalized_provider}': #{e.message}"
          end

          private

          def config_resolver
            Ace::Support::Config.create(
              config_dir: ".ace",
              defaults_dir: ".ace-defaults",
              gem_path: ConfigLoader.gem_root
            )
          end

          def normalize_preset_name(name)
            preset_name = name.to_s.strip
            raise ConfigurationError, "Preset name cannot be empty" if preset_name.empty?

            preset_name
          end

          def normalize_provider_name(provider)
            normalized_provider = provider.to_s.strip.downcase.gsub(/[-_]/, "")
            raise ConfigurationError, "Provider name cannot be empty" if normalized_provider.empty?

            normalized_provider
          end

          def resolve_preset(preset_name)
            config = config_resolver.resolve_namespace("llm", filename: "presets/#{preset_name}")
            preset_hash = deep_stringify_keys(config.to_h)
            preset_hash.is_a?(Hash) ? preset_hash : {}
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
