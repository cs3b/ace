# frozen_string_literal: true

require "open3"
require "json"
require "shellwords"
require "timeout"

module Ace
  module LLM
    module Providers
      module CLI
        # Client for interacting with Codex CLI (OpenAI)
        # Provides access to Codex models through subprocess execution
        class CodexClient < Ace::LLM::Organisms::BaseClient
          # Not used for CLI interaction but required by BaseClient
          API_BASE_URL = "https://api.openai.com"
          DEFAULT_GENERATION_CONFIG = {}.freeze

          # Provider registration - auto-registers as "codex"
          def self.provider_name
            "codex"
          end

          # Default model (can be overridden by config)
          DEFAULT_MODEL = "gpt-5"

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
            validate_codex_availability!

            # Convert messages to prompt format
            prompt = format_messages_as_prompt(messages)

            cmd = build_codex_command(prompt, options)
            stdout, stderr, status = execute_codex_command(cmd, prompt, options)

            parse_codex_response(stdout, stderr, status, prompt, options)
          rescue => e
            handle_codex_error(e)
          end

          # List available Codex models
          def list_models
            # Return models based on what the CLI supports
            # Actual models come from YAML config
            [
              { id: "gpt-5", name: "GPT-5", description: "Advanced Codex model", context_size: 128_000 },
              { id: "gpt-5-mini", name: "GPT-5 Mini", description: "Smaller, faster model", context_size: 128_000 }
            ]
          end

          private


          def format_messages_as_prompt(messages)
            # Handle both array of message hashes and string prompt
            return messages if messages.is_a?(String)

            # Extract system message if present
            system_msg = messages.find { |m| (m[:role] || m["role"]) == "system" }
            other_msgs = messages.reject { |m| (m[:role] || m["role"]) == "system" }

            # Format remaining messages
            formatted = other_msgs.map do |msg|
              role = msg[:role] || msg["role"]
              content = msg[:content] || msg["content"]

              case role
              when "user"
                "User: #{content}"
              when "assistant"
                "Assistant: #{content}"
              else
                content
              end
            end

            # Prepend system message if present
            if system_msg
              system_content = system_msg[:content] || system_msg["content"]
              formatted.unshift("System: #{system_content}")
            end

            formatted.join("\n\n")
          end

          def codex_available?
            system("which codex > /dev/null 2>&1")
          end

          def validate_codex_availability!
            unless codex_available?
              raise Ace::LLM::ProviderError, "Codex CLI not found. Install with: npm install -g @openai/codex or visit https://codex.ai"
            end

            # Check if Codex is authenticated
            unless codex_authenticated?
              raise Ace::LLM::AuthenticationError, "Codex authentication required. Run 'codex login' or configure API key"
            end
          end

          def codex_authenticated?
            # Quick check if Codex can execute (will fail fast if not authenticated)
            begin
              cmd = ["codex", "--version"]
              stdout, _, status = Open3.capture3(*cmd)
              return status.success? && (stdout.include?("codex") || stdout.include?("Codex"))
            rescue
              # If version check fails, try help command
              begin
                cmd = ["codex", "--help"]
                _, _, status = Open3.capture3(*cmd)
                return status.success?
              rescue
                return false
              end
            end
          end

          def build_codex_command(prompt, options)
            # Use codex exec for non-interactive execution
            cmd = ["codex", "exec"]

            # Add model selection if not default
            if @model && @model != DEFAULT_MODEL
              cmd << "--model" << @model
            end

            # Note: Codex exec doesn't support direct system prompts or temperature/max_tokens
            # These would need to be incorporated into the prompt itself

            cmd
          end

          def execute_codex_command(cmd, prompt, options)
            # Prepare the input - combine system prompt with user prompt if needed
            input = prompt.to_s

            # Check for system prompt in options or generation config
            system_content = options[:system_instruction] ||
                           options[:system] ||
                           options[:system_prompt] ||
                           @generation_config[:system_prompt]

            if system_content && !prompt.include?("System:")
              input = "System: #{system_content}\n\nUser: #{input}"
            end

            # Execute with timeout to prevent hanging, piping prompt via stdin
            timeout_val = @options[:timeout] || 120
            Timeout.timeout(timeout_val) do
              Open3.capture3(*cmd, stdin_data: input)
            end
          rescue Timeout::Error
            raise Ace::LLM::ProviderError, "Codex CLI execution timed out after #{timeout_val} seconds"
          end

          def parse_codex_response(stdout, stderr, status, prompt, options)
            unless status.success?
              error_msg = stderr.empty? ? stdout : stderr
              raise Ace::LLM::ProviderError, "Codex CLI failed: #{error_msg}"
            end

            # Parse Codex output format to extract the actual response
            # Codex output includes metadata lines and the actual response
            lines = stdout.split("\n")

            # Find where the actual response starts (after "codex" header)
            response_start = lines.find_index { |line| line.include?("codex") }

            if response_start && response_start < lines.length - 1
              # Extract text after the "codex" line, skipping empty lines
              response_lines = lines[(response_start + 1)..-1]
              # Remove token usage lines at the end
              response_lines = response_lines.reject { |line| line.include?("tokens used:") }
              text = response_lines.join("\n").strip
            else
              # Fallback: use entire output if we can't parse the format
              text = stdout.strip
            end

            # Build metadata
            metadata = build_synthetic_metadata(text, prompt)

            # Return hash compatible with ace-llm format
            {
              text: text,
              metadata: metadata
            }
          end

          def build_synthetic_metadata(response_text, prompt)
            # Create synthetic metadata since Codex CLI might not provide detailed usage info
            # Rough token estimation
            prompt_tokens = (prompt.to_s.length / 4).round # Rough estimate: 4 chars per token
            response_tokens = (response_text.length / 4).round

            {
              provider: "codex",
              model: @model || DEFAULT_MODEL,
              input_tokens: prompt_tokens,
              output_tokens: response_tokens,
              total_tokens: prompt_tokens + response_tokens,
              finish_reason: "success",
              timestamp: Time.now.utc.iso8601
            }
          end

          def handle_codex_error(error)
            # Re-raise the error for proper handling by the base client error flow
            raise error
          end
        end
      end
    end
  end
end