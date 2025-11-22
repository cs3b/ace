# frozen_string_literal: true

require_relative "../atoms/content_hasher"
require_relative "../atoms/model_alias_resolver"

module Ace
  module Prompt
    module Organisms
      # Enhance prompts using LLM with caching
      class PromptEnhancer
        class EnhancementError < Ace::Prompt::Error; end

        def initialize(config)
          @config = config
          @cache = {}
        end

        # Enhance prompt content via LLM
        # @param content [String] Content to enhance
        # @param system_prompt_uri [String] System prompt URI
        # @return [String] Enhanced content
        def enhance(content, system_prompt_uri: nil)
          cache_key = Atoms::ContentHasher.hash(content)

          # Check cache first
          return @cache[cache_key] if @cache.key?(cache_key)

          # Perform enhancement
          enhanced = call_llm(content, system_prompt_uri)
          @cache[cache_key] = enhanced
          enhanced
        rescue => e
          warn "Warning: Enhancement failed: #{e.message}. Using original content."
          content
        end

        private

        def call_llm(content, system_prompt_uri)
          require 'ace/llm/query_interface'

          model = resolve_model
          system_prompt = load_system_prompt(system_prompt_uri)
          temperature = @config.dig("enhancement", "temperature") || 0.3

          # Use ace-llm API directly instead of shelling out
          response = Ace::LLM::QueryInterface.query(
            model,
            content,
            system: system_prompt,
            temperature: temperature,
            format: "text"
          )

          response[:text].strip
        rescue => e
          raise EnhancementError, "LLM call failed: #{e.message}"
        end

        def resolve_model
          model = @config.dig("enhancement", "model") || "glite"
          Atoms::ModelAliasResolver.resolve(model)
        end

        def load_system_prompt(uri)
          prompt_uri = uri || @config.dig("enhancement", "system_prompt") || "prompt://ace-prompt/base/enhance"

          # Try to load via ace-nav
          if prompt_uri.start_with?("prompt://")
            cmd = "ace-nav '#{prompt_uri}' 2>&1"
            path = `#{cmd}`.strip
            return File.read(path) if $?.success? && File.exist?(path)
          end

          # Fallback to default system prompt
          default_system_prompt
        end

        def default_system_prompt
          <<~PROMPT
            You are an expert at refining and clarifying prompts for LLM interactions.
            Enhance the user's prompt to make it more clear, specific, and unambiguous while preserving intent.
            Output only the enhanced prompt - no meta-commentary or explanations.
          PROMPT
        end
      end
    end
  end
end
