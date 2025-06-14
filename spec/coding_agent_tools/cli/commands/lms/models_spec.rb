# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/lms/models"

RSpec.describe CodingAgentTools::Cli::Commands::LMS::Models do
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
        expect(output_content).to include("Available LM Studio Models:")
        expect(output_content).to include("Default model")
        expect(output_content).to include("Usage: llm-lmstudio-query")
        # Should contain at least one model
        expect(output_content).to match(/ID: [\w\/-]+/)
        expect(output_content).to match(/Name: /)
        expect(output_content).to match(/Description: /)
      end

      it "shows server information" do
        command.call

        output_content = output.string
        expect(output_content).to include("Note: Models must be loaded in LM Studio before use")
        expect(output_content).to include("http://localhost:1234")
      end
    end

    context "with filter option" do
      it "filters models correctly" do
        command.call(filter: "mistral")

        output_content = output.string
        expect(output_content).to match(/ID: mistralai\/[\w\/-]+/)
      end

      it "is case insensitive" do
        command.call(filter: "MISTRAL")

        output_content = output.string
        expect(output_content).to match(/ID: mistralai\/[\w\/-]+/)
      end

      it "shows no results message when no matches" do
        command.call(filter: "nonexistent")

        output_content = output.string
        expect(output_content).to include("No models found matching the filter criteria")
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
        expect(json_output).to have_key("server_url")
        expect(json_output["default_model"]).not_to be_empty
        expect(json_output["server_url"]).to eq("http://localhost:1234")
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
        command.call(format: "json", filter: "mistral")

        output_content = output.string
        json_output = JSON.parse(output_content)

        expect(json_output["count"]).to be >= 1
        json_output["models"].each do |model|
          expect(model["id"]).to include("mistral")
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
          CodingAgentTools::Molecules::Model.new(id: "mistralai/model-1", name: "Mistral One", description: "First model"),
          CodingAgentTools::Molecules::Model.new(id: "deepseek/model-2", name: "DeepSeek Two", description: "Second model"),
          CodingAgentTools::Molecules::Model.new(id: "qwen/coder-model", name: "Qwen Coder", description: "Coding model")
        ]
      end

      it "returns all models when no filter is provided" do
        result = command.send(:filter_models, models, nil)
        expect(result).to eq(models)
      end

      it "filters by model id" do
        result = command.send(:filter_models, models, "mistralai")
        expect(result.length).to eq(1)
        expect(result.first.id).to eq("mistralai/model-1")
      end

      it "filters by model name" do
        result = command.send(:filter_models, models, "DeepSeek")
        expect(result.length).to eq(1)
        expect(result.first.name).to eq("DeepSeek Two")
      end

      it "filters by description" do
        result = command.send(:filter_models, models, "Coding")
        expect(result.length).to eq(1)
        expect(result.first.description).to eq("Coding model")
      end

      it "is case insensitive" do
        result = command.send(:filter_models, models, "QWEN")
        expect(result.length).to eq(1)
        expect(result.first.name).to eq("Qwen Coder")
      end

      it "returns empty array when no matches" do
        result = command.send(:filter_models, models, "nonexistent")
        expect(result).to be_empty
      end
    end
  end
end
