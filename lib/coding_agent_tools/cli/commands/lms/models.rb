# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/lm_studio_client"
require_relative "../../../molecules/model"

module CodingAgentTools
  module Cli
    module Commands
      module LMS
        # Models command for listing available LM Studio models
        class Models < Dry::CLI::Command
          desc "List available LM Studio AI models"

          option :filter, type: :string, aliases: ["f"],
            desc: "Filter models by name (fuzzy search)"

          option :format, type: :string, default: "text", values: %w[text json],
            desc: "Output format (text or json)"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          example [
            "",
            "--filter mistral",
            "--filter deepseek --format json",
            "--format json"
          ]

          def call(**options)
            models = get_available_models
            filtered_models = filter_models(models, options[:filter])
            output_models(filtered_models, options)
          rescue => e
            handle_error(e, options[:debug])
          end

          private

          # Get list of available LM Studio models
          def get_available_models
            client = Organisms::LMStudioClient.new
            models_response = client.list_models

            default_model_id = Organisms::LMStudioClient::DEFAULT_MODEL
            # Convert API response to our model structure
            models_response.map do |model|
              model_id = model[:id]
              Molecules::Model.new(
                id: model_id,
                name: format_model_name(model_id),
                description: "LM Studio model",
                default: model_id == default_model_id
              )
            end.sort_by(&:id)
          rescue
            # Fallback to hardcoded list if API/server fails
            fallback_models
          end

          # Format model name for display
          def format_model_name(model_id)
            # Extract the model name part after the last slash
            name_part = model_id.split("/").last

            # Convert to title case
            words = name_part.split(/[-_]/).map(&:capitalize)
            words.join(" ")
          end

          # Fallback models if API call fails
          def fallback_models
            default_model_id = Organisms::LMStudioClient::DEFAULT_MODEL
            [
              Molecules::Model.new(
                id: "mistralai/devstral-small-2505",
                name: "Devstral Small",
                description: "Specialized coding model, optimized for development tasks",
                default: default_model_id == "mistralai/devstral-small-2505"
              ),
              Molecules::Model.new(
                id: "deepseek/deepseek-r1-0528-qwen3-8b",
                name: "DeepSeek R1 Qwen3 8B",
                description: "Advanced reasoning model with strong performance",
                default: default_model_id == "deepseek/deepseek-r1-0528-qwen3-8b"
              )
            ]
          end

          # Filter models based on search term
          def filter_models(models, filter_term)
            return models unless filter_term

            filter_term = filter_term.downcase
            models.select do |model|
              model.id.downcase.include?(filter_term) ||
                model.name.downcase.include?(filter_term) ||
                model.description.downcase.include?(filter_term)
            end
          end

          # Output models in the specified format
          def output_models(models, options)
            case options[:format]
            when "json"
              output_json_models(models)
            else
              output_text_models(models)
            end
          end

          # Output models as formatted text
          def output_text_models(models)
            if models.empty?
              puts "No models found matching the filter criteria."
              return
            end

            puts "Available LM Studio Models:"
            puts "=" * 50
            puts
            puts "Note: Models must be loaded in LM Studio before use."
            puts

            models.each do |model|
              puts
              puts model
            end

            puts
            puts "Usage: llm-lmstudio-query \"your prompt\" --model MODEL_ID"
            puts
            puts "Server: Ensure LM Studio is running at http://localhost:1234"
          end

          # Output models as JSON
          def output_json_models(models)
            default_model = models.find(&:default?)
            output = {
              models: models.map(&:to_json_hash),
              count: models.length,
              default_model: default_model&.id || Organisms::LMStudioClient::DEFAULT_MODEL,
              server_url: "http://localhost:1234"
            }

            puts JSON.pretty_generate(output)
          end

          # Handle errors
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
