# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/lm_studio_client"
require_relative "../../../organisms/prompt_processor"
require_relative "../../../atoms/json_formatter"

module CodingAgentTools
  module Cli
    module Commands
      module LMS
        # Query command for interacting with LM Studio local server
        class Query < Dry::CLI::Command
          desc "Query LM Studio AI with a prompt"

          argument :prompt, required: true, desc: "The prompt text or file path (use --file flag for files)"

          option :file, type: :boolean, default: false, aliases: ["f"],
            desc: "Treat the prompt argument as a file path"

          option :format, type: :string, default: "text", values: %w[text json],
            desc: "Output format (text or json)"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :model, type: :string, default: "mistralai/devstral-small-2505",
            desc: "Model to use (default: mistralai/devstral-small-2505)"

          option :temperature, type: :float,
            desc: "Temperature for generation (0.0-2.0)"

          option :max_tokens, type: :integer,
            desc: "Maximum output tokens (-1 for unlimited)"

          option :system, type: :string,
            desc: "System instruction/prompt"

          example [
            '"What is Ruby programming language?"',
            '"Explain quantum computing" --format json',
            "prompt.txt --file",
            "prompt.txt --file --format json --debug",
            '"Hello" --model mistralai/devstral-small-2505 --temperature 0.5'
          ]

          def call(prompt:, **options)
            # Validate prompt argument (now handled by dry-cli, but keep empty check)
            if prompt.nil? || prompt.to_s.strip.empty?
              error_output("Error: Prompt is required")
              exit 1
            end

            # Process the prompt
            prompt_text = process_prompt(prompt, options)

            # Initialize and query LM Studio
            response = query_lm_studio(prompt_text, options)

            # Format and output the response
            output_response(response, options)
          rescue => e
            handle_error(e, options[:debug])
          end

          private

          def process_prompt(prompt, options)
            processor = Organisms::PromptProcessor.new
            # Ensure from_file is explicitly a boolean
            from_file = options[:file] == true
            processor.process(prompt, from_file: from_file)
          rescue CodingAgentTools::Error => e
            raise e # Re-raise specific CodingAgentTools errors directly
          rescue => e # Catch other StandardErrors
            new_error = CodingAgentTools::Error.new("Failed to process prompt: #{e.message}")
            new_error.set_backtrace(e.backtrace)
            raise new_error
          end

          def query_lm_studio(prompt_text, options)
            client = build_lm_studio_client(options)

            generation_options = build_generation_options(options)

            # Always pass generation_options as keyword arguments, even if empty
            if generation_options.empty?
              client.generate_text(prompt_text)
            else
              client.generate_text(prompt_text, **generation_options)
            end
          rescue => e
            new_error = CodingAgentTools::Error.new("Failed to query LM Studio: #{e.message}")
            new_error.set_backtrace(e.backtrace)
            raise new_error
          end

          def build_lm_studio_client(options)
            client_options = {}
            client_options[:model] = options[:model] if options[:model]

            Organisms::LMStudioClient.new(**client_options)
          end

          def build_generation_options(options)
            generation_options = {}

            # Add system instruction if provided
            generation_options[:system_instruction] = options[:system] if options[:system]

            # Build generation config if temperature or max_tokens provided
            generation_config = {}
            generation_config[:temperature] = options[:temperature] if options[:temperature]
            generation_config[:max_tokens] = options[:max_tokens] if options[:max_tokens]

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
                usage: response[:usage_metadata]
              }
            }

            formatted = Atoms::JSONFormatter.pretty_format(output)
            puts formatted
            response
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
