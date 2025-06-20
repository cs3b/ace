# frozen_string_literal: true

require "dry/cli"
require "yaml"
require "fileutils"

module CodingAgentTools
  module Cli
    module Commands
      module LLM
        # Models command for listing available AI models from various providers
        class Models < Dry::CLI::Command
          desc "List available AI models from various providers"

          argument :provider, type: :string, default: "google",
            desc: "Provider to list models for (google, lmstudio)"

          option :filter, type: :string, aliases: ["f"],
            desc: "Filter models by name (fuzzy search)"

          option :format, type: :string, default: CodingAgentTools::Constants::CliConstants::FORMAT_TEXT,
            values: CodingAgentTools::Constants::CliConstants::VALID_FORMATS,
            desc: "Output format (text or json)"

          option :refresh, type: :boolean, default: false,
            desc: "Refresh cache by fetching latest data from APIs"

          option :debug, type: :boolean, default: false, aliases: CodingAgentTools::Constants::CliConstants::DEBUG_OPTION_ALIASES,
            desc: "Enable debug output for verbose error information"

          example [
            "google",
            "lmstudio",
            "google --filter flash",
            "lmstudio --filter mistral --format json",
            "google --refresh"
          ]

          def call(provider: "google", **options)
            unless valid_provider?(provider)
              warn "Error: Invalid provider '#{provider}'. Valid providers are: google, lmstudio"
              exit 1
            end

            models = get_available_models(provider, options[:refresh])
            filtered_models = filter_models(models, options[:filter])
            output_models(filtered_models, options.merge(provider: provider))
          rescue => e
            handle_error(e, options[:debug])
          end

          # Filter models based on search term
          # @param models [Array] Array of model objects
          # @param filter_term [String, nil] Filter term for fuzzy search
          # @return [Array] Filtered models
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
          # @param models [Array] Array of model objects
          # @param options [Hash] Command options
          def output_models(models, options)
            case options[:format]
            when "json"
              output_json_models(models, **options)
            else
              output_text_models(models, **options)
            end
          end

          # Handle command errors with optional debug output
          # @param error [Exception] The error that occurred
          # @param debug_enabled [Boolean] Whether to show debug information
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

          # Output error message to stderr
          # @param message [String] Error message
          def error_output(message)
            warn message
          end

          private

          # Check if provider is valid
          def valid_provider?(provider)
            %w[google lmstudio].include?(provider)
          end

          # Get list of available models for the specified provider
          def get_available_models(provider, refresh = false)
            if refresh || !cache_exists?(provider)
              models = fetch_models_from_api(provider)
              cache_models(provider, models)
              models
            else
              load_models_from_cache(provider)
            end
          end

          # Fetch models from API based on provider
          def fetch_models_from_api(provider)
            case provider
            when "google"
              fetch_gemini_models
            when "lmstudio"
              fetch_lmstudio_models
            end
          rescue
            # Fallback to hardcoded list if API fails
            fallback_models(provider)
          end

          # Fetch Gemini models from API
          def fetch_gemini_models
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
          end

          # Fetch LM Studio models from API
          def fetch_lmstudio_models
            client = Organisms::LMStudioClient.new
            models_response = client.list_models

            default_model_id = Organisms::LMStudioClient::DEFAULT_MODEL
            # Convert API response to our model structure
            models_response.map do |model|
              model_id = model[:id]
              CodingAgentTools::Models::LlmModelInfo.new(
                id: model_id,
                name: format_lmstudio_model_name(model_id),
                description: "LM Studio model",
                default: model_id == default_model_id
              )
            end.sort_by(&:id)
          end

          # Format Gemini model name for display
          def format_model_name(model_name)
            name = model_name.sub(CodingAgentTools::Constants::CliConstants::MODELS_PREFIX, "")

            # Convert kebab-case to title case
            words = name.split("-").map do |word|
              CodingAgentTools::Constants::CliConstants::MODEL_NAME_MAPPINGS[word] || word.capitalize
            end

            words.join(" ")
          end

          # Format LM Studio model name for display
          def format_lmstudio_model_name(model_id)
            # Extract the model name part after the last slash
            name_part = model_id.split("/").last

            # Convert to title case
            words = name_part.split(/[-_]/).map(&:capitalize)
            words.join(" ")
          end

          # Fallback models if API call fails
          def fallback_models(provider)
            config_path = File.expand_path("../../../../config/fallback_models.yml", __FILE__)
            config = YAML.load_file(config_path)

            case provider
            when "google"
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
            when "lmstudio"
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
          end

          # Cache management methods
          def cache_dir
            @cache_dir ||= File.expand_path("~/.coding-agent-tools-cache")
          end

          def cache_file_path(provider)
            File.join(cache_dir, "#{provider}_models.yml")
          end

          def cache_exists?(provider)
            File.exist?(cache_file_path(provider))
          end

          def cache_models(provider, models)
            FileUtils.mkdir_p(cache_dir)

            cache_data = {
              "cached_at" => Time.now.iso8601,
              "provider" => provider,
              "models" => models.map do |model|
                {
                  "id" => model.id,
                  "name" => model.name,
                  "description" => model.description,
                  "default" => model.default?
                }
              end
            }

            File.write(cache_file_path(provider), YAML.dump(cache_data))
          end

          def load_models_from_cache(provider)
            cache_data = YAML.load_file(cache_file_path(provider))

            cache_data["models"].map do |model_data|
              CodingAgentTools::Models::LlmModelInfo.new(
                id: model_data["id"],
                name: model_data["name"],
                description: model_data["description"],
                default: model_data["default"]
              )
            end
          end

          # Output models as formatted text
          def output_text_models(models, **options)
            provider = options[:provider] || "google"
            if models.empty?
              puts CodingAgentTools::Constants::CliConstants::NO_MODELS_FOUND_MESSAGE
              return
            end

            config_path = File.expand_path("../../../../config/fallback_models.yml", __FILE__)
            config = YAML.load_file(config_path)

            case provider
            when "google"
              usage_config = config["usage_instructions"]["gemini"]
              puts usage_config["header"]
              puts CodingAgentTools::Constants::CliConstants::SEPARATOR_LINE

              models.each do |model|
                puts
                puts model
              end

              puts
              puts "Usage: #{usage_config["command"]}"
            when "lmstudio"
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
          end

          # Output models as JSON
          def output_json_models(models, **options)
            provider = options[:provider] || "google"
            config_path = File.expand_path("../../../../config/fallback_models.yml", __FILE__)
            config = YAML.load_file(config_path)

            default_model = models.find(&:default?)
            output = {
              models: models.map(&:to_json_hash),
              count: models.length,
              provider: provider
            }

            case provider
            when "google"
              output[:default_model] = default_model&.id || Organisms::GeminiClient::DEFAULT_MODEL
            when "lmstudio"
              usage_config = config["usage_instructions"]["lm_studio"]
              output[:default_model] = default_model&.id || Organisms::LMStudioClient::DEFAULT_MODEL
              output[:server_url] = usage_config["server_url"]
            end

            puts JSON.pretty_generate(output)
          end
        end
      end
    end
  end
end
