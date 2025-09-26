# frozen_string_literal: true

require "open3"
require "json"
require "shellwords"
require "timeout"

module Ace
  module LLM
    module Providers
      module CLI
        # Client for interacting with Codex OSS CLI
        # Provides access to open source code models through subprocess execution
        class CodexOSSClient < Ace::LLM::Organisms::BaseClient
          # Not used for CLI interaction but required by BaseClient
          API_BASE_URL = "https://codex-oss.dev"
          DEFAULT_GENERATION_CONFIG = {}.freeze

          # Provider registration - auto-registers as "codexoss"
          def self.provider_name
            "codexoss"
          end

          # Default model
          DEFAULT_MODEL = "default"

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
            validate_codexoss_availability!

            # Convert messages to prompt format
            prompt = format_messages_as_prompt(messages)

            cmd = build_codexoss_command(prompt, options)
            stdout, stderr, status = execute_codexoss_command(cmd)

            parse_codexoss_response(stdout, stderr, status, prompt, options)
          rescue => e
            handle_codexoss_error(e)
          end

          # List available Codex OSS models
          def list_models
            # Codex OSS typically has a single default model
            [
              {
                id: "default",
                name: "Codex OSS Default",
                description: "Open source code generation model",
                context_size: 16_384
              }
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

          def codexoss_available?
            system("which codex-oss > /dev/null 2>&1")
          end

          def validate_codexoss_availability!
            unless codexoss_available?
              raise Ace::LLM::ProviderError, "Codex OSS CLI not found. Install with: pip install codex-oss or visit https://github.com/codex-oss/codex"
            end

            # Check if Codex OSS is properly configured
            unless codexoss_configured?
              raise Ace::LLM::AuthenticationError, "Codex OSS not configured. Run 'codex-oss init' to set up"
            end
          end

          def codexoss_configured?
            # Quick check if Codex OSS can execute
            begin
              cmd = ["codex-oss", "--version"]
              stdout, _, status = Open3.capture3(*cmd)
              status.success? && stdout.include?("codex")
            rescue
              false
            end
          end

          def build_codexoss_command(prompt, options)
            cmd = ["codex-oss", "generate"]

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
              cmd << "--max-length" << max_tokens.to_s
            end

            # Add system prompt if provided
            system_content = options[:system_instruction] ||
                           options[:system] ||
                           options[:system_prompt] ||
                           @generation_config[:system_prompt]

            if system_content
              cmd << "--context" << system_content.to_s
            end

            # Request JSON output if supported
            cmd << "--format" << "json"

            cmd
          end

          def execute_codexoss_command(cmd)
            # Execute with timeout to prevent hanging
            timeout_val = @options[:timeout] || 120
            Timeout.timeout(timeout_val) do
              Open3.capture3(*cmd)
            end
          rescue Timeout::Error
            raise Ace::LLM::ProviderError, "Codex OSS CLI execution timed out after #{timeout_val} seconds"
          end

          def parse_codexoss_response(stdout, stderr, status, prompt, options)
            unless status.success?
              error_msg = stderr.empty? ? stdout : stderr
              raise Ace::LLM::ProviderError, "Codex OSS CLI failed: #{error_msg}"
            end

            begin
              # Try to parse as JSON first
              response = JSON.parse(stdout)
              text = response["output"] || response["text"] || response["result"] || ""
            rescue JSON::ParserError
              # Fall back to treating entire output as text
              # Codex OSS might output plain text
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
            # Codex OSS may not provide detailed usage stats

            # Rough token estimation
            prompt_tokens = (prompt.to_s.length / 4).round
            output_tokens = (text.length / 4).round

            {
              provider: "codexoss",
              model: @model || DEFAULT_MODEL,
              input_tokens: prompt_tokens,
              output_tokens: output_tokens,
              total_tokens: prompt_tokens + output_tokens,
              finish_reason: response["stop_reason"] || "success",
              timestamp: Time.now.utc.iso8601,
              provider_specific: {
                processing_time: response["processing_time"],
                model_version: response["model_version"]
              }.compact
            }
          end

          def handle_codexoss_error(error)
            # Re-raise the error for proper handling by the base client error flow
            raise error
          end
        end
      end
    end
  end
end