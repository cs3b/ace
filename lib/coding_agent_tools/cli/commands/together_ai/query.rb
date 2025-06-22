# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/together_ai_client"

module CodingAgentTools
  module Cli
    module Commands
      module TogetherAI
        # Query command for interacting with Together AI API
        class Query < Dry::CLI::Command
          desc "Query Together AI API with a prompt"

          argument :prompt, required: true, desc: "The prompt text or file path (auto-detected)"

          option :output, type: :string, aliases: ["o"],
            desc: "Output file path (format inferred from extension)"

          option :format, type: :string, values: %w[text json markdown],
            desc: "Output format (overrides file extension inference)"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :model, type: :string, default: "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo",
            desc: "Model to use (default: meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo)"

          option :temperature, type: :float,
            desc: "Temperature for generation (0.0-2.0)"

          option :max_tokens, type: :integer,
            desc: "Maximum output tokens"

          option :system, type: :string,
            desc: "System instruction/prompt (text or file path, auto-detected)"

          option :timeout, type: :integer, desc: "Request timeout in seconds"

          example [
            '"What is Ruby programming language?"',
            '"Explain quantum computing" --format json',
            "prompt.txt --output response.json",
            "prompt.txt --system system.md --output response.md",
            '"Hello" --model mistralai/Mistral-8x7B-Instruct-v0.1 --temperature 0.5 --output result.txt',
            '"Hello" --timeout 60'
          ]

          def call(prompt:, **options)
            # Validate prompt argument (now handled by dry-cli, but keep empty check)
            if prompt.nil? || prompt.strip.empty?
              error_output("Error: Prompt is required")
              exit 1
            end

            # Initialize file I/O handler
            @file_handler = Molecules::FileIoHandler.new

            # Process the prompt and system instruction
            prompt_text = process_content(prompt, "prompt")
            system_text = process_system_instruction(options[:system]) if options[:system]

            # Track execution time
            start_time = Time.now

            # Initialize and query Together AI
            response = query_together_ai(prompt_text, system_text, options)

            # Calculate execution time
            execution_time = Time.now - start_time

            # Add normalized metadata
            normalized_response = add_normalized_metadata(response, execution_time, options)

            # Format and output the response
            output_response(normalized_response, options)
          rescue => e
            handle_error(e, options[:debug])
          end

          private

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

          def query_together_ai(prompt_text, system_text, options)
            client = build_together_ai_client(options)

            generation_options = build_generation_options(options, system_text)

            client.generate_text(prompt_text, **generation_options)
          rescue => e
            new_error = CodingAgentTools::Error.new("Failed to query Together AI: #{e.message}")
            new_error.set_backtrace(e.backtrace)
            raise new_error
          end

          def build_together_ai_client(options)
            client_options = {}
            client_options[:model] = options[:model] if options[:model]
            client_options[:timeout] = options[:timeout] if options[:timeout]

            Organisms::TogetherAIClient.new(**client_options)
          end

          def build_generation_options(options, system_text)
            generation_options = {}

            # Add system instruction if provided
            generation_options[:system_instruction] = system_text if system_text

            # Build generation config if temperature or max_tokens provided
            generation_config = {}
            generation_config[:temperature] = options[:temperature] if options[:temperature]
            generation_config[:max_tokens] = options[:max_tokens] if options[:max_tokens]

            generation_options[:generation_config] = generation_config unless generation_config.empty?

            generation_options
          end

          def add_normalized_metadata(response, execution_time, options)
            metadata = Molecules::MetadataNormalizer.normalize(
              response,
              provider: "together_ai",
              model: options[:model] || "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo",
              execution_time: execution_time
            )

            {
              text: response[:text],
              metadata: metadata
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
            @file_handler.write_content(formatted_content, options[:output], format: format)

            # Print summary to stdout
            summary = handler.generate_summary(response, options[:output])
            puts summary
          end

          def output_to_stdout(response, options)
            format = options[:format] || "text"
            handler = Molecules::FormatHandlers.get_handler(format)

            formatted_content = handler.format(response)
            puts formatted_content
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
