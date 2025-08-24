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
    # Client for interacting with Claude Code via the Claude CLI
    # Provides access to Claude Code models through subprocess execution
    class ClaudeCodeClient < BaseClient
      # Not used for CLI interaction but required by BaseClient
      API_BASE_URL = "https://claude.ai"
      DEFAULT_GENERATION_CONFIG = {}.freeze
      
      # Provider registration - auto-registers as "cc"
      def self.provider_name
        "cc"
      end

      # No aliases needed - "cc" stands alone
      def self.dynamic_aliases
        {}
      end

      # Model name mappings for convenience
      MODEL_MAPPING = {
        "opus" => "opus",
        "sonnet" => "sonnet", 
        "haiku" => "haiku",
        "opus-4" => "opus",
        "sonnet-4" => "sonnet",
        "haiku-3" => "haiku"
      }.freeze

      # Default model for quick access
      DEFAULT_MODEL = "sonnet"

      def initialize(model: nil, **options)
        @model = normalize_model_name(model || DEFAULT_MODEL)
        # Skip normal BaseClient initialization that requires API key
        @options = options
        @default_config = options[:temperature] || options[:max_tokens] || {}
      end

      # Generate text using Claude CLI
      def generate_text(prompt, **options)
        validate_claude_availability!
        
        cmd = build_claude_command(prompt, options)
        stdout, stderr, status = execute_claude_command(cmd)
        
        parse_claude_response(stdout, stderr, status, prompt, options)
      rescue => e
        handle_claude_error(e)
      end

      # List available Claude Code models
      def list_models
        # Return array directly, not wrapped in Result
        unless claude_available?
          # Fallback models when Claude CLI is unavailable
          return %w[opus sonnet haiku].map do |model|
            CodingAgentTools::Models::LlmModelInfo.new(
              id: model,
              name: model,
              description: "Claude Code model",
              context_size: 200_000
            )
          end
        end
        
        # Get unique base model names (opus, sonnet, haiku)
        unique_models = %w[opus sonnet haiku]
        
        unique_models.map do |model_name|
          CodingAgentTools::Models::LlmModelInfo.new(
            id: model_name,
            name: model_name,
            description: "Claude Code model",
            context_size: model_context_size(model_name)
          )
        end
      end

      private

      def normalize_model_name(model)
        # Handle various model name formats
        model_key = model.to_s.downcase
        MODEL_MAPPING[model_key] || model_key
      end

      def model_context_size(model_name)
        # Claude Code models have large context windows
        case model_name
        when /opus/
          200_000
        when /sonnet/
          200_000
        when /haiku/
          200_000
        else
          128_000 # Conservative default
        end
      end

      def claude_available?
        system("which claude > /dev/null 2>&1")
      end

      def validate_claude_availability!
        unless claude_available?
          raise Error, "Claude CLI not found. Install with: npm install -g @anthropic-ai/claude-cli"
        end
        
        # Check if Claude is authenticated (quick check)
        unless claude_authenticated?
          raise Error, "Claude authentication required. Run 'claude setup-token' to configure"
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

      def build_claude_command(prompt, options)
        cmd = ["claude", "-p"]
        
        # Add prompt (from string or file)
        if prompt.is_a?(String) && File.exist?(prompt)
          cmd << File.read(prompt)
        else
          cmd << prompt.to_s
        end
        
        # Always use JSON output for consistent parsing
        cmd << "--output-format" << "json"
        
        # Add model selection if not default
        if @model && @model != DEFAULT_MODEL
          cmd << "--model" << @model
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

      def execute_claude_command(cmd)
        # Execute with timeout to prevent hanging
        Timeout.timeout(120) do
          Open3.capture3(*cmd)
        end
      rescue Timeout::Error
        raise Error, "Claude CLI execution timed out after 120 seconds"
      end

      def parse_claude_response(stdout, stderr, status, prompt, options)
        unless status.success?
          error_msg = stderr.empty? ? stdout : stderr
          raise Error, "Claude CLI failed: #{error_msg}"
        end
        
        begin
          response = JSON.parse(stdout)
        rescue JSON::ParserError => e
          raise Error, "Failed to parse Claude response: #{e.message}"
        end
        
        # Extract the text result
        text = response["result"] || response["response"] || ""
        
        # Return hash compatible with other providers
        {
          text: text,
          finish_reason: response["subtype"] || "success",
          usage_metadata: response["usage"],
          total_cost_usd: response["total_cost_usd"],
          session_id: response["session_id"],
          duration_ms: response["duration_ms"]
        }
      end

      def build_metadata(response, prompt, options)
        usage = response["usage"] || {}
        
        # Build standard metadata structure
        metadata = {
          provider: "cc",
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
    end
  end
end