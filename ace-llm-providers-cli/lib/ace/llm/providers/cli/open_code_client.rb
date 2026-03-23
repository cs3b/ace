# frozen_string_literal: true

require "json"
require "open3"
require "shellwords"

require_relative "cli_args_support"
require_relative "atoms/execution_context"

module Ace
  module LLM
    module Providers
      module CLI
        # Client for interacting with OpenCode CLI
        # Provides access to multiple AI providers through OpenCode's unified platform
        class OpenCodeClient < Ace::LLM::Organisms::BaseClient
          include CliArgsSupport

          # Not used for CLI interaction but required by BaseClient
          API_BASE_URL = "https://models.dev"
          DEFAULT_GENERATION_CONFIG = {}.freeze

          # Provider registration - auto-registers as "opencode"
          def self.provider_name
            "opencode"
          end

          # Default model (can be overridden by config)
          DEFAULT_MODEL = "google/gemini-2.5-flash"

          def initialize(model: nil, **options)
            @model = model || DEFAULT_MODEL
            # Skip normal BaseClient initialization that requires API key
            @options = options
            @generation_config = options[:generation_config] || {}
          end

          # Override to indicate this client doesn't need API credentials
          def needs_credentials?
            false
          end

          # Generate a response from the LLM
          # @param messages [Array<Hash>] Conversation messages
          # @param options [Hash] Generation options
          # @return [Hash] Response with text and metadata
          def generate(messages, **options)
            validate_opencode_availability!

            # Convert messages to prompt format
            prompt = format_messages_as_prompt(messages)

            # Build full prompt with system instruction for accurate token accounting
            full_prompt = build_full_prompt(prompt, options)

            cmd = build_opencode_command_with_prompt(full_prompt, options)
            stdout, stderr, status = execute_opencode_command(cmd, options: options)

            parse_opencode_response(stdout, stderr, status, full_prompt, options)
          rescue => e
            handle_opencode_error(e)
          end

          # List available OpenCode models
          def list_models
            # Return a standard set of models that OpenCode typically supports
            # Actual models come from YAML config
            [
              {id: "google/gemini-2.5-flash", name: "Gemini 2.5 Flash", description: "Fast Google model", context_size: 1_000_000},
              {id: "google/gemini-2.0-flash-experimental", name: "Gemini 2.0 Flash", description: "Experimental Google model", context_size: 1_000_000},
              {id: "google/gemini-1.5-pro", name: "Gemini 1.5 Pro", description: "Advanced Google model", context_size: 2_000_000},
              {id: "anthropic/claude-3-5-sonnet", name: "Claude 3.5 Sonnet", description: "Anthropic model", context_size: 200_000},
              {id: "anthropic/claude-3-5-haiku", name: "Claude 3.5 Haiku", description: "Fast Anthropic model", context_size: 200_000},
              {id: "openai/gpt-4o", name: "GPT-4 Omni", description: "OpenAI model", context_size: 128_000},
              {id: "openai/gpt-4o-mini", name: "GPT-4 Omni Mini", description: "Small OpenAI model", context_size: 128_000}
            ]
          end

          private

          def format_messages_as_prompt(messages)
            # Handle both array of message hashes and string prompt
            return messages if messages.is_a?(String)

            # Convert array of messages to formatted prompt
            formatted = messages.map do |msg|
              role = msg[:role] || msg["role"]
              content = msg[:content] || msg["content"]

              case role
              when "system"
                "System: #{content}"
              when "user"
                "User: #{content}"
              when "assistant"
                "Assistant: #{content}"
              else
                content
              end
            end

            formatted.join("\n\n")
          end

          def opencode_available?
            system("which opencode > /dev/null 2>&1")
          end

          def validate_opencode_availability!
            unless opencode_available?
              raise Ace::LLM::ProviderError, "OpenCode CLI not found. Install with: npm install -g opencode-cli or visit https://opencode.dev"
            end

            # Check if OpenCode is authenticated (quick check)
            unless opencode_authenticated?
              raise Ace::LLM::AuthenticationError, "OpenCode authentication required. Run 'opencode auth' to configure"
            end
          end

          def opencode_authenticated?
            # Quick check if OpenCode can execute (will fail fast if not authenticated)

            cmd = ["opencode", "--version"]
            _, _, status = Open3.capture3(*cmd)
            status.success?
          rescue
            false
          end

          # Build command array with pre-built full prompt
          # @param full_prompt [String] The complete prompt (already includes system instruction if any)
          # @param options [Hash] Generation options (unused for command flags, kept for API compatibility)
          # @return [Array<String>] Command array ready for execution
          def build_opencode_command_with_prompt(full_prompt, options)
            cmd = ["opencode", "run"]

            # Add model selection with fallback chain
            model_to_use = @model || @generation_config[:model] || DEFAULT_MODEL
            cmd << "--model" << model_to_use

            # Add JSON format for structured output (less likely to prompt interactively)
            cmd << "--format" << "json"

            # User CLI args after generated flags so they take precedence (last-wins),
            # but before positional prompt arg
            cmd.concat(normalized_cli_args(options))

            # Prompt is passed as positional argument (not via --prompt flag)
            # NOTE: OpenCode CLI does not support --temperature, --max-tokens, or --system flags
            # Coerce to string to handle nil or non-string inputs gracefully
            cmd << full_prompt.to_s

            cmd
          end

          # Legacy method for backward compatibility and tests
          # @deprecated Use build_full_prompt + build_opencode_command_with_prompt instead
          def build_opencode_command(prompt, options)
            full_prompt = build_full_prompt(prompt, options)
            build_opencode_command_with_prompt(full_prompt, options)
          end

          # Build full prompt by prepending system instruction if provided
          #
          # OpenCode CLI does not support a --system flag, so we prepend system
          # instructions to the main prompt using the "System: " prefix format.
          #
          # @param prompt [String] The main user prompt (may already contain "System:" from message formatting)
          # @param options [Hash] Options that may contain system instruction keys
          # @return [String] Full prompt with system instruction prepended if provided
          # @note System instruction priority order (first match wins):
          #   1. options[:system_instruction]
          #   2. options[:system]
          #   3. options[:system_prompt]
          #   4. @generation_config[:system_prompt]
          # @note If the prompt already starts with "System:" (from format_messages_as_prompt),
          #   the options-based system instruction is skipped to avoid duplication.
          def build_full_prompt(prompt, options)
            prompt_str = prompt.to_s

            # Skip prepending if prompt already has a system instruction from message formatting
            # This prevents double "System:" prefixes when messages contain role: "system"
            return prompt_str if prompt_str.start_with?("System:")

            system_content = options[:system_instruction] ||
              options[:system] ||
              options[:system_prompt] ||
              @generation_config[:system_prompt]

            if system_content
              "System: #{system_content}\n\n#{prompt_str}"
            else
              prompt_str
            end
          end

          def execute_opencode_command(cmd, timeout: nil, options: {})
            timeout_val = timeout || @options[:timeout] || 120
            working_dir = Atoms::ExecutionContext.resolve_working_dir(
              working_dir: options[:working_dir],
              subprocess_env: options[:subprocess_env]
            )
            Molecules::SafeCapture.call(
              cmd,
              timeout: timeout_val,
              stdin_data: "",
              chdir: working_dir,
              provider_name: "OpenCode"
            )
          end

          def parse_opencode_response(stdout, stderr, status, prompt, options)
            unless status.success?
              error_msg = stderr.empty? ? stdout : stderr

              # Detect common error patterns for better error messages
              if error_msg.include?("400") || error_msg.include?("Bad Request")
                raise Ace::LLM::ProviderError, "OpenCode API request failed (400 Bad Request). The model or prompt may be invalid."
              end

              raise Ace::LLM::ProviderError, "OpenCode CLI failed: #{error_msg}"
            end

            begin
              # Try to parse as JSON first
              response = JSON.parse(stdout)
              text = response["result"] || response["text"] || response["response"] || ""
            rescue JSON::ParserError
              # Fall back to treating entire output as text
              text = stdout.strip
              response = {}
            end

            # Build metadata
            metadata = build_metadata(response, text, prompt, options)

            # Return hash compatible with ace-llm format
            {
              text: text,
              metadata: metadata
            }
          end

          def build_metadata(response, text, prompt, options)
            # Build standard metadata structure
            usage = response["usage"] || {}

            # Rough token estimation if not provided
            prompt_tokens = usage["input_tokens"] || (prompt.to_s.length / 4).round
            output_tokens = usage["output_tokens"] || (text.length / 4).round

            {
              provider: "opencode",
              model: @model || DEFAULT_MODEL,
              input_tokens: prompt_tokens,
              output_tokens: output_tokens,
              total_tokens: prompt_tokens + output_tokens,
              finish_reason: response["finish_reason"] || "success",
              timestamp: Time.now.utc.iso8601
            }
          end

          def handle_opencode_error(error)
            # Re-raise the error for proper handling by the base client error flow
            raise error
          end
        end
      end
    end
  end
end
