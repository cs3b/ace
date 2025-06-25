# frozen_string_literal: true

require "dry/cli"
require_relative "../../../cost_tracker"

module CodingAgentTools
  module Cli
    module Commands
      module LLM
        # Query command for interacting with any LLM provider
        # This consolidates all provider-specific logic into one command
        class Query < Dry::CLI::Command
          desc "Query any LLM provider"

          argument :provider_model, required: true,
            desc: "Provider and model ('provider:model'), provider only ('provider'), or alias ('gflash')"

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

          option :force, type: :boolean, default: false, aliases: ["f"],
            desc: "Force overwrite existing output files without confirmation"

          example [
            'google:gemini-2.5-flash "What is Ruby programming language?"',
            'google "What is Ruby?" # uses default model',
            'anthropic:claude-4-0-sonnet-latest "Explain quantum computing" --format json',
            'openai:gpt-4o "Hello world" --temperature 0.5',
            'gflash "Quick question about Ruby" # alias for google:gemini-2.5-flash',
            'csonet "Explain AI" # alias for anthropic:claude-4-0-sonnet-latest',
            'o4mini "Code review" # alias for openai:gpt-4o-mini',
            "lmstudio prompt.txt --output response.json",
            "mistral prompt.txt --system system.md --output response.md"
          ]

          def call(provider_model:, prompt:, **options)
            # Parse provider:model argument
            parser = Molecules::ProviderModelParser.new
            parse_result = parser.parse(provider_model)

            unless parse_result.valid?
              error_output("Error: #{parse_result.error}")
              error_output("\nSupported providers: #{parser.supported_providers.join(", ")}")
              error_output("Available aliases: #{parser.dynamic_aliases.keys.join(", ")}")
              error_output("\nExamples:")
              error_output("  llm-query google \"What is Ruby?\"")
              error_output("  llm-query gflash \"Quick question\"")
              error_output("  llm-query anthropic:claude-4-0-sonnet-latest \"Explain AI\"")
              exit 1
            end

            # Validate prompt argument
            if prompt.nil? || prompt.strip.empty?
              error_output("Error: Prompt is required")
              exit 1
            end

            # Execute the unified query logic
            execute_query(parse_result.provider, parse_result.model, prompt, options)
          rescue => e
            handle_error(e, options[:debug])
          end

          private

          def execute_query(provider, model, prompt, options)
            # Initialize file I/O handler
            @file_handler = Molecules::FileIoHandler.new

            # Process the prompt and system instruction
            prompt_text = process_content(prompt, "prompt")
            system_text = process_system_instruction(options[:system]) if options[:system]

            # Track execution time
            start_time = Time.now

            # Query the provider
            response = query_provider(provider, model, prompt_text, system_text, options)

            # Calculate execution time
            execution_time = Time.now - start_time

            # Add normalized metadata
            normalized_response = add_normalized_metadata(response, execution_time, provider, model)

            # Format and output the response
            output_response(normalized_response, options)
          end

          def process_content(content, content_type)
            @file_handler.read_content(content, auto_detect: true)
          rescue CodingAgentTools::Error => e
            raise e # Re-raise specific CodingAgentTools errors directly
          rescue => e # Catch other StandardErrors
            new_error = CodingAgentTools::Error.new("Failed to process #{content_type}: #{e.message}")
            new_error.set_backtrace(e.backtrace)
            raise new_error
          end

          def process_system_instruction(system_content)
            return nil if system_content.nil? || system_content.strip.empty?
            process_content(system_content, "system instruction")
          end

          def query_provider(provider, model, prompt_text, system_text, options)
            client = build_client(provider, model, options)
            generation_options = build_generation_options(provider, options, system_text)

            client.generate_text(prompt_text, **generation_options)
          rescue => e
            new_error = CodingAgentTools::Error.new("Failed to query #{provider}: #{e.message}")
            new_error.set_backtrace(e.backtrace)
            raise new_error
          end

          def build_client(provider, model, options)
            client_options = {model: model}
            client_options[:timeout] = options[:timeout] if options[:timeout]

            Molecules::ClientFactory.build(provider, client_options)
          rescue Molecules::ClientFactory::UnknownProviderError => e
            raise ArgumentError, e.message
          end

          def build_generation_options(provider, options, system_text)
            generation_options = {}

            # Add system instruction if provided
            generation_options[:system_instruction] = system_text if system_text

            # Build generation config if temperature or max_tokens provided
            generation_config = {}

            # Handle provider-specific temperature conversion
            if options[:temperature]
              generation_config[:temperature] = case provider
              when "anthropic", "openai"
                options[:temperature].to_f
              else
                options[:temperature]
              end
            end

            # Handle provider-specific max_tokens naming
            if options[:max_tokens]
              case provider
              when "google"
                generation_config[:maxOutputTokens] = options[:max_tokens]
              else
                generation_config[:max_tokens] = options[:max_tokens]
              end
            end

            generation_options[:generation_config] = generation_config unless generation_config.empty?

            generation_options
          end

          def add_normalized_metadata(response, execution_time, provider, model)
            # Initialize cost tracker for enhanced metadata
            cost_tracker = CostTracker.new

            # Use cost-enabled normalization
            metadata_with_cost = Molecules::MetadataNormalizer.normalize_with_cost(
              response,
              provider: provider,
              model: model,
              execution_time: execution_time,
              cost_tracker: cost_tracker
            )

            {
              text: response[:text],
              metadata: metadata_with_cost.to_h,
              usage_metadata: metadata_with_cost
            }
          end

          def output_response(response, options)
            if options[:output]
              output_to_file(response, options)
            else
              output_to_stdout(response, options)
            end
            response
          end

          def output_to_file(response, options)
            format = determine_output_format(options)
            handler = Molecules::FormatHandlers.get_handler(format)

            formatted_content = handler.format(response)
            @file_handler.write_content(formatted_content, options[:output], format: format, force: options[:force])

            # Print summary to stdout
            summary = handler.generate_summary(response, options[:output])
            puts summary
          end

          def output_to_stdout(response, options)
            format = options[:format] || "text"
            handler = Molecules::FormatHandlers.get_handler(format)

            formatted_content = handler.format(response)
            puts formatted_content

            # Display usage and cost summary for text format
            if format == "text" && response[:usage_metadata]
              puts "\n" + generate_usage_summary(response[:usage_metadata])
            end
          end

          def generate_usage_summary(usage_metadata)
            lines = []
            lines << "Token Usage:"
            lines << "  Input: #{usage_metadata.input_tokens.to_s.rjust(8)} tokens"
            lines << "  Output: #{usage_metadata.output_tokens.to_s.rjust(7)} tokens"

            if usage_metadata.cached?
              lines << "  Cached: #{usage_metadata.cached_tokens.to_s.rjust(7)} tokens"
            end

            if usage_metadata.has_cost_info?
              lines << ""
              lines << usage_metadata.cost_summary
            end

            lines.join("\n")
          end

          def determine_output_format(options)
            # Format flag takes precedence over file extension
            return options[:format] if options[:format]

            # Infer from file extension
            @file_handler.infer_format_from_path(options[:output])
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
