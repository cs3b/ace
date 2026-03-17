# frozen_string_literal: true

require "ace/llm"

module Ace
  module Review
    module Molecules
      # Executes LLM queries for code reviews using Ruby API
      class LlmExecutor
        # Warning threshold: 80% of typical 200K context window
        PROMPT_SIZE_WARNING_THRESHOLD = 160_000

        def initialize
          @default_model = Ace::Review.get("defaults", "model") || "google:gemini-2.5-flash"
        end

        # Execute an LLM query using Ruby API
        # @param system_prompt [String] system prompt
        # @param user_prompt [String] user prompt
        # @param model [String] the model to use
        # @param session_dir [String] the session directory for output
        # @param output_file [String, nil] optional custom output file path
        # @return [Hash] result with success, response, output_file, metadata, and error keys
        def execute(system_prompt:, user_prompt:, model: nil, session_dir:, output_file: nil)
          model ||= @default_model

          # Warn if prompt is large
          warn_if_prompt_large(system_prompt, user_prompt, model)

          # Check if ace-llm Ruby API is available
          unless ruby_api_available?
            return {
              success: false,
              response: nil,
              error: "ace-llm Ruby API not available. Please install ace-llm gem or use --dry-run"
            }
          end

          # Use Ruby API directly for v0.13.0 architecture
          execute_with_ruby_api(system_prompt, user_prompt, model, session_dir, output_file)
        rescue StandardError => e
          {
            success: false,
            response: nil,
            error: "LLM execution failed: #{e.message}"
          }
        end

        private

        # Warn if prompt size may exceed model context limits
        #
        # Uses rough estimate of 4 characters per token. Warns at 80% of
        # typical context window to give user advance notice before execution fails.
        #
        # @param system_prompt [String, nil] system prompt
        # @param user_prompt [String, nil] user prompt
        # @param model [String] model identifier
        def warn_if_prompt_large(system_prompt, user_prompt, model)
          total_chars = (system_prompt&.length || 0) + (user_prompt&.length || 0)
          estimated_tokens = total_chars / 4  # Rough estimate: 4 chars per token

          return unless estimated_tokens > PROMPT_SIZE_WARNING_THRESHOLD

          warn "Warning: Prompt size (~#{estimated_tokens.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')} tokens) " \
               "may exceed #{model} context limits"
        end

        # Check if Ruby API is available
        def ruby_api_available?
          defined?(Ace::LLM::QueryInterface)
        end

        # Execute using Ruby API with system/user prompts
        def execute_with_ruby_api(system_prompt, user_prompt, model, session_dir, custom_output_file = nil)
          # Use custom output file if provided, otherwise generate default
          output_file = if custom_output_file
                         custom_output_file
                       else
                         # Extract model short name for output filename
                         model_short = model.include?(":") ? model.split(":", 2).last : model
                         File.join(session_dir, "review-report-#{model_short}.md")
                       end

          # Build file paths for providers that support file-based prompts (e.g., Gemini CLI)
          # These files are already saved by ReviewManager in the session directory
          system_file = File.join(session_dir, "system.prompt.md")
          prompt_file = File.join(session_dir, "user.prompt.md")

          # Use Ruby API directly
          result = Ace::LLM::QueryInterface.query(
            model,
            user_prompt,
            system: system_prompt,
            system_file: File.exist?(system_file) ? system_file : nil,
            prompt_file: File.exist?(prompt_file) ? prompt_file : nil,
            output: output_file,
            format: "text",
            timeout: 600,
            force: true,
            fallback: false  # Disable ace-llm fallback - ace-review handles retries
          )

          # Return structured result with rich metadata
          {
            success: true,
            response: result[:text],
            output_file: output_file,
            metadata: result[:metadata],
            usage: result[:usage],
            model_info: result[:model],
            provider_info: result[:provider],
            error: nil
          }
        rescue Ace::LLM::Error => e
          {
            success: false,
            response: nil,
            error: "LLM error: #{e.message}",
            error_type: e.class.name
          }
        rescue => e
          {
            success: false,
            response: nil,
            error: "Unexpected error: #{e.message}",
            error_type: e.class.name
          }
        end
      end
    end
  end
end
