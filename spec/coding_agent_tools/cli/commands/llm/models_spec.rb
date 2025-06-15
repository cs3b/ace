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
    context "with default options" do
      it "lists all available models" do
        command.call

        output_content = output.string
        expect(output_content).to include("Available Gemini Models:")
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

    context "with filter option" do
      it "filters models correctly" do
        # Test with a term that should match at least one model
        command.call(filter: "gemini")

        output_content = output.string
        # Should have models since "gemini" should match
        expect(output_content).to match(/ID: gemini-[\w\.-]+/)
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
      it "returns an array of model hashes" do
        models = command.send(:get_available_models)

        expect(models).to be_an(Array)
        expect(models.length).to be > 0

        models.each do |model|
          expect(model).to respond_to(:id)
          expect(model).to respond_to(:name)
          expect(model).to respond_to(:description)
          expect(model).to respond_to(:default?)
        end
      end

      it "includes the default model" do
        models = command.send(:get_available_models)
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
    end
  end
end
