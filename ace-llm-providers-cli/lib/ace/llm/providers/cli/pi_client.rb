# frozen_string_literal: true

require "json"
require "open3"
require "shellwords"

require_relative "cli_args_support"
require_relative "atoms/execution_context"
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

          DEFAULT_MODEL = "zai/glm-5.3-flash"

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
            subprocess_env = options[:subprocess_env]
            working_dir = Atoms::ExecutionContext.resolve_working_dir(
              working_dir: options[:working_dir],
              subprocess_env: subprocess_env
            )
            full_prompt = rewrite_skill_commands(full_prompt, working_dir: working_dir)

            cmd = build_pi_command(full_prompt, options, system_prompt: system_prompt)
            capture = execute_pi_command(cmd, working_dir: working_dir, options: options)
            begin
              capture.raise_unless_success
            rescue Ace::LLM::ProviderError
              raise if !capture.status || capture.status.success?

              # 401 output means credentials, not a generic CLI failure —
              # AuthenticationError classifies as skip-to-next-provider.
              raise auth_error if captured_auth_failure?(capture)

              raise
            end

            parse_pi_response(capture, full_prompt, options)
          rescue => e
            handle_pi_error(e)
          end

          # List available Pi models
          def list_models
            [
              {id: "zai/glm-5.3", name: "GLM 5.3", description: "ZAI flagship model", context_size: 1_000_000},
              {id: "zai/glm-5.3-flash", name: "GLM 5.3 Flash", description: "ZAI routine default", context_size: 1_000_000},
              {id: "zai/glm-5.3-highspeed", name: "GLM 5.3 Highspeed", description: "ZAI low-latency model", context_size: 1_000_000},
              {id: "anthropic/claude-opus-4-6", name: "Claude Opus 4.6", description: "Anthropic flagship", context_size: 200_000},
              {id: "anthropic/claude-sonnet-4-5", name: "Claude Sonnet 4.5", description: "Anthropic balanced", context_size: 200_000},
              {id: "anthropic/claude-haiku-4-5", name: "Claude Haiku 4.5", description: "Anthropic fast", context_size: 200_000},
              {id: "google-gemini-cli/gemini-2.5-pro", name: "Gemini 2.5 Pro", description: "Google advanced", context_size: 1_000_000},
              {id: "google-gemini-cli/gemini-2.5-flash", name: "Gemini 2.5 Flash", description: "Google fast", context_size: 1_000_000},
              {id: "openai-codex/gpt-5.2", name: "GPT 5.2", description: "OpenAI model", context_size: 128_000}
            ]
          end

          def interactive_supported?
            true
          end

          def build_interactive_invocation(messages, **options)
            validate_pi_availability!

            prompt = format_messages_as_prompt(messages)
            full_prompt, system_prompt = build_full_prompt(prompt, options)
            subprocess_env = options[:subprocess_env]
            working_dir = Atoms::ExecutionContext.resolve_working_dir(
              working_dir: options[:working_dir],
              subprocess_env: subprocess_env
            )
            full_prompt = rewrite_skill_commands(full_prompt, working_dir: working_dir)

            cmd = build_pi_interactive_command(full_prompt, options, system_prompt: system_prompt)
            {
              command: cmd,
              env: subprocess_env,
              working_dir: working_dir,
              prompt: full_prompt
            }
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
          def rewrite_skill_commands(prompt, working_dir: nil)
            skills_dir = resolve_skills_dir(working_dir: working_dir)
            return prompt unless skills_dir

            skill_names = @skill_name_reader.call(skills_dir)
            return prompt if skill_names.empty?

            Atoms::CommandRewriter.call(prompt, skill_names: skill_names, formatter: Atoms::CommandFormatters::PI_FORMATTER)
          end

          def resolve_skills_dir(working_dir: nil)
            configured = @options[:skills_dir] || @generation_config[:skills_dir]
            return configured if configured && Dir.exist?(configured)

            working_dir ||= Atoms::ExecutionContext.resolve_working_dir
            candidate_dir = File.join(working_dir, ".pi", "skills")
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

            # Keep the terminal stop reason so truncated responses cannot pass
            # as successful plain-text output.
            cmd << "--mode" << "json"

            # No skills (we handle skill content ourselves in one-shot mode)
            cmd << "--no-skills"

            # System prompt via native flag if available
            if system_prompt
              cmd << "--system-prompt" << system_prompt
            end

            # Provider/model from the model string (format: "provider/model")
            model_to_use = @model || @generation_config[:model] || DEFAULT_MODEL
            provider_name, model_id = split_provider_model(model_to_use)
            cmd << "--provider" << provider_name
            cmd << "--model" << model_id

            cmd.concat(
              normalized_cli_args_without_conflicts(
                options,
                forbidden_flags: ["--mode", "--provider", "--model", "--models"],
                label: "Pi"
              )
            )

            cmd
          end

          def build_pi_interactive_command(full_prompt, options, system_prompt: nil)
            cmd = ["pi"]

            if system_prompt
              cmd << "--system-prompt" << system_prompt
            end

            model_to_use = @model || @generation_config[:model] || DEFAULT_MODEL
            provider_name, model_id = split_provider_model(model_to_use)
            cmd << "--provider" << provider_name
            cmd << "--model" << model_id

            cmd.concat(
              normalized_cli_args_without_conflicts(
                options,
                forbidden_flags: ["-p", "--print", "--no-session", "--no-skills", "--mode", "--provider", "--model", "--models"],
                label: "Pi"
              )
            )
            cmd << full_prompt.to_s unless full_prompt.to_s.empty?
            cmd
          end

          # Split "provider/model" into ["provider", "model"]
          # Handles multi-segment providers like "google-gemini-cli/gemini-2.5-pro"
          # Also handles nested providers like "openrouter:openai/gpt-oss-120b"
          def split_provider_model(model_string)
            raise Ace::LLM::ProviderError, "Pi model must resolve to provider/model" unless model_string
            raise Ace::LLM::ProviderError, "Pi model must resolve to provider/model: #{model_string}" if model_string.start_with?(":")

            # Check for nested provider pattern (e.g., "openrouter:openai/model")
            colon = model_string.index(":")
            slash = model_string.index("/")
            if colon && (!slash || colon < slash)
              parts = model_string.split(":", 2)
              nested_parts = parts[1]&.split("/", 2)
              if parts.length == 2 && !parts[0].empty? && nested_parts&.length == 2 && nested_parts.all? { |part| !part.empty? }
                # Nested provider: "openrouter:openai/model" -> ["openrouter", "openai/model"]
                return [parts[0], parts[1]]
              end
              raise Ace::LLM::ProviderError, "Pi model must resolve to provider/model: #{model_string}"
            end

            # Standard provider/model format
            parts = model_string.split("/", 2)
            raise Ace::LLM::ProviderError, "Pi model must resolve to provider/model: #{model_string}" unless parts.length == 2 && parts.all? { |part| !part.empty? }

            [parts[0], parts[1]]
          end

          def execute_pi_command(cmd, timeout: nil, working_dir: nil, options: {})
            timeout_val = timeout || @options[:timeout] || 120
            Molecules::SafeCapture.call(
              cmd,
              timeout: timeout_val,
              stdin_data: "",
              chdir: working_dir,
              env: options[:subprocess_env],
              command_prefix: options[:subprocess_command_prefix],
              provider_name: "Pi"
            )
          end

          # 401/Unauthorized anywhere in captured output marks a credentials
          # failure rather than a generic CLI error.
          def captured_auth_failure?(capture)
            output = "#{capture.stderr}\n#{capture.stdout}"
            output.include?("401") || output.include?("Unauthorized")
          end

          def auth_error
            Ace::LLM::AuthenticationError.new("Pi authentication failed. Run 'pi login' to configure credentials.")
          end

          def parse_pi_response(capture, prompt, options)
            # Unreachable through generate (raise_unless_success precedes parse),
            # kept for direct callers: auth failures stay AuthenticationError.
            unless capture.status.success?
              error_msg = capture.stderr.empty? ? capture.stdout : capture.stderr

              if captured_auth_failure?(capture)
                raise Ace::LLM::AuthenticationError, "Pi authentication failed. Run 'pi login' to configure credentials."
              end

              raise capture.provider_error("Pi CLI failed: #{error_msg}")
            end

            text, usage, finish_reason = parse_ndjson(capture.stdout)
            response = {"usage" => normalize_usage(usage), "finish_reason" => finish_reason}

            metadata = build_metadata(response, text, prompt, options)

            {
              text: text,
              metadata: metadata
            }
          end

          # Measured usage only. When the pi CLI supplies usage the token counts
          # are recorded as-is (cached 0 means "no cache read", distinct from
          # absent); when it does not, tokens are absent entirely and the
          # session records an explicit "unavailable" state — never an estimate.
          def build_metadata(response, text, prompt, options)
            usage = response["usage"] || {}

            metadata = {
              provider: "pi",
              model: @model || DEFAULT_MODEL,
              finish_reason: response["finish_reason"] || "success",
              timestamp: Time.now.utc.iso8601
            }

            if usage["input_tokens"] || usage["output_tokens"]
              metadata[:input_tokens] = usage["input_tokens"] unless usage["input_tokens"].nil?
              metadata[:output_tokens] = usage["output_tokens"] unless usage["output_tokens"].nil?
              metadata[:cached_tokens] = usage["cached_tokens"] if usage.key?("cached_tokens")
              metadata[:total_tokens] = usage["total_tokens"] ||
                (usage["input_tokens"].to_i + usage["output_tokens"].to_i)
              metadata[:usage_status] = "measured"
            else
              metadata[:usage_status] = "unavailable"
              version = pi_version
              metadata[:pi_version] = version if version
            end

            metadata
          end

          # Best-effort pi CLI version for the usage-unavailable record. Runs
          # outside SafeCapture (a bare --version probe) and is memoized per
          # instance so retries don't re-spawn the process.
          def pi_version
            return @pi_version if defined?(@pi_version)

            @pi_version = begin
              stdout, _stderr, status = Open3.capture3("pi", "--version")
              status.success? ? stdout.strip : nil
            rescue StandardError
              nil
            end
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
            terminal_event = nil
            settled = false
            message_stop_reason = nil

            lines.each do |line|
              next if line.strip.empty?
              event = JSON.parse(line)
              raise Ace::LLM::ProviderError, "Pi JSON stream contains a non-object event" unless event.is_a?(Hash)
              case event["type"]
              when "message_end"
                # Extract text from content array
                message = event["message"] || {}
                if message["role"].nil? || message["role"] == "assistant"
                  text_parts = extract_message_text(message)
                  usage = message["usage"]
                  message_stop_reason = message["stopReason"] if message["stopReason"]
                end
              when "agent_end"
                settled = false
                if event["willRetry"]
                  text_parts.clear
                  usage = nil
                  terminal_event = nil
                  message_stop_reason = nil
                  next
                end
                terminal_event = event
                messages = event["messages"] || []
                if (last_assistant = messages.reverse.find { |msg| (msg["role"].nil? || msg["role"] == "assistant") && extract_message_text(msg).any? })
                  text_parts = extract_message_text(last_assistant)
                  usage ||= last_assistant["usage"]
                  message_stop_reason ||= last_assistant["stopReason"]
                end
              when "agent_settled"
                settled = true if terminal_event
              end
            end

            raise Ace::LLM::ProviderError, "Pi JSON stream ended without agent_end" unless terminal_event
            raise Ace::LLM::ProviderError, "Pi JSON stream ended without agent_settled" unless settled

            text = text_parts.join("")
            raise Ace::LLM::ProviderError, "Pi JSON stream produced no final assistant message" if text.strip.empty?
            terminal_reason = terminal_event["stopReason"] || terminal_event.dig("messages", -1, "stopReason")
            successful_reasons = Ace::LLM::SUCCESSFUL_FINISH_REASONS
            finish_reason = if %w[error aborted].include?(terminal_reason.to_s.downcase)
              terminal_reason
            elsif message_stop_reason && !successful_reasons.include?(message_stop_reason.to_s.downcase)
              message_stop_reason
            else
              terminal_reason || message_stop_reason || "success"
            end
            [text, usage || {}, finish_reason]
          rescue JSON::ParserError
            raise Ace::LLM::ProviderError, "Pi JSON stream contains invalid events"
          end

          def extract_message_text(message)
            Array(message["content"]).filter_map { |content| content["text"] if content["type"] == "text" }
          end

          # Normalize Pi usage field names to our standard format.
          # Pi reports input/output/cacheRead/cacheWrite/totalTokens on the
          # assistant message; we map them to *_tokens keys. A measured zero
          # cacheRead is kept (distinguishing "no cache" from "unknown"); a
          # missing key stays missing.
          #
          # @param usage [Hash] Raw usage hash from Pi response
          # @return [Hash] Normalized usage hash
          def normalize_usage(usage)
            return {} unless usage
            {
              "input_tokens" => usage["input"] || usage["input_tokens"],
              "output_tokens" => usage["output"] || usage["output_tokens"],
              "cached_tokens" => (usage["cacheRead"] if usage.key?("cacheRead")),
              "total_tokens" => (usage["totalTokens"] if usage.key?("totalTokens"))
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
