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
        # @param frontmatter [Hash] Optional frontmatter for context-based enhancement
        # @return [String] Enhanced content
        def enhance(content, system_prompt_uri: nil, frontmatter: nil)
          warn "[DEBUG] PromptEnhancer.enhance called"
          warn "[DEBUG] Frontmatter present: #{!frontmatter.nil?}"
          warn "[DEBUG] Enhancement context: #{frontmatter&.dig('enhancement', 'context')&.inspect || 'nil'}"

          # Use context-based enhancement if frontmatter has enhancement.context
          if frontmatter && frontmatter.dig("enhancement", "context")
            warn "[DEBUG] Using context-based enhancement"
            return enhance_with_context(content, frontmatter)
          end

          warn "[DEBUG] Using basic enhancement (no context found)"
          # Otherwise use simple enhancement (backward compatible)
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

        # Enhance with context using materialized session files
        # @param content [String] Content to enhance
        # @param frontmatter [Hash] Frontmatter with enhancement.context config
        # @return [String] Enhanced content
        def enhance_with_context(content, frontmatter)
          require_relative "enhancement_session_manager"

          session_manager = EnhancementSessionManager.new(@config)
          session_manager.enhance_with_context(content, frontmatter)
        rescue => e
          warn "Warning: Context-based enhancement failed: #{e.message}. Using original content."
          content
        end

        private

        def call_llm(content, system_prompt_uri)
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
          prompt_uri = uri || @config.dig("enhancement", "system_prompt") || "prompt://enhance-instructions.system"

          # Try to load via ace-nav Ruby API (security fix)
          if prompt_uri.start_with?("prompt://")
            begin
              require "ace/nav"
              require "ace/nav/organisms/navigation_engine"

              engine = Ace::Nav::Organisms::NavigationEngine.new
              path = engine.resolve(prompt_uri)
              return File.read(path) if path && File.exist?(path)
            rescue LoadError, StandardError => e
              # Fall through to default
            end
          end

          # Direct file path
          return File.read(prompt_uri) if File.exist?(prompt_uri)

          # Fallback to default system prompt
          default_system_prompt
        end

        def default_system_prompt
          <<~PROMPT
            You are an expert at refining and clarifying prompts for AI coding assistants.

            Your task: Transform the user's prompt to be more clear, specific, and actionable while preserving their original intent.

            Guidelines:
            - Break down vague requests into concrete steps
            - Specify expected inputs and outputs
            - Add relevant technical context when helpful
            - Keep the enhanced prompt concise and focused
            - Preserve the user's voice and requirements

            Output ONLY the enhanced prompt - no explanations, no meta-commentary, no quotation marks.
          PROMPT
        end
      end
    end
  end
end
