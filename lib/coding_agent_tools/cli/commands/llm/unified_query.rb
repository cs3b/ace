# frozen_string_literal: true

require "dry/cli"

module CodingAgentTools
  module Cli
    module Commands
      module LLM
        # Unified query command for interacting with any LLM provider
        class UnifiedQuery < Dry::CLI::Command
          desc "Query any LLM provider with unified provider:model syntax"

          argument :provider_model, required: true,
            desc: "Provider and model in format 'provider:model' or dynamic alias (e.g., 'google:gemini-2.5-flash', 'gflash')"

          argument :prompt, required: true, desc: "The prompt text or file path (auto-detected)"

          option :output, type: :string, aliases: ["o"],
            desc: "Output file path (format inferred from extension)"

          option :format, type: :string, values: %w[text json markdown],
            desc: "Output format (overrides file extension inference)"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :temperature, type: :float,
            desc: "Temperature for generation (0.0-2.0)"

          option :max_tokens, type: :integer,
            desc: "Maximum output tokens"

          option :system, type: :string,
            desc: "System instruction/prompt (text or file path, auto-detected)"

          option :timeout, type: :integer, desc: "Request timeout in seconds"

          example [
            'google:gemini-2.5-flash "What is Ruby programming language?"',
            'anthropic:claude-4-0-sonnet-latest "Explain quantum computing" --format json',
            'openai:gpt-4o "Hello world" --temperature 0.5',
            'gflash "Quick question about Ruby"',
            'csonet prompt.txt --output response.json',
            'o4mini prompt.txt --system system.md --output response.md'
          ]

          def call(provider_model:, prompt:, **options)
            # Parse provider:model argument
            parser = Molecules::ProviderModelParser.new
            parse_result = parser.parse(provider_model)

            unless parse_result.valid?
              error_output("Error: #{parse_result.error}")
              error_output("\nSupported providers: #{parser.supported_providers.join(', ')}")
              error_output("Available aliases: #{parser.dynamic_aliases.keys.join(', ')}")
              exit 1
            end

            # Validate prompt argument
            if prompt.nil? || prompt.strip.empty?
              error_output("Error: Prompt is required")
              exit 1
            end

            # Route to appropriate provider command
            route_to_provider_command(parse_result.provider, parse_result.model, prompt, options)
          rescue => e
            handle_error(e, options[:debug])
          end

          private

          def route_to_provider_command(provider, model, prompt, options)
            # Add model to options since individual provider commands expect it
            provider_options = options.merge(model: model)

            case provider
            when "google"
              Commands::Google::Query.new.call(prompt: prompt, **provider_options)
            when "anthropic"
              Commands::Anthropic::Query.new.call(prompt: prompt, **provider_options)
            when "openai"
              Commands::OpenAI::Query.new.call(prompt: prompt, **provider_options)
            when "mistral"
              Commands::Mistral::Query.new.call(prompt: prompt, **provider_options)
            when "together_ai"
              Commands::TogetherAI::Query.new.call(prompt: prompt, **provider_options)
            when "lmstudio"
              # LMStudio uses a different command structure (lms query)
              Commands::LMS::Query.new.call(prompt: prompt, **provider_options)
            else
              error_output("Error: Unsupported provider: #{provider}")
              exit 1
            end
          end

          def handle_error(error, debug_enabled)
            if debug_enabled
              error_output("Error: #{error.class.name}: #{error.message}")
              error_output("\nBacktrace:")
              error.backtrace.each { |line| error_output("  #{line}") }
            else
              error_output("Error: #{error.message}")
              error_output("Use --debug flag for more information")
            end
            exit 1
          end

          def error_output(message)
            warn message
          end
        end
      end
    end
  end
end
