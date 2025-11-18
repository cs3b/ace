# frozen_string_literal: true

require "ace/llm"

module Ace
  module Review
    module Molecules
      # Executes LLM queries for code reviews using Ruby API
      class LlmExecutor
        def initialize
          @default_model = Ace::Review.get("defaults", "model") || "google:gemini-2.5-flash"
        end

        # Execute an LLM query using Ruby API
        # @param system_prompt [String] system prompt
        # @param user_prompt [String] user prompt
        # @param model [String] the model to use
        # @param session_dir [String] the session directory for output
        # @return [Hash] result with success, response, output_file, metadata, and error keys
        def execute(system_prompt:, user_prompt:, model: nil, session_dir:)
          model ||= @default_model

          # Check if ace-llm Ruby API is available
          unless ruby_api_available?
            return {
              success: false,
              response: nil,
              error: "ace-llm Ruby API not available. Please install ace-llm gem or use --dry-run"
            }
          end

          # Use Ruby API directly for v0.13.0 architecture
          execute_with_ruby_api(system_prompt, user_prompt, model, session_dir)
        rescue StandardError => e
          {
            success: false,
            response: nil,
            error: "LLM execution failed: #{e.message}"
          }
        end

        private

        # Check if Ruby API is available
        def ruby_api_available?
          defined?(Ace::LLM::QueryInterface)
        end

        # Execute using Ruby API with system/user prompts
        def execute_with_ruby_api(system_prompt, user_prompt, model, session_dir)
          # Extract model short name for output filename
          model_short = model.include?(":") ? model.split(":", 2).last : model
          output_file = File.join(session_dir, "review-report-#{model_short}.md")

          # Use Ruby API directly - no temp files needed!
          result = Ace::LLM::QueryInterface.query(
            model,
            user_prompt,
            system: system_prompt,
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