# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/openai/query"
require "webmock/rspec"

RSpec.describe CodingAgentTools::Cli::Commands::OpenAI::Query do
  let(:command) { described_class.new }
  let(:api_key) { "test-api-key" }
  let(:prompt) { "Test prompt" }
  let(:mock_client) { instance_double(CodingAgentTools::Organisms::OpenAIClient) }
  let(:mock_file_handler) { instance_double(CodingAgentTools::Molecules::FileIoHandler) }
  let(:mock_response) do
    {
      text: "Test response",
      finish_reason: "stop",
      usage_metadata: {"prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30}
    }
  end

  before do
    # Mock environment variable - allow all ENV access but stub specific key
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(api_key)

    # Mock file handler
    allow(CodingAgentTools::Molecules::FileIoHandler).to receive(:new).and_return(mock_file_handler)
    allow(mock_file_handler).to receive(:read_content).with(prompt, auto_detect: true).and_return(prompt)

    # Mock client
    allow(CodingAgentTools::Organisms::OpenAIClient).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:generate_text).and_return(mock_response)

    # Mock metadata normalizer
    allow(CodingAgentTools::Molecules::MetadataNormalizer).to receive(:normalize).and_return({
      provider: "openai",
      model: "gpt-4o",
      execution_time: 1.5
    })

    # Mock format handlers
    allow(CodingAgentTools::Molecules::FormatHandlers).to receive(:get_handler).and_return(
      double("handler", format: "Test response")
    )

    # Suppress stdout during tests
    allow($stdout).to receive(:puts)
  end

  describe "#call" do
    context "with timeout parameter" do
      it "passes timeout to OpenAIClient" do
        expect(CodingAgentTools::Organisms::OpenAIClient).to receive(:new).with(
          hash_including(timeout: 60)
        ).and_return(mock_client)

        command.call(prompt: prompt, timeout: 60)
      end

      it "uses default timeout when not specified" do
        expect(CodingAgentTools::Organisms::OpenAIClient).to receive(:new).with(
          no_args
        ).and_return(mock_client)

        command.call(prompt: prompt)
      end

      it "handles custom timeout value" do
        expect(CodingAgentTools::Organisms::OpenAIClient).to receive(:new).with(
          hash_including(timeout: 120)
        ).and_return(mock_client)

        command.call(prompt: prompt, timeout: 120)
      end
    end

    context "with valid prompt" do
      it "queries OpenAI and outputs response" do
        expect(mock_client).to receive(:generate_text).with(
          prompt
        ).and_return(mock_response)

        result = command.call(prompt: prompt)
        expect(result).to be_a(Hash)
        expect(result[:text]).to eq("Test response")
      end
    end

    context "with custom model" do
      it "passes model to client" do
        expect(CodingAgentTools::Organisms::OpenAIClient).to receive(:new).with(
          hash_including(model: "gpt-3.5-turbo")
        ).and_return(mock_client)

        command.call(prompt: prompt, model: "gpt-3.5-turbo")
      end
    end

    context "with generation options" do
      it "passes temperature and max_tokens" do
        expect(mock_client).to receive(:generate_text).with(
          prompt,
          generation_config: {temperature: 0.5, max_tokens: 1000}
        ).and_return(mock_response)

        command.call(prompt: prompt, temperature: 0.5, max_tokens: 1000)
      end

      it "passes system instruction" do
        system_text = "You are a helpful assistant"
        allow(mock_file_handler).to receive(:read_content).with(system_text, auto_detect: true).and_return(system_text)

        expect(mock_client).to receive(:generate_text).with(
          prompt,
          system_instruction: system_text
        ).and_return(mock_response)

        command.call(prompt: prompt, system: system_text)
      end
    end

    context "with timeout and other options combined" do
      it "passes all options correctly" do
        system_text = "You are a helpful assistant"
        allow(mock_file_handler).to receive(:read_content).with(system_text, auto_detect: true).and_return(system_text)

        expect(CodingAgentTools::Organisms::OpenAIClient).to receive(:new).with(
          hash_including(
            model: "gpt-4o-mini",
            timeout: 90
          )
        ).and_return(mock_client)

        expect(mock_client).to receive(:generate_text).with(
          prompt,
          system_instruction: system_text,
          generation_config: {temperature: 0.8, max_tokens: 2000}
        ).and_return(mock_response)

        command.call(
          prompt: prompt,
          model: "gpt-4o-mini",
          temperature: 0.8,
          max_tokens: 2000,
          system: system_text,
          timeout: 90
        )
      end
    end

    context "with error handling" do
      it "handles errors gracefully without debug" do
        allow(mock_client).to receive(:generate_text).and_raise(StandardError.new("API Error"))

        expect {
          expect { command.call(prompt: prompt) }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
        }.to output(/Error: Failed to query OpenAI: API Error/).to_stderr
      end

      it "handles errors with debug information" do
        allow(mock_client).to receive(:generate_text).and_raise(StandardError.new("API Error"))

        expect {
          expect { command.call(prompt: prompt, debug: true) }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
        }.to output(/Error: CodingAgentTools::Error: Failed to query OpenAI: API Error/).to_stderr
      end
    end

    context "with empty prompt" do
      it "exits with error for nil prompt" do
        expect {
          expect { command.call(prompt: nil) }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
        }.to output(/Error: Prompt is required/).to_stderr
      end

      it "exits with error for empty prompt" do
        expect {
          expect { command.call(prompt: "") }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
        }.to output(/Error: Prompt is required/).to_stderr
      end

      it "exits with error for whitespace-only prompt" do
        expect {
          expect { command.call(prompt: "   ") }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
        }.to output(/Error: Prompt is required/).to_stderr
      end
    end
  end

  describe "command metadata" do
    it "has correct description" do
      expect(described_class.new.description).to eq("Query OpenAI API with a prompt")
    end

    it "has timeout option defined" do
      # Test that the command responds to the timeout option by checking if it's in examples
      examples = described_class.examples
      timeout_example = examples.find { |example| example.include?("--timeout") }
      expect(timeout_example).not_to be_nil
      expect(timeout_example).to include("--timeout 60")
    end
  end
end
