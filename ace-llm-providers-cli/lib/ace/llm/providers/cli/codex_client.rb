# frozen_string_literal: true

require "json"
require "open3"
require "shellwords"
require "tempfile"
require "fileutils"

require_relative "cli_args_support"
require_relative "atoms/execution_context"
require_relative "atoms/command_rewriter"
require_relative "atoms/command_formatters"
require_relative "atoms/interactive_startup_policy"
require_relative "atoms/worktree_dir_resolver"
require_relative "molecules/skill_name_reader"

module Ace
  module LLM
    module Providers
      module CLI
        # Client for interacting with Codex CLI (OpenAI)
        # Provides access to Codex models through subprocess execution
        class CodexClient < Ace::LLM::Organisms::BaseClient
          include CliArgsSupport

          # Not used for CLI interaction but required by BaseClient
          API_BASE_URL = "https://api.openai.com"
          DEFAULT_GENERATION_CONFIG = {}.freeze

          # Provider registration - auto-registers as "codex"
          def self.provider_name
            "codex"
          end

          def initialize(model: nil, **options)
            @model = model || Ace::LLM::Molecules::ClientRegistry.new.models_for_provider("codex").first
            raise Ace::LLM::ConfigurationError, "No default model configured for codex" if @model.to_s.empty?
            # Skip normal BaseClient initialization that requires API key
            @options = options
            @generation_config = options[:generation_config] || {}
            @skill_name_reader = Molecules::SkillNameReader.new
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
            subprocess_env = options[:subprocess_env]
            working_dir = Atoms::ExecutionContext.resolve_working_dir(
              working_dir: options[:working_dir],
              subprocess_env: subprocess_env
            )
            prompt = rewrite_skill_commands(prompt, working_dir: working_dir)
            requested_last_message = File.expand_path(options[:last_message_file], working_dir) if options[:last_message_file]
            if requested_last_message && File.directory?(requested_last_message)
              raise Ace::LLM::ProviderError, "last_message_file must name a file, not a directory: #{requested_last_message}"
            end

            Tempfile.create(["ace-codex-last-", ".md"]) do |last_message|
              last_message.close
              direct_capture = requested_last_message && File.writable?(File.dirname(requested_last_message)) && !File.directory?(requested_last_message)
              execution_options = options.merge(last_message_file: direct_capture ? requested_last_message : last_message.path)
              cmd = build_codex_command(prompt, execution_options, working_dir: working_dir)
              if direct_capture && File.exist?(requested_last_message)
                begin
                  File.delete(requested_last_message)
                rescue SystemCallError
                  direct_capture = false
                  execution_options = options.merge(last_message_file: last_message.path)
                  cmd = build_codex_command(prompt, execution_options, working_dir: working_dir)
                end
              end
              completed = false
              result = nil
              begin
                stdout, stderr, status = execute_codex_command(cmd, prompt, execution_options)
                result = parse_codex_response(stdout, stderr, status, prompt, execution_options)
                completed = true
                result
              ensure
                if requested_last_message && !direct_capture && (completed || File.size?(last_message.path))
                  begin
                    FileUtils.cp(last_message.path, requested_last_message)
                  rescue => copy_error
                    result[:metadata][:last_message_copy_error] = copy_error.message if completed
                  end
                end
              end
            end
          rescue => e
            handle_codex_error(e)
          end

          # List available Codex models
          def list_models
            Ace::LLM::Molecules::ClientRegistry.new.models_for_provider("codex").map { |id| {id: id, name: id} }
          end

          def interactive_supported?
            true
          end

          def build_interactive_invocation(messages, **options)
            validate_codex_availability!

            prompt = format_messages_as_prompt(messages)
            subprocess_env = options[:subprocess_env]
            working_dir = Atoms::ExecutionContext.resolve_working_dir(
              working_dir: options[:working_dir],
              subprocess_env: subprocess_env
            )
            prompt = rewrite_skill_commands(prompt, working_dir: working_dir)

            env = subprocess_env ? subprocess_env.to_h.dup : {}

            cmd = build_codex_interactive_command(
              prompt,
              options,
              working_dir: working_dir
            )
            {
              command: cmd,
              env: env,
              working_dir: working_dir,
              prompt: prompt
            }
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

            cmd = ["codex", "--version"]
            stdout, _, status = Open3.capture3(*cmd)
            status.success? && (stdout.include?("codex") || stdout.include?("Codex"))
          rescue
            # If version check fails, try help command
            begin
              cmd = ["codex", "--help"]
              _, _, status = Open3.capture3(*cmd)
              status.success?
            rescue
              false
            end
          end

          def build_codex_command(prompt, options, working_dir: nil)
            working_dir ||= Atoms::ExecutionContext.resolve_working_dir(
              working_dir: options[:working_dir],
              subprocess_env: options[:subprocess_env]
            )
            # Use codex exec for non-interactive execution
            cmd = ["codex", "exec"]

            # Add sandbox mode if specified by caller
            if options[:sandbox]
              cmd << "--sandbox" << options[:sandbox].to_s
            end

            # Add model selection if not default
            if @model
              cmd << "--model" << @model
            end

            # Note: Codex exec doesn't support direct system prompts or temperature/max_tokens
            # These would need to be incorporated into the prompt itself

            # Add writable dir for git worktree metadata
            if (git_dir = Atoms::WorktreeDirResolver.call(working_dir: working_dir))
              cmd << "--add-dir" << git_dir
            end

            # Capture last message progressively for timeout resilience
            if options[:last_message_file]
              cmd << "--output-last-message" << options[:last_message_file]
            end

            cli_args = normalized_cli_args_without_conflicts(
              options,
              forbidden_flags: ["--model", "-m", "--profile", "--output-last-message"],
              label: "Codex"
            )
            if codex_cli_args_override_model?(cli_args)
              raise Ace::LLM::ProviderError, "Codex cli args cannot override the resolved model"
            end
            cmd.concat(cli_args)

            cmd
          end

          def build_codex_interactive_command(prompt, options, working_dir: nil)
            working_dir ||= Atoms::ExecutionContext.resolve_working_dir(
              working_dir: options[:working_dir],
              subprocess_env: options[:subprocess_env]
            )
            cmd = ["codex"]

            if options[:sandbox]
              cmd << "--sandbox" << options[:sandbox].to_s
            end

            if @model
              cmd << "--model" << @model
            end

            if (git_dir = Atoms::WorktreeDirResolver.call(working_dir: working_dir))
              cmd << "--add-dir" << git_dir
            end

            cmd << "-C" << working_dir

            if (trust_override = Atoms::InteractiveStartupPolicy.codex_trust_override(
              working_dir: working_dir
            ))
              cmd << "-c" << trust_override
            end

            cli_args = normalized_cli_args_without_conflicts(
              options,
              forbidden_flags: ["exec", "review", "-C", "--cd", "--output-last-message", "--model", "-m", "--profile"],
              label: "Codex"
            )
            raise Ace::LLM::ProviderError, "Codex cli args cannot override the resolved model" if codex_cli_args_override_model?(cli_args)
            cmd.concat(cli_args)
            cmd << prompt.to_s unless prompt.to_s.empty?
            cmd
          end

          def codex_cli_args_override_model?(args)
            args.any? { |arg| arg.match?(/\A-m.+/) } ||
              args.each_cons(2).any? { |flag, value| %w[-c --config].include?(flag) && value.match?(/\A(?:model|model_provider|profiles\.[^.]+\.(?:model|model_provider))\s*=/) } ||
              args.any? { |arg| arg.match?(/\A(?:-c|--config)=?(?:model|model_provider|profiles\.[^.]+\.(?:model|model_provider))\s*=/) }
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
              env: options[:subprocess_env],
              command_prefix: options[:subprocess_command_prefix],
              provider_name: "Codex"
            )
          end

          def parse_codex_response(stdout, stderr, status, prompt, options)
            unless status.success?
              error_msg = stderr.empty? ? stdout : stderr
              raise Ace::LLM::ProviderError, "Codex CLI failed: #{error_msg}"
            end

            # The native last-message file contains only the final response,
            # unlike stdout's transcript of tools and status messages.
            last_message_path = options[:last_message_file]
            if last_message_path
              text = File.file?(last_message_path) ? File.read(last_message_path).strip : ""
              raise Ace::LLM::ProviderError, "Codex CLI produced no final message" if text.empty?

              return {text: text, metadata: build_synthetic_metadata(text, prompt)}
            end

            # Older CLI wrappers may supply stdout only. Parse its transcript
            # only when a real CLI banner is present, not when report prose
            # happens to contain a standalone `codex` line.
            # Codex output includes metadata lines and the actual response
            lines = stdout.split("\n")

            has_cli_banner = lines.first(20).any? { |line| line.start_with?("OpenAI Codex v") }
            response_start = lines.find_index { |line| line.strip == "codex" } if has_cli_banner

            if response_start && response_start < lines.length - 1
              # Extract text after the "codex" line, skipping empty lines
              response_lines = lines[(response_start + 1)..]
              # Remove token usage lines at the end
              response_lines = response_lines.reject { |line| line.include?("tokens used") }
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
            candidate_dir = File.join(working_dir, ".codex", "skills")
            candidate_dir if Dir.exist?(candidate_dir)
          end
        end
      end
    end
  end
end
