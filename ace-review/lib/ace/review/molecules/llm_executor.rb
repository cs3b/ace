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
        # @param reviewer [Models::Reviewer, nil] optional reviewer for provider options
        # @return [Hash] result with success, response, output_file, metadata, and error keys
        def execute(system_prompt:, user_prompt:, model: nil, session_dir:, output_file: nil, reviewer: nil)
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
          execute_with_ruby_api(system_prompt, user_prompt, model, session_dir, output_file, reviewer)
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
        def execute_with_ruby_api(system_prompt, user_prompt, model, session_dir, custom_output_file = nil, reviewer = nil)
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

          provider_options = extract_provider_options(reviewer)
          query_options = build_query_options(
            system_prompt: system_prompt,
            output_file: output_file,
            system_file: system_file,
            prompt_file: prompt_file,
            provider_options: provider_options
          )

          # Use Ruby API directly
          result = Ace::LLM::QueryInterface.query(model, user_prompt, **query_options)

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

        # Build QueryInterface options from fixed defaults and reviewer provider options.
        #
        # Provider options are currently intended to control runtime behavior such as
        # timeout, sandbox mode and CLI args, and are defined per provider/reviewer.
        def build_query_options(system_prompt:, output_file:, system_file:, prompt_file:, provider_options:)
          query_options = {
            system: system_prompt,
            system_file: File.exist?(system_file) ? system_file : nil,
            prompt_file: File.exist?(prompt_file) ? prompt_file : nil,
            output: output_file,
            format: "text",
            force: true,
            fallback: false # Disable ace-llm fallback - ace-review handles retries
          }

          sandbox = provider_options[:sandbox]
          cli_args = provider_options[:cli_args]
          cli_args = normalize_cli_args(Array(cli_args), sandbox) if cli_args
          query_options[:cli_args] = cli_args if cli_args && !cli_args.empty?
          query_options[:sandbox] = sandbox if sandbox
          timeout = provider_options[:timeout] || Ace::Review.get("defaults", "llm_timeout")
          query_options[:timeout] = timeout.to_i if timeout

          query_options
        end

        # Extract provider options from reviewer while allowing nil reviewer.
        # Keys are normalized to symbols to simplify downstream usage.
        def extract_provider_options(reviewer)
          return {} unless reviewer

          provider_options = reviewer.respond_to?(:provider_options) ? reviewer.provider_options : nil
          return {} unless provider_options

          provider_options = provider_options.to_h if provider_options.respond_to?(:to_h)
          return {} unless provider_options.is_a?(Hash)

          provider_options.each_with_object({}) do |(key, value), acc|
            symbolized_key = key.to_sym
            next if symbolized_key.to_s.empty?
            acc[symbolized_key] = value
          end
        end

        # Remove duplicate sandbox flags from provider CLI args when sandbox is also
        # passed explicitly as a query option.
        def normalize_cli_args(cli_args, sandbox)
          return cli_args unless sandbox

          normalized = []
          index = 0

          while index < cli_args.length
            current = cli_args[index].to_s
            next_value = cli_args[index + 1]&.to_s

            if current == "--sandbox" && next_value == sandbox.to_s
              index += 2
              next
            end

            if current.start_with?("--sandbox=")
              value = current.sub("--sandbox=", "")
              if value == sandbox.to_s
                index += 1
                next
              end
            end

            normalized << cli_args[index]
            index += 1
          end

          normalized
        end
      end
    end
  end
end
