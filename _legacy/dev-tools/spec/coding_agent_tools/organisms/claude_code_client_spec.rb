# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/organisms/claude_code_client"

RSpec.describe CodingAgentTools::Organisms::ClaudeCodeClient do
  let(:client) { described_class.new }
  let(:mock_success_response) do
    {
      "type" => "result",
      "result" => "Hello from Claude!",
      "usage" => {
        "input_tokens" => 10,
        "output_tokens" => 5,
        "cache_read_input_tokens" => 100
      },
      "total_cost_usd" => 0.00123,
      "session_id" => "test-session-123",
      "duration_ms" => 1500,
      "uuid" => "test-uuid-456"
    }.to_json
  end

  describe ".provider_name" do
    it "returns 'cc'" do
      expect(described_class.provider_name).to eq("cc")
    end
  end

  describe ".dynamic_aliases" do
    it "returns empty hash (no aliases)" do
      expect(described_class.dynamic_aliases).to eq({})
    end
  end

  describe "#initialize" do
    it "defaults to sonnet model" do
      expect(client.instance_variable_get(:@model)).to eq("sonnet")
    end

    it "accepts custom model" do
      client = described_class.new(model: "opus")
      expect(client.instance_variable_get(:@model)).to eq("opus")
    end

    it "normalizes model names" do
      client = described_class.new(model: "opus-4")
      expect(client.instance_variable_get(:@model)).to eq("opus")
    end
  end

  describe "#generate_text" do
    context "when Claude CLI is not available" do
      before do
        allow(client).to receive(:claude_available?).and_return(false)
      end

      it "returns error about missing CLI" do
        result = client.generate_text("test prompt")
        expect(result).to be_failure
        expect(result.error).to include("Claude CLI not found")
        expect(result.error).to include("npm install -g @anthropic-ai/claude-cli")
      end
    end

    context "when Claude CLI is available but not authenticated" do
      before do
        allow(client).to receive(:claude_available?).and_return(true)
        allow(client).to receive(:claude_authenticated?).and_return(false)
      end

      it "returns error about authentication" do
        result = client.generate_text("test prompt")
        expect(result).to be_failure
        expect(result.error).to include("Claude authentication required")
        expect(result.error).to include("claude setup-token")
      end
    end

    context "when Claude CLI is available and authenticated" do
      before do
        allow(client).to receive(:claude_available?).and_return(true)
        allow(client).to receive(:claude_authenticated?).and_return(true)
      end

      context "with successful response" do
        before do
          allow(Open3).to receive(:capture3).and_return([
            mock_success_response,
            "",
            double(success?: true)
          ])
        end

        it "returns successful result with text" do
          result = client.generate_text("test prompt")
          expect(result).to be_success
          expect(result.data).to eq("Hello from Claude!")
        end

        it "includes metadata" do
          result = client.generate_text("test prompt")
          metadata = result.metadata
          
          expect(metadata[:provider]).to eq("cc")
          expect(metadata[:model]).to eq("sonnet")
          expect(metadata[:input_tokens]).to eq(10)
          expect(metadata[:output_tokens]).to eq(5)
          expect(metadata[:total_tokens]).to eq(15)
          expect(metadata[:cached_tokens]).to eq(100)
          expect(metadata[:took]).to eq(1.5)
        end

        it "includes cost information" do
          result = client.generate_text("test prompt")
          cost = result.metadata[:cost]
          
          expect(cost[:total_cost]).to eq(0.00123)
          expect(cost[:currency]).to eq("USD")
        end

        it "includes session ID" do
          result = client.generate_text("test prompt")
          expect(result.metadata[:session_id]).to eq("test-session-123")
        end

        it "includes provider-specific data" do
          result = client.generate_text("test prompt")
          provider_data = result.metadata[:provider_specific]
          
          expect(provider_data[:uuid]).to eq("test-uuid-456")
        end
      end

      context "with system instruction" do
        it "passes system instruction to Claude" do
          expect(Open3).to receive(:capture3).with(
            "claude", "-p", "test", "--output-format", "json",
            "--system", "You are a helpful assistant"
          ).and_return([mock_success_response, "", double(success?: true)])
          
          client.generate_text("test", system: "You are a helpful assistant")
        end
      end

      context "with temperature" do
        it "passes temperature to Claude" do
          expect(Open3).to receive(:capture3).with(
            "claude", "-p", "test", "--output-format", "json",
            "--temperature", "0.7"
          ).and_return([mock_success_response, "", double(success?: true)])
          
          client.generate_text("test", temperature: 0.7)
        end
      end

      context "with max_tokens" do
        it "passes max_tokens to Claude" do
          expect(Open3).to receive(:capture3).with(
            "claude", "-p", "test", "--output-format", "json",
            "--max-tokens", "1000"
          ).and_return([mock_success_response, "", double(success?: true)])
          
          client.generate_text("test", max_tokens: 1000)
        end
      end

      context "with file input" do
        let(:temp_file) { Tempfile.new(["prompt", ".txt"]) }
        
        before do
          temp_file.write("File content prompt")
          temp_file.close
        end
        
        after do
          temp_file.unlink
        end

        it "reads content from file" do
          expect(Open3).to receive(:capture3).with(
            "claude", "-p", "File content prompt", "--output-format", "json"
          ).and_return([mock_success_response, "", double(success?: true)])
          
          client.generate_text(temp_file.path)
        end
      end

      context "with custom model" do
        let(:client) { described_class.new(model: "opus") }

        it "passes model to Claude" do
          expect(Open3).to receive(:capture3).with(
            "claude", "-p", "test", "--output-format", "json",
            "--model", "opus"
          ).and_return([mock_success_response, "", double(success?: true)])
          
          client.generate_text("test")
        end
      end

      context "when Claude returns error" do
        before do
          allow(Open3).to receive(:capture3).and_return([
            "",
            "Error: Invalid request",
            double(success?: false)
          ])
        end

        it "returns failure with error message" do
          result = client.generate_text("test")
          expect(result).to be_failure
          expect(result.error).to include("Claude CLI failed")
          expect(result.error).to include("Invalid request")
        end
      end

      context "when Claude returns invalid JSON" do
        before do
          allow(Open3).to receive(:capture3).and_return([
            "Not valid JSON",
            "",
            double(success?: true)
          ])
        end

        it "returns failure with parse error" do
          result = client.generate_text("test")
          expect(result).to be_failure
          expect(result.error).to include("Failed to parse Claude response")
        end
      end

      context "when Claude times out" do
        before do
          allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
        end

        it "returns timeout error" do
          result = client.generate_text("test")
          expect(result).to be_failure
          expect(result.error).to include("timed out")
        end
      end
    end
  end

  describe "#list_models" do
    context "when Claude CLI is available" do
      before do
        allow(client).to receive(:claude_available?).and_return(true)
      end

      it "returns available models" do
        result = client.list_models
        expect(result).to be_success
        
        models = result.data
        expect(models).to be_an(Array)
        expect(models.size).to be >= 3
        
        model_names = models.map(&:name)
        expect(model_names).to include("opus", "sonnet", "haiku")
      end

      it "includes context sizes" do
        result = client.list_models
        models = result.data
        
        models.each do |model|
          expect(model.context_size).to eq(200_000)
        end
      end

      it "sets provider to cc" do
        result = client.list_models
        models = result.data
        
        models.each do |model|
          expect(model.provider).to eq("cc")
        end
      end
    end

    context "when Claude CLI is not available" do
      before do
        allow(client).to receive(:claude_available?).and_return(false)
      end

      it "returns fallback models" do
        result = client.list_models
        expect(result).to be_success
        
        models = result.data
        expect(models.size).to eq(3)
        
        model_names = models.map(&:name)
        expect(model_names).to eq(%w[opus sonnet haiku])
      end
    end
  end

  describe "private methods" do
    describe "#normalize_model_name" do
      it "maps opus-4 to opus" do
        expect(client.send(:normalize_model_name, "opus-4")).to eq("opus")
      end

      it "maps sonnet-4 to sonnet" do
        expect(client.send(:normalize_model_name, "sonnet-4")).to eq("sonnet")
      end

      it "maps haiku-3 to haiku" do
        expect(client.send(:normalize_model_name, "haiku-3")).to eq("haiku")
      end

      it "returns unmapped names as-is" do
        expect(client.send(:normalize_model_name, "custom")).to eq("custom")
      end
    end

    describe "#model_context_size" do
      it "returns 200k for opus" do
        expect(client.send(:model_context_size, "opus")).to eq(200_000)
      end

      it "returns 200k for sonnet" do
        expect(client.send(:model_context_size, "sonnet")).to eq(200_000)
      end

      it "returns 200k for haiku" do
        expect(client.send(:model_context_size, "haiku")).to eq(200_000)
      end

      it "returns 128k for unknown models" do
        expect(client.send(:model_context_size, "unknown")).to eq(128_000)
      end
    end
  end
end