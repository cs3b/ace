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

      # Available models for Codex CLI (based on research)
      AVAILABLE_MODELS = {
        "o3" => "o3",
        "o3-mini" => "o3-mini", 
        "gpt-5" => "gpt-5",
        "gpt-5-mini" => "gpt-5-mini"
      }.freeze

      # Default model (using o3-mini as suggested in research)
      DEFAULT_MODEL = "o3-mini"

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
        stdout, stderr, status = execute_codex_command(cmd)
        
        parse_codex_response(stdout, stderr, status, prompt, options)
      rescue => e
        handle_codex_error(e)
      end

      # List available Codex models
      def list_models
        # Return array directly, not wrapped in Result
        unless codex_available?
          # Fallback models when Codex CLI is unavailable
          return %w[o3-mini o3 gpt-5-mini gpt-5].map do |model|
            CodingAgentTools::Models::LlmModelInfo.new(
              id: model,
              name: model,
              description: "Codex CLI model",
              context_size: 200_000
            )
          end
        end
        
        # Get available models
        available_models = %w[o3-mini o3 gpt-5-mini gpt-5]
        
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
        # Codex models have large context windows
        case model_name
        when /o3/
          200_000
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
        # Based on research suggesting codex exec or similar pattern
        # Using reasonable assumptions for command structure
        cmd = ["codex"]
        
        # Add model selection (using -m flag as suggested in research)
        if @model && @model != DEFAULT_MODEL
          cmd << "-m" << @model
        end
        
        # Add sandbox mode (using danger-full-access as suggested in research)
        cmd << "-s" << "danger-full-access"
        
        # Add prompt (assuming similar pattern to Claude)
        if prompt.is_a?(String) && File.exist?(prompt)
          cmd << File.read(prompt)
        else
          cmd << prompt.to_s
        end
        
        # Add system prompt if provided
        if options[:system_instruction] || options[:system]
          system_text = options[:system_instruction] || options[:system]
          cmd << "--system" << system_text.to_s
        end
        
        # Add temperature if provided
        if options[:temperature]
          cmd << "--temperature" << options[:temperature].to_s
        end
        
        # Add max tokens if provided
        if options[:max_tokens]
          cmd << "--max-tokens" << options[:max_tokens].to_s
        end
        
        cmd
      end

      def execute_codex_command(cmd)
        # Execute with timeout to prevent hanging
        Timeout.timeout(120) do
          Open3.capture3(*cmd)
        end
      rescue Timeout::Error
        raise Error, "Codex CLI execution timed out after 120 seconds"
      end

      def parse_codex_response(stdout, stderr, status, prompt, options)
        unless status.success?
          error_msg = stderr.empty? ? stdout : stderr
          raise Error, "Codex CLI failed: #{error_msg}"
        end
        
        # Based on research, Codex might not support JSON output
        # So we'll parse text output and create synthetic metadata
        text = stdout.strip
        
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