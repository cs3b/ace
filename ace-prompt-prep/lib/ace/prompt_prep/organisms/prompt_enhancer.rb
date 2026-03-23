# frozen_string_literal: true

require_relative "../molecules/enhancement_tracker"

module Ace
  module PromptPrep
    module Organisms
      # Enhances prompts using LLM via ace-llm
      class PromptEnhancer
        # Default system prompt URI
        DEFAULT_SYSTEM_PROMPT_URI = "prompt://prompt-enhance-instructions.system"

        # Enhance prompt content using LLM
        #
        # @param content [String] Original prompt content
        # @param model [String, nil] Model alias or provider:model format (ace-llm handles alias resolution)
        # @param system_prompt_uri [String, nil] System prompt URI or path
        # @param temperature [Float] Temperature for LLM generation (0.0-2.0)
        # @return [Hash] Result with :content, :enhanced, :cached, :error keys
        def self.call(content:, model: nil, system_prompt_uri: nil, temperature: 0.3)
          # Use default model from config if not specified
          resolved_model = model || Ace::PromptPrep.default_model

          # Validate and clamp temperature to valid range
          validated_temperature = [[temperature.to_f, Ace::PromptPrep.temperature_min].max, Ace::PromptPrep.temperature_max].min

          # Resolve system prompt path
          system_prompt_path = system_prompt_uri || DEFAULT_SYSTEM_PROMPT_URI

          # Load system prompt FIRST with context enrichment via session manager
          # This must happen before cache check so we can include resolved content in cache key
          session = EnhancementSessionManager.prepare_session(system_prompt_path)
          system_prompt = session[:content]

          unless system_prompt
            warn "Warning: Failed to load system prompt, using original content"
            return {
              content: content,
              enhanced: false,
              cached: false,
              error: session[:error] || "Failed to load system prompt"
            }
          end

          # Check cache with full key (content + model + resolved system prompt + temperature)
          # Uses resolved system_prompt content (not URI) so cache invalidates when prompt changes
          cache_key = Molecules::EnhancementTracker.cache_key(content, resolved_model, system_prompt, validated_temperature)
          if Molecules::EnhancementTracker.cached?(cache_key)
            cached_content = Molecules::EnhancementTracker.get_cached(cache_key)
            return {
              content: cached_content,
              enhanced: true,
              cached: true,
              error: nil
            }
          end

          # Call LLM
          begin
            require "ace/llm"

            result = Ace::LLM::QueryInterface.query(
              resolved_model,
              content,
              system: system_prompt,
              temperature: validated_temperature
            )

            enhanced_content = result[:text]

            # Validate response
            if enhanced_content.nil? || enhanced_content.empty?
              warn "Warning: LLM returned empty response, using original content"
              return {
                content: content,
                enhanced: false,
                cached: false,
                error: "Empty LLM response"
              }
            end

            # Store in cache
            Molecules::EnhancementTracker.store_cache(cache_key, enhanced_content)

            {
              content: enhanced_content,
              enhanced: true,
              cached: false,
              error: nil
            }
          rescue LoadError => e
            warn "Warning: ace-llm gem not available: #{e.message}"
            {
              content: content,
              enhanced: false,
              cached: false,
              error: "ace-llm not available"
            }
          rescue => e
            warn "Warning: LLM enhancement failed: #{e.message}"
            {
              content: content,
              enhanced: false,
              cached: false,
              error: e.message
            }
          end
        end

        # Load system prompt from URI or path
        #
        # @param uri_or_path [String] System prompt URI or path
        # @return [String, nil] System prompt content or nil if failed
        def self.load_system_prompt(uri_or_path)
          # Try to resolve via ace-nav if it's a protocol URI
          if uri_or_path.include?("://")
            begin
              require "ace/support/nav/organisms/navigation_engine"

              engine = Ace::Support::Nav::Organisms::NavigationEngine.new

              # First try to get content directly (most efficient)
              content = engine.resolve(uri_or_path, content: true)
              return content if content.is_a?(String) && !content.empty?

              # Fallback: resolve to path and read file
              # Note: resolve() without options returns a string path, not a hash
              result = engine.resolve(uri_or_path)
              if result.is_a?(String) && File.exist?(result)
                return File.read(result, encoding: "utf-8")
              end
            rescue LoadError => e
              warn "Warning: ace-nav not available: #{e.message}" if ENV["DEBUG"]
            rescue => e
              warn "Warning: ace-nav resolution failed: #{e.message}" if ENV["DEBUG"]
            end
          end

          # Try as direct file path
          if File.exist?(uri_or_path)
            return File.read(uri_or_path, encoding: "utf-8")
          end

          # Failed to load
          nil
        rescue => e
          warn "Warning: Failed to load system prompt: #{e.message}"
          nil
        end
      end
    end
  end
end
