# frozen_string_literal: true

require "open3"
require "json"
require "shellwords"
require "timeout"
require_relative "base_client"
require_relative "../models/llm_model_info"
require_relative "../models/result"

module CodingAgentTools
  module Organisms
    # Client for interacting with Codex CLI (OpenAI)
    # Provides access to Codex models through subprocess execution
    class CodexClient < BaseClient
      # Not used for CLI interaction but required by BaseClient
      API_BASE_URL = "https://api.openai.com"
      DEFAULT_GENERATION_CONFIG = {}.freeze
      
      # Provider registration - auto-registers as "codex"
      def self.provider_name
        "codex"
      end

      # No aliases needed - "codex" stands alone but we support model shortcuts
      def self.dynamic_aliases
        {}
      end

      # Available models for Codex CLI
      # Note: o3 models are no longer available, using gpt-5 models
      AVAILABLE_MODELS = {
        "mini" => "gpt-5-mini",
        "default" => "gpt-5",
        "gpt-5" => "gpt-5",
        "gpt-5-mini" => "gpt-5-mini"
      }.freeze

      # Default model (using gpt-5 which is confirmed working)
      DEFAULT_MODEL = "gpt-5"

      def initialize(model: nil, **options)
        @model = normalize_model_name(model || DEFAULT_MODEL)
        # Skip normal BaseClient initialization that requires API key
        @options = options
        @default_config = options[:temperature] || options[:max_tokens] || {}
      end

      # Generate text using Codex CLI
      def generate_text(prompt, **options)
        validate_codex_availability!
        
        cmd = build_codex_command(prompt, options)
        stdout, stderr, status = execute_codex_command(cmd, prompt, options)
        
        parse_codex_response(stdout, stderr, status, prompt, options)
      rescue => e
        handle_codex_error(e)
      end

      # List available Codex models
      def list_models
        # Return array directly, not wrapped in Result
        available_models = %w[gpt-5 gpt-5-mini]
        
        available_models.map do |model_name|
          CodingAgentTools::Models::LlmModelInfo.new(
            id: model_name,
            name: model_name,
            description: "Codex CLI model",
            context_size: model_context_size(model_name)
          )
        end
      end

      private

      def model_context_size(model_name)
        # Codex/GPT-5 models have large context windows
        case model_name
        when /gpt-5-mini/
          128_000
        when /gpt-5/
          128_000
        else
          128_000 # Conservative default
        end
      end

      def codex_available?
        system("which codex > /dev/null 2>&1")
      end

      def validate_codex_availability!
        unless codex_available?
          raise Error, "Codex CLI not found. Install with: npm install -g @openai/codex or visit https://codex.ai"
        end
        
        # Check if Codex is authenticated
        unless codex_authenticated?
          raise Error, "Codex authentication required. Run 'codex login' or configure API key"
        end
      end

      def codex_authenticated?
        # Quick check if Codex can execute (will fail fast if not authenticated)
        # Based on research, try a simple version check or help command
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
          cmd << "--model" << normalize_model_name(@model)
        end
        
        # Note: Codex exec doesn't support direct system prompts or temperature/max_tokens
        # These would need to be incorporated into the prompt itself
        
        cmd
      end

      def execute_codex_command(cmd, prompt, options)
        # Prepare the input - combine system prompt with user prompt if needed
        input = prompt.to_s
        
        if options[:system_instruction] || options[:system]
          system_text = options[:system_instruction] || options[:system]
          input = "System: #{system_text}\n\nUser: #{input}"
        end
        
        # Execute with timeout to prevent hanging, piping prompt via stdin
        Timeout.timeout(120) do
          Open3.capture3(*cmd, stdin_data: input)
        end
      rescue Timeout::Error
        raise Error, "Codex CLI execution timed out after 120 seconds"
      end

      def parse_codex_response(stdout, stderr, status, prompt, options)
        unless status.success?
          error_msg = stderr.empty? ? stdout : stderr
          raise Error, "Codex CLI failed: #{error_msg}"
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
        
        # Return hash compatible with other providers
        {
          text: text,
          finish_reason: "success",
          usage_metadata: build_synthetic_metadata(text, prompt),
          total_cost_usd: nil, # Not available from CLI
          session_id: nil,
          duration_ms: nil
        }
      end

      def build_synthetic_metadata(response_text, prompt)
        # Create synthetic metadata since Codex CLI might not provide detailed usage info
        # Rough token estimation
        prompt_tokens = (prompt.to_s.length / 4).round # Rough estimate: 4 chars per token
        response_tokens = (response_text.length / 4).round
        
        {
          "input_tokens" => prompt_tokens,
          "output_tokens" => response_tokens,
          "total_tokens" => prompt_tokens + response_tokens,
          "model" => @model,
          "provider" => "codex"
        }
      end

      def handle_codex_error(error)
        # Re-raise the error for proper handling by the base client error flow
        raise error
      end
      
      def normalize_model_name(model)
        # Map aliases to actual model names, or pass through
        AVAILABLE_MODELS[model] || model
      end
    end
  end
end