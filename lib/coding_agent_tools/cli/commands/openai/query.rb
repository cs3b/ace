# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/openai_client"

module CodingAgentTools
  module Cli
    module Commands
      module OpenAI
        # Query command for interacting with OpenAI API
        class Query < Dry::CLI::Command
          desc "Query OpenAI API with a prompt"

          argument :prompt, required: true, desc: "The prompt text or file path (auto-detected)"

          option :output, type: :string, aliases: ["o"],
            desc: "Output file path (format inferred from extension)"

          option :format, type: :string, values: %w[text json markdown],
            desc: "Output format (overrides file extension inference)"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :model, type: :string, default: "gpt-4o",
            desc: "Model to use (default: gpt-4o)"

          option :temperature, type: :float,
            desc: "Temperature for generation (0.0-2.0)"

          option :max_tokens, type: :integer,
            desc: "Maximum output tokens"

          option :system, type: :string,
            desc: "System instruction/prompt (text or file path, auto-detected)"

          example [
            '"What is Ruby programming language?"',
            '"Explain quantum computing" --format json',
            "prompt.txt --output response.json",
            "prompt.txt --system system.md --output response.md",
            '"Hello" --model gpt-4o-mini --temperature 0.5 --output result.txt'
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

            # Initialize and query OpenAI
            response = query_openai(prompt_text, system_text, options)

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

          def query_openai(prompt_text, system_text, options)
            client = build_openai_client(options)

            generation_options = build_generation_options(options, system_text)

            client.generate_text(prompt_text, **generation_options)
          rescue => e
            new_error = CodingAgentTools::Error.new("Failed to query OpenAI: #{e.message}")
            new_error.set_backtrace(e.backtrace)
            raise new_error
          end

          def build_openai_client(options)
            client_options = {}
            client_options[:model] = options[:model] if options[:model]

            Organisms::OpenAIClient.new(**client_options)
          end

          def build_generation_options(options, system_text)
            generation_options = {}

            # Add system instruction if provided
            generation_options[:system_instruction] = system_text if system_text

            # Build generation config if temperature or max_tokens provided
            generation_config = {}
            generation_config[:temperature] = options[:temperature].to_f if options[:temperature]
            generation_config[:max_tokens] = options[:max_tokens] if options[:max_tokens]

            generation_options[:generation_config] = generation_config unless generation_config.empty?

            generation_options
          end

          def add_normalized_metadata(response, execution_time, options)
            metadata = Molecules::MetadataNormalizer.normalize(
              response,
              provider: "openai",
              model: options[:model] || "gpt-4o",
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
