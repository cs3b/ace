# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Organisms::OpenCodeClient do
  let(:client) { described_class.new }
  let(:model_client) { described_class.new(model: "anthropic/claude-3-5-sonnet") }
  
  describe ".provider_name" do
    it "returns 'oc'" do
      expect(described_class.provider_name).to eq("oc")
    end
  end

  describe ".dynamic_aliases" do
    it "returns opencode alias mapping" do
      aliases = described_class.dynamic_aliases
      expect(aliases).to be_a(Hash)
      expect(aliases["opencode"]).to eq("google/gemini-2.5-flash")
    end
  end

  describe "#initialize" do
    it "initializes with default model" do
      expect(client.instance_variable_get(:@model)).to eq("google/gemini-2.5-flash")
    end

    it "initializes with specified model" do
      expect(model_client.instance_variable_get(:@model)).to eq("anthropic/claude-3-5-sonnet")
    end

    it "doesn't require API credentials" do
      expect(client.instance_variable_get(:@api_key)).to be_nil
    end
  end

  describe "#generate_text" do
    context "when OpenCode CLI is not available" do
      before do
        allow(client).to receive(:opencode_available?).and_return(false)
      end

      it "raises error about missing OpenCode CLI" do
        expect {
          client.generate_text("Hello")
        }.to raise_error(CodingAgentTools::Error, /OpenCode CLI not found/)
      end
    end

    context "when OpenCode CLI is available but not authenticated" do
      before do
        allow(client).to receive(:opencode_available?).and_return(true)
        allow(client).to receive(:opencode_authenticated?).and_return(false)
      end

      it "raises authentication error" do
        expect {
          client.generate_text("Hello")
        }.to raise_error(CodingAgentTools::Error, /OpenCode authentication required/)
      end
    end

    context "when OpenCode CLI is available and authenticated" do
      let(:successful_status) { double("status", success?: true) }
      let(:successful_output) { "This is a response from OpenCode" }

      before do
        allow(client).to receive(:opencode_available?).and_return(true)
        allow(client).to receive(:opencode_authenticated?).and_return(true)
        allow(Open3).to receive(:capture3).and_return([successful_output, "", successful_status])
      end

      it "executes OpenCode command successfully" do
        result = client.generate_text("Hello world")
        
        expect(result).to be_a(Hash)
        expect(result[:text]).to eq(successful_output)
        expect(result[:finish_reason]).to eq("success")
        expect(result[:usage_metadata]).to include(:input_tokens, :output_tokens, :total_tokens)
      end

      it "builds correct command with model" do
        expect(Open3).to receive(:capture3).with(
          "opencode", "run", "--model", "google/gemini-2.5-flash", "Hello world"
        ).and_return([successful_output, "", successful_status])

        client.generate_text("Hello world")
      end

      it "builds correct command with custom model" do
        expect(Open3).to receive(:capture3).with(
          "opencode", "run", "--model", "anthropic/claude-3-5-sonnet", "Hello world"
        ).and_return([successful_output, "", successful_status])

        model_client.generate_text("Hello world")
      end

      it "handles file input" do
        allow(File).to receive(:exist?).with("prompt.txt").and_return(true)
        allow(File).to receive(:read).with("prompt.txt").and_return("File content")
        
        expect(Open3).to receive(:capture3).with(
          "opencode", "run", "--model", "google/gemini-2.5-flash", "File content"
        ).and_return([successful_output, "", successful_status])

        client.generate_text("prompt.txt")
      end
    end

    context "when OpenCode command fails" do
      let(:failed_status) { double("status", success?: false) }
      let(:error_output) { "Model not found error" }

      before do
        allow(client).to receive(:opencode_available?).and_return(true)
        allow(client).to receive(:opencode_authenticated?).and_return(true)
        allow(Open3).to receive(:capture3).and_return(["", error_output, failed_status])
      end

      it "raises error with OpenCode output" do
        expect {
          client.generate_text("Hello")
        }.to raise_error(CodingAgentTools::Error, /OpenCode CLI failed: Model not found error/)
      end

      it "provides specific error for authentication issues" do
        allow(Open3).to receive(:capture3).and_return(["", "authentication failed", failed_status])
        
        expect {
          client.generate_text("Hello")
        }.to raise_error(CodingAgentTools::Error, /OpenCode authentication required/)
      end

      it "provides specific error for model issues" do
        allow(Open3).to receive(:capture3).and_return(["", "model xyz not found", failed_status])
        
        expect {
          client.generate_text("Hello")
        }.to raise_error(CodingAgentTools::Error, /Use provider\/model format/)
      end
    end

    context "when OpenCode command times out" do
      before do
        allow(client).to receive(:opencode_available?).and_return(true)
        allow(client).to receive(:opencode_authenticated?).and_return(true)
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
      end

      it "raises timeout error" do
        expect {
          client.generate_text("Hello")
        }.to raise_error(CodingAgentTools::Error, /execution timed out after 120 seconds/)
      end
    end
  end

  describe "#list_models" do
    context "when OpenCode CLI is not available" do
      before do
        allow(client).to receive(:opencode_available?).and_return(false)
      end

      it "returns fallback models" do
        models = client.list_models
        expect(models).to be_an(Array)
        expect(models.length).to be > 0
        expect(models.first).to be_a(CodingAgentTools::Models::LlmModelInfo)
        expect(models.map(&:id)).to include("google/gemini-2.5-flash")
      end
    end

    context "when OpenCode CLI is available" do
      let(:models_output) do
        <<~OUTPUT
          google/gemini-2.5-flash
          google/gemini-1.5-pro
          anthropic/claude-3-5-sonnet
          anthropic/claude-3-5-haiku
          openai/gpt-4o
          openai/gpt-4o-mini
        OUTPUT
      end
      let(:successful_status) { double("status", success?: true) }

      before do
        allow(client).to receive(:opencode_available?).and_return(true)
        allow(Open3).to receive(:capture3)
          .with("opencode", "models")
          .and_return([models_output, "", successful_status])
      end

      it "returns parsed models from OpenCode" do
        models = client.list_models
        expect(models).to be_an(Array)
        expect(models.length).to eq(6)
        expect(models.map(&:id)).to include(
          "google/gemini-2.5-flash",
          "anthropic/claude-3-5-sonnet",
          "openai/gpt-4o"
        )
      end

      it "creates proper model info objects" do
        models = client.list_models
        model = models.first
        expect(model.id).to be_a(String)
        expect(model.name).to be_a(String)
        expect(model.description).to include("OpenCode model")
        expect(model.context_size).to be_a(Integer)
        expect(model.context_size).to be > 0
      end
    end

    context "when OpenCode models command fails" do
      let(:failed_status) { double("status", success?: false) }

      before do
        allow(client).to receive(:opencode_available?).and_return(true)
        allow(Open3).to receive(:capture3)
          .with("opencode", "models")
          .and_return(["", "auth error", failed_status])
      end

      it "returns fallback models" do
        models = client.list_models
        expect(models).to be_an(Array)
        expect(models.length).to be > 0
        expect(models.first).to be_a(CodingAgentTools::Models::LlmModelInfo)
      end
    end

    context "when OpenCode models command raises exception" do
      before do
        allow(client).to receive(:opencode_available?).and_return(true)
        allow(Open3).to receive(:capture3).and_raise(StandardError.new("Command failed"))
      end

      it "returns fallback models" do
        models = client.list_models
        expect(models).to be_an(Array)
        expect(models.length).to be > 0
        expect(models.first).to be_a(CodingAgentTools::Models::LlmModelInfo)
      end
    end
  end

  describe "private methods" do
    describe "#opencode_available?" do
      it "returns true when opencode command exists" do
        expect(client).to receive(:system).with("which opencode > /dev/null 2>&1").and_return(true)
        expect(client.send(:opencode_available?)).to be true
      end

      it "returns false when opencode command doesn't exist" do
        expect(client).to receive(:system).with("which opencode > /dev/null 2>&1").and_return(false)
        expect(client.send(:opencode_available?)).to be false
      end
    end

    describe "#opencode_authenticated?" do
      it "returns true when models command succeeds" do
        allow(Open3).to receive(:capture3)
          .with("opencode", "models")
          .and_return(["google/gemini-2.5-flash", "", double("status", success?: true)])
        
        expect(client.send(:opencode_authenticated?)).to be true
      end

      it "returns false when models command fails" do
        allow(Open3).to receive(:capture3)
          .with("opencode", "models")
          .and_return(["", "error", double("status", success?: false)])
        
        expect(client.send(:opencode_authenticated?)).to be false
      end

      it "returns false when models command raises exception" do
        allow(Open3).to receive(:capture3).and_raise(StandardError.new("Command failed"))
        
        expect(client.send(:opencode_authenticated?)).to be false
      end
    end

    describe "#estimate_tokens" do
      it "estimates tokens based on character count" do
        expect(client.send(:estimate_tokens, "hello world")).to eq(3) # ~11 chars / 4
        expect(client.send(:estimate_tokens, "a" * 40)).to eq(10) # 40 chars / 4
      end
    end

    describe "#estimate_context_size" do
      it "estimates context size for different model types" do
        expect(client.send(:estimate_context_size, "google/gemini-2.5-flash")).to eq(1_000_000)
        expect(client.send(:estimate_context_size, "anthropic/claude-3-5-sonnet")).to eq(200_000)
        expect(client.send(:estimate_context_size, "openai/gpt-4o")).to eq(128_000)
        expect(client.send(:estimate_context_size, "unknown/model")).to eq(32_000)
      end
    end
  end
end