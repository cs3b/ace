# frozen_string_literal: true

require "json"
require "open3"
require "shellwords"

require_relative "cli_args_support"
require_relative "atoms/command_rewriter"
require_relative "atoms/command_formatters"
require_relative "molecules/skill_name_reader"

module Ace
  module LLM
    module Providers
      module CLI
        # Client for interacting with Pi CLI
        # Provides access to multiple AI providers through Pi's unified platform
        # with skill command rewriting support
        class PiClient < Ace::LLM::Organisms::BaseClient
          include CliArgsSupport

          API_BASE_URL = "https://pi.dev"
          DEFAULT_GENERATION_CONFIG = {}.freeze

          def self.provider_name
            "pi"
          end

          DEFAULT_MODEL = "zai/glm-4.7"

          def initialize(model: nil, **options)
            @model = model || DEFAULT_MODEL
            @options = options
            @generation_config = options[:generation_config] || {}
            @skill_name_reader = Molecules::SkillNameReader.new
          end

          def needs_credentials?
            false
          end

          # Generate a response from the LLM
          # @param messages [Array<Hash>] Conversation messages
          # @param options [Hash] Generation options
          # @return [Hash] Response with text and metadata
          def generate(messages, **options)
            validate_pi_availability!

            prompt = format_messages_as_prompt(messages)
            full_prompt, system_prompt = build_full_prompt(prompt, options)
            full_prompt = rewrite_skill_commands(full_prompt)

            cmd = build_pi_command(full_prompt, options, system_prompt: system_prompt)
            stdout, stderr, status = execute_pi_command(cmd)

            parse_pi_response(stdout, stderr, status, full_prompt, options)
          rescue => e
            handle_pi_error(e)
          end

          # List available Pi models
          def list_models
            [
              { id: "zai/glm-4.7", name: "GLM 4.7", description: "ZAI default model", context_size: 128_000 },
              { id: "anthropic/claude-opus-4-6", name: "Claude Opus 4.6", description: "Anthropic flagship", context_size: 200_000 },
              { id: "anthropic/claude-sonnet-4-5", name: "Claude Sonnet 4.5", description: "Anthropic balanced", context_size: 200_000 },
              { id: "anthropic/claude-haiku-4-5", name: "Claude Haiku 4.5", description: "Anthropic fast", context_size: 200_000 },
              { id: "google-gemini-cli/gemini-2.5-pro", name: "Gemini 2.5 Pro", description: "Google advanced", context_size: 1_000_000 },
              { id: "google-gemini-cli/gemini-2.5-flash", name: "Gemini 2.5 Flash", description: "Google fast", context_size: 1_000_000 },
              { id: "openai-codex/gpt-5.2", name: "GPT 5.2", description: "OpenAI model", context_size: 128_000 }
            ]
          end

          private

          def format_messages_as_prompt(messages)
            return messages if messages.is_a?(String)

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

          # Build full prompt, using --system-prompt flag for system content
          # when possible, otherwise prepending to prompt.
          #
          # @param prompt [String] The main user prompt
          # @param options [Hash] Options that may contain system instruction keys
          # @return [Array(String, String)] [prompt, system_prompt] pair
          def build_full_prompt(prompt, options)
            prompt_str = prompt.to_s

            # If prompt already has system instruction from message formatting, use as-is
            return [prompt_str, nil] if prompt_str.start_with?("System:")

            system_content = options[:system_instruction] ||
                           options[:system] ||
                           options[:system_prompt] ||
                           @generation_config[:system_prompt]

            [prompt_str, system_content]
          end

          # Rewrite /name → /skill:name in the prompt for known skills
          def rewrite_skill_commands(prompt)
            skills_dir = resolve_skills_dir
            return prompt unless skills_dir

            skill_names = @skill_name_reader.call(skills_dir)
            return prompt if skill_names.empty?

            Atoms::CommandRewriter.call(prompt, skill_names: skill_names, formatter: Atoms::CommandFormatters::PI_FORMATTER)
          end

          def resolve_skills_dir
            configured = @options[:skills_dir] || @generation_config[:skills_dir]
            return configured if configured && Dir.exist?(configured)

            candidate_dir = File.join(Dir.pwd, ".pi", "skills")
            candidate_dir if Dir.exist?(candidate_dir)
          end

          # Build the pi command array
          #
          # @param full_prompt [String] The complete prompt
          # @param options [Hash] Generation options
          # @param system_prompt [String, nil] System prompt for --system-prompt flag
          # @return [Array<String>] Command array
          def build_pi_command(full_prompt, options, system_prompt: nil)
            cmd = ["pi"]

            # Print mode (non-interactive, one-shot)
            cmd << "-p" << full_prompt.to_s

            # No session (stateless)
            cmd << "--no-session"

            # No skills (we handle skill content ourselves in one-shot mode)
            cmd << "--no-skills"

            # System prompt via native flag if available
            if system_prompt
              cmd << "--system-prompt" << system_prompt
            end

            # Provider/model from the model string (format: "provider/model")
            model_to_use = @model || @generation_config[:model] || DEFAULT_MODEL
            provider_name, model_id = split_provider_model(model_to_use)
            if provider_name && model_id
              cmd << "--provider" << provider_name
              cmd << "--model" << model_id
            end

            # User CLI args after generated flags (last-wins precedence)
            cmd.concat(normalized_cli_args(options))

            cmd
          end

          # Split "provider/model" into ["provider", "model"]
          # Handles multi-segment providers like "google-gemini-cli/gemini-2.5-pro"
          # Also handles nested providers like "openrouter:openai/gpt-oss-120b"
          def split_provider_model(model_string)
            return [nil, nil] unless model_string

            # Check for nested provider pattern (e.g., "openrouter:openai/model")
            if model_string.count(":") > 0
              parts = model_string.split(":", 2)
              if parts.length == 2 && parts[1].include?("/")
                # Nested provider: "openrouter:openai/model" -> ["openrouter", "openai/model"]
                return [parts[0], parts[1]]
              end
            end

            # Standard provider/model format
            parts = model_string.split("/", 2)
            return [nil, nil] unless parts.length == 2

            [parts[0], parts[1]]
          end

          def execute_pi_command(cmd, timeout: nil)
            timeout_val = timeout || @options[:timeout] || 120
            Molecules::SafeCapture.call(cmd, timeout: timeout_val, stdin_data: "", provider_name: "Pi")
          end

          def parse_pi_response(stdout, stderr, status, prompt, options)
            unless status.success?
              error_msg = stderr.empty? ? stdout : stderr

              if error_msg.include?("401") || error_msg.include?("Unauthorized")
                raise Ace::LLM::AuthenticationError, "Pi authentication failed. Run 'pi login' to configure credentials."
              end

              raise Ace::LLM::ProviderError, "Pi CLI failed: #{error_msg}"
            end

            # Detect NDJSON: starts with {"type":"
            if stdout.strip.start_with?('{"type":"')
              text, usage = parse_ndjson(stdout)
              response = { "usage" => normalize_usage(usage) }
            else
              # Plain text output
              text = stdout.strip
              response = {}
            end

            metadata = build_metadata(response, text, prompt, options)

            {
              text: text,
              metadata: metadata
            }
          end

          def build_metadata(response, text, prompt, options)
            usage = response["usage"] || {}

            prompt_tokens = usage["input_tokens"] || (prompt.to_s.length / 4).round
            output_tokens = usage["output_tokens"] || (text.length / 4).round

            {
              provider: "pi",
              model: @model || DEFAULT_MODEL,
              input_tokens: prompt_tokens,
              output_tokens: output_tokens,
              total_tokens: prompt_tokens + output_tokens,
              finish_reason: response["finish_reason"] || "success",
              timestamp: Time.now.utc.iso8601
            }
          end

          # Parse NDJSON output from Pi CLI when --mode json is used.
          # NDJSON is one JSON object per line, with event types like message_end, agent_end.
          #
          # @param stdout [String] The raw stdout from Pi CLI
          # @return [Array<String, Hash>] Tuple of [extracted_text, usage_hash]
          def parse_ndjson(stdout)
            lines = stdout.split("\n")
            text_parts = []
            usage = nil

            lines.each do |line|
              next if line.strip.empty?
              event = JSON.parse(line)
              case event["type"]
              when "message_end"
                # Extract text from content array
                content = event.dig("message", "content") || []
                content.each do |c|
                  text_parts << c["text"] if c["type"] == "text"
                end
                usage = event.dig("message", "usage")
              when "agent_end"
                # Fallback: extract from messages array
                messages = event["messages"] || []
                messages.each do |msg|
                  content = msg["content"] || []
                  content.each do |c|
                    text_parts << c["text"] if c["type"] == "text"
                  end
                end
                usage = messages.dig(0, "usage") if usage.nil?
              end
            end

            text = text_parts.join("")
            [text, usage || {}]
          rescue JSON::ParserError
            # If parsing fails, treat as plain text
            [stdout.strip, {}]
          end

          # Normalize Pi usage field names to our standard format.
          # Pi uses "input"/"output", we normalize to "input_tokens"/"output_tokens".
          #
          # @param usage [Hash] Raw usage hash from Pi response
          # @return [Hash] Normalized usage hash
          def normalize_usage(usage)
            return {} unless usage
            {
              "input_tokens" => usage["input"] || usage["input_tokens"],
              "output_tokens" => usage["output"] || usage["output_tokens"]
            }.compact
          end

          def pi_available?
            system("which pi > /dev/null 2>&1")
          end

          def validate_pi_availability!
            unless pi_available?
              raise Ace::LLM::ProviderError, "Pi CLI not found. Install from: https://pi.dev"
            end
          end

          def handle_pi_error(error)
            raise error
          end
        end
      end
    end
  end
end
