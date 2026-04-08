# frozen_string_literal: true

require "fileutils"
require "json"

require_relative "cli_args_support"
require_relative "atoms/execution_context"

module Ace
  module LLM
    module Providers
      module CLI
        # Client for interacting with Google Gemini CLI
        # Provides access to Gemini models through subprocess execution
        class GeminiClient < Ace::LLM::Organisms::BaseClient
          include CliArgsSupport

          # Not used for CLI interaction but required by BaseClient
          API_BASE_URL = "https://generativelanguage.googleapis.com"
          DEFAULT_GENERATION_CONFIG = {}.freeze

          # Default maximum prompt length before switching to file-based prompts (100K characters)
          # This can be overridden via config: default_options.max_prompt_length
          # Gemini's actual token limit is much higher (~1M tokens), but this provides
          # a reasonable safeguard for accidental misuse
          DEFAULT_MAX_PROMPT_LENGTH = 100_000

          # Provider registration - auto-registers as "gemini"
          def self.provider_name
            "gemini"
          end

          # Default model (can be overridden by config)
          DEFAULT_MODEL = "gemini-2.5-flash"

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
            validate_gemini_availability!

            # Convert messages to prompt format
            prompt = format_messages_as_prompt(messages)

            cmd = build_gemini_command(prompt, options)
            stdout, stderr, status = execute_gemini_command(cmd, prompt, options)

            parse_gemini_response(stdout, stderr, status, prompt, options)
          end

          # List available Gemini models
          # Note: This list should stay in sync with .ace-defaults/llm/providers/gemini.yml
          # Project-level additions (like preview models) are handled by the config cascade
          def list_models
            [
              {id: "gemini-2.5-flash", name: "Gemini 2.5 Flash", description: "Fast, efficient Gemini model", context_size: 1_048_576},
              {id: "gemini-2.5-pro", name: "Gemini 2.5 Pro", description: "Advanced Gemini model", context_size: 1_048_576},
              {id: "gemini-2.0-flash", name: "Gemini 2.0 Flash", description: "Fast Gemini model", context_size: 1_048_576},
              {id: "gemini-1.5-pro-latest", name: "Gemini 1.5 Pro", description: "Previous generation Pro model", context_size: 2_097_152}
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

            # Join messages
            prompt = formatted.join("\n\n")

            # Prepend system message if present (Gemini CLI doesn't support native system prompts)
            if system_msg
              system_content = system_msg[:content] || system_msg["content"]
              # Check if system prompt already embedded
              if prompt.include?("System:")
                prompt
              else
                "System: #{system_content}\n\n#{prompt}"
              end
            else
              prompt
            end
          end

          def gemini_available?
            system("which", "gemini", out: File::NULL, err: File::NULL)
          end

          def validate_gemini_availability!
            unless gemini_available?
              raise Ace::LLM::ProviderError, "Gemini CLI not found. Install with: npm install -g @google/gemini-cli or visit https://geminicli.com"
            end
            # Authentication is handled by the CLI itself - no pre-check needed
          end

          def build_gemini_command(prompt, options)
            # If caller provided file paths, use them directly (e.g., ace-review session files)
            # This avoids creating duplicate temp files and conflicting system prompts
            if options[:system_file] && options[:prompt_file]
              return build_command_with_existing_files(options[:system_file], options[:prompt_file], options)
            end

            # Calculate total prompt length with system prompt
            system_prompt = @generation_config[:system_prompt]
            total_length = prompt.to_s.length + (system_prompt&.length || 0) + "System: \n\n".length

            # Check if we need to use file references for large prompts
            # max_prompt_length is configurable via default_options in provider config
            max_length = @generation_config[:max_prompt_length] || @options[:max_prompt_length] || DEFAULT_MAX_PROMPT_LENGTH
            if total_length > max_length
              build_command_with_file_references(prompt, system_prompt, options)
            else
              build_standard_command(prompt, system_prompt, options)
            end
          end

          def build_command_with_existing_files(system_file, prompt_file, options)
            # Build instruction prompt referencing existing files
            # No temp file creation - caller has already saved prompts to files
            file_refs = []
            file_refs << "Read the system instructions: #{system_file}"
            file_refs << "Read the user context: #{prompt_file}"
            file_refs << "Follow the instructions in the files."

            new_prompt = file_refs.join("\n")

            # Build gemini CLI command with file reading enabled
            cmd = ["gemini"]
            cmd << "--output-format" << "json"

            # Add model selection if not default
            if @model && @model != DEFAULT_MODEL
              cmd << "--model" << @model
            end

            # User CLI args after generated flags so they take precedence (last-wins),
            # but before positional prompt arg
            append_cli_args(cmd, options)
            cmd << new_prompt

            cmd
          end

          def build_standard_command(prompt, system_prompt, options)
            # Prepend default system prompt if no system message exists
            unless prompt.include?("System:")
              if system_prompt
                prompt = "System: #{system_prompt}\n\n#{prompt}"
              end
            end

            # Build gemini CLI command for headless execution
            # Note: prompt is passed as positional argument for one-shot mode
            cmd = ["gemini"]
            cmd << "--output-format" << "json"

            # Add model selection if not default
            if @model && @model != DEFAULT_MODEL
              cmd << "--model" << @model
            end

            # User CLI args after generated flags so they take precedence (last-wins),
            # but before positional prompt arg
            append_cli_args(cmd, options)
            cmd << prompt

            cmd
          end

          def build_command_with_file_references(prompt, system_prompt, options)
            # Use project .ace-local directory so Gemini CLI can access the files
            # (system temp /var/folders is outside Gemini's workspace)
            cache_dir = create_prompt_cache_dir(options[:working_dir], subprocess_env: options[:subprocess_env])
            timestamp = Time.now.strftime("%Y%m%d-%H%M%S-%L")

            # Write system prompt to cache file
            system_file_path = nil
            if system_prompt
              system_file_path = File.join(cache_dir, "system-#{timestamp}.txt")
              File.write(system_file_path, system_prompt)
            end

            # Write user prompt to cache file
            user_file_path = File.join(cache_dir, "user-#{timestamp}.txt")
            File.write(user_file_path, prompt)

            # Build instruction prompt with file references
            file_refs = []
            file_refs << "Read this system instruction: #{system_file_path}" if system_file_path
            file_refs << "Read the user instructions: #{user_file_path}"
            file_refs << "Follow the instructions in the file#{"s" if system_file_path}."

            new_prompt = file_refs.join("\n")

            # Build gemini CLI command for one-shot execution with file reading
            # Note: prompt is passed as positional argument (not -i which conflicts with stdin)
            # Enable read_file tool without confirmation for headless execution
            cmd = ["gemini"]
            cmd << "--output-format" << "json"

            # Add model selection if not default
            if @model && @model != DEFAULT_MODEL
              cmd << "--model" << @model
            end

            # User CLI args after generated flags so they take precedence (last-wins),
            # but before positional prompt arg
            append_cli_args(cmd, options)
            cmd << new_prompt

            cmd
          end

          def create_prompt_cache_dir(working_dir = nil, subprocess_env: nil)
            resolved_working_dir = Atoms::ExecutionContext.resolve_working_dir(
              working_dir: working_dir,
              subprocess_env: subprocess_env
            )
            cache_dir = File.join(resolved_working_dir, ".ace-local", "llm", "prompts")
            FileUtils.mkdir_p(cache_dir) unless Dir.exist?(cache_dir)
            cache_dir
          end

          def append_cli_args(cmd, options)
            cmd.concat(normalized_cli_args(options))
          end

          def execute_gemini_command(cmd, prompt, options)
            timeout_val = options[:timeout] || @options[:timeout] || 120
            working_dir = Atoms::ExecutionContext.resolve_working_dir(
              working_dir: options[:working_dir],
              subprocess_env: options[:subprocess_env]
            )
            Molecules::SafeCapture.call(
              cmd,
              timeout: timeout_val,
              chdir: working_dir,
              env: options[:subprocess_env],
              provider_name: "Gemini"
            )
          end

          def parse_gemini_response(stdout, stderr, status, prompt, options)
            unless status.success?
              error_msg = stderr.empty? ? stdout : stderr
              raise Ace::LLM::ProviderError, "Gemini CLI failed: #{error_msg}"
            end

            # Try to parse JSON output first
            begin
              parsed = JSON.parse(stdout)

              # Extract response text from parsed JSON
              # Gemini CLI JSON format: { "response": "...", "stats": { ... } }
              text = if parsed["response"]
                parsed["response"]
              elsif parsed["candidates"] && parsed["candidates"].first
                parsed["candidates"].first["content"] || parsed["candidates"].first["text"]
              else
                # Fallback to raw output if JSON structure unexpected
                stdout.strip
              end

              # Extract metadata from stats if available
              metadata = extract_metadata_from_json(parsed, prompt)
            rescue JSON::ParserError
              # Fallback to raw text output if JSON parsing fails
              text = stdout.strip
              metadata = build_synthetic_metadata(text, prompt)
            end

            # Return hash compatible with ace-llm format
            {
              text: text,
              metadata: metadata
            }
          end

          def extract_metadata_from_json(parsed, prompt)
            # Try to extract metadata from Gemini CLI JSON response
            stats = parsed["stats"] || {}
            tokens = stats["tokens"] || {}

            {
              provider: "gemini",
              model: @model || DEFAULT_MODEL,
              input_tokens: tokens["promptTokens"] || tokens["input"] || 0,
              output_tokens: tokens["candidatesTokens"] || tokens["output"] || 0,
              total_tokens: tokens["totalTokens"] || tokens["total"] || 0,
              finish_reason: "success",
              timestamp: Time.now.utc.iso8601
            }
          end

          def build_synthetic_metadata(response_text, prompt)
            # Create synthetic metadata if JSON metadata not available
            # Token estimation: ~4 characters per token is a reasonable approximation for
            # English text with Gemini's tokenizer. This varies by language and content type
            # but provides useful estimates when actual token counts aren't available.
            prompt_tokens = (prompt.to_s.length / 4).round
            response_tokens = (response_text.length / 4).round

            {
              provider: "gemini",
              model: @model || DEFAULT_MODEL,
              input_tokens: prompt_tokens,
              output_tokens: response_tokens,
              total_tokens: prompt_tokens + response_tokens,
              finish_reason: "success",
              timestamp: Time.now.utc.iso8601
            }
          end
        end
      end
    end
  end
end
