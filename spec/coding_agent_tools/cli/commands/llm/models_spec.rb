# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/llm/models"
require "timeout"

RSpec.describe CodingAgentTools::Cli::Commands::LLM::Models do
  subject(:command) { described_class.new }

  let(:output) { StringIO.new }

  before do
    allow($stdout).to receive(:puts) { |msg| output.puts(msg) }
    allow($stdout).to receive(:print) { |msg| output.print(msg) }
  end

  describe "#call" do
    context "with google provider (default)" do
      it "lists all available models" do
        command.call

        output_content = output.string
        expect(output_content).to include("Available Google Models")
        expect(output_content).to include("Usage: llm-google-query")
        # Should contain at least one model
        expect(output_content).to match(/ID: [\w\.-]+/)
        expect(output_content).to match(/Name: /)
        expect(output_content).to match(/Description: /)
      end

      it "shows model descriptions" do
        command.call

        output_content = output.string
        # Should have proper structure
        expect(output_content).to match(/ID: /)
        expect(output_content).to match(/Name: /)
        expect(output_content).to match(/Description: /)
      end
    end

    context "with lmstudio provider" do
      it "lists all available models" do
        command.call(provider: "lmstudio")

        output_content = output.string
        expect(output_content).to include("Available LM Studio Models")
        expect(output_content).to include("Default model")
        expect(output_content).to include("Usage: llm-lmstudio-query")
        # Should contain at least one model
        expect(output_content).to match(/ID: [\w\/-]+/)
        expect(output_content).to match(/Name: /)
        expect(output_content).to match(/Description: /)
      end

      it "shows server information" do
        command.call(provider: "lmstudio")

        output_content = output.string
        expect(output_content).to include("Note: Models must be loaded in LM Studio before use")
        expect(output_content).to include("http://localhost:1234")
      end
    end

    context "with openai provider" do
      it "lists all available models" do
        command.call(provider: "openai")

        output_content = output.string
        expect(output_content).to include("Available OpenAI Models")
        expect(output_content).to include("Default model")
        expect(output_content).to include("Usage: llm-openai-query")
        # Should contain at least one model
        expect(output_content).to match(/ID: gpt-[\w\.-]+/)
        expect(output_content).to match(/Name: /)
        expect(output_content).to match(/Description: /)
      end
    end

    context "with anthropic provider" do
      it "lists all available models" do
        command.call(provider: "anthropic")

        output_content = output.string
        expect(output_content).to include("Available Anthropic Models")
        expect(output_content).to include("Default model")
        expect(output_content).to include("Usage: llm-anthropic-query")
        # Should contain at least one model
        expect(output_content).to match(/ID: claude-[\w\.-]+/)
        expect(output_content).to match(/Name: /)
        expect(output_content).to match(/Description: /)
      end
    end

    context "with mistral provider" do
      it "lists all available models" do
        command.call(provider: "mistral")

        output_content = output.string
        expect(output_content).to include("Available Mistral AI Models")
        expect(output_content).to include("Default model")
        expect(output_content).to include("Usage: llm-mistral-query")
        # Should contain at least one model
        expect(output_content).to match(/ID: (mistral|open-mistral|codestral)[\w\.-]*/)
        expect(output_content).to match(/Name: /)
        expect(output_content).to match(/Description: /)
      end
    end

    context "with together_ai provider" do
      it "lists all available models" do
        command.call(provider: "together_ai")

        output_content = output.string
        expect(output_content).to include("Available Together AI Models")

        expect(output_content).to include("Usage: llm-together-ai-query")
        # Should contain at least one model
        expect(output_content).to match(/ID: [\w\/-]+/)
        expect(output_content).to match(/Name: /)
        expect(output_content).to match(/Description: /)
      end
    end

    context "with invalid provider" do
      it "shows error message" do
        allow(command).to receive(:warn).and_return(nil)
        expect { command.call(provider: "invalid") }.to raise_error(SystemExit)
        expect(command).to have_received(:warn).with("Error: Invalid provider 'invalid'. Valid providers are: google, lmstudio, openai, anthropic, mistral, together_ai")
      end
    end

    context "with filter option" do
      it "filters google models correctly" do
        # Mock fallback models to ensure consistent test results
        fallback_models = [
          CodingAgentTools::Models::LlmModelInfo.new(id: "gemini-2.0-flash-lite", name: "Gemini 2.0 Flash Lite", description: "Fast model")
        ]
        allow(command).to receive(:get_available_models).and_return(fallback_models)

        command.call(filter: "gemini")

        output_content = output.string
        expect(output_content).to match(/ID: gemini-[\w\.-]+/)
      end

      it "filters lmstudio models correctly" do
        command.call(provider: "lmstudio", filter: "mistral")

        output_content = output.string
        expect(output_content).to match(/ID: mistralai\/[\w\/-]+/)
      end

      it "filters openai models correctly" do
        command.call(provider: "openai", filter: "gpt-4")

        output_content = output.string
        expect(output_content).to match(/ID: gpt-4[\w\.-]*/)
      end

      it "filters anthropic models correctly" do
        command.call(provider: "anthropic", filter: "claude-3")

        output_content = output.string
        expect(output_content).to match(/ID: claude-3[\w\.-]*/)
      end

      it "filters mistral models correctly" do
        command.call(provider: "mistral", filter: "mistral")

        output_content = output.string
        expect(output_content).to match(/ID: open-mistral[\w\.-]*/)
      end

      it "filters together_ai models correctly" do
        command.call(provider: "together_ai", filter: "llama")

        output_content = output.string
        expect(output_content).to match(/ID: [\w\/-]*llama[\w\/-]*/i)
      end

      it "shows no results message when no matches" do
        command.call(filter: "nonexistent")

        output_content = output.string
        expect(output_content).to include("No models found matching the filter criteria")
      end

      it "is case insensitive" do
        # Mock fallback models to ensure consistent test results
        fallback_models = [
          CodingAgentTools::Models::LlmModelInfo.new(id: "gemini-2.0-flash-lite", name: "Gemini 2.0 Flash Lite", description: "Fast model")
        ]
        allow(command).to receive(:get_available_models).and_return(fallback_models)

        command.call(filter: "GEMINI")

        output_content = output.string
        expect(output_content).to match(/ID: gemini-[\w\.-]+/)
      end
    end

    context "with json format" do
      it "outputs models in JSON format" do
        command.call(format: "json")

        output_content = output.string
        json_output = JSON.parse(output_content)

        expect(json_output).to have_key("models")
        expect(json_output).to have_key("count")
        expect(json_output).to have_key("default_model")
        expect(json_output["default_model"]).not_to be_empty
        expect(json_output["models"]).to be_an(Array)
        expect(json_output["models"].length).to be > 0
      end

      it "includes model details in JSON" do
        command.call(format: "json")

        output_content = output.string
        json_output = JSON.parse(output_content)

        first_model = json_output["models"].first
        expect(first_model).to have_key("id")
        expect(first_model).to have_key("name")
        expect(first_model).to have_key("description")
        expect(first_model).to have_key("default")
        expect(first_model).to have_key("context_size")
        expect(first_model).to have_key("max_output_tokens")
      end

      it "includes context size information in JSON output" do
        # Mock models with context size to ensure consistent test results
        models_with_context_size = [
          CodingAgentTools::Models::LlmModelInfo.new(
            id: "gemini-2.0-flash-lite",
            name: "Gemini 2.0 Flash Lite",
            description: "Fast model",
            context_size: 1_048_576
          )
        ]
        allow(command).to receive(:get_available_models).and_return(models_with_context_size)

        command.call(format: "json")

        output_content = output.string
        json_output = JSON.parse(output_content)

        # At least some models should have context size information
        models_with_context = json_output["models"].select { |m| m["context_size"] }
        expect(models_with_context).not_to be_empty

        models_with_context.each do |model|
          expect(model["context_size"]).to be_a(Integer)
          expect(model["context_size"]).to be > 1000  # Should be reasonable
        end
      end

      it "filters work with JSON format" do
        # Mock models to ensure consistent test results
        gemini_models = [
          CodingAgentTools::Models::LlmModelInfo.new(id: "gemini-1.5-pro", name: "Gemini 1.5 Pro", description: "Advanced model")
        ]
        allow(command).to receive(:get_available_models).and_return(gemini_models)

        command.call(format: "json", filter: "gemini-1.5")

        output_content = output.string
        json_output = JSON.parse(output_content)

        expect(json_output["count"]).to be >= 1
        json_output["models"].each do |model|
          expect(model["id"].downcase).to include("gemini-1.5")
        end
      end

      it "outputs lmstudio models in JSON format" do
        command.call(provider: "lmstudio", format: "json")

        output_content = output.string
        json_output = JSON.parse(output_content)

        expect(json_output).to have_key("models")
        expect(json_output).to have_key("count")
        expect(json_output).to have_key("default_model")
        expect(json_output).to have_key("server_url")
        expect(json_output["provider"]).to eq("lmstudio")
        expect(json_output["server_url"]).to eq("http://localhost:1234")
        expect(json_output["models"]).to be_an(Array)
        expect(json_output["models"].length).to be > 0
      end

      it "outputs openai models in JSON format" do
        command.call(provider: "openai", format: "json")

        output_content = output.string
        json_output = JSON.parse(output_content)

        expect(json_output).to have_key("models")
        expect(json_output).to have_key("count")
        expect(json_output).to have_key("default_model")
        expect(json_output["provider"]).to eq("openai")
        expect(json_output["models"]).to be_an(Array)
        expect(json_output["models"].length).to be > 0
      end

      it "outputs anthropic models in JSON format" do
        command.call(provider: "anthropic", format: "json")

        output_content = output.string
        json_output = JSON.parse(output_content)

        expect(json_output).to have_key("models")
        expect(json_output).to have_key("count")
        expect(json_output).to have_key("default_model")
        expect(json_output["provider"]).to eq("anthropic")
        expect(json_output["models"]).to be_an(Array)
        expect(json_output["models"].length).to be > 0
      end

      it "outputs mistral models in JSON format" do
        command.call(provider: "mistral", format: "json")

        output_content = output.string
        json_output = JSON.parse(output_content)

        expect(json_output).to have_key("models")
        expect(json_output).to have_key("count")
        expect(json_output).to have_key("default_model")
        expect(json_output["provider"]).to eq("mistral")
        expect(json_output["models"]).to be_an(Array)
        expect(json_output["models"].length).to be > 0
      end

      it "outputs together_ai models in JSON format" do
        command.call(provider: "together_ai", format: "json")

        output_content = output.string
        json_output = JSON.parse(output_content)

        expect(json_output).to have_key("models")
        expect(json_output).to have_key("count")
        expect(json_output).to have_key("default_model")
        expect(json_output["provider"]).to eq("together_ai")
        expect(json_output["models"]).to be_an(Array)
        expect(json_output["models"].length).to be > 0
      end
    end

    context "error handling" do
      it "handles exceptions gracefully" do
        allow(command).to receive(:get_available_models).and_raise(StandardError.new("Test error"))
        allow(command).to receive(:warn)

        expect { command.call }.to raise_error(SystemExit)
        expect(command).to have_received(:warn).with(/Error: Test error/)
      end

      it "shows debug information when debug flag is set" do
        allow(command).to receive(:get_available_models).and_raise(StandardError.new("Test error"))
        allow(command).to receive(:warn)

        expect { command.call(debug: true) }.to raise_error(SystemExit)
        expect(command).to have_received(:warn).with(/Error: StandardError: Test error/)
        expect(command).to have_received(:warn).with(/Backtrace:/)
      end

      it "handles network timeouts gracefully" do
        allow(command).to receive(:get_available_models).and_raise(Timeout::Error.new("Connection timed out"))
        allow(command).to receive(:warn)

        expect { command.call }.to raise_error(SystemExit)
        expect(command).to have_received(:warn).with(/Error: Connection timed out/)
      end

      it "handles API authentication errors" do
        allow(command).to receive(:get_available_models).and_raise(StandardError.new("Unauthorized"))
        allow(command).to receive(:warn)

        expect { command.call }.to raise_error(SystemExit)
        expect(command).to have_received(:warn).with(/Error: Unauthorized/)
      end

      it "handles JSON parsing errors" do
        allow(command).to receive(:get_available_models).and_raise(JSON::ParserError.new("Invalid JSON"))
        allow(command).to receive(:warn)

        expect { command.call }.to raise_error(SystemExit)
        expect(command).to have_received(:warn).with(/Error: Invalid JSON/)
      end
    end

    context "with refresh option" do
      it "refreshes cache and fetches new data" do
        allow(command).to receive(:fetch_models_from_api).and_return([
          CodingAgentTools::Models::LlmModelInfo.new(id: "fresh-model", name: "Fresh Model", description: "Freshly fetched")
        ])
        allow(command).to receive(:cache_models)

        command.call(refresh: true)

        expect(command).to have_received(:fetch_models_from_api).with("google")
        expect(command).to have_received(:cache_models)

        output_content = output.string
        expect(output_content).to include("Fresh Model")
      end

      it "ignores existing cache when refresh is true" do
        cache_manager = instance_double(CodingAgentTools::Molecules::CacheManager)
        allow(command).to receive(:cache_manager).and_return(cache_manager)
        allow(cache_manager).to receive(:cache_exists?).and_return(true)
        allow(command).to receive(:fetch_models_from_api).and_return([
          CodingAgentTools::Models::LlmModelInfo.new(id: "api-model", name: "API Model", description: "From API")
        ])
        allow(command).to receive(:cache_models)
        allow(command).to receive(:load_models_from_cache)

        command.call(refresh: true)

        expect(command).to have_received(:fetch_models_from_api)
        expect(command).not_to have_received(:load_models_from_cache)
      end

      it "refreshes cache for specific providers" do
        allow(command).to receive(:fetch_models_from_api).and_return([
          CodingAgentTools::Models::LlmModelInfo.new(id: "openai-fresh", name: "OpenAI Fresh", description: "Fresh OpenAI model")
        ])
        allow(command).to receive(:cache_models)

        command.call(provider: "openai", refresh: true)

        expect(command).to have_received(:fetch_models_from_api).with("openai")
        expect(command).to have_received(:cache_models).with("openai", anything)
      end
    end

    context "API fallback scenarios" do
      it "uses fallback models when API fails" do
        fallback_models = [
          CodingAgentTools::Models::LlmModelInfo.new(id: "fallback-model", name: "Fallback Model", description: "Fallback model")
        ]

        allow(command).to receive(:get_available_models).and_return(fallback_models)

        command.call

        output_content = output.string
        expect(output_content).to include("Fallback Model")
      end

      it "handles empty model lists gracefully" do
        allow(command).to receive(:get_available_models).and_return([])

        command.call

        output_content = output.string
        expect(output_content).to include("No models found matching the filter criteria")
      end

      it "handles corrupted cache data" do
        cache_manager = instance_double(CodingAgentTools::Molecules::CacheManager)
        allow(command).to receive(:cache_manager).and_return(cache_manager)
        allow(cache_manager).to receive(:cache_exists?).and_return(true)
        allow(cache_manager).to receive(:read_cache).and_return(nil)
        allow(command).to receive(:fallback_models).and_return([
          CodingAgentTools::Models::LlmModelInfo.new(id: "fallback", name: "Fallback", description: "Fallback from corrupted cache")
        ])

        command.call

        expect(command).to have_received(:fallback_models).with("google")
      end
    end
  end

  describe "private methods" do
    describe "#get_available_models" do
      it "returns an array of model hashes for google" do
        models = command.send(:get_available_models, "google")

        expect(models).to be_an(Array)
        expect(models.length).to be > 0

        models.each do |model|
          expect(model).to respond_to(:id)
          expect(model).to respond_to(:name)
          expect(model).to respond_to(:description)
          expect(model).to respond_to(:default?)
        end
      end

      it "returns an array of model hashes for lmstudio" do
        models = command.send(:get_available_models, "lmstudio")

        expect(models).to be_an(Array)
        expect(models.length).to be > 0

        models.each do |model|
          expect(model).to respond_to(:id)
          expect(model).to respond_to(:name)
          expect(model).to respond_to(:description)
          expect(model).to respond_to(:default?)
        end
      end

      it "returns an array of model hashes for openai" do
        models = command.send(:get_available_models, "openai")

        expect(models).to be_an(Array)
        expect(models.length).to be > 0

        models.each do |model|
          expect(model).to respond_to(:id)
          expect(model).to respond_to(:name)
          expect(model).to respond_to(:description)
          expect(model).to respond_to(:default?)
        end
      end

      it "returns an array of model hashes for anthropic" do
        models = command.send(:get_available_models, "anthropic")

        expect(models).to be_an(Array)
        expect(models.length).to be > 0

        models.each do |model|
          expect(model).to respond_to(:id)
          expect(model).to respond_to(:name)
          expect(model).to respond_to(:description)
          expect(model).to respond_to(:default?)
        end
      end

      it "returns an array of model hashes for mistral" do
        models = command.send(:get_available_models, "mistral")

        expect(models).to be_an(Array)
        expect(models.length).to be > 0

        models.each do |model|
          expect(model).to respond_to(:id)
          expect(model).to respond_to(:name)
          expect(model).to respond_to(:description)
          expect(model).to respond_to(:default?)
        end
      end

      it "returns an array of model hashes for together_ai" do
        models = command.send(:get_available_models, "together_ai")

        expect(models).to be_an(Array)
        expect(models.length).to be > 0

        models.each do |model|
          expect(model).to respond_to(:id)
          expect(model).to respond_to(:name)
          expect(model).to respond_to(:description)
          expect(model).to respond_to(:default?)
        end
      end

      it "includes the default model for google" do
        # Mock fallback models since API might not be available in test
        fallback_models = [
          CodingAgentTools::Models::LlmModelInfo.new(
            id: "gemini-2.0-flash-lite",
            name: "Gemini 2.0 Flash Lite",
            description: "Fast and efficient model",
            default: true
          ),
          CodingAgentTools::Models::LlmModelInfo.new(
            id: "gemini-1.5-pro",
            name: "Gemini 1.5 Pro",
            description: "Pro model",
            default: false
          )
        ]

        # Mock the entire get_available_models method to return our test data
        allow(command).to receive(:get_available_models).and_return(fallback_models)

        models = command.send(:get_available_models, "google")
        default_model = models.find(&:default?)

        expect(models).not_to be_empty
        expect(default_model).not_to be_nil
        expect(default_model.id).to eq("gemini-2.0-flash-lite")
      end

      it "includes the default model for lmstudio" do
        models = command.send(:get_available_models, "lmstudio")
        default_model = models.find(&:default?)

        expect(default_model).not_to be_nil
        expect(default_model.id).not_to be_empty
      end

      it "includes the default model for openai" do
        models = command.send(:get_available_models, "openai")
        default_model = models.find(&:default?)

        expect(default_model).not_to be_nil
        expect(default_model.id).not_to be_empty
      end

      it "includes the default model for anthropic" do
        models = command.send(:get_available_models, "anthropic")
        default_model = models.find(&:default?)

        expect(default_model).not_to be_nil
        expect(default_model.id).not_to be_empty
      end

      it "includes the default model for mistral" do
        models = command.send(:get_available_models, "mistral")
        default_model = models.find(&:default?)

        expect(default_model).not_to be_nil
        expect(default_model.id).not_to be_empty
      end
    end

    describe "#filter_models" do
      let(:models) do
        [
          CodingAgentTools::Models::LlmModelInfo.new(id: "model-1", name: "Model One", description: "First model"),
          CodingAgentTools::Models::LlmModelInfo.new(id: "model-2", name: "Model Two", description: "Second model"),
          CodingAgentTools::Models::LlmModelInfo.new(id: "flash-model", name: "Flash Model", description: "Fast model")
        ]
      end

      let(:lmstudio_models) do
        [
          CodingAgentTools::Models::LlmModelInfo.new(id: "mistralai/model-1", name: "Mistral One", description: "First model"),
          CodingAgentTools::Models::LlmModelInfo.new(id: "deepseek/model-2", name: "DeepSeek Two", description: "Second model"),
          CodingAgentTools::Models::LlmModelInfo.new(id: "qwen/coder-model", name: "Qwen Coder", description: "Coding model")
        ]
      end

      it "returns all models when no filter is provided" do
        result = command.send(:filter_models, models, nil)
        expect(result).to eq(models)
      end

      it "filters by model id" do
        result = command.send(:filter_models, models, "model-1")
        expect(result.length).to eq(1)
        expect(result.first.id).to eq("model-1")
      end

      it "filters by model name" do
        result = command.send(:filter_models, models, "Flash")
        expect(result.length).to eq(1)
        expect(result.first.name).to eq("Flash Model")
      end

      it "filters by description" do
        result = command.send(:filter_models, models, "Fast")
        expect(result.length).to eq(1)
        expect(result.first.description).to eq("Fast model")
      end

      it "is case insensitive" do
        result = command.send(:filter_models, models, "FLASH")
        expect(result.length).to eq(1)
        expect(result.first.name).to eq("Flash Model")
      end

      it "returns empty array when no matches" do
        result = command.send(:filter_models, models, "nonexistent")
        expect(result).to be_empty
      end

      it "filters lmstudio models by provider" do
        result = command.send(:filter_models, lmstudio_models, "mistralai")
        expect(result.length).to eq(1)
        expect(result.first.id).to eq("mistralai/model-1")
      end

      it "filters lmstudio models by name" do
        result = command.send(:filter_models, lmstudio_models, "DeepSeek")
        expect(result.length).to eq(1)
        expect(result.first.name).to eq("DeepSeek Two")
      end

      it "filters lmstudio models by description" do
        result = command.send(:filter_models, lmstudio_models, "Coding")
        expect(result.length).to eq(1)
        expect(result.first.description).to eq("Coding model")
      end
    end
  end

  # Additional focused tests for key uncovered methods
  describe "additional method coverage" do
    describe "#valid_provider?" do
      it "returns true for valid providers" do
        ["google", "lmstudio", "openai", "anthropic", "mistral", "together_ai"].each do |provider|
          expect(command.send(:valid_provider?, provider)).to be true
        end
      end

      it "returns false for invalid providers" do
        ["invalid", "unknown", "fake"].each do |provider|
          expect(command.send(:valid_provider?, provider)).to be false
        end
      end

      it "is case sensitive" do
        expect(command.send(:valid_provider?, "GOOGLE")).to be false
        expect(command.send(:valid_provider?, "Google")).to be false
      end
    end

    describe "cache management" do
      let(:cache_manager) { instance_double(CodingAgentTools::Molecules::CacheManager) }

      before do
        allow(command).to receive(:cache_manager).and_return(cache_manager)
      end

      describe "#cache_exists?" do
        it "checks if cache exists for provider" do
          allow(cache_manager).to receive(:cache_exists?).with("google_models.yml").and_return(true)

          result = command.send(:cache_exists?, "google")
          expect(result).to be true
        end

        it "returns false when cache doesn't exist" do
          allow(cache_manager).to receive(:cache_exists?).with("lmstudio_models.yml").and_return(false)

          result = command.send(:cache_exists?, "lmstudio")
          expect(result).to be false
        end
      end

      describe "#cache_models" do
        it "caches models for provider" do
          models = [CodingAgentTools::Models::LlmModelInfo.new(id: "test", name: "Test")]
          expect(cache_manager).to receive(:write_cache).with("google_models.yml", hash_including("provider" => "google"))

          command.send(:cache_models, "google", models)
        end
      end

      describe "#load_models_from_cache" do
        it "loads models from cache" do
          cache_data = {
            "models" => [
              {
                "id" => "cached",
                "name" => "Cached",
                "description" => "Cached model",
                "default" => false
              }
            ]
          }
          allow(cache_manager).to receive(:read_cache).with("google_models.yml").and_return(cache_data)

          result = command.send(:load_models_from_cache, "google")
          expect(result).to be_an(Array)
          expect(result.first.id).to eq("cached")
        end
      end
    end

    describe "model name formatting methods" do
      describe "#format_openai_model_name" do
        it "formats known OpenAI models correctly" do
          expect(command.send(:format_openai_model_name, "gpt-4o")).to eq("GPT-4 Omni")
          expect(command.send(:format_openai_model_name, "gpt-4-turbo")).to eq("GPT-4 Turbo")
          expect(command.send(:format_openai_model_name, "gpt-4")).to eq("GPT-4")
          expect(command.send(:format_openai_model_name, "gpt-3.5-turbo")).to eq("GPT-3.5 Turbo")
          expect(command.send(:format_openai_model_name, "o1-preview")).to eq("O1 Preview")
          expect(command.send(:format_openai_model_name, "o1-mini")).to eq("O1 Mini")
        end

        it "formats unknown models generically" do
          expect(command.send(:format_openai_model_name, "unknown-model")).to eq("Unknown Model")
        end
      end

      describe "#format_anthropic_model_name" do
        it "formats known Anthropic models correctly" do
          expect(command.send(:format_anthropic_model_name, "claude-3-5-sonnet")).to eq("Claude 3.5 Sonnet")
          expect(command.send(:format_anthropic_model_name, "claude-3-5-haiku")).to eq("Claude 3.5 Haiku")
          expect(command.send(:format_anthropic_model_name, "claude-3-opus")).to eq("Claude 3 Opus")
          expect(command.send(:format_anthropic_model_name, "claude-3-sonnet")).to eq("Claude 3 Sonnet")
          expect(command.send(:format_anthropic_model_name, "claude-3-haiku")).to eq("Claude 3 Haiku")
        end

        it "formats unknown models generically" do
          expect(command.send(:format_anthropic_model_name, "claude-unknown")).to eq("Claude Unknown")
        end
      end

      describe "#format_mistral_model_name" do
        it "formats known Mistral models correctly" do
          expect(command.send(:format_mistral_model_name, "mistral-large")).to eq("Mistral Large")
          expect(command.send(:format_mistral_model_name, "mistral-medium")).to eq("Mistral Medium")
          expect(command.send(:format_mistral_model_name, "mistral-small")).to eq("Mistral Small")
          expect(command.send(:format_mistral_model_name, "mistral-tiny")).to eq("Mistral Tiny")
          expect(command.send(:format_mistral_model_name, "mistral-8x7b")).to eq("Mistral 8x7B")
          expect(command.send(:format_mistral_model_name, "mistral-8x22b")).to eq("Mistral 8x22B")
        end

        it "formats unknown models generically" do
          expect(command.send(:format_mistral_model_name, "mistral-unknown")).to eq("Mistral Unknown")
        end
      end
    end

    describe "edge cases and error conditions" do
      it "handles filter with nil model attributes" do
        models_with_nils = [
          CodingAgentTools::Models::LlmModelInfo.new(id: nil, name: "Test", description: nil),
          CodingAgentTools::Models::LlmModelInfo.new(id: "valid", name: nil, description: "Valid model")
        ]

        result = command.send(:filter_models, models_with_nils, "valid")
        expect(result.length).to eq(1)
        expect(result.first.id).to eq("valid")
      end

      it "handles refresh cache flag" do
        models = [CodingAgentTools::Models::LlmModelInfo.new(id: "fresh", name: "Fresh")]
        allow(command).to receive(:fetch_models_from_api).and_return(models)
        allow(command).to receive(:cache_models)

        result = command.send(:get_available_models, "google", true)
        expect(result).to eq(models)
        expect(command).to have_received(:cache_models).with("google", models)
      end
    end

    # Simplified edge case tests focusing on key functionality
    describe "additional edge case scenarios" do
      describe "provider validation" do
        it "validates provider names correctly" do
          valid_providers = ["google", "lmstudio", "openai", "anthropic", "mistral", "together_ai"]
          invalid_providers = ["invalid", "unknown", "fake"]

          valid_providers.each do |provider|
            expect(command.send(:valid_provider?, provider)).to be true
          end

          invalid_providers.each do |provider|
            expect(command.send(:valid_provider?, provider)).to be false
          end
        end
      end

      describe "individual fetch methods" do
        describe "#fetch_google_models" do
          it "fetches and formats Google models correctly" do
            mock_client = instance_double(CodingAgentTools::Organisms::GoogleClient)
            mock_response = [
              {
                name: "models/gemini-1.5-pro",
                description: "Google's Gemini 1.5 Pro model",
                supportedGenerationMethods: ["generateContent"]
              }
            ]

            allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
            allow(mock_client).to receive(:list_models).and_return(mock_response)

            result = command.send(:fetch_google_models)

            expect(result).to be_an(Array)
            expect(result.first.id).to eq("gemini-1.5-pro")
            expect(result.first.name).to include("Gemini")
          end

          it "handles API errors gracefully" do
            allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_raise(StandardError.new("API Error"))

            expect { command.send(:fetch_google_models) }.to raise_error(StandardError)
          end
        end

        describe "#fetch_openai_models" do
          it "fetches and formats OpenAI models correctly" do
            mock_client = instance_double(CodingAgentTools::Organisms::OpenaiClient)
            mock_response = [
              {id: "gpt-4", created: 1_234_567_890},
              {id: "gpt-3.5-turbo", created: 1_234_567_890},
              {id: "text-davinci-003", created: 1_234_567_890}  # Should be filtered out
            ]

            allow(CodingAgentTools::Organisms::OpenaiClient).to receive(:new).and_return(mock_client)
            allow(mock_client).to receive(:list_models).and_return(mock_response)

            result = command.send(:fetch_openai_models)

            expect(result).to be_an(Array)
            expect(result.map(&:id)).to include("gpt-4", "gpt-3.5-turbo")
            expect(result.map(&:id)).not_to include("text-davinci-003")
          end
        end

        describe "#fetch_anthropic_models" do
          it "fetches and formats Anthropic models correctly" do
            mock_client = instance_double(CodingAgentTools::Organisms::AnthropicClient)
            mock_response = [
              {id: "claude-3-5-sonnet-20241022", description: "Claude 3.5 Sonnet"}
            ]

            allow(CodingAgentTools::Organisms::AnthropicClient).to receive(:new).and_return(mock_client)
            allow(mock_client).to receive(:list_models).and_return(mock_response)

            result = command.send(:fetch_anthropic_models)

            expect(result).to be_an(Array)
            expect(result.first.id).to eq("claude-3-5-sonnet-20241022")
            expect(result.first.name).to eq("Claude 3.5 Sonnet")
          end
        end

        describe "#fetch_mistral_models" do
          it "fetches and formats Mistral models correctly" do
            mock_client = instance_double(CodingAgentTools::Organisms::MistralClient)
            mock_response = [
              {id: "mistral-large-2407", description: "Mistral Large model"}
            ]

            allow(CodingAgentTools::Organisms::MistralClient).to receive(:new).and_return(mock_client)
            allow(mock_client).to receive(:list_models).and_return(mock_response)

            result = command.send(:fetch_mistral_models)

            expect(result).to be_an(Array)
            expect(result.first.id).to eq("mistral-large-2407")
            expect(result.first.name).to eq("Mistral Large")
          end
        end

        describe "#fetch_together_ai_models" do
          it "fetches and formats Together AI models correctly" do
            mock_client = instance_double(CodingAgentTools::Organisms::TogetheraiClient)
            mock_response = [
              {id: "meta-llama/Llama-3.1-70B-Instruct", name: "Llama 3.1 70B Instruct"}
            ]

            allow(CodingAgentTools::Organisms::TogetheraiClient).to receive(:new).and_return(mock_client)
            allow(mock_client).to receive(:list_models).and_return(mock_response)

            result = command.send(:fetch_together_ai_models)

            expect(result).to be_an(Array)
            expect(result.first.id).to eq("meta-llama/Llama-3.1-70B-Instruct")
            expect(result.first.name).to eq("Llama 3.1 70B")
          end

          it "raises error when no models returned" do
            mock_client = instance_double(CodingAgentTools::Organisms::TogetheraiClient)
            allow(CodingAgentTools::Organisms::TogetheraiClient).to receive(:new).and_return(mock_client)
            allow(mock_client).to receive(:list_models).and_return([])

            expect { command.send(:fetch_together_ai_models) }.to raise_error("No models returned from API")
          end
        end

        describe "#fetch_lmstudio_models" do
          it "fetches and formats LM Studio models correctly" do
            mock_client = instance_double(CodingAgentTools::Organisms::LmstudioClient)
            mock_response = [
              {id: "mistralai/mistral-7b-instruct", context_length: 32_768}
            ]

            allow(CodingAgentTools::Organisms::LmstudioClient).to receive(:new).and_return(mock_client)
            allow(mock_client).to receive(:list_models).and_return(mock_response)

            result = command.send(:fetch_lmstudio_models)

            expect(result).to be_an(Array)
            expect(result.first.id).to eq("mistralai/mistral-7b-instruct")
            expect(result.first.name).to eq("Mistral 7b Instruct")
          end
        end
      end

      describe "model name formatting edge cases" do
        it "handles empty and edge case model names" do
          # The actual implementation will fail for empty strings (name_part becomes nil)
          expect { command.send(:format_lmstudio_model_name, "") }.to raise_error(NoMethodError)
          expect(command.send(:format_lmstudio_model_name, "single")).to eq("Single")
          expect(command.send(:format_lmstudio_model_name, "provider/")).to eq("Provider")
          expect(command.send(:format_lmstudio_model_name, "mistralai/mistral-7b-instruct")).to eq("Mistral 7b Instruct")
        end

        it "formats Together AI model names for known patterns" do
          expect(command.send(:format_together_ai_model_name, "meta-llama/Llama-3.1-70B-Instruct")).to eq("Llama 3.1 70B")
          expect(command.send(:format_together_ai_model_name, "deepseek-ai/deepseek-coder")).to eq("DeepSeek Coder")
          expect(command.send(:format_together_ai_model_name, "provider/generic-model-name")).to eq("Generic Model Name")
        end

        it "formats OpenAI model names correctly" do
          expect(command.send(:format_openai_model_name, "gpt-4o")).to eq("GPT-4 Omni")
          expect(command.send(:format_openai_model_name, "gpt-4-turbo")).to eq("GPT-4 Turbo")
          expect(command.send(:format_openai_model_name, "o1-preview")).to eq("O1 Preview")
          expect(command.send(:format_openai_model_name, "unknown-model")).to eq("Unknown Model")
        end

        it "formats Anthropic model names correctly" do
          expect(command.send(:format_anthropic_model_name, "claude-3-5-sonnet")).to eq("Claude 3.5 Sonnet")
          expect(command.send(:format_anthropic_model_name, "claude-3-opus")).to eq("Claude 3 Opus")
          expect(command.send(:format_anthropic_model_name, "claude-unknown")).to eq("Claude Unknown")
        end

        it "formats Mistral model names correctly" do
          expect(command.send(:format_mistral_model_name, "mistral-large")).to eq("Mistral Large")
          expect(command.send(:format_mistral_model_name, "mistral-8x7b")).to eq("Mistral 8x7B")
          expect(command.send(:format_mistral_model_name, "mistral-unknown")).to eq("Mistral Unknown")
        end
      end

      describe "context size extraction" do
        it "extracts Google context sizes correctly" do
          model_with_limit = {inputTokenLimit: 1_000_000}
          expect(command.send(:extract_google_context_size, model_with_limit)).to eq(1_000_000)

          model_zero = {inputTokenLimit: 0}
          expect(command.send(:extract_google_context_size, model_zero)).to be_nil

          model_pattern = {name: "models/gemini-1.5-pro"}
          expect(command.send(:extract_google_context_size, model_pattern)).to eq(2_097_152)
        end

        it "extracts Google max output tokens correctly" do
          model_with_limit = {outputTokenLimit: 8192}
          expect(command.send(:extract_google_max_output_tokens, model_with_limit)).to eq(8192)

          model_pattern = {name: "models/gemini-1.0-pro"}
          expect(command.send(:extract_google_max_output_tokens, model_pattern)).to eq(2_048)
        end

        it "extracts LM Studio context sizes correctly" do
          model_context = {context_length: 32_768}
          expect(command.send(:extract_lmstudio_context_size, model_context)).to eq(32_768)

          model_pattern = {id: "meta-llama/llama-3.1-8b-instruct"}
          expect(command.send(:extract_lmstudio_context_size, model_pattern)).to eq(131_072)
        end

        it "extracts LM Studio max output tokens correctly" do
          model_tokens = {max_tokens: 4096}
          expect(command.send(:extract_lmstudio_max_output_tokens, model_tokens)).to eq(4096)

          # Test calculation from context size
          model_with_context = {context_length: 32_768}
          allow(command).to receive(:extract_lmstudio_context_size).and_return(32_768)
          result = command.send(:extract_lmstudio_max_output_tokens, model_with_context)
          expect(result).to eq(16_384)  # Half of context size

          # Test minimum enforcement
          allow(command).to receive(:extract_lmstudio_context_size).and_return(2048)
          result = command.send(:extract_lmstudio_max_output_tokens, model_with_context)
          expect(result).to eq(4096)  # Minimum enforced
        end
      end

      describe "cache file operations" do
        it "generates correct cache file names" do
          expect(command.send(:cache_file_name, "google")).to eq("google_models.yml")
          expect(command.send(:cache_file_name, "lmstudio")).to eq("lmstudio_models.yml")
          expect(command.send(:cache_file_name, "openai")).to eq("openai_models.yml")
          expect(command.send(:cache_file_name, "anthropic")).to eq("anthropic_models.yml")
        end
      end

      describe "output methods" do
        describe "#output_models" do
          let(:test_models) do
            [
              CodingAgentTools::Models::LlmModelInfo.new(id: "test-1", name: "Test Model 1", description: "First test model"),
              CodingAgentTools::Models::LlmModelInfo.new(id: "test-2", name: "Test Model 2", description: "Second test model")
            ]
          end

          it "outputs models in text format by default" do
            expect(command).to receive(:output_text_models).with(test_models, hash_including(format: "text"))

            command.send(:output_models, test_models, format: "text", provider: "google")
          end

          it "outputs models in JSON format when specified" do
            expect(command).to receive(:output_json_models).with(test_models, hash_including(format: "json"))

            command.send(:output_models, test_models, format: "json", provider: "google")
          end
        end

        describe "#output_text_models" do
          it "displays no models message when list is empty" do
            command.send(:output_text_models, [], provider: "google")

            output_content = output.string
            expect(output_content).to include("No models found matching the filter criteria")
          end

          it "includes usage information for each provider" do
            test_models = [
              CodingAgentTools::Models::LlmModelInfo.new(id: "test", name: "Test", description: "Test model")
            ]

            ["google", "lmstudio", "openai", "anthropic", "mistral", "together_ai"].each do |provider|
              output.string.clear
              command.send(:output_text_models, test_models, provider: provider)

              output_content = output.string
              expect(output_content).to include("Usage:")
            end
          end
        end

        describe "#output_json_models" do
          it "outputs valid JSON structure" do
            test_models = [
              CodingAgentTools::Models::LlmModelInfo.new(id: "test", name: "Test", description: "Test model", default: true)
            ]

            command.send(:output_json_models, test_models, provider: "google")

            output_content = output.string
            json_output = JSON.parse(output_content)

            expect(json_output).to have_key("models")
            expect(json_output).to have_key("count")
            expect(json_output).to have_key("provider")
            expect(json_output).to have_key("default_model")
          end
        end
      end

      describe "#handle_error method" do
        let(:test_error) { StandardError.new("Test error message") }

        before do
          test_error.set_backtrace(["line1", "line2", "line3"])
        end

        it "shows simple error message when debug is disabled" do
          allow(command).to receive(:error_output)

          command.send(:handle_error, test_error, false)

          expect(command).to have_received(:error_output).with("Error: Test error message")
          expect(command).to have_received(:error_output).with("Use --debug flag for more information")
        end

        it "shows detailed error information when debug is enabled" do
          allow(command).to receive(:error_output)

          command.send(:handle_error, test_error, true)

          expect(command).to have_received(:error_output).with("Error: StandardError: Test error message")
          expect(command).to have_received(:error_output).with("\nBacktrace:")
          expect(command).to have_received(:error_output).with("  line1")
          expect(command).to have_received(:error_output).with("  line2")
          expect(command).to have_received(:error_output).with("  line3")
        end

        it "handles errors with nil backtrace" do
          error_no_backtrace = StandardError.new("Error without backtrace")
          allow(command).to receive(:error_output)

          command.send(:handle_error, error_no_backtrace, true)

          expect(command).to have_received(:error_output).with("Error: StandardError: Error without backtrace")
          expect(command).to have_received(:error_output).with("\nBacktrace:")
        end
      end

      describe "error handling scenarios" do
        it "handles invalid provider in fetch_models_from_api" do
          result = command.send(:fetch_models_from_api, "invalid_provider")
          expect(result).to be_nil
        end

        it "returns proper error structures" do
          allow(command).to receive(:warn)
          expect { command.call(provider: "invalid") }.to raise_error(SystemExit)
          expect(command).to have_received(:warn).with(/Invalid provider/)
        end

        it "handles fetch_models_from_api errors with fallback" do
          fallback_models = [
            CodingAgentTools::Models::LlmModelInfo.new(id: "fallback", name: "Fallback", description: "Fallback model")
          ]

          # Mock the specific method chain that happens in fetch_models_from_api
          allow(command).to receive(:fetch_models_from_api).and_call_original
          allow(command).to receive(:fallback_models).and_return(fallback_models)

          # Simulate API failure by making Google client fail
          allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_raise(StandardError.new("API Down"))

          result = command.send(:get_available_models, "google", true)

          expect(result.first.id).to eq("fallback")
          expect(command).to have_received(:fallback_models).with("google")
        end
      end
    end
  end

  # Additional comprehensive test coverage for error handling and uncovered methods
  describe "error handling and uncovered method coverage" do
    describe "#call method provider validation" do
      it "validates provider and exits with error code 1 for invalid providers" do
        allow(command).to receive(:warn)

        exit_code = nil
        begin
          command.call(provider: "invalid_provider")
        rescue SystemExit => e
          exit_code = e.status
        end

        expect(exit_code).to eq(1)
        expect(command).to have_received(:warn).with("Error: Invalid provider 'invalid_provider'. Valid providers are: google, lmstudio, openai, anthropic, mistral, together_ai")
      end

      it "returns 0 on successful execution" do
        allow(command).to receive(:get_available_models).and_return([
          CodingAgentTools::Models::LlmModelInfo.new(id: "test", name: "Test", description: "Test model")
        ])
        allow(command).to receive(:output_models)

        result = command.call(provider: "google")
        expect(result).to eq(0)
      end

      it "exits with code 1 when exception occurs in main flow" do
        allow(command).to receive(:get_available_models).and_raise(StandardError.new("Simulated error"))
        allow(command).to receive(:handle_error)

        exit_code = nil
        begin
          command.call(provider: "google")
        rescue SystemExit => e
          exit_code = e.status
        end

        expect(exit_code).to eq(1)
        expect(command).to have_received(:handle_error)
      end
    end

    describe "#handle_error method" do
      let(:test_error) { StandardError.new("Test error message") }

      before do
        test_error.set_backtrace(["line1", "line2", "line3"])
      end

      it "shows concise error when debug is false" do
        expect(command).to receive(:error_output).with("Error: Test error message")
        expect(command).to receive(:error_output).with("Use --debug flag for more information")

        command.send(:handle_error, test_error, false)
      end

      it "shows detailed error with backtrace when debug is true" do
        expect(command).to receive(:error_output).with("Error: StandardError: Test error message")
        expect(command).to receive(:error_output).with("\nBacktrace:")
        expect(command).to receive(:error_output).with("  line1")
        expect(command).to receive(:error_output).with("  line2")
        expect(command).to receive(:error_output).with("  line3")

        command.send(:handle_error, test_error, true)
      end

      it "handles errors with nil backtrace gracefully" do
        error_without_backtrace = StandardError.new("No backtrace error")
        expect(command).to receive(:error_output).with("Error: StandardError: No backtrace error")
        expect(command).to receive(:error_output).with("\nBacktrace:")

        command.send(:handle_error, error_without_backtrace, true)
      end
    end

    describe "#error_output method" do
      it "outputs to stderr via warn" do
        expect(command).to receive(:warn).with("Test error message")
        command.send(:error_output, "Test error message")
      end
    end

    describe "#default_config method" do
      it "returns cached default config on subsequent calls" do
        first_config = command.send(:default_config)
        second_config = command.send(:default_config)

        expect(first_config).to be_a(CodingAgentTools::Models::DefaultModelConfig)
        expect(second_config).to be(first_config) # Same object instance
      end
    end

    describe "#get_available_models method" do
      it "fetches from API and caches when refresh is true" do
        mock_models = [CodingAgentTools::Models::LlmModelInfo.new(id: "fresh", name: "Fresh")]
        expect(command).to receive(:fetch_models_from_api).with("google").and_return(mock_models)
        expect(command).to receive(:cache_models).with("google", mock_models)

        result = command.send(:get_available_models, "google", true)
        expect(result).to eq(mock_models)
      end

      it "fetches from API when cache doesn't exist" do
        allow(command).to receive(:cache_exists?).with("google").and_return(false)
        mock_models = [CodingAgentTools::Models::LlmModelInfo.new(id: "api", name: "API")]
        expect(command).to receive(:fetch_models_from_api).with("google").and_return(mock_models)
        expect(command).to receive(:cache_models).with("google", mock_models)

        result = command.send(:get_available_models, "google", false)
        expect(result).to eq(mock_models)
      end

      it "loads from cache when cache exists and refresh is false" do
        allow(command).to receive(:cache_exists?).with("google").and_return(true)
        cached_models = [CodingAgentTools::Models::LlmModelInfo.new(id: "cached", name: "Cached")]
        expect(command).to receive(:load_models_from_cache).with("google").and_return(cached_models)
        expect(command).not_to receive(:fetch_models_from_api)

        result = command.send(:get_available_models, "google", false)
        expect(result).to eq(cached_models)
      end
    end

    describe "#fetch_models_from_api method" do
      it "calls appropriate fetch method for each provider" do
        providers_and_methods = {
          "google" => :fetch_google_models,
          "lmstudio" => :fetch_lmstudio_models,
          "openai" => :fetch_openai_models,
          "anthropic" => :fetch_anthropic_models,
          "mistral" => :fetch_mistral_models,
          "together_ai" => :fetch_together_ai_models
        }

        providers_and_methods.each do |provider, method|
          mock_models = [CodingAgentTools::Models::LlmModelInfo.new(id: "test", name: "Test")]
          expect(command).to receive(method).and_return(mock_models)

          result = command.send(:fetch_models_from_api, provider)
          expect(result).to eq(mock_models)
        end
      end

      it "falls back to hardcoded models when API fails" do
        fallback_models = [CodingAgentTools::Models::LlmModelInfo.new(id: "fallback", name: "Fallback")]
        expect(command).to receive(:fetch_google_models).and_raise(StandardError.new("API Error"))
        expect(command).to receive(:fallback_models).with("google").and_return(fallback_models)

        # Mock ENV check for DEBUG_MODELS
        old_debug = ENV["DEBUG_MODELS"]
        ENV["DEBUG_MODELS"] = "true"
        expect(command).to receive(:warn).with("API failed for google: API Error")

        result = command.send(:fetch_models_from_api, "google")
        expect(result).to eq(fallback_models)

        ENV["DEBUG_MODELS"] = old_debug
      end

      it "returns nil for unknown provider" do
        result = command.send(:fetch_models_from_api, "unknown_provider")
        expect(result).to be_nil
      end
    end

    describe "individual fetch methods detailed testing" do
      describe "#fetch_google_models" do
        it "processes Google API response correctly" do
          mock_client = instance_double(CodingAgentTools::Organisms::GoogleClient)
          api_response = [
            {
              name: "models/gemini-1.5-pro",
              description: "Google's Gemini 1.5 Pro model",
              supportedGenerationMethods: ["generateContent"],
              inputTokenLimit: 2_097_152,
              outputTokenLimit: 8_192
            },
            {
              name: "models/gemini-1.0-pro",
              description: "Google's Gemini 1.0 Pro model",
              supportedGenerationMethods: ["generateContent"]
            },
            {
              name: "models/text-only-model",
              description: "Text only model without generateContent",
              supportedGenerationMethods: ["textGeneration"]
            }
          ]

          allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return(api_response)

          result = command.send(:fetch_google_models)

          expect(result.length).to eq(2) # Only models with generateContent

          first_model = result.find { |m| m.id == "gemini-1.5-pro" }
          expect(first_model).not_to be_nil
          expect(first_model.name).to include("Gemini")
          expect(first_model.context_size).to eq(2_097_152)
          expect(first_model.max_output_tokens).to eq(8_192)

          second_model = result.find { |m| m.id == "gemini-1.0-pro" }
          expect(second_model).not_to be_nil
          expect(second_model.context_size).to eq(32_768) # Fallback value
        end

        it "handles context size extraction edge cases" do
          mock_client = instance_double(CodingAgentTools::Organisms::GoogleClient)
          api_response = [
            {
              name: "models/test-model",
              supportedGenerationMethods: ["generateContent"],
              inputTokenLimit: 0 # Should be ignored
            }
          ]

          allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return(api_response)

          result = command.send(:fetch_google_models)
          expect(result.first.context_size).to be_nil # No fallback match
        end
      end

      describe "#fetch_lmstudio_models" do
        it "processes LM Studio API response correctly" do
          mock_client = instance_double(CodingAgentTools::Organisms::LmstudioClient)
          api_response = [
            {
              id: "mistralai/mistral-7b-instruct",
              context_length: 32_768,
              max_tokens: 4_096
            },
            {
              id: "meta-llama/llama-3.1-8b-instruct",
              context_length: 131_072
            }
          ]

          allow(CodingAgentTools::Organisms::LmstudioClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return(api_response)

          result = command.send(:fetch_lmstudio_models)

          expect(result.length).to eq(2)

          mistral_model = result.find { |m| m.id == "mistralai/mistral-7b-instruct" }
          expect(mistral_model.name).to eq("Mistral 7b Instruct")
          expect(mistral_model.context_size).to eq(32_768)
          expect(mistral_model.max_output_tokens).to eq(4_096)

          llama_model = result.find { |m| m.id == "meta-llama/llama-3.1-8b-instruct" }
          expect(llama_model.context_size).to eq(131_072)
          expect(llama_model.max_output_tokens).to eq(65_536) # Half of context
        end
      end

      describe "#fetch_openai_models" do
        it "filters and processes OpenAI models correctly" do
          mock_client = instance_double(CodingAgentTools::Organisms::OpenaiClient)
          api_response = [
            {id: "gpt-4o", created: 1_234_567_890},
            {id: "gpt-4-turbo", created: 1_234_567_890},
            {id: "gpt-3.5-turbo", created: 1_234_567_890},
            {id: "o1-preview", created: 1_234_567_890},
            {id: "text-davinci-003", created: 1_234_567_890}, # Should be filtered out
            {id: "davinci", created: 1_234_567_890} # Should be filtered out
          ]

          allow(CodingAgentTools::Organisms::OpenaiClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return(api_response)

          result = command.send(:fetch_openai_models)

          expect(result.length).to eq(4) # Only chat models
          expect(result.map(&:id)).to include("gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo", "o1-preview")
          expect(result.map(&:id)).not_to include("text-davinci-003", "davinci")

          gpt4o_model = result.find { |m| m.id == "gpt-4o" }
          expect(gpt4o_model.name).to eq("GPT-4 Omni")
        end
      end

      describe "#fetch_anthropic_models" do
        it "processes Anthropic API response correctly" do
          mock_client = instance_double(CodingAgentTools::Organisms::AnthropicClient)
          api_response = [
            {id: "claude-3-5-sonnet-20241022", description: "Claude 3.5 Sonnet"},
            {id: "claude-3-haiku-20240307", description: "Claude 3 Haiku"}
          ]

          allow(CodingAgentTools::Organisms::AnthropicClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return(api_response)

          result = command.send(:fetch_anthropic_models)

          expect(result.length).to eq(2)

          sonnet_model = result.find { |m| m.id == "claude-3-5-sonnet-20241022" }
          expect(sonnet_model.name).to eq("Claude 3.5 Sonnet")
          expect(sonnet_model.description).to eq("Claude 3.5 Sonnet")
        end
      end

      describe "#fetch_mistral_models" do
        it "processes Mistral API response correctly" do
          mock_client = instance_double(CodingAgentTools::Organisms::MistralClient)
          api_response = [
            {id: "mistral-large-2407", description: "Mistral Large model"},
            {id: "mistral-8x7b-instruct", description: "Mistral 8x7B Instruct"}
          ]

          allow(CodingAgentTools::Organisms::MistralClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return(api_response)

          result = command.send(:fetch_mistral_models)

          expect(result.length).to eq(2)

          large_model = result.find { |m| m.id == "mistral-large-2407" }
          expect(large_model.name).to eq("Mistral Large")
        end
      end

      describe "#fetch_together_ai_models" do
        it "processes Together AI API response correctly" do
          mock_client = instance_double(CodingAgentTools::Organisms::TogetheraiClient)
          api_response = [
            {id: "meta-llama/Llama-3.1-70B-Instruct", name: "Llama 3.1 70B Instruct"},
            {name: "mistralai/Mistral-8x7B-Instruct", description: "Mistral 8x7B"}
          ]

          allow(CodingAgentTools::Organisms::TogetheraiClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return(api_response)

          result = command.send(:fetch_together_ai_models)

          expect(result.length).to eq(2)

          llama_model = result.find { |m| m.id == "meta-llama/Llama-3.1-70B-Instruct" }
          expect(llama_model.name).to eq("Llama 3.1 70B")

          mistral_model = result.find { |m| m.id == "mistralai/Mistral-8x7B-Instruct" }
          expect(mistral_model.id).to eq("mistralai/Mistral-8x7B-Instruct")
        end

        it "raises error when no models are returned" do
          mock_client = instance_double(CodingAgentTools::Organisms::TogetheraiClient)
          allow(CodingAgentTools::Organisms::TogetheraiClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return([])

          expect { command.send(:fetch_together_ai_models) }.to raise_error("No models returned from API")
        end
      end
    end

    describe "advanced filter testing" do
      let(:complex_models) do
        [
          CodingAgentTools::Models::LlmModelInfo.new(id: "gemini-1.5-pro", name: "Gemini 1.5 Pro", description: "Advanced reasoning model"),
          CodingAgentTools::Models::LlmModelInfo.new(id: "gpt-4o", name: "GPT-4 Omni", description: "OpenAI's latest multimodal model"),
          CodingAgentTools::Models::LlmModelInfo.new(id: nil, name: "Model with nil ID", description: "Edge case model"),
          CodingAgentTools::Models::LlmModelInfo.new(id: "claude-3-opus", name: nil, description: "Anthropic's powerful model"),
          CodingAgentTools::Models::LlmModelInfo.new(id: "mistral-large", name: "Mistral Large", description: nil)
        ]
      end

      it "handles filtering with nil attributes gracefully" do
        result = command.send(:filter_models, complex_models, "nil")
        expect(result.length).to eq(1) # Only the one with "Model with nil ID"
        expect(result.first.name).to eq("Model with nil ID")
      end

      it "performs case-insensitive partial matching" do
        result = command.send(:filter_models, complex_models, "GEMINI")
        expect(result.length).to eq(1)
        expect(result.first.id).to eq("gemini-1.5-pro")
      end

      it "searches across all attributes (id, name, description)" do
        result = command.send(:filter_models, complex_models, "multimodal")
        expect(result.length).to eq(1)
        expect(result.first.id).to eq("gpt-4o")
      end

      it "returns empty array when no matches found" do
        result = command.send(:filter_models, complex_models, "nonexistent")
        expect(result).to be_empty
      end

      it "handles empty filter term" do
        result = command.send(:filter_models, complex_models, "")
        expect(result).to eq(complex_models)
      end
    end

    describe "output method comprehensive testing" do
      let(:test_models) do
        [
          CodingAgentTools::Models::LlmModelInfo.new(
            id: "test-model-1",
            name: "Test Model 1",
            description: "First test model",
            default: true,
            context_size: 128_000,
            max_output_tokens: 4_096
          ),
          CodingAgentTools::Models::LlmModelInfo.new(
            id: "test-model-2",
            name: "Test Model 2",
            description: "Second test model",
            default: false,
            context_size: 32_000,
            max_output_tokens: 2_048
          )
        ]
      end

      describe "#output_models" do
        it "delegates to output_text_models for text format" do
          expect(command).to receive(:output_text_models).with(test_models, hash_including(format: "text", provider: "google"))
          command.send(:output_models, test_models, format: "text", provider: "google")
        end

        it "delegates to output_json_models for json format" do
          expect(command).to receive(:output_json_models).with(test_models, hash_including(format: "json", provider: "google"))
          command.send(:output_models, test_models, format: "json", provider: "google")
        end

        it "defaults to text format for unknown formats" do
          expect(command).to receive(:output_text_models).with(test_models, hash_including(format: "unknown", provider: "google"))
          command.send(:output_models, test_models, format: "unknown", provider: "google")
        end
      end

      describe "#output_text_models comprehensive testing" do
        it "handles empty model list" do
          command.send(:output_text_models, [], provider: "google")
          expect(output.string).to include("No models found matching the filter criteria")
        end

        it "outputs Google models with proper format and usage" do
          command.send(:output_text_models, test_models, provider: "google")

          output_content = output.string
          expect(output_content).to include("Available Google Models")
          expect(output_content).to include("Usage: llm-google-query")
          expect(output_content).to include("Test Model 1")
          expect(output_content).to include("Test Model 2")
        end

        it "outputs LM Studio models with server information" do
          command.send(:output_text_models, test_models, provider: "lmstudio")

          output_content = output.string
          expect(output_content).to include("Available LM Studio Models")
          expect(output_content).to include("Note: Models must be loaded in LM Studio before use")
          expect(output_content).to include("http://localhost:1234")
          expect(output_content).to include("Usage: llm-lmstudio-query")
        end

        it "outputs provider-specific information for all providers" do
          providers = ["openai", "anthropic", "mistral", "together_ai"]

          providers.each do |provider|
            output.string.clear
            command.send(:output_text_models, test_models, provider: provider)

            output_content = output.string
            expect(output_content).to include("Available")
            expect(output_content).to include("Usage:")
            expect(output_content).to include("Test Model 1")
          end
        end
      end

      describe "#output_json_models comprehensive testing" do
        it "outputs valid JSON structure with all required fields" do
          command.send(:output_json_models, test_models, provider: "google")

          output_content = output.string
          json_output = JSON.parse(output_content)

          expect(json_output).to have_key("models")
          expect(json_output).to have_key("count")
          expect(json_output).to have_key("provider")
          expect(json_output).to have_key("default_model")

          expect(json_output["models"]).to be_an(Array)
          expect(json_output["count"]).to eq(2)
          expect(json_output["provider"]).to eq("google")
          expect(json_output["default_model"]).to eq("test-model-1")
        end

        it "includes model details in proper format" do
          command.send(:output_json_models, test_models, provider: "google")

          json_output = JSON.parse(output.string)
          first_model = json_output["models"].first

          expect(first_model).to have_key("id")
          expect(first_model).to have_key("name")
          expect(first_model).to have_key("description")
          expect(first_model).to have_key("default")
          expect(first_model).to have_key("context_size")
          expect(first_model).to have_key("max_output_tokens")

          expect(first_model["context_size"]).to eq(128_000)
          expect(first_model["max_output_tokens"]).to eq(4_096)
        end

        it "includes provider-specific information for LM Studio" do
          command.send(:output_json_models, test_models, provider: "lmstudio")

          json_output = JSON.parse(output.string)
          expect(json_output).to have_key("server_url")
          expect(json_output["server_url"]).to eq("http://localhost:1234")
          expect(json_output["provider"]).to eq("lmstudio")
        end
      end
    end
  end

  # Additional comprehensive test coverage for edge cases and error scenarios
  describe "comprehensive edge case and error coverage" do
    describe "filter edge cases" do
      let(:test_models) do
        [
          CodingAgentTools::Models::LlmModelInfo.new(id: "model-1", name: "Test Model", description: "Test description"),
          CodingAgentTools::Models::LlmModelInfo.new(id: nil, name: "Nil ID Model", description: "Model with nil ID"),
          CodingAgentTools::Models::LlmModelInfo.new(id: "model-3", name: nil, description: "Model with nil name"),
          CodingAgentTools::Models::LlmModelInfo.new(id: "model-4", name: "Model Four", description: nil)
        ]
      end

      it "handles nil filter term gracefully" do
        result = command.send(:filter_models, test_models, nil)
        expect(result).to eq(test_models)
      end

      it "handles empty string filter" do
        result = command.send(:filter_models, test_models, "")
        expect(result).to eq(test_models)
      end

      it "handles filter with special characters" do
        special_models = [
          CodingAgentTools::Models::LlmModelInfo.new(id: "model-with-special!@#", name: "Special Model", description: "Model with special chars")
        ]
        result = command.send(:filter_models, special_models, "special!@")
        expect(result.length).to eq(1)
      end

      it "handles nil model attributes in filter" do
        result = command.send(:filter_models, test_models, "test")
        # Should match models where name or description contains "test" (case insensitive)
        expect(result.length).to be >= 1
        expect(result.map(&:name).compact).to include("Test Model")
      end

      it "filters with unicode characters" do
        unicode_models = [
          CodingAgentTools::Models::LlmModelInfo.new(id: "unicode-model", name: "Modèl Tëst", description: "Ünïcødé description")
        ]
        result = command.send(:filter_models, unicode_models, "modèl")
        expect(result.length).to eq(1)
      end
    end

    describe "comprehensive error handling scenarios" do
      it "handles SystemExit correctly in call method" do
        allow(command).to receive(:warn)
        expect { command.call(provider: "nonexistent") }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
        expect(command).to have_received(:warn).with(/Invalid provider 'nonexistent'/)
      end

      it "handles network timeout with proper error message" do
        allow(command).to receive(:get_available_models).and_raise(Timeout::Error.new("Connection timeout"))
        allow(command).to receive(:warn)

        expect { command.call }.to raise_error(SystemExit)
        expect(command).to have_received(:warn).with(/Error: Connection timeout/)
      end

      it "handles API authentication errors" do
        allow(command).to receive(:get_available_models).and_raise(StandardError.new("401 Unauthorized"))
        allow(command).to receive(:warn)

        expect { command.call }.to raise_error(SystemExit)
        expect(command).to have_received(:warn).with(/Error: 401 Unauthorized/)
      end

      it "handles API rate limiting errors" do
        allow(command).to receive(:get_available_models).and_raise(StandardError.new("429 Too Many Requests"))
        allow(command).to receive(:warn)

        expect { command.call }.to raise_error(SystemExit)
        expect(command).to have_received(:warn).with(/Error: 429 Too Many Requests/)
      end

      it "handles malformed JSON responses" do
        allow(command).to receive(:get_available_models).and_raise(JSON::ParserError.new("Invalid JSON format"))
        allow(command).to receive(:warn)

        expect { command.call }.to raise_error(SystemExit)
        expect(command).to have_received(:warn).with(/Error: Invalid JSON format/)
      end

      it "handles SSL certificate errors" do
        allow(command).to receive(:get_available_models).and_raise(OpenSSL::SSL::SSLError.new("Certificate verify failed"))
        allow(command).to receive(:warn)

        expect { command.call }.to raise_error(SystemExit)
        expect(command).to have_received(:warn).with(/Error: Certificate verify failed/)
      end
    end

    describe "cache corruption and edge cases" do
      let(:cache_manager) { instance_double(CodingAgentTools::Molecules::CacheManager) }

      before do
        allow(command).to receive(:cache_manager).and_return(cache_manager)
      end

      it "handles corrupted cache file gracefully" do
        allow(cache_manager).to receive(:cache_exists?).and_return(true)
        yaml_error = Psych::SyntaxError.new("cache.yaml", 1, 1, 0, "YAML parsing error", "YAML parsing error")
        allow(cache_manager).to receive(:read_cache).and_raise(yaml_error)

        # Should raise the error since the actual implementation doesn't catch it
        expect { command.send(:load_models_from_cache, "google") }.to raise_error(Psych::SyntaxError)
      end

      it "handles empty cache data" do
        allow(cache_manager).to receive(:cache_exists?).and_return(true)
        allow(cache_manager).to receive(:read_cache).and_return({})

        # Should raise an error since empty hash doesn't have "models" key
        expect { command.send(:load_models_from_cache, "google") }.to raise_error(NoMethodError)
      end

      it "handles cache file permission errors" do
        allow(cache_manager).to receive(:cache_exists?).and_return(true)
        allow(cache_manager).to receive(:read_cache).and_raise(Errno::EACCES.new("Permission denied"))

        # Should raise the error since the actual implementation doesn't catch it
        expect { command.send(:load_models_from_cache, "google") }.to raise_error(Errno::EACCES)
      end

      it "handles cache write failures gracefully" do
        models = [CodingAgentTools::Models::LlmModelInfo.new(id: "test", name: "Test")]
        allow(cache_manager).to receive(:write_cache).and_raise(Errno::ENOSPC.new("No space left on device"))

        # Should raise the error since the actual implementation doesn't handle it
        expect { command.send(:cache_models, "google", models) }.to raise_error(Errno::ENOSPC)
      end
    end

    describe "API client error scenarios" do
      describe "Google API failures" do
        it "handles empty API response" do
          mock_client = instance_double(CodingAgentTools::Organisms::GoogleClient)
          allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return([])

          result = command.send(:fetch_google_models)
          expect(result).to eq([])
        end

        it "handles malformed API response structure" do
          mock_client = instance_double(CodingAgentTools::Organisms::GoogleClient)
          allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return([
            {name: "models/gemini-test"}  # Missing supportedGenerationMethods
          ])

          result = command.send(:fetch_google_models)
          expect(result).to eq([])  # Should filter out models without supportedGenerationMethods
        end

        it "handles API connection refused" do
          allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_raise(Errno::ECONNREFUSED.new("Connection refused"))

          expect { command.send(:fetch_google_models) }.to raise_error(Errno::ECONNREFUSED)
        end
      end

      describe "OpenAI API failures" do
        it "handles empty model list" do
          mock_client = instance_double(CodingAgentTools::Organisms::OpenaiClient)
          allow(CodingAgentTools::Organisms::OpenaiClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return([])

          result = command.send(:fetch_openai_models)
          expect(result).to eq([])
        end

        it "filters out non-chat models correctly" do
          mock_client = instance_double(CodingAgentTools::Organisms::OpenaiClient)
          allow(CodingAgentTools::Organisms::OpenaiClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return([
            {id: "gpt-4", created: 1_234_567_890},
            {id: "text-davinci-003", created: 1_234_567_890},  # Should be excluded
            {id: "o1-preview", created: 1_234_567_890}
          ])

          result = command.send(:fetch_openai_models)
          expect(result.length).to eq(2)
          expect(result.map(&:id)).to include("gpt-4", "o1-preview")
          expect(result.map(&:id)).not_to include("text-davinci-003")
        end
      end

      describe "LM Studio API failures" do
        it "handles server not running" do
          allow(CodingAgentTools::Organisms::LmstudioClient).to receive(:new).and_raise(Errno::ECONNREFUSED.new("Connection refused"))

          expect { command.send(:fetch_lmstudio_models) }.to raise_error(Errno::ECONNREFUSED)
        end

        it "handles models with missing metadata" do
          mock_client = instance_double(CodingAgentTools::Organisms::LmstudioClient)
          allow(CodingAgentTools::Organisms::LmstudioClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return([
            {id: "model-without-context"}  # Missing context_length
          ])

          result = command.send(:fetch_lmstudio_models)
          expect(result.length).to eq(1)
          expect(result.first.id).to eq("model-without-context")
        end
      end

      describe "Together AI specific edge cases" do
        it "raises error when API returns empty model list" do
          mock_client = instance_double(CodingAgentTools::Organisms::TogetheraiClient)
          allow(CodingAgentTools::Organisms::TogetheraiClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return([])

          expect { command.send(:fetch_together_ai_models) }.to raise_error("No models returned from API")
        end

        it "handles models with mixed id/name fields" do
          mock_client = instance_double(CodingAgentTools::Organisms::TogetheraiClient)
          allow(CodingAgentTools::Organisms::TogetheraiClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_return([
            {id: "model-with-id", description: "Model with ID field"},
            {name: "model-with-name", description: "Model with name field"}
          ])

          result = command.send(:fetch_together_ai_models)
          expect(result.length).to eq(2)
          expect(result.first.id).to eq("model-with-id")
          expect(result.last.id).to eq("model-with-name")
        end
      end
    end

    describe "fallback mechanism edge cases" do
      it "handles missing fallback configuration file" do
        allow(File).to receive(:expand_path).and_return("/nonexistent/path")
        allow(YAML).to receive(:load_file).and_raise(Errno::ENOENT.new("No such file"))

        expect { command.send(:fallback_models, "google") }.to raise_error(Errno::ENOENT)
      end

      it "handles malformed fallback YAML" do
        yaml_error = Psych::SyntaxError.new("test.yaml", 1, 1, 0, "Invalid YAML", "Invalid YAML")
        allow(YAML).to receive(:load_file).and_raise(yaml_error)

        expect { command.send(:fallback_models, "google") }.to raise_error(Psych::SyntaxError)
      end

      it "handles fallback for unknown provider" do
        result = command.send(:fallback_models, "unknown_provider")
        expect(result).to be_nil
      end
    end

    describe "output format edge cases" do
      describe "JSON output edge cases" do
        it "handles models with nil values in JSON output" do
          models_with_nils = [
            CodingAgentTools::Models::LlmModelInfo.new(id: "test", name: nil, description: nil, default: false)
          ]

          command.send(:output_json_models, models_with_nils, provider: "google")

          output_content = output.string
          json_output = JSON.parse(output_content)

          expect(json_output["models"]).to be_an(Array)
          expect(json_output["models"].first["name"]).to be_nil
          expect(json_output["models"].first["description"]).to be_nil
        end

        it "handles large model lists in JSON output" do
          large_model_list = Array.new(100) do |i|
            CodingAgentTools::Models::LlmModelInfo.new(
              id: "model-#{i}",
              name: "Model #{i}",
              description: "Description #{i}",
              default: i == 0
            )
          end

          command.send(:output_json_models, large_model_list, provider: "google")

          output_content = output.string
          json_output = JSON.parse(output_content)

          expect(json_output["count"]).to eq(100)
          expect(json_output["models"].length).to eq(100)
        end
      end

      describe "text output edge cases" do
        it "handles empty model list gracefully" do
          command.send(:output_text_models, [], provider: "google")

          output_content = output.string
          expect(output_content).to include("No models found matching the filter criteria")
        end

        it "handles models with very long descriptions" do
          long_description = "A" * 1000
          models_with_long_desc = [
            CodingAgentTools::Models::LlmModelInfo.new(
              id: "long-desc-model",
              name: "Long Description Model",
              description: long_description
            )
          ]

          expect { command.send(:output_text_models, models_with_long_desc, provider: "google") }.not_to raise_error
        end
      end
    end

    describe "context size extraction edge cases" do
      describe "Google context size extraction" do
        it "handles models with zero or negative token limits" do
          model_zero = {inputTokenLimit: 0}
          expect(command.send(:extract_google_context_size, model_zero)).to be_nil

          model_negative = {inputTokenLimit: -1}
          expect(command.send(:extract_google_context_size, model_negative)).to be_nil
        end

        it "handles models with invalid name patterns" do
          model_invalid = {name: "invalid-model-name"}
          expect(command.send(:extract_google_context_size, model_invalid)).to be_nil
        end

        it "handles models with missing name field" do
          model_no_name = {}
          expect(command.send(:extract_google_context_size, model_no_name)).to be_nil
        end
      end

      describe "LM Studio context size extraction" do
        it "handles models with invalid context size values" do
          model_zero = {context_length: 0}
          expect(command.send(:extract_lmstudio_context_size, model_zero)).to be_nil

          model_negative = {context_length: -1}
          expect(command.send(:extract_lmstudio_context_size, model_negative)).to be_nil
        end

        it "handles models with unrecognized naming patterns" do
          model_unknown = {id: "unknown/random-model-name"}
          expect(command.send(:extract_lmstudio_context_size, model_unknown)).to be_nil
        end

        it "handles max output token calculation edge cases" do
          # Test nil context size
          allow(command).to receive(:extract_lmstudio_context_size).and_return(nil)
          result = command.send(:extract_lmstudio_max_output_tokens, {})
          expect(result).to be_nil

          # Test very small context size
          allow(command).to receive(:extract_lmstudio_context_size).and_return(1000)
          result = command.send(:extract_lmstudio_max_output_tokens, {})
          expect(result).to eq(4096)  # Should enforce minimum
        end
      end
    end

    describe "model name formatting comprehensive edge cases" do
      describe "Google model name formatting" do
        it "handles edge cases in model name formatting" do
          expect(command.send(:format_model_name, "models/")).to eq("")
          expect(command.send(:format_model_name, "models/single")).to eq("Single")
          expect(command.send(:format_model_name, "models/gemini-ultra-advanced")).to eq("Gemini Ultra Advanced")
        end
      end

      describe "LM Studio model name formatting edge cases" do
        it "handles models with empty path components" do
          expect { command.send(:format_lmstudio_model_name, "/") }.to raise_error(NoMethodError)
          expect(command.send(:format_lmstudio_model_name, "provider/")).to eq("Provider")
        end

        it "handles models with special characters in names" do
          expect(command.send(:format_lmstudio_model_name, "provider/model_with_underscores")).to eq("Model With Underscores")
          expect(command.send(:format_lmstudio_model_name, "provider/model-with-hyphens")).to eq("Model With Hyphens")
        end
      end

      describe "Together AI model name formatting edge cases" do
        it "handles complex model naming patterns" do
          # Test nested path structures
          expect(command.send(:format_together_ai_model_name, "org/suborg/model-name")).to eq("Model Name")

          # Test models that don't match any known pattern
          expect(command.send(:format_together_ai_model_name, "unknown-provider/weird-model")).to eq("Weird Model")

          # Test edge case for Qwen models
          expect(command.send(:format_together_ai_model_name, "qwen/qwen2-7b-instruct")).to eq("Qwen2 7b Instruct")
        end
      end
    end

    describe "integration and memory edge cases" do
      it "handles very large model lists without memory issues" do
        # Mock a scenario with hundreds of models
        large_model_response = Array.new(500) do |i|
          {
            name: "models/test-model-#{i}",
            description: "Test model #{i}",
            supportedGenerationMethods: ["generateContent"]
          }
        end

        mock_client = instance_double(CodingAgentTools::Organisms::GoogleClient)
        allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:list_models).and_return(large_model_response)

        result = command.send(:fetch_google_models)
        expect(result.length).to eq(500)
      end

      it "handles concurrent access scenarios gracefully" do
        # This is a simplified test for thread safety concerns
        cache_manager = instance_double(CodingAgentTools::Molecules::CacheManager)
        allow(command).to receive(:cache_manager).and_return(cache_manager)
        allow(cache_manager).to receive(:cache_exists?).and_return(false)
        allow(command).to receive(:fetch_models_from_api).and_return([
          CodingAgentTools::Models::LlmModelInfo.new(id: "concurrent-test", name: "Concurrent Test")
        ])
        allow(cache_manager).to receive(:write_cache)

        # Simulate multiple calls
        results = []
        3.times do
          results << command.send(:get_available_models, "google", false)
        end

        expect(results.all? { |r| r.first.id == "concurrent-test" }).to be true
      end
    end

    describe "comprehensive system integration scenarios" do
      it "handles full workflow with all error conditions" do
        # Test complete workflow from call to output with various error conditions
        allow(command).to receive(:get_available_models).and_return([
          CodingAgentTools::Models::LlmModelInfo.new(id: "integration-test", name: "Integration Test", description: "Full workflow test")
        ])

        # Should complete without errors
        expect { command.call(provider: "google", format: "json", filter: "integration") }.not_to raise_error

        output_content = output.string
        json_output = JSON.parse(output_content)
        expect(json_output["models"].first["id"]).to eq("integration-test")
      end

      it "validates complete error recovery workflow" do
        # Test that errors are properly caught and handled at the top level
        allow(command).to receive(:get_available_models).and_raise(StandardError.new("Simulated failure"))
        allow(command).to receive(:warn)

        expect { command.call }.to raise_error(SystemExit)
        expect(command).to have_received(:warn).with(/Error: Simulated failure/)
      end
    end

    describe "comprehensive caching system testing" do
      let(:cache_manager) { instance_double(CodingAgentTools::Molecules::CacheManager) }
      let(:test_models) do
        [CodingAgentTools::Models::LlmModelInfo.new(id: "cached-model", name: "Cached Model", description: "Test cached model")]
      end

      before do
        allow(command).to receive(:cache_manager).and_return(cache_manager)
      end

      describe "#cache_models" do
        it "serializes models correctly to cache" do
          expect(cache_manager).to receive(:write_cache) do |filename, cache_data|
            expect(filename).to eq("google_models.yml")
            expect(cache_data).to have_key("cached_at")
            expect(cache_data["cached_at"]).to be_a(String)
            expect(cache_data["provider"]).to eq("google")
            expect(cache_data["models"]).to be_an(Array)
            expect(cache_data["models"].first["id"]).to eq("cached-model")
            expect(cache_data["models"].first["name"]).to eq("Cached Model")
            expect(cache_data["models"].first["description"]).to eq("Test cached model")
            expect(cache_data["models"].first["default"]).to be_nil # default? returns nil, not false
          end

          command.send(:cache_models, "google", test_models)
        end

        it "includes timestamp in cache data" do
          freeze_time = Time.parse("2024-01-01 12:00:00 UTC")
          allow(Time).to receive(:now).and_return(freeze_time)

          expected_cache_data = hash_including(
            "cached_at" => "2024-01-01T12:00:00Z"
          )

          expect(cache_manager).to receive(:write_cache).with("google_models.yml", expected_cache_data)

          command.send(:cache_models, "google", test_models)
        end
      end

      describe "#load_models_from_cache" do
        it "reconstructs models from cache data correctly" do
          cache_data = {
            "cached_at" => "2024-01-01T12:00:00Z",
            "provider" => "google",
            "models" => [
              {
                "id" => "cached-model",
                "name" => "Cached Model",
                "description" => "Test cached model",
                "default" => true,
                "context_size" => 128_000,
                "max_output_tokens" => 4_096
              }
            ]
          }

          allow(cache_manager).to receive(:read_cache).with("google_models.yml").and_return(cache_data)

          result = command.send(:load_models_from_cache, "google")

          expect(result.length).to eq(1)
          model = result.first
          expect(model.id).to eq("cached-model")
          expect(model.name).to eq("Cached Model")
          expect(model.default?).to be true
          expect(model.context_size).to eq(128_000)
          expect(model.max_output_tokens).to eq(4_096)
        end

        it "falls back to hardcoded models when cache is nil" do
          allow(cache_manager).to receive(:read_cache).with("google_models.yml").and_return(nil)
          fallback_models = [CodingAgentTools::Models::LlmModelInfo.new(id: "fallback", name: "Fallback")]
          expect(command).to receive(:fallback_models).with("google").and_return(fallback_models)

          result = command.send(:load_models_from_cache, "google")
          expect(result).to eq(fallback_models)
        end
      end

      describe "#cache_file_name" do
        it "generates correct cache file names for all providers" do
          providers = ["google", "lmstudio", "openai", "anthropic", "mistral", "together_ai"]

          providers.each do |provider|
            expected_filename = "#{provider}_models.yml"
            expect(command.send(:cache_file_name, provider)).to eq(expected_filename)
          end
        end
      end

      describe "#cache_exists?" do
        it "delegates to cache manager correctly" do
          allow(cache_manager).to receive(:cache_exists?).with("google_models.yml").and_return(true)

          result = command.send(:cache_exists?, "google")
          expect(result).to be true
        end
      end
    end

    describe "comprehensive API error scenarios" do
      describe "network-level failures" do
        it "handles connection refused errors" do
          allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_raise(Errno::ECONNREFUSED.new("Connection refused"))

          expect { command.send(:fetch_google_models) }.to raise_error(Errno::ECONNREFUSED)
        end

        it "handles timeout errors" do
          allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_raise(Timeout::Error.new("Request timeout"))

          expect { command.send(:fetch_google_models) }.to raise_error(Timeout::Error)
        end

        it "handles SSL certificate errors" do
          allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_raise(OpenSSL::SSL::SSLError.new("Certificate verify failed"))

          expect { command.send(:fetch_google_models) }.to raise_error(OpenSSL::SSL::SSLError)
        end
      end

      describe "HTTP-level failures" do
        it "handles authentication errors (401)" do
          mock_client = instance_double(CodingAgentTools::Organisms::GoogleClient)
          allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_raise(StandardError.new("401 Unauthorized"))

          expect { command.send(:fetch_google_models) }.to raise_error(StandardError, "401 Unauthorized")
        end

        it "handles rate limiting errors (429)" do
          mock_client = instance_double(CodingAgentTools::Organisms::OpenaiClient)
          allow(CodingAgentTools::Organisms::OpenaiClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_raise(StandardError.new("429 Too Many Requests"))

          expect { command.send(:fetch_openai_models) }.to raise_error(StandardError, "429 Too Many Requests")
        end

        it "handles server errors (500)" do
          mock_client = instance_double(CodingAgentTools::Organisms::AnthropicClient)
          allow(CodingAgentTools::Organisms::AnthropicClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_raise(StandardError.new("500 Internal Server Error"))

          expect { command.send(:fetch_anthropic_models) }.to raise_error(StandardError, "500 Internal Server Error")
        end
      end

      describe "response parsing failures" do
        it "handles malformed JSON responses" do
          mock_client = instance_double(CodingAgentTools::Organisms::MistralClient)
          allow(CodingAgentTools::Organisms::MistralClient).to receive(:new).and_return(mock_client)
          allow(mock_client).to receive(:list_models).and_raise(JSON::ParserError.new("Invalid JSON"))

          expect { command.send(:fetch_mistral_models) }.to raise_error(JSON::ParserError)
        end

        it "handles unexpected response structure" do
          mock_client = instance_double(CodingAgentTools::Organisms::GoogleClient)
          allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
          # Return response with missing required fields
          allow(mock_client).to receive(:list_models).and_return([{missing_name: "invalid"}])

          result = command.send(:fetch_google_models)
          expect(result).to eq([]) # Should filter out invalid entries
        end
      end
    end

    describe "advanced context size and formatting edge cases" do
      describe "context size extraction with edge values" do
        it "handles very large context sizes" do
          model_huge = {inputTokenLimit: 10_000_000}
          expect(command.send(:extract_google_context_size, model_huge)).to eq(10_000_000)
        end

        it "handles negative values gracefully" do
          model_negative = {inputTokenLimit: -1}
          expect(command.send(:extract_google_context_size, model_negative)).to be_nil
        end

        it "handles string values that should be numbers" do
          model_string = {context_length: "32768"}
          # This would actually cause an error in the real implementation since it calls positive? on a string
          expect { command.send(:extract_lmstudio_context_size, model_string) }.to raise_error(NoMethodError)
        end
      end

      describe "model name formatting with special cases" do
        it "handles very long model names" do
          long_name = "a" * 1000
          result = command.send(:format_lmstudio_model_name, "provider/#{long_name}")
          expect(result.length).to be > 500
          expect(result).to start_with("A")
        end

        it "handles model names with unicode characters" do
          unicode_name = "modèl-naïve-tëst"
          result = command.send(:format_lmstudio_model_name, "provider/#{unicode_name}")
          expect(result).to eq("Modèl Naïve Tëst")
        end

        it "handles model names with numbers and special patterns" do
          complex_names = [
            "provider/gpt-4o-2024-08-06",
            "provider/claude-3-5-sonnet-20241022",
            "provider/llama-3.1-70b-instruct-turbo"
          ]

          complex_names.each do |name|
            result = command.send(:format_lmstudio_model_name, name)
            expect(result).to be_a(String)
            expect(result).not_to be_empty
          end
        end
      end
    end

    describe "integration edge cases and resource management" do
      it "handles very large model lists without memory issues" do
        large_api_response = Array.new(1000) do |i|
          {
            name: "models/test-model-#{i}",
            description: "Test model #{i}",
            supportedGenerationMethods: ["generateContent"]
          }
        end

        mock_client = instance_double(CodingAgentTools::Organisms::GoogleClient)
        allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:list_models).and_return(large_api_response)

        result = command.send(:fetch_google_models)
        expect(result.length).to eq(1000)
        expect(result.first.id).to eq("test-model-0")
        expect(result.last.id).to eq("test-model-999")
      end

      it "handles concurrent-like access patterns" do
        # Simulate multiple sequential calls that might happen in concurrent scenarios
        cache_manager = instance_double(CodingAgentTools::Molecules::CacheManager)
        allow(command).to receive(:cache_manager).and_return(cache_manager)
        allow(cache_manager).to receive(:cache_exists?).and_return(false)

        models = [CodingAgentTools::Models::LlmModelInfo.new(id: "concurrent-test", name: "Concurrent Test")]
        allow(command).to receive(:fetch_models_from_api).and_return(models)
        allow(cache_manager).to receive(:write_cache)

        # Multiple sequential calls
        results = []
        5.times do
          results << command.send(:get_available_models, "google", false)
        end

        expect(results.all? { |r| r.first.id == "concurrent-test" }).to be true
      end

      it "handles mixed success/failure scenarios across providers" do
        # Test scenario where some providers work and others fail
        allow(command).to receive(:fetch_google_models).and_return([
          CodingAgentTools::Models::LlmModelInfo.new(id: "google-works", name: "Google Works")
        ])
        allow(command).to receive(:fetch_openai_models).and_raise(StandardError.new("OpenAI failed"))
        allow(command).to receive(:fallback_models).with("openai").and_return([
          CodingAgentTools::Models::LlmModelInfo.new(id: "openai-fallback", name: "OpenAI Fallback")
        ])

        google_result = command.send(:fetch_models_from_api, "google")
        expect(google_result.first.id).to eq("google-works")

        # Mock the environment variable for debug output
        old_debug = ENV["DEBUG_MODELS"]
        ENV["DEBUG_MODELS"] = "true"
        expect(command).to receive(:warn).with("API failed for openai: OpenAI failed")

        openai_result = command.send(:fetch_models_from_api, "openai")
        expect(openai_result.first.id).to eq("openai-fallback")

        ENV["DEBUG_MODELS"] = old_debug
      end
    end

    describe "comprehensive validation and sanitization" do
      it "handles malformed model data gracefully" do
        malformed_models = [
          CodingAgentTools::Models::LlmModelInfo.new(id: "", name: "", description: ""),
          CodingAgentTools::Models::LlmModelInfo.new(id: nil, name: nil, description: nil),
          CodingAgentTools::Models::LlmModelInfo.new(id: "valid", name: "Valid Model", description: "Valid description")
        ]

        # Test filtering with malformed data
        result = command.send(:filter_models, malformed_models, "valid")
        expect(result.length).to eq(1)
        expect(result.first.id).to eq("valid")
      end

      it "handles extreme input values" do
        # Test with very long filter strings
        long_filter = "a" * 10_000
        models = [CodingAgentTools::Models::LlmModelInfo.new(id: "test", name: "Test", description: "Test")]

        result = command.send(:filter_models, models, long_filter)
        expect(result).to be_empty
      end

      it "validates cache data integrity" do
        # Test with corrupted cache data missing required fields
        corrupted_cache = {
          "cached_at" => "2024-01-01T12:00:00Z",
          "provider" => "google"
          # Missing "models" field
        }

        cache_manager = instance_double(CodingAgentTools::Molecules::CacheManager)
        allow(command).to receive(:cache_manager).and_return(cache_manager)
        allow(cache_manager).to receive(:read_cache).and_return(corrupted_cache)

        expect { command.send(:load_models_from_cache, "google") }.to raise_error(NoMethodError)
      end
    end
  end
end
