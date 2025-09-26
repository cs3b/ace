# frozen_string_literal: true

require "open3"
require "json"
require "shellwords"
require "timeout"

module Ace
  module LLM
    module Providers
      module CLI
        # Client for interacting with OpenCode CLI
        # Provides access to multiple AI providers through OpenCode's unified platform
        class OpenCodeClient < Ace::LLM::Organisms::BaseClient
          # Not used for CLI interaction but required by BaseClient
          API_BASE_URL = "https://models.dev"
          DEFAULT_GENERATION_CONFIG = {}.freeze

          # Provider registration - auto-registers as "opencode"
          def self.provider_name
            "opencode"
          end

          # Default model when user doesn't specify one
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

            cmd = build_opencode_command(prompt, options)
            stdout, stderr, status = execute_opencode_command(cmd)

            parse_opencode_response(stdout, stderr, status, prompt, options)
          rescue => e
            handle_opencode_error(e)
          end

          # List available OpenCode models
          def list_models
            unless opencode_available?
              # Fallback models when OpenCode CLI is unavailable
              return fallback_models
            end

            begin
              # Try to get models from OpenCode CLI
              cmd = ["opencode", "models"]
              stdout, stderr, status = execute_opencode_command(cmd, timeout: 30)

              unless status.success?
                # If models command fails, return fallback
                return fallback_models
              end

              parse_models_output(stdout)
            rescue => e
              # If anything goes wrong, return fallback models
              fallback_models
            end
          end

          private

          def fallback_models
            [
              # Google models
              { id: "google/gemini-2.5-flash", name: "Gemini 2.5 Flash", description: "Fast Google model", context_size: 1_000_000 },
              { id: "google/gemini-2.0-flash-experimental", name: "Gemini 2.0 Flash", description: "Experimental Google model", context_size: 1_000_000 },
              { id: "google/gemini-1.5-pro", name: "Gemini 1.5 Pro", description: "Advanced Google model", context_size: 2_000_000 },

              # Anthropic models
              { id: "anthropic/claude-3-5-sonnet", name: "Claude 3.5 Sonnet", description: "Anthropic model", context_size: 200_000 },
              { id: "anthropic/claude-3-5-haiku", name: "Claude 3.5 Haiku", description: "Fast Anthropic model", context_size: 200_000 },

              # OpenAI models
              { id: "openai/gpt-4o", name: "GPT-4 Omni", description: "OpenAI model", context_size: 128_000 },
              { id: "openai/gpt-4o-mini", name: "GPT-4 Omni Mini", description: "Small OpenAI model", context_size: 128_000 },
            ]
          end

          def parse_models_output(stdout)
            # Parse model list from OpenCode CLI output
            # Format may vary, so we'll handle common formats
            models = []

            begin
              # Try JSON parsing first
              json_data = JSON.parse(stdout)
              if json_data.is_a?(Array)
                models = json_data.map do |model|
                  {
                    id: model["id"] || model["name"],
                    name: model["display_name"] || model["name"],
                    description: model["description"] || "OpenCode model",
                    context_size: model["context_size"] || 128_000
                  }
                end
              end
            rescue JSON::ParserError
              # Fall back to line-based parsing
              stdout.lines.each do |line|
                next if line.strip.empty? || line.start_with?("#")

                # Simple format: model_id [display_name] (context_size)
                if line =~ /^([\w\/\-\.]+)/
                  model_id = $1.strip
                  models << {
                    id: model_id,
                    name: model_id.split("/").last.capitalize,
                    description: "OpenCode model",
                    context_size: 128_000
                  }
                end
              end
            end

            models.empty? ? fallback_models : models
          end

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
            begin
              cmd = ["opencode", "--version"]
              stdout, _, status = Open3.capture3(*cmd)
              status.success?
            rescue
              false
            end
          end

          def build_opencode_command(prompt, options)
            cmd = ["opencode", "generate"]

            # Add model selection
            model_to_use = @model || DEFAULT_MODEL
            cmd << "--model" << model_to_use

            # Add prompt
            cmd << "--prompt" << prompt.to_s

            # Add temperature if provided
            temp = options[:temperature] || @generation_config[:temperature]
            if temp
              cmd << "--temperature" << temp.to_s
            end

            # Add max tokens if provided
            max_tokens = options[:max_tokens] || @generation_config[:max_tokens]
            if max_tokens
              cmd << "--max-tokens" << max_tokens.to_s
            end

            # Add system prompt if provided
            system_content = options[:system_instruction] ||
                           options[:system] ||
                           options[:system_prompt] ||
                           @generation_config[:system_prompt]

            if system_content
              cmd << "--system" << system_content.to_s
            end

            # Request JSON output for consistent parsing
            cmd << "--format" << "json"

            cmd
          end

          def execute_opencode_command(cmd, timeout: nil)
            # Execute with timeout to prevent hanging
            timeout_val = timeout || @options[:timeout] || 120
            Timeout.timeout(timeout_val) do
              Open3.capture3(*cmd)
            end
          rescue Timeout::Error
            raise Ace::LLM::ProviderError, "OpenCode CLI execution timed out after #{timeout_val} seconds"
          end

          def parse_opencode_response(stdout, stderr, status, prompt, options)
            unless status.success?
              error_msg = stderr.empty? ? stdout : stderr
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