# frozen_string_literal: true

require "dry/cli"
require "yaml"
require "fileutils"
require_relative "../../../models/default_model_config"

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
              warn "Error: Invalid provider '#{provider}'. Valid providers are: google, lmstudio, openai, anthropic, mistral, together_ai"
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
              model.id&.downcase&.include?(filter_term) ||
                model.name&.downcase&.include?(filter_term) ||
                model.description&.downcase&.include?(filter_term)
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

          # Get the default model configuration
          def default_config
            @default_config ||= CodingAgentTools::Models::DefaultModelConfig.default
          end

          # Check if provider is valid
          def valid_provider?(provider)
            %w[google lmstudio openai anthropic mistral together_ai].include?(provider)
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
              fetch_google_models
            when "lmstudio"
              fetch_lmstudio_models
            when "openai"
              fetch_openai_models
            when "anthropic"
              fetch_anthropic_models
            when "mistral"
              fetch_mistral_models
            when "together_ai"
              fetch_together_ai_models
            end
          rescue
            # Fallback to hardcoded list if API fails
            fallback_models(provider)
          end

          # Fetch Google models from API
          def fetch_google_models
            client = Organisms::GoogleClient.new
            models_response = client.list_models

            # Filter to only include generateContent-capable models
            generate_models = models_response.select do |model|
              model[:supportedGenerationMethods]&.include?(CodingAgentTools::Constants::CliConstants::GENERATE_CONTENT_METHOD)
            end

            # Convert API response to our model structure
            default_model_id = default_config.default_model_for("google")
            generate_models.map do |model|
              model_id = model[:name].sub(CodingAgentTools::Constants::CliConstants::MODELS_PREFIX, "")
              CodingAgentTools::Models::LlmModelInfo.new(
                id: model_id,
                name: format_model_name(model[:name]),
                description: model[:description] || "Google model",
                default: model_id == default_model_id
              )
            end.sort_by(&:id)
          end

          # Fetch LM Studio models from API
          def fetch_lmstudio_models
            client = Organisms::LmstudioClient.new
            models_response = client.list_models

            default_model_id = default_config.default_model_for("lmstudio")
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

          # Fetch OpenAI models from API
          def fetch_openai_models
            client = Organisms::OpenaiClient.new
            models_response = client.list_models

            # Filter to only include chat/completion models
            chat_models = models_response.select do |model|
              model[:id].include?("gpt") || model[:id].include?("o1")
            end

            default_model_id = default_config.default_model_for("openai")
            # Convert API response to our model structure
            chat_models.map do |model|
              model_id = model[:id]
              CodingAgentTools::Models::LlmModelInfo.new(
                id: model_id,
                name: format_openai_model_name(model_id),
                description: "OpenAI model",
                default: model_id == default_model_id
              )
            end.sort_by(&:id)
          end

          # Fetch Anthropic models from API
          def fetch_anthropic_models
            client = Organisms::AnthropicClient.new
            models_response = client.list_models

            default_model_id = default_config.default_model_for("anthropic")
            # Convert API response to our model structure
            models_response.map do |model|
              model_id = model[:id]
              CodingAgentTools::Models::LlmModelInfo.new(
                id: model_id,
                name: format_anthropic_model_name(model_id),
                description: model[:description] || "Anthropic Claude model",
                default: model_id == default_model_id
              )
            end.sort_by(&:id)
          end

          # Fetch Mistral models from API
          def fetch_mistral_models
            client = Organisms::MistralClient.new
            models_response = client.list_models

            default_model_id = default_config.default_model_for("mistral")
            # Convert API response to our model structure
            models_response.map do |model|
              model_id = model[:id]
              CodingAgentTools::Models::LlmModelInfo.new(
                id: model_id,
                name: format_mistral_model_name(model_id),
                description: model[:description] || "Mistral AI model",
                default: model_id == default_model_id
              )
            end.sort_by(&:id)
          end

          # Fetch Together AI models from API
          def fetch_together_ai_models
            client = Organisms::TogetheraiClient.new
            models_response = client.list_models

            default_model_id = default_config.default_model_for("together_ai")
            # Convert API response to our model structure
            models_response.map do |model|
              model_id = model[:id] || model[:name]
              CodingAgentTools::Models::LlmModelInfo.new(
                id: model_id,
                name: format_together_ai_model_name(model_id),
                description: model[:description] || "Together AI model",
                default: model_id == default_model_id
              )
            end.sort_by(&:id)
          end

          # Format Google model name for display
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

          # Format OpenAI model name for display
          def format_openai_model_name(model_id)
            # Handle common OpenAI model naming patterns
            case model_id
            when /^gpt-4o/
              "GPT-4 Omni"
            when /^gpt-4-turbo/
              "GPT-4 Turbo"
            when /^gpt-4/
              "GPT-4"
            when /^gpt-3.5-turbo/
              "GPT-3.5 Turbo"
            when /^o1-preview/
              "O1 Preview"
            when /^o1-mini/
              "O1 Mini"
            else
              model_id.split("-").map(&:capitalize).join(" ")
            end
          end

          # Format Anthropic model name for display
          def format_anthropic_model_name(model_id)
            # Handle Anthropic model naming patterns
            case model_id
            when /^claude-3-5-sonnet/
              "Claude 3.5 Sonnet"
            when /^claude-3-5-haiku/
              "Claude 3.5 Haiku"
            when /^claude-3-opus/
              "Claude 3 Opus"
            when /^claude-3-sonnet/
              "Claude 3 Sonnet"
            when /^claude-3-haiku/
              "Claude 3 Haiku"
            else
              model_id.split("-").map(&:capitalize).join(" ")
            end
          end

          # Format Mistral model name for display
          def format_mistral_model_name(model_id)
            # Handle Mistral AI model naming patterns
            case model_id
            when /^mistral-large/
              "Mistral Large"
            when /^mistral-medium/
              "Mistral Medium"
            when /^mistral-small/
              "Mistral Small"
            when /^mistral-tiny/
              "Mistral Tiny"
            when /^mistral-8x7b/
              "Mistral 8x7B"
            when /^mistral-8x22b/
              "Mistral 8x22B"
            else
              model_id.split("-").map(&:capitalize).join(" ")
            end
          end

          # Format Together AI model name for display
          def format_together_ai_model_name(model_id)
            # Handle Together AI model naming patterns
            case model_id
            when /meta-llama.*3.*70[Bb]/
              "Llama 3.1 70B"
            when /meta-llama.*3.*8[Bb]/
              "Llama 3.1 8B"
            when /mistralai.*[Mm]istral.*8x7[Bb]/
              "Mistral 8x7B"
            when /mistralai.*[Mm]istral.*8x22[Bb]/
              "Mistral 8x22B"
            when /deepseek/i
              "DeepSeek Coder"
            when /qwen/i
              model_id.split("/").last.split("-").map(&:capitalize).join(" ")
            else
              model_id.split("/").last.split("-").map(&:capitalize).join(" ")
            end
          end

          # Fallback models if API call fails
          def fallback_models(provider)
            config_path = File.expand_path("../../../../config/fallback_models.yml", __FILE__)
            config = YAML.load_file(config_path)

            case provider
            when "google"
              default_model_id = default_config.default_model_for("google")
              google_config = config["google"]

              google_config["models"].map do |model_data|
                CodingAgentTools::Models::LlmModelInfo.new(
                  id: model_data["id"],
                  name: model_data["name"],
                  description: model_data["description"],
                  default: model_data["id"] == default_model_id
                )
              end
            when "lmstudio"
              default_model_id = default_config.default_model_for("lmstudio")
              lms_config = config["lm_studio"]

              lms_config["models"].map do |model_data|
                CodingAgentTools::Models::LlmModelInfo.new(
                  id: model_data["id"],
                  name: model_data["name"],
                  description: model_data["description"],
                  default: model_data["id"] == default_model_id
                )
              end
            when "openai"
              default_model_id = default_config.default_model_for("openai")
              openai_config = config["openai"]

              openai_config["models"].map do |model_data|
                CodingAgentTools::Models::LlmModelInfo.new(
                  id: model_data["id"],
                  name: model_data["name"],
                  description: model_data["description"],
                  default: model_data["id"] == default_model_id
                )
              end
            when "anthropic"
              default_model_id = default_config.default_model_for("anthropic")
              anthropic_config = config["anthropic"]

              anthropic_config["models"].map do |model_data|
                CodingAgentTools::Models::LlmModelInfo.new(
                  id: model_data["id"],
                  name: model_data["name"],
                  description: model_data["description"],
                  default: model_data["id"] == default_model_id
                )
              end
            when "mistral"
              default_model_id = default_config.default_model_for("mistral")
              mistral_config = config["mistral"]

              mistral_config["models"].map do |model_data|
                CodingAgentTools::Models::LlmModelInfo.new(
                  id: model_data["id"],
                  name: model_data["name"],
                  description: model_data["description"],
                  default: model_data["id"] == default_model_id
                )
              end
            when "together_ai"
              default_model_id = default_config.default_model_for("together_ai")
              together_ai_config = config["together_ai"]

              together_ai_config["models"].map do |model_data|
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
              usage_config = config["usage_instructions"]["google"]
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
            when "openai"
              puts "Available OpenAI Models"
              puts CodingAgentTools::Constants::CliConstants::SEPARATOR_LINE

              models.each do |model|
                puts
                puts model
              end

              puts
              puts "Usage: llm-openai-query \"Your prompt here\" --model MODEL_ID"
            when "anthropic"
              puts "Available Anthropic Models"
              puts CodingAgentTools::Constants::CliConstants::SEPARATOR_LINE

              models.each do |model|
                puts
                puts model
              end

              puts
              puts "Usage: llm-anthropic-query \"Your prompt here\" --model MODEL_ID"
            when "mistral"
              puts "Available Mistral AI Models"
              puts CodingAgentTools::Constants::CliConstants::SEPARATOR_LINE

              models.each do |model|
                puts
                puts model
              end

              puts
              puts "Usage: llm-mistral-query \"Your prompt here\" --model MODEL_ID"
            when "together_ai"
              puts "Available Together AI Models"
              puts CodingAgentTools::Constants::CliConstants::SEPARATOR_LINE

              models.each do |model|
                puts
                puts model
              end

              puts
              puts "Usage: llm-together-ai-query \"Your prompt here\" --model MODEL_ID"
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
              output[:default_model] = default_model&.id || default_config.default_model_for("google")
            when "lmstudio"
              usage_config = config["usage_instructions"]["lm_studio"]
              output[:default_model] = default_model&.id || default_config.default_model_for("lmstudio")
              output[:server_url] = usage_config["server_url"]
            when "openai"
              output[:default_model] = default_model&.id || default_config.default_model_for("openai")
            when "anthropic"
              output[:default_model] = default_model&.id || default_config.default_model_for("anthropic")
            when "mistral"
              output[:default_model] = default_model&.id || default_config.default_model_for("mistral")
            when "together_ai"
              output[:default_model] = default_model&.id || default_config.default_model_for("together_ai")
            end

            puts JSON.pretty_generate(output)
          end
        end
      end
    end
  end
end
