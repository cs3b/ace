# frozen_string_literal: true

require_relative "molecules/client_registry"
require_relative "molecules/provider_model_parser"
require_relative "molecules/format_handlers"
require_relative "molecules/file_io_handler"

module Ace
  module LLM
    # QueryInterface provides a simple Ruby API with named parameters matching the CLI
    # This allows direct Ruby calls to LLM providers without subprocess overhead
    class QueryInterface
      # Query an LLM provider with named parameters matching CLI flags exactly
      #
      # @param provider_model [String] Provider:model or alias (e.g., "glite", "google:gemini-2.0-flash-lite")
      # @param prompt [String] The user prompt to send to the LLM
      # @param output [String, nil] Optional file path to write output (--output FILE)
      # @param format [String] Output format: "text", "json", "yaml", "raw" (--format FORMAT)
      # @param temperature [Float, nil] Optional temperature for generation (--temperature FLOAT)
      # @param max_tokens [Integer, nil] Optional maximum tokens (--max-tokens INT)
      # @param system [String, nil] Optional system prompt (--system TEXT)
      # @param timeout [Integer] Request timeout in seconds (--timeout SECONDS)
      # @param force [Boolean] Force overwrite output file (--force)
      # @param debug [Boolean] Enable debug output (--debug)
      # @param model [String, nil] Model name (overrides PROVIDER[:MODEL] if both present) (--model MODEL)
      #
      # @return [Hash] Response with :text, :model, :provider, and other metadata
      # @raise [Error] If provider/model invalid or request fails
      def self.query(provider_model, prompt,
                    output: nil,
                    format: "text",
                    temperature: nil,
                    max_tokens: nil,
                    system: nil,
                    timeout: 30,
                    force: false,
                    debug: false,
                    model: nil)

        # Initialize registry and parser
        registry = Molecules::ClientRegistry.new
        parser = Molecules::ProviderModelParser.new(registry: registry)

        # Parse model/alias
        parse_result = parser.parse(provider_model)
        raise Error, parse_result.error unless parse_result.valid?

        # Resolve final model: model parameter > positional :MODEL > provider default
        final_model = model || parse_result.model

        # Validate that we have a model from some source
        if final_model.nil? || final_model.empty?
          raise Error, "No model specified and no default available for #{parse_result.provider}"
        end

        # Build messages array
        messages = []
        messages << { role: "system", content: system } if system && !system.empty?
        messages << { role: "user", content: prompt }

        # Get client with timeout option
        client = registry.get_client(
          parse_result.provider,
          model: final_model,
          timeout: timeout
        )

        # Build generation options
        generation_opts = {}
        generation_opts[:temperature] = temperature if temperature
        generation_opts[:max_tokens] = max_tokens if max_tokens

        # Debug output if requested
        if debug
          $stderr.puts "Provider: #{parse_result.provider}"
          $stderr.puts "Model: #{final_model}"
          $stderr.puts "Temperature: #{temperature}" if temperature
          $stderr.puts "Max tokens: #{max_tokens}" if max_tokens
        end

        # Generate response
        response = client.generate(messages, **generation_opts)

        # Extract text content based on response structure
        text_content = extract_text_content(response)

        # Build result hash
        result = {
          text: text_content,
          model: final_model,
          provider: parse_result.provider,
          usage: response[:usage],
          metadata: response[:metadata]
        }

        # Handle output option if provided
        if output && !output.empty?
          handler = Molecules::FormatHandlers.get_handler(format)

          # Format the content based on requested format
          formatted_content = case format
          when "json"
            handler.format(result)
          when "yaml"
            handler.format(result)
          when "raw"
            handler.format(response)
          else # "text" or default
            text_content
          end

          # Write to file
          file_handler = Molecules::FileIoHandler.new
          file_handler.write_content(formatted_content, output, format: format, force: force)

          $stderr.puts "Output written to: #{output}" if debug
        end

        result
      end

      private

      # Extract text content from various response formats
      # @param response [Hash] The response from the LLM client
      # @return [String] The extracted text content
      def self.extract_text_content(response)
        # Handle different response structures
        if response[:text]
          # Direct text field
          response[:text]
        elsif response[:content]
          # Content field (some providers)
          response[:content]
        elsif response[:choices] && response[:choices].is_a?(Array) && !response[:choices].empty?
          # OpenAI-style response
          choice = response[:choices].first
          if choice[:message] && choice[:message][:content]
            choice[:message][:content]
          elsif choice[:text]
            choice[:text]
          else
            ""
          end
        elsif response[:candidates] && response[:candidates].is_a?(Array) && !response[:candidates].empty?
          # Google-style response
          candidate = response[:candidates].first
          if candidate[:content] && candidate[:content][:parts] && !candidate[:content][:parts].empty?
            candidate[:content][:parts].first[:text] || ""
          else
            ""
          end
        else
          # Fallback to string representation if structure unknown
          response.to_s
        end
      end
    end
  end
end