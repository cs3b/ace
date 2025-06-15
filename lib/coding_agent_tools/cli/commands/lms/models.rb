# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/lm_studio_client"
require_relative "../../../models/llm_model_info"
require_relative "../../shared_behavior"
require_relative "../../../constants/cli_constants"
require_relative "../../../constants/model_constants"
require "yaml"

module CodingAgentTools
  module Cli
    module Commands
      module LMS
        # Models command for listing available LM Studio models
        class Models < Dry::CLI::Command
          include CodingAgentTools::Cli::SharedBehavior
          desc "List available LM Studio AI models"

          option :filter, type: :string, aliases: ["f"],
            desc: "Filter models by name (fuzzy search)"

          option :format, type: :string, default: CodingAgentTools::Constants::CliConstants::FORMAT_TEXT,
            values: CodingAgentTools::Constants::CliConstants::VALID_FORMATS,
            desc: "Output format (text or json)"

          option :debug, type: :boolean, default: false, aliases: CodingAgentTools::Constants::CliConstants::DEBUG_OPTION_ALIASES,
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
              CodingAgentTools::Models::LlmModelInfo.new(
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
            config_path = File.expand_path("../../../../config/fallback_models.yml", __FILE__)
            config = YAML.load_file(config_path)

            default_model_id = Organisms::LMStudioClient::DEFAULT_MODEL
            lms_config = config["lm_studio"]

            lms_config["models"].map do |model_data|
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
            usage_config = config["usage_instructions"]["lm_studio"]

            puts usage_config["header"]
            puts CodingAgentTools::Constants::CliConstants::SEPARATOR_LINE
            puts
            puts usage_config["note"]
            puts

            models.each do |model|
              puts
              puts model
            end

            puts
            puts "Usage: #{usage_config["command"]}"
            puts
            puts usage_config["server_info"]
          end

          # Output models as JSON
          def output_json_models(models)
            config_path = File.expand_path("../../../../config/fallback_models.yml", __FILE__)
            config = YAML.load_file(config_path)
            usage_config = config["usage_instructions"]["lm_studio"]

            default_model = models.find(&:default?)
            output = {
              models: models.map(&:to_json_hash),
              count: models.length,
              default_model: default_model&.id || Organisms::LMStudioClient::DEFAULT_MODEL,
              server_url: usage_config["server_url"]
            }

            puts JSON.pretty_generate(output)
          end
        end
      end
    end
  end
end
