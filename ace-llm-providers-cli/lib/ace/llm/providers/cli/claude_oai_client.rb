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
        # Client for Claude over Anthropic-compatible APIs (Z.ai, OpenRouter, etc.)
        # Uses the claude CLI subprocess with backend-specific env vars to route
        # requests through alternative Anthropic-compatible endpoints.
        class ClaudeOaiClient < Ace::LLM::Organisms::BaseClient
          include CliArgsSupport

          API_BASE_URL = "https://api.z.ai"
          DEFAULT_GENERATION_CONFIG = {}.freeze

          def self.provider_name
            "claudeoai"
          end

          DEFAULT_MODEL = "zai/glm-5"

          def initialize(model: nil, **options)
            @model = model || DEFAULT_MODEL
            @options = options
            @generation_config = options[:generation_config] || {}
            @backends = options[:backends] || {}
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
            validate_claude_availability!

            prompt = format_messages_as_prompt(messages)
            subprocess_env = options.delete(:subprocess_env)
            working_dir = Atoms::ExecutionContext.resolve_working_dir(
              working_dir: options[:working_dir],
              subprocess_env: subprocess_env
            )
            prompt = rewrite_skill_commands(prompt, working_dir: working_dir)

            cmd = build_claude_command(options)
            stdout, stderr, status = execute_claude_command(
              cmd,
              prompt,
              subprocess_env: subprocess_env,
              working_dir: working_dir
            )

            parse_claude_response(stdout, stderr, status, prompt, options)
          rescue => e
            handle_claude_error(e)
          end

          # List available models
          def list_models
            [
              { id: "zai/glm-5", name: "GLM-5", description: "Z.ai flagship model (Anthropic-compatible)", context_size: 128_000 },
              { id: "zai/glm-4.7", name: "GLM-4.7", description: "Z.ai balanced model (Anthropic-compatible)", context_size: 128_000 },
              { id: "zai/glm-4.6", name: "GLM-4.6", description: "Z.ai fast model (Anthropic-compatible)", context_size: 128_000 }
            ]
          end

          # Split "backend/model" into ["backend", "model"]
          # @param model_string [String] e.g. "zai/glm-5"
          # @return [Array<String>] e.g. ["zai", "glm-5"]
          def split_backend_model(model_string)
            return [nil, nil] unless model_string

            parts = model_string.split("/", 2)
            return [nil, nil] unless parts.length == 2

            parts
          end

          private

          def format_messages_as_prompt(messages)
            return messages if messages.is_a?(String)

            system_msg = messages.find { |m| (m[:role] || m["role"]) == "system" }
            other_msgs = messages.reject { |m| (m[:role] || m["role"]) == "system" }

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

            if system_msg
              system_content = system_msg[:content] || system_msg["content"]
              formatted.unshift("System: #{system_content}")
            end

            formatted.join("\n\n")
          end

          def claude_available?
            system("which claude > /dev/null 2>&1")
          end

          def validate_claude_availability!
            unless claude_available?
              raise Ace::LLM::ProviderError, "Claude CLI not found. Install with: npm install -g @anthropic-ai/claude-cli"
            end
          end

          def build_claude_command(options)
            cmd = ["claude"]
            cmd << "-p"

            # Always use JSON output for consistent parsing
            cmd << "--output-format" << "json"

            # Use a tier alias (sonnet/opus/haiku) that claude CLI recognizes,
            # rather than the backend model name (e.g. glm-5) which it doesn't.
            tier = resolve_model_tier
            cmd << "--model" << tier if tier

            # Add max tokens if provided
            max_tokens = options[:max_tokens] || @generation_config[:max_tokens]
            if max_tokens
              cmd << "--max-tokens" << max_tokens.to_s
            end

            # User CLI args last so they take precedence
            cmd.concat(normalized_cli_args(options))

            cmd
          end

          def execute_claude_command(cmd, prompt, subprocess_env: nil, working_dir: nil)
            timeout_val = @options[:timeout] || 120

            # Build env with backend-specific vars for Anthropic-compatible routing
            env = {"CLAUDECODE" => nil}
            env.merge!(backend_env_vars)
            env.merge!(subprocess_env) if subprocess_env

            debug_subprocess("spawn timeout=#{timeout_val}s cmd=#{cmd.join(" ")} prompt_bytes=#{prompt.to_s.bytesize}")
            Molecules::SafeCapture.call(
              cmd,
              timeout: timeout_val,
              stdin_data: prompt.to_s,
              chdir: working_dir,
              env: env,
              provider_name: "Claude OAI"
            )
          end

          # Build env vars hash for the current backend
          # Sets ANTHROPIC_BASE_URL, ANTHROPIC_AUTH_TOKEN, and clears ANTHROPIC_API_KEY
          def backend_env_vars
            backend_name, _model_name = split_backend_model(@model)
            return {} unless backend_name

            backend_config = @backends[backend_name] || @backends[backend_name.to_sym] || {}
            return {} if backend_config.empty?

            env = {}

            # Set the base URL for the Anthropic-compatible endpoint
            if (base_url = backend_config["base_url"] || backend_config[:base_url])
              env["ANTHROPIC_BASE_URL"] = base_url
            end

            # Read the API key from the env var specified in config
            if (env_key = backend_config["env_key"] || backend_config[:env_key])
              env["ANTHROPIC_AUTH_TOKEN"] = ENV[env_key]
            end

            # Clear ANTHROPIC_API_KEY so claude doesn't use cached Anthropic creds
            env["ANTHROPIC_API_KEY"] = ""

            # Map the tier alias to the backend's actual model name so
            # `--model sonnet` resolves to e.g. "glm-5" at the backend
            _bn, model_name = split_backend_model(@model)
            tier = resolve_model_tier
            if tier && model_name
              env_key_for_tier = "ANTHROPIC_DEFAULT_#{tier.upcase}_MODEL"
              env[env_key_for_tier] = model_name
            end

            env
          end

          # Resolve which Claude CLI tier alias to use for --model.
          # Looks up model_tiers in backend config; falls back to "sonnet".
          def resolve_model_tier
            backend_name, model_name = split_backend_model(@model)
            return "sonnet" unless backend_name && model_name

            backend_config = @backends[backend_name] || @backends[backend_name.to_sym] || {}
            tiers = backend_config["model_tiers"] || backend_config[:model_tiers] || {}

            # Find the tier whose value matches the requested model.
            # Note: first matching tier wins when multiple tiers map to the same model.
            matched = tiers.find { |_tier, m| m.to_s == model_name }
            return matched[0].to_s if matched

            # No explicit tier mapping — default to sonnet
            "sonnet"
          end

          def parse_claude_response(stdout, stderr, status, prompt, options)
            unless status.success?
              error_msg = stderr.empty? ? stdout : stderr
              raise Ace::LLM::ProviderError, "Claude OAI CLI failed: #{error_msg}"
            end

            begin
              response = JSON.parse(stdout, allow_duplicate_key: true)
            rescue JSON::ParserError => e
              raise Ace::LLM::ProviderError, "Failed to parse Claude OAI response: #{e.message}"
            end

            text = response["result"] || response["response"] || ""
            metadata = build_metadata(response, prompt, options)

            {
              text: text,
              metadata: metadata
            }
          end

          def build_metadata(response, prompt, options)
            usage = response["usage"] || {}

            metadata = {
              provider: "claudeoai",
              model: @model || DEFAULT_MODEL,
              input_tokens: usage["input_tokens"] || 0,
              output_tokens: usage["output_tokens"] || 0,
              total_tokens: (usage["input_tokens"] || 0) + (usage["output_tokens"] || 0),
              cached_tokens: usage["cache_read_input_tokens"] || 0,
              finish_reason: response["subtype"] || "success",
              took: (response["duration_ms"] || 0) / 1000.0,
              timestamp: Time.now.utc.iso8601
            }

            if response["total_cost_usd"]
              metadata[:cost] = {
                input_cost: 0.0,
                output_cost: 0.0,
                total_cost: response["total_cost_usd"],
                currency: "USD"
              }
            end

            metadata[:session_id] = response["session_id"] if response["session_id"]

            metadata[:provider_specific] = {
              uuid: response["uuid"],
              service_tier: usage["service_tier"],
              duration_api_ms: response["duration_api_ms"],
              cache_creation_tokens: usage["cache_creation_input_tokens"]
            }.compact

            metadata
          end

          def handle_claude_error(error)
            raise error
          end

          def rewrite_skill_commands(prompt, working_dir: nil)
            skills_dir = resolve_skills_dir(working_dir: working_dir)
            return prompt unless skills_dir

            skill_names = @skill_name_reader.call(skills_dir)
            return prompt if skill_names.empty?

            Atoms::CommandRewriter.call(prompt, skill_names: skill_names, formatter: Atoms::CommandFormatters::CODEX_FORMATTER)
          end

          def resolve_skills_dir(working_dir: nil)
            configured = @options[:skills_dir] || @generation_config[:skills_dir]
            return configured if configured && Dir.exist?(configured)

            working_dir ||= Atoms::ExecutionContext.resolve_working_dir
            candidate_dirs = [
              File.join(working_dir, ".claude", "skills"),
              File.join(working_dir, ".agent", "skills")
            ]
            candidate_dirs.find { |dir| Dir.exist?(dir) }
          end

          def debug_subprocess(message)
            return unless ENV["ACE_LLM_DEBUG_SUBPROCESS"] == "1"

            $stderr.puts("[ClaudeOaiClient] #{message}")
          end
        end
      end
    end
  end
end
