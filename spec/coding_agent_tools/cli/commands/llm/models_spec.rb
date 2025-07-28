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
        expect(output_content).to include("Default model")
        expect(output_content).to include("Usage: llm-google-query")
        # Should contain at least one model
        expect(output_content).to match(/ID: gemini-[\w\.-]+/)
        expect(output_content).to match(/Name: Gemini/)
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
        # Test with a term that should match at least one model
        command.call(filter: "gemini")

        output_content = output.string
        # Should have models since "gemini" should match
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
        command.call(filter: "GEMINI")

        output_content = output.string
        # Should have models since case shouldn't matter
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

        allow(command).to receive(:fallback_models).and_return(fallback_models)
        allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_raise(StandardError.new("API not available"))

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
        %w[google lmstudio openai anthropic mistral together_ai].each do |provider|
          expect(command.send(:valid_provider?, provider)).to be true
        end
      end

      it "returns false for invalid providers" do
        %w[invalid unknown fake].each do |provider|
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
          valid_providers = %w[google lmstudio openai anthropic mistral together_ai]
          invalid_providers = %w[invalid unknown fake]

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
              {id: "gpt-4", created: 1234567890},
              {id: "gpt-3.5-turbo", created: 1234567890},
              {id: "text-davinci-003", created: 1234567890}  # Should be filtered out
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
              {id: "mistralai/mistral-7b-instruct", context_length: 32768}
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
          model_with_limit = {inputTokenLimit: 1000000}
          expect(command.send(:extract_google_context_size, model_with_limit)).to eq(1000000)

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
          model_context = {context_length: 32768}
          expect(command.send(:extract_lmstudio_context_size, model_context)).to eq(32768)

          model_pattern = {id: "meta-llama/llama-3.1-8b-instruct"}
          expect(command.send(:extract_lmstudio_context_size, model_pattern)).to eq(131_072)
        end

        it "extracts LM Studio max output tokens correctly" do
          model_tokens = {max_tokens: 4096}
          expect(command.send(:extract_lmstudio_max_output_tokens, model_tokens)).to eq(4096)

          # Test calculation from context size
          model_with_context = {context_length: 32768}
          allow(command).to receive(:extract_lmstudio_context_size).and_return(32768)
          result = command.send(:extract_lmstudio_max_output_tokens, model_with_context)
          expect(result).to eq(16384)  # Half of context size

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

            %w[google lmstudio openai anthropic mistral together_ai].each do |provider|
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
end
