# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/gemini_client"
require_relative "../../../models/llm_model_info"

module CodingAgentTools
  module Cli
    module Commands
      module LLM
        # Models command for listing available Google Gemini models
        class Models < Dry::CLI::Command
          desc "List available Google Gemini AI models"

          option :filter, type: :string, aliases: ["f"],
            desc: "Filter models by name (fuzzy search)"

          option :format, type: :string, default: "text", values: %w[text json],
            desc: "Output format (text or json)"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          example [
            "",
            "--filter flash",
            "--filter pro --format json",
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

          # Get list of available Gemini models dynamically from API
          def get_available_models
            client = Organisms::GeminiClient.new
            models_response = client.list_models

            # Filter to only include generateContent-capable models
            generate_models = models_response.select do |model|
              model[:supportedGenerationMethods]&.include?("generateContent")
            end

            # Convert API response to our model structure
            default_model_id = Organisms::GeminiClient::DEFAULT_MODEL
            generate_models.map do |model|
              model_id = model[:name].sub("models/", "")
              CodingAgentTools::Models::LlmModelInfo.new(
                id: model_id,
                name: format_model_name(model[:name]),
                description: model[:description] || "Gemini model",
                default: model_id == default_model_id
              )
            end.sort_by(&:id)
          rescue
            # Fallback to hardcoded list if API fails
            fallback_models
          end

          # Format model name for display
          def format_model_name(model_name)
            name = model_name.sub("models/", "")

            # Convert kebab-case to title case
            words = name.split("-").map do |word|
              case word
              when "gemini" then "Gemini"
              when "flash" then "Flash"
              when "pro" then "Pro"
              when "lite" then "Lite"
              when "preview" then "Preview"
              else word.capitalize
              end
            end

            words.join(" ")
          end

          # Fallback models if API call fails
          def fallback_models
            default_model_id = Organisms::GeminiClient::DEFAULT_MODEL
            [
              CodingAgentTools::Models::LlmModelInfo.new(
                id: "gemini-2.0-flash-lite",
                name: "Gemini 2.0 Flash Lite",
                description: "Fast and efficient model, good for most tasks",
                default: default_model_id == "gemini-2.0-flash-lite"
              ),
              CodingAgentTools::Models::LlmModelInfo.new(
                id: "gemini-1.5-flash",
                name: "Gemini 1.5 Flash",
                description: "Fast multimodal model optimized for speed",
                default: default_model_id == "gemini-1.5-flash"
              ),
              CodingAgentTools::Models::LlmModelInfo.new(
                id: "gemini-1.5-pro",
                name: "Gemini 1.5 Pro",
                description: "Mid-size multimodal model for complex reasoning tasks",
                default: default_model_id == "gemini-1.5-pro"
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

            puts "Available Gemini Models:"
            puts "=" * 50

            models.each do |model|
              puts
              puts model
            end

            puts
            puts "Usage: llm-gemini-query \"your prompt\" --model MODEL_ID"
          end

          # Output models as JSON
          def output_json_models(models)
            default_model = models.find(&:default?)
            output = {
              models: models.map(&:to_json_hash),
              count: models.length,
              default_model: default_model&.id || Organisms::GeminiClient::DEFAULT_MODEL
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
