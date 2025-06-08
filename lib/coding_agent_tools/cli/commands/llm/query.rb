# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/gemini_client"
require_relative "../../../organisms/prompt_processor"
require_relative "../../../atoms/json_formatter"

module CodingAgentTools
  module Cli
    module Commands
      module LLM
        # Query command for interacting with Google Gemini API
        class Query < Dry::CLI::Command
          desc "Query Google Gemini AI with a prompt"

          argument :prompt, required: true, desc: "The prompt text or file path (use --file flag for files)"

          option :file, type: :boolean, default: false, aliases: ["f"],
            desc: "Treat the prompt argument as a file path"

          option :format, type: :string, default: "text", values: %w[text json],
            desc: "Output format (text or json)"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :model, type: :string, default: "gemini-2.0-flash-lite",
            desc: "Model to use (default: gemini-2.0-flash-lite)"

          option :temperature, type: :float,
            desc: "Temperature for generation (0.0-2.0)"

          option :max_tokens, type: :integer,
            desc: "Maximum output tokens"

          option :system, type: :string,
            desc: "System instruction/prompt"

          example [
            '"What is Ruby programming language?"',
            '"Explain quantum computing" --format json',
            "prompt.txt --file",
            "prompt.txt --file --format json --debug",
            '"Hello" --model gemini-pro --temperature 0.5'
          ]

          def call(prompt:, **options)
            # Validate prompt argument (now handled by dry-cli, but keep empty check)
            if prompt.nil? || prompt.strip.empty?
              error_output("Error: Prompt is required", options[:debug])
              exit 1
            end

            # Process the prompt
            prompt_text = process_prompt(prompt, options)

            # Initialize and query Gemini
            response = query_gemini(prompt_text, options)

            # Format and output the response
            output_response(response, options)
          rescue => e
            handle_error(e, options[:debug])
          end

          private

          def process_prompt(prompt, options)
            processor = Organisms::PromptProcessor.new
            processor.process(prompt, from_file: options[:file])
          rescue CodingAgentTools::Error => e
            raise e
          rescue => e
            raise CodingAgentTools::Error, "Failed to process prompt: #{e.message}"
          end

          def query_gemini(prompt_text, options)
            client = build_gemini_client(options)

            generation_options = build_generation_options(options)

            client.generate_text(prompt_text, **generation_options)
          rescue => e
            new_error = CodingAgentTools::Error.new("Failed to query Gemini: #{e.message}")
            new_error.set_backtrace(e.backtrace)
            raise new_error
          end

          def build_gemini_client(options)
            client_options = {}
            client_options[:model] = options[:model] if options[:model]

            Organisms::GeminiClient.new(**client_options)
          end

          def build_generation_options(options)
            generation_options = {}

            # Add system instruction if provided
            generation_options[:system_instruction] = options[:system] if options[:system]

            # Build generation config if temperature or max_tokens provided
            generation_config = {}
            generation_config[:temperature] = options[:temperature] if options[:temperature]
            generation_config[:maxOutputTokens] = options[:max_tokens] if options[:max_tokens]

            generation_options[:generation_config] = generation_config unless generation_config.empty?

            generation_options
          end

          def output_response(response, options)
            case options[:format]
            when "json"
              output_json_response(response)
            else
              output_text_response(response)
            end
            response
          end

          def output_text_response(response)
            puts response[:text]
            response
          end

          def output_json_response(response)
            # Structure the JSON output
            output = {
              text: response[:text],
              metadata: {
                finish_reason: response[:finish_reason],
                safety_ratings: response[:safety_ratings],
                usage: response[:usage_metadata]
              }
            }

            formatted = Atoms::JSONFormatter.pretty_format(output)
            puts formatted
            response
          end

          def handle_error(error, debug_enabled)
            if debug_enabled
              error_output("Error: #{error.class.name}: #{error.message}", true)
              error_output("\nBacktrace:", true)
              error.backtrace.each { |line| error_output("  #{line}", true) }
            else
              error_output("Error: #{error.message}", false)
              error_output("Use --debug flag for more information", false)
            end
            exit 1
          end

          def error_output(message, debug_enabled)
            warn message
          end
        end
      end
    end
  end
end
