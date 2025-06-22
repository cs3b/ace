# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/anthropic/query"

RSpec.describe CodingAgentTools::Cli::Commands::Anthropic::Query do
  let(:command) { described_class.new }
  let(:anthropic_client) { instance_double(CodingAgentTools::Organisms::AnthropicClient) }
  let(:prompt) { "What is Ruby?" }
  let(:response) do
    {
      text: "Ruby is a dynamic programming language.",
      finish_reason: "stop",
      usage_metadata: {"input_tokens" => 10, "output_tokens" => 20}
    }
  end

  before do
    # Mock the organisms
    allow(CodingAgentTools::Organisms::AnthropicClient).to receive(:new).and_return(anthropic_client)

    # Set up default environment
    ENV["ANTHROPIC_API_KEY"] = "test-api-key"

    # Mock other dependencies
    allow(CodingAgentTools::Molecules::FileIoHandler).to receive(:new).and_return(
      double("file_handler", read_content: prompt)
    )
    allow(CodingAgentTools::Molecules::MetadataNormalizer).to receive(:normalize).and_return({
      finish_reason: "stop",
      input_tokens: 10,
      output_tokens: 20,
      took: 1.5,
      provider: "anthropic",
      model: "claude-3-5-sonnet-20241022",
      timestamp: "2024-01-01T00:00:00Z"
    })
    allow(CodingAgentTools::Molecules::FormatHandlers).to receive(:get_handler).and_return(
      double("handler", format: "Ruby is a dynamic programming language.")
    )
    allow(anthropic_client).to receive(:generate_text).and_return(response)
    allow($stdout).to receive(:puts) # Suppress output for tests
  end

  after do
    ENV.delete("ANTHROPIC_API_KEY")
  end

  describe "#call" do
    context "with timeout parameter" do
      it "passes timeout to AnthropicClient" do
        expect(CodingAgentTools::Organisms::AnthropicClient).to receive(:new).with(
          hash_including(timeout: 60)
        ).and_return(anthropic_client)

        command.call(prompt: prompt, timeout: 60)
      end

      it "uses default timeout when not specified" do
        expect(CodingAgentTools::Organisms::AnthropicClient).to receive(:new).with(
          no_args
        ).and_return(anthropic_client)

        command.call(prompt: prompt)
      end

      it "handles custom timeout value" do
        expect(CodingAgentTools::Organisms::AnthropicClient).to receive(:new).with(
          hash_including(timeout: 120)
        ).and_return(anthropic_client)

        command.call(prompt: prompt, timeout: 120)
      end

      it "passes timeout with other options" do
        expect(CodingAgentTools::Organisms::AnthropicClient).to receive(:new).with(
          hash_including(model: "claude-3-opus-20240229", timeout: 90)
        ).and_return(anthropic_client)

        command.call(prompt: prompt, model: "claude-3-opus-20240229", timeout: 90)
      end
    end

    context "with valid prompt" do
      it "queries Anthropic and outputs response" do
        expect(anthropic_client).to receive(:generate_text).with(
          prompt
        ).and_return(response)

        expect { command.call(prompt: prompt) }.to output("Ruby is a dynamic programming language.\n").to_stdout
      end
    end

    context "with custom model" do
      it "passes model to client" do
        expect(CodingAgentTools::Organisms::AnthropicClient).to receive(:new).with(
          hash_including(model: "claude-3-haiku-20240307")
        ).and_return(anthropic_client)

        command.call(prompt: prompt, model: "claude-3-haiku-20240307")
      end
    end

    context "with generation options" do
      before do
        file_handler = double("file_handler")
        allow(CodingAgentTools::Molecules::FileIoHandler).to receive(:new).and_return(file_handler)
        allow(file_handler).to receive(:read_content).with("Test", auto_detect: true).and_return("Test")
        allow(file_handler).to receive(:read_content).with("You are a helpful assistant", auto_detect: true).and_return("You are a helpful assistant")
      end

      it "passes temperature and max_tokens" do
        expect(anthropic_client).to receive(:generate_text).with(
          "Test",
          generation_config: {temperature: 0.5, max_tokens: 1000}
        ).and_return(response)

        command.call(prompt: "Test", temperature: 0.5, max_tokens: 1000)
      end

      it "passes system instruction" do
        expect(anthropic_client).to receive(:generate_text).with(
          "Test",
          system_instruction: "You are a helpful assistant"
        ).and_return(response)

        command.call(prompt: "Test", system: "You are a helpful assistant")
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
      expect(described_class.description).to eq("Query Anthropic Claude API with a prompt")
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
