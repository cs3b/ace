# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/llm/models"

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
        expect(output_content).to include("Available Gemini Models")
        expect(output_content).to include("Default model")
        expect(output_content).to include("Usage: llm-gemini-query")
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
        models = command.send(:get_available_models, "google")
        default_model = models.find(&:default?)

        expect(default_model).not_to be_nil
        expect(default_model.id).not_to be_empty
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
end
