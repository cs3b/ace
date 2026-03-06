# frozen_string_literal: true

require "json"
require "open3"
require "shellwords"

require_relative "cli_args_support"

module Ace
  module LLM
    module Providers
      module CLI
        # Client for interacting with Claude Code via the Claude CLI
        # Provides access to Claude Code models through subprocess execution
        class ClaudeCodeClient < Ace::LLM::Organisms::BaseClient
          include CliArgsSupport
          # Not used for CLI interaction but required by BaseClient
          API_BASE_URL = "https://claude.ai"
          DEFAULT_GENERATION_CONFIG = {}.freeze

          # Provider registration - auto-registers as "claude"
          def self.provider_name
            "claude"
          end

          # Default model (can be overridden by config)
          DEFAULT_MODEL = "claude-sonnet-4-0"

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
            validate_claude_availability!

            # Convert messages to prompt format
            prompt = format_messages_as_prompt(messages)

            cmd = build_claude_command(options)
            subprocess_env = options.delete(:subprocess_env)
            stdout, stderr, status = execute_claude_command(cmd, prompt, subprocess_env: subprocess_env)

            parse_claude_response(stdout, stderr, status, prompt, options)
          rescue => e
            handle_claude_error(e)
          end

          # List available Claude Code models
          def list_models
            # Return models based on what the CLI supports
            # This is a simplified list - actual models come from YAML config
            [
              { id: "claude-opus-4-1", name: "Claude Opus 4.1", description: "Most capable model", context_size: 200_000 },
              { id: "claude-sonnet-4-0", name: "Claude Sonnet 4.0", description: "Balanced model", context_size: 200_000 },
              { id: "claude-3-5-haiku-latest", name: "Claude Haiku 3.5", description: "Fast model", context_size: 200_000 }
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

          def claude_available?
            system("which claude > /dev/null 2>&1")
          end

          def validate_claude_availability!
            unless claude_available?
              raise Ace::LLM::ProviderError, "Claude CLI not found. Install with: npm install -g @anthropic-ai/claude-cli"
            end

            # Check if Claude is authenticated (quick check)
            unless claude_authenticated?
              raise Ace::LLM::AuthenticationError, "Claude authentication required. Run 'claude setup-token' to configure"
            end
          end

          def claude_authenticated?
            # Quick check if Claude can execute (will fail fast if not authenticated)
            # Using a minimal test that should complete quickly
            cmd = ["claude", "--version"]
            stdout, _, status = Open3.capture3(*cmd)
            status.success? && (stdout.include?("Claude") || stdout.include?("claude"))
          rescue
            false
          end

          def build_claude_command(options)
            cmd = ["claude"]
            cmd << "-p"

            # Always use JSON output for consistent parsing
            cmd << "--output-format" << "json"

            # Add model selection if not default
            if @model && @model != DEFAULT_MODEL
              cmd << "--model" << @model
            end

            # Prompt is passed via stdin to avoid exceeding Linux MAX_ARG_STRLEN
            # (128KB per-argument limit). System content is already embedded in the
            # formatted prompt via format_messages_as_prompt.

            # Add max tokens if provided
            max_tokens = options[:max_tokens] || @generation_config[:max_tokens]
            if max_tokens
              cmd << "--max-tokens" << max_tokens.to_s
            end

            # User CLI args last so they take precedence (last-wins in most CLIs)
            cmd.concat(normalized_cli_args(options))

            cmd
          end


          def execute_claude_command(cmd, prompt, subprocess_env: nil)
            timeout_val = @options[:timeout] || 120
            # Clear CLAUDECODE env var so `claude -p` (non-interactive, one-shot mode)
            # can run as a subprocess from within a Claude Code session.
            # The guard was added in Claude Code v2.1.41 to prevent nested interactive
            # sessions, but -p mode doesn't share session state.
            env = {"CLAUDECODE" => nil}
            env.merge!(subprocess_env) if subprocess_env
            debug_subprocess("spawn timeout=#{timeout_val}s cmd=#{cmd.join(" ")} prompt_bytes=#{prompt.to_s.bytesize}")
            Molecules::SafeCapture.call(cmd, timeout: timeout_val, stdin_data: prompt.to_s, env: env, provider_name: "Claude")
          end

          def parse_claude_response(stdout, stderr, status, prompt, options)
            unless status.success?
              error_msg = stderr.empty? ? stdout : stderr
              raise Ace::LLM::ProviderError, "Claude CLI failed: #{error_msg}"
            end

            begin
              # Allow duplicate keys to avoid warnings from Claude CLI output
              # Some versions of Claude CLI may return JSON with duplicate keys
              response = JSON.parse(stdout, allow_duplicate_key: true)
            rescue JSON::ParserError => e
              raise Ace::LLM::ProviderError, "Failed to parse Claude response: #{e.message}"
            end

            # Extract the text result
            text = response["result"] || response["response"] || ""

            # Build metadata
            metadata = build_metadata(response, prompt, options)

            # Return hash compatible with ace-llm format
            {
              text: text,
              metadata: metadata
            }
          end

          def build_metadata(response, prompt, options)
            usage = response["usage"] || {}

            # Build standard metadata structure
            metadata = {
              provider: "claude",
              model: @model || DEFAULT_MODEL,
              input_tokens: usage["input_tokens"] || 0,
              output_tokens: usage["output_tokens"] || 0,
              total_tokens: (usage["input_tokens"] || 0) + (usage["output_tokens"] || 0),
              cached_tokens: usage["cache_read_input_tokens"] || 0,
              finish_reason: response["subtype"] || "success",
              took: (response["duration_ms"] || 0) / 1000.0,
              timestamp: Time.now.utc.iso8601
            }

            # Add cost information if available
            if response["total_cost_usd"]
              metadata[:cost] = {
                input_cost: 0.0, # Claude provides total only
                output_cost: 0.0,
                total_cost: response["total_cost_usd"],
                currency: "USD"
              }
            end

            # Add session ID if available
            metadata[:session_id] = response["session_id"] if response["session_id"]

            # Add any Claude-specific data
            metadata[:provider_specific] = {
              uuid: response["uuid"],
              service_tier: usage["service_tier"],
              duration_api_ms: response["duration_api_ms"],
              cache_creation_tokens: usage["cache_creation_input_tokens"]
            }.compact

            metadata
          end

          def handle_claude_error(error)
            # Re-raise the error for proper handling by the base client error flow
            raise error
          end

          def debug_subprocess(message)
            return unless ENV["ACE_LLM_DEBUG_SUBPROCESS"] == "1"

            $stderr.puts("[ClaudeCodeClient] #{message}")
          end
        end
      end
    end
  end
end
