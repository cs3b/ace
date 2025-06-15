# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/gemini_client"
require_relative "../../../models/llm_model_info"
require_relative "../../shared_behavior"
require_relative "../../../constants/cli_constants"
require_relative "../../../constants/model_constants"
require "yaml"

module CodingAgentTools
  module Cli
    module Commands
      module LLM
        # Models command for listing available Google Gemini models
        class Models < Dry::CLI::Command
          include CodingAgentTools::Cli::SharedBehavior
          desc "List available Google Gemini AI models"

          option :filter, type: :string, aliases: ["f"],
            desc: "Filter models by name (fuzzy search)"

          option :format, type: :string, default: CodingAgentTools::Constants::CliConstants::FORMAT_TEXT,
            values: CodingAgentTools::Constants::CliConstants::VALID_FORMATS,
            desc: "Output format (text or json)"

          option :debug, type: :boolean, default: false, aliases: CodingAgentTools::Constants::CliConstants::DEBUG_OPTION_ALIASES,
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
              model[:supportedGenerationMethods]&.include?(CodingAgentTools::Constants::CliConstants::GENERATE_CONTENT_METHOD)
            end

            # Convert API response to our model structure
            default_model_id = Organisms::GeminiClient::DEFAULT_MODEL
            generate_models.map do |model|
              model_id = model[:name].sub(CodingAgentTools::Constants::CliConstants::MODELS_PREFIX, "")
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
            name = model_name.sub(CodingAgentTools::Constants::CliConstants::MODELS_PREFIX, "")

            # Convert kebab-case to title case
            words = name.split("-").map do |word|
              CodingAgentTools::Constants::CliConstants::MODEL_NAME_MAPPINGS[word] || word.capitalize
            end

            words.join(" ")
          end

          # Fallback models if API call fails
          def fallback_models
            config_path = File.expand_path("../../../../config/fallback_models.yml", __FILE__)
            config = YAML.load_file(config_path)

            default_model_id = Organisms::GeminiClient::DEFAULT_MODEL
            gemini_config = config["gemini"]

            gemini_config["models"].map do |model_data|
              CodingAgentTools::Models::LlmModelInfo.new(
                id: model_data["id"],
                name: model_data["name"],
                description: model_data["description"],
                default: model_data["id"] == default_model_id
              )
            end
          end

          # Output models as formatted text
          def output_text_models(models)
            if models.empty?
              puts CodingAgentTools::Constants::CliConstants::NO_MODELS_FOUND_MESSAGE
              return
            end

            config_path = File.expand_path("../../../../config/fallback_models.yml", __FILE__)
            config = YAML.load_file(config_path)
            usage_config = config["usage_instructions"]["gemini"]

            puts usage_config["header"]
            puts CodingAgentTools::Constants::CliConstants::SEPARATOR_LINE

            models.each do |model|
              puts
              puts model
            end

            puts
            puts "Usage: #{usage_config["command"]}"
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
        end
      end
    end
  end
end
