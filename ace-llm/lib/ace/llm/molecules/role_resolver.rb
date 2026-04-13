# frozen_string_literal: true

require_relative "../models/role_config"
require_relative "client_registry"

module Ace
  module LLM
    module Molecules
      # RoleResolver maps role names to an available concrete selector.
      class RoleResolver
        THINKING_LEVELS = %w[low medium high xhigh].freeze

        def initialize(registry: nil, configuration: nil)
          @registry = registry || ClientRegistry.new
          @configuration = configuration || Ace::LLM.configuration
        end

        # Resolve role name to first available candidate selector string.
        # @param role_name [String]
        # @return [String]
        def resolve(role_name)
          selector, _remaining = resolve_with_candidates(role_name)
          selector
        end

        # Resolve role name and return both the selected candidate and remaining candidates.
        # Remaining candidates can be used as a fallback chain at query time.
        # @param role_name [String]
        # @return [Array(String, Array<String>)] [resolved_selector, remaining_candidates]
        def resolve_with_candidates(role_name)
          normalized_role_name = role_name.to_s.strip
          if normalized_role_name.empty?
            raise Ace::LLM::ConfigurationError, "Invalid target: role name cannot be empty"
          end

          role_config = Models::RoleConfig.from_hash(@configuration.get("llm.roles"))
          candidates = role_config.candidates_for(normalized_role_name)
          unless candidates
            available = role_config.role_names
            available_display = available.empty? ? "(none)" : available.join(", ")
            raise Ace::LLM::ConfigurationError,
              "Unknown role: #{normalized_role_name}. Defined roles: #{available_display}"
          end

          candidates.each_with_index do |candidate, index|
            if candidate_available?(candidate)
              remaining = candidates[(index + 1)..]
              return [candidate, remaining]
            end
          end

          raise Ace::LLM::ConfigurationError,
            "No available models for role '#{normalized_role_name}'. Tried: #{candidates.join(", ")}"
        end

        private

        def candidate_available?(candidate)
          provider = provider_for_candidate(candidate)
          return false if provider.nil? || provider.empty?
          return false if @configuration.provider_inactive?(provider)
          return false unless @registry.provider_available?(provider)

          true
        end

        def provider_for_candidate(candidate)
          candidate_target, _preset, _preset_error = split_preset_suffix(candidate.to_s)
          model_target, _thinking, _thinking_error = split_thinking_suffix(candidate_target)
          resolved = @registry.resolve_alias(model_target)
          provider = resolved.to_s.split(":", 2).first
          normalize_provider(provider)
        end

        def normalize_provider(name)
          name.to_s.strip.downcase.gsub(/[-_]/, "")
        end

        def split_preset_suffix(input)
          provider_target, preset_name = input.split("@", 2)
          return [input, nil, nil] unless input.include?("@")

          [provider_target.to_s.strip, preset_name.to_s.strip, nil]
        end

        def split_thinking_suffix(model_input)
          trimmed = model_input.to_s.strip
          base, separator, suffix = trimmed.rpartition(":")
          return [trimmed, nil, nil] if separator.empty?

          normalized_level = suffix.to_s.strip.downcase
          return [trimmed, nil, nil] unless THINKING_LEVELS.include?(normalized_level)
          return [trimmed, nil, nil] if base.to_s.strip.empty?

          [base.strip, normalized_level, nil]
        end
      end
    end
  end
end
