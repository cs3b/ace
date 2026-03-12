# frozen_string_literal: true

require "json"
require "open3"
require "shellwords"

require_relative "cli_args_support"
require_relative "atoms/execution_context"
require_relative "atoms/command_rewriter"
require_relative "atoms/command_formatters"
require_relative "atoms/worktree_dir_resolver"
require_relative "molecules/skill_name_reader"

module Ace
  module LLM
    module Providers
      module CLI
        # Client for interacting with Codex CLI targeting OpenAI-compatible providers
        # Dynamically configures codex to use any backend (Z.ai, DeepSeek, etc.)
        # via -c flag overrides for model_provider and model_providers config
        class CodexOaiClient < Ace::LLM::Organisms::BaseClient
          include CliArgsSupport

          API_BASE_URL = "https://api.openai.com"
          DEFAULT_GENERATION_CONFIG = {}.freeze

          def self.provider_name
            "codexoai"
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
            validate_codex_availability!

            prompt = format_messages_as_prompt(messages)
            subprocess_env = options[:subprocess_env]
            working_dir = Atoms::ExecutionContext.resolve_working_dir(
              working_dir: options[:working_dir],
              subprocess_env: subprocess_env
            )
            prompt = rewrite_skill_commands(prompt, working_dir: working_dir)

            cmd = build_codex_oai_command(prompt, options, working_dir: working_dir)
            stdout, stderr, status = execute_codex_command(cmd, prompt, options)

            parse_codex_response(stdout, stderr, status, prompt, options)
          rescue => e
            handle_codex_error(e)
          end

          # List available models
          def list_models
            [
              { id: "zai/glm-5", name: "GLM-5", description: "Z.ai flagship model", context_size: 128_000 },
              { id: "zai/glm-4.7", name: "GLM-4.7", description: "Z.ai balanced model", context_size: 128_000 },
              { id: "zai/glm-4.6", name: "GLM-4.6", description: "Z.ai fast model", context_size: 128_000 }
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

          def codex_available?
            system("which codex > /dev/null 2>&1")
          end

          def validate_codex_availability!
            unless codex_available?
              raise Ace::LLM::ProviderError, "Codex CLI not found. Install with: npm install -g @openai/codex or visit https://codex.ai"
            end
          end

          def build_codex_oai_command(prompt, options, working_dir: nil)
            working_dir ||= Atoms::ExecutionContext.resolve_working_dir(
              working_dir: options[:working_dir],
              subprocess_env: options[:subprocess_env]
            )
            cmd = ["codex", "exec"]

            # Add sandbox mode if specified
            if options[:sandbox]
              cmd << "--sandbox" << options[:sandbox].to_s
            end

            # Parse backend/model from the model string
            backend_name, model_name = split_backend_model(@model)

            if backend_name && model_name
              backend_config = @backends[backend_name] || @backends[backend_name.to_sym] || {}

              # Set the model provider
              cmd << "-c" << "model_provider=\"#{backend_name}\""

              # Provider name (required by codex)
              provider_display = backend_config["name"] || backend_config[:name] || backend_name
              cmd << "-c" << "model_providers.#{backend_name}.name=\"#{provider_display}\""

              # Configure backend-specific settings
              if (base_url = backend_config["base_url"] || backend_config[:base_url])
                cmd << "-c" << "model_providers.#{backend_name}.base_url=\"#{base_url}\""
              end

              if (env_key = backend_config["env_key"] || backend_config[:env_key])
                cmd << "-c" << "model_providers.#{backend_name}.env_key=\"#{env_key}\""
              end

              # Set the model
              cmd << "-m" << model_name
            end

            # Add writable dir for git worktree metadata
            if (git_dir = Atoms::WorktreeDirResolver.call(working_dir: working_dir))
              cmd << "--add-dir" << git_dir
            end

            # User CLI args last so they take precedence
            cmd.concat(normalized_cli_args(options))

            cmd
          end

          def execute_codex_command(cmd, prompt, options)
            input = prompt.to_s

            system_content = options[:system_instruction] ||
                           options[:system] ||
                           options[:system_prompt] ||
                           @generation_config[:system_prompt]

            if system_content && !prompt.include?("System:")
              input = "System: #{system_content}\n\nUser: #{input}"
            end

            timeout_val = @options[:timeout] || 120
            working_dir = Atoms::ExecutionContext.resolve_working_dir(
              working_dir: options[:working_dir],
              subprocess_env: options[:subprocess_env]
            )
            Molecules::SafeCapture.call(
              cmd,
              timeout: timeout_val,
              stdin_data: input,
              chdir: working_dir,
              provider_name: "Codex OAI"
            )
          end

          def parse_codex_response(stdout, stderr, status, prompt, options)
            unless status.success?
              error_msg = stderr.empty? ? stdout : stderr
              raise Ace::LLM::ProviderError, "Codex OAI CLI failed: #{error_msg}"
            end

            lines = stdout.split("\n")
            response_start = lines.find_index { |line| line.include?("codex") }

            if response_start && response_start < lines.length - 1
              response_lines = lines[(response_start + 1)..-1]
              response_lines = response_lines.reject { |line| line.include?("tokens used") }
              text = response_lines.join("\n").strip
            else
              text = stdout.strip
            end

            metadata = build_synthetic_metadata(text, prompt)

            {
              text: text,
              metadata: metadata
            }
          end

          def build_synthetic_metadata(response_text, prompt)
            prompt_tokens = (prompt.to_s.length / 4).round
            response_tokens = (response_text.length / 4).round

            {
              provider: "codexoai",
              model: @model || DEFAULT_MODEL,
              input_tokens: prompt_tokens,
              output_tokens: response_tokens,
              total_tokens: prompt_tokens + response_tokens,
              finish_reason: "success",
              timestamp: Time.now.utc.iso8601
            }
          end

          def handle_codex_error(error)
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
              File.join(working_dir, ".codex", "skills"),
              File.join(working_dir, ".agent", "skills"),
              File.join(working_dir, ".claude", "skills")
            ]
            candidate_dirs.find { |dir| Dir.exist?(dir) }
          end
        end
      end
    end
  end
end
