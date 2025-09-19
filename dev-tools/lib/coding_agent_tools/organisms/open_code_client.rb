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
    # Client for interacting with OpenCode CLI
    # Provides access to multiple AI providers through OpenCode's unified platform
    class OpenCodeClient < BaseClient
      # Not used for CLI interaction but required by BaseClient
      API_BASE_URL = "https://models.dev"
      DEFAULT_GENERATION_CONFIG = {}.freeze
      
      # Provider registration - auto-registers as "oc"
      def self.provider_name
        "oc"
      end

      # Add convenience aliases for quick access
      def self.dynamic_aliases
        {
          "opencode" => "google/gemini-2.5-flash"  # Default alias
        }
      end

      # Default model when user doesn't specify one
      DEFAULT_MODEL = "google/gemini-2.5-flash"

      def initialize(model: nil, **options)
        @model = normalize_model_name(model || DEFAULT_MODEL)
        # Skip normal BaseClient initialization that requires API key
        @options = options
        @default_config = options[:temperature] || options[:max_tokens] || {}
      end

      # Generate text using OpenCode CLI
      def generate_text(prompt, **options)
        validate_opencode_availability!
        
        cmd = build_opencode_command(prompt, options)
        stdout, stderr, status = execute_opencode_command(cmd)
        
        parse_opencode_response(stdout, stderr, status, prompt, options)
      rescue => e
        handle_opencode_error(e)
      end

      # List available OpenCode models
      def list_models
        # Return array directly, not wrapped in Result
        unless opencode_available?
          # Fallback models when OpenCode CLI is unavailable
          return fallback_models
        end
        
        begin
          # Try to get models from OpenCode CLI
          cmd = ["opencode", "models"]
          stdout, stderr, status = execute_opencode_command(cmd, timeout: 30)
          
          unless status.success?
            # If models command fails, return fallback
            return fallback_models
          end
          
          parse_models_output(stdout)
        rescue => e
          # If anything goes wrong, return fallback models
          fallback_models
        end
      end

      private

      def fallback_models
        [
          # Google models
          create_model_info("google/gemini-2.5-flash", "Gemini 2.5 Flash", 1_000_000),
          create_model_info("google/gemini-2.0-flash-experimental", "Gemini 2.0 Flash", 1_000_000),
          create_model_info("google/gemini-1.5-pro", "Gemini 1.5 Pro", 2_000_000),
          
          # Anthropic models
          create_model_info("anthropic/claude-3-5-sonnet", "Claude 3.5 Sonnet", 200_000),
          create_model_info("anthropic/claude-3-5-haiku", "Claude 3.5 Haiku", 200_000),
          
          # OpenAI models
          create_model_info("openai/gpt-4o", "GPT-4 Omni", 128_000),
          create_model_info("openai/gpt-4o-mini", "GPT-4 Omni Mini", 128_000),
        ]
      end

      def create_model_info(id, name, context_size)
        CodingAgentTools::Models::LlmModelInfo.new(
          id: id,
          name: name,
          description: "OpenCode model via #{id.split('/').first}",
          context_size: context_size
        )
      end

      def parse_models_output(output)
        models = []
        
        # Parse the models output (expecting provider/model format)
        output.lines.each do |line|
          line = line.strip
          next if line.empty? || line.start_with?('#')
          
          # Expect provider/model format
          if line.match?(/^[a-zA-Z0-9_-]+\/[a-zA-Z0-9_.-]+$/)
            models << create_model_info(line, line.gsub('/', ' '), estimate_context_size(line))
          end
        end
        
        models.empty? ? fallback_models : models
      end

      def estimate_context_size(model_name)
        case model_name.downcase
        when /gemini.*2\.5/
          1_000_000
        when /gemini.*2\.0/
          1_000_000
        when /gemini.*1\.5/
          2_000_000
        when /claude/
          200_000
        when /gpt-4o/
          128_000
        when /gpt-4/
          128_000
        else
          32_000 # Conservative default
        end
      end

      def opencode_available?
        system("which opencode > /dev/null 2>&1")
      end

      def validate_opencode_availability!
        unless opencode_available?
          raise Error, "OpenCode CLI not found. Install via npm: npm install -g @sst/opencode"
        end
        
        # Check if OpenCode is authenticated by trying models command
        unless opencode_authenticated?
          raise Error, "OpenCode authentication required. Run 'opencode auth' to configure providers via Models.dev"
        end
      end

      def opencode_authenticated?
        # Quick check if OpenCode can list models (indicates auth is working)
        cmd = ["opencode", "models"]
        stdout, _, status = Open3.capture3(*cmd)
        status.success? && !stdout.strip.empty?
      rescue
        false
      end

      def build_opencode_command(prompt, options)
        cmd = ["opencode", "run"]
        
        # Add model selection (required)
        cmd << "--model" << @model
        
        # Add prompt (as argument, not from file for now)
        if prompt.is_a?(String) && File.exist?(prompt)
          cmd << File.read(prompt)
        else
          cmd << prompt.to_s
        end
        
        cmd
      end

      def execute_opencode_command(cmd, timeout: 120)
        # Execute with timeout to prevent hanging
        Timeout.timeout(timeout) do
          Open3.capture3(*cmd)
        end
      rescue Timeout::Error
        raise Error, "OpenCode CLI execution timed out after #{timeout} seconds"
      end

      def parse_opencode_response(stdout, stderr, status, prompt, options)
        unless status.success?
          error_msg = stderr.empty? ? stdout : stderr
          
          # Check for specific error cases
          if error_msg.include?("authentication") || error_msg.include?("auth")
            raise Error, "OpenCode authentication required. Run 'opencode auth' to configure providers via Models.dev"
          elsif error_msg.include?("model") && error_msg.include?("not found")
            raise Error, "Error: Model '#{@model}' not recognized. Use provider/model format, e.g., 'anthropic/claude-3-5-sonnet'"
          else
            raise Error, "OpenCode CLI failed: #{error_msg}"
          end
        end
        
        # OpenCode returns text output directly (no JSON parsing needed)
        text = stdout.strip
        
        # Return hash compatible with other providers
        {
          text: text,
          finish_reason: "success",
          usage_metadata: build_synthetic_usage(text, prompt),
          total_cost_usd: nil, # OpenCode CLI doesn't provide cost info
          session_id: nil,
          duration_ms: nil
        }
      end

      def build_synthetic_usage(text, prompt)
        # Estimate token counts since OpenCode CLI doesn't provide them
        input_tokens = estimate_tokens(prompt.to_s)
        output_tokens = estimate_tokens(text)
        
        {
          input_tokens: input_tokens,
          output_tokens: output_tokens,
          total_tokens: input_tokens + output_tokens
        }
      end

      def estimate_tokens(text)
        # Rough estimation: ~4 characters per token
        (text.length / 4.0).round
      end

      def handle_opencode_error(error)
        # Re-raise the error for proper handling by the base client error flow
        raise error
      end
      
      def normalize_model_name(model)
        # Ensure model is in provider/model format
        return model if model.include?('/')
        
        # If it's just a model name, we need to validate it's a recognized format
        # For now, assume it's meant to be a full provider/model string
        # This will be caught by validation if invalid
        model
      end

      # Override base client methods since we don't need credentials
      def needs_credentials?
        false
      end

      def setup_credentials(api_key, options)
        # No API credentials needed for CLI-based client
        @api_key = nil
      end

      def setup_request_builder(options)
        # No HTTP request builder needed for CLI-based client  
        @request_builder = nil
      end

      def setup_response_parser
        # No API response parser needed for CLI-based client
        @response_parser = nil
      end
    end
  end
end