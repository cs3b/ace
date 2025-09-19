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
    # Client for interacting with Codex CLI in OSS mode (local Ollama integration)
    # Provides access to local models through Codex CLI with --oss flag
    class CodexOSSClient < BaseClient
      # Not used for CLI interaction but required by BaseClient
      API_BASE_URL = "http://localhost:11434"
      DEFAULT_GENERATION_CONFIG = {}.freeze
      
      # Provider registration - auto-registers as "codexoss"
      def self.provider_name
        "codexoss"
      end

      # No aliases needed - "codexoss" stands alone
      def self.dynamic_aliases
        {}
      end

      # Default model for OSS mode
      DEFAULT_MODEL = "llama3"

      def initialize(model: nil, **options)
        @model = model || DEFAULT_MODEL
        # Skip normal BaseClient initialization that requires API key
        @options = options
        @default_config = options[:temperature] || options[:max_tokens] || {}
      end

      # Generate text using Codex CLI with OSS mode
      def generate_text(prompt, **options)
        validate_codex_oss_availability!
        
        cmd = build_codex_oss_command(prompt, options)
        stdout, stderr, status = execute_codex_command(cmd)
        
        parse_codex_response(stdout, stderr, status, prompt, options)
      rescue => e
        handle_codex_error(e)
      end

      # List available Codex OSS models (discover from Ollama)
      def list_models
        unless codex_available?
          return []
        end
        
        # Try to discover models through Codex OSS mode
        # This is speculative based on task research
        begin
          cmd = ["codex", "--oss", "--list-models"]
          stdout, _, status = Open3.capture3(*cmd)
          
          if status.success?
            models = stdout.lines.map(&:strip).reject(&:empty?)
            return models.map do |model_name|
              CodingAgentTools::Models::LlmModelInfo.new(
                id: model_name,
                name: model_name,
                description: "Codex OSS model (via Ollama)",
                context_size: 8192 # Conservative default for local models
              )
            end
          end
        rescue
          # Fall through to default models
        end
        
        # Fallback to common Ollama models
        %w[llama3 llama3:8b mistral codellama].map do |model_name|
          CodingAgentTools::Models::LlmModelInfo.new(
            id: model_name,
            name: model_name,
            description: "Codex OSS model (via Ollama)",
            context_size: 8192
          )
        end
      end

      private

      def codex_available?
        system("which codex > /dev/null 2>&1")
      end

      def validate_codex_oss_availability!
        unless codex_available?
          raise Error, "Codex CLI not found. Install with: npm install -g @openai/codex or visit https://codex.ai"
        end
        
        # For OSS mode, we don't need authentication but we need Ollama running
        unless ollama_running?
          raise Error, "Ollama not running or accessible. Ensure Ollama is running on localhost:11434"
        end
      end

      def ollama_running?
        # Simple check if Ollama is accessible
        require 'net/http'
        uri = URI('http://localhost:11434/api/version')
        response = Net::HTTP.get_response(uri)
        response.code == '200'
      rescue
        false
      end

      def build_codex_oss_command(prompt, options)
        cmd = ["codex", "--oss"]
        
        # Add model selection
        if @model
          cmd << "-m" << @model
        end
        
        # Add prompt
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
        Timeout.timeout(180) do # Longer timeout for local models
          Open3.capture3(*cmd)
        end
      rescue Timeout::Error
        raise Error, "Codex OSS CLI execution timed out after 180 seconds"
      end

      def parse_codex_response(stdout, stderr, status, prompt, options)
        unless status.success?
          error_msg = stderr.empty? ? stdout : stderr
          raise Error, "Codex OSS CLI failed: #{error_msg}"
        end
        
        # Parse text output and create synthetic metadata
        text = stdout.strip
        
        # Return hash compatible with other providers
        {
          text: text,
          finish_reason: "success",
          usage_metadata: build_synthetic_metadata(text, prompt),
          total_cost_usd: 0.0, # Local models are free
          session_id: nil,
          duration_ms: nil
        }
      end

      def build_synthetic_metadata(response_text, prompt)
        # Create synthetic metadata for local models
        prompt_tokens = (prompt.to_s.length / 4).round
        response_tokens = (response_text.length / 4).round
        
        {
          "input_tokens" => prompt_tokens,
          "output_tokens" => response_tokens,
          "total_tokens" => prompt_tokens + response_tokens,
          "model" => @model,
          "provider" => "codexoss"
        }
      end

      def handle_codex_error(error)
        # Re-raise the error for proper handling by the base client error flow
        raise error
      end
    end
  end
end