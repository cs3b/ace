# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Organisms::CodexClient do
  let(:client) { described_class.new }
  let(:model_client) { described_class.new(model: "o3") }

  describe '.provider_name' do
    it 'returns "codex"' do
      expect(described_class.provider_name).to eq('codex')
    end
  end

  describe '#initialize' do
    it 'sets default model' do
      expect(client.instance_variable_get(:@model)).to eq('o3-mini')
    end

    it 'accepts custom model' do
      expect(model_client.instance_variable_get(:@model)).to eq('o3')
    end
  end

  describe '#list_models' do
    context 'when codex is not available' do
      before do
        allow(client).to receive(:codex_available?).and_return(false)
      end

      it 'returns fallback models' do
        models = client.list_models
        expect(models).to all(be_a(CodingAgentTools::Models::LlmModelInfo))
        expect(models.map(&:id)).to include('o3-mini', 'o3', 'gpt-5-mini', 'gpt-5')
      end
    end

    context 'when codex is available' do
      before do
        allow(client).to receive(:codex_available?).and_return(true)
      end

      it 'returns available models' do
        models = client.list_models
        expect(models).to all(be_a(CodingAgentTools::Models::LlmModelInfo))
        expect(models.map(&:id)).to include('o3-mini', 'o3', 'gpt-5-mini', 'gpt-5')
      end
    end
  end

  describe '#generate_text' do
    let(:prompt) { "Hello, world!" }
    
    before do
      allow(client).to receive(:validate_codex_availability!)
    end

    context 'when codex command succeeds' do
      let(:mock_stdout) { "Hello! How can I help you today?" }
      let(:mock_stderr) { "" }
      let(:mock_status) { double(success?: true) }

      before do
        allow(Open3).to receive(:capture3).and_return([mock_stdout, mock_stderr, mock_status])
      end

      it 'returns parsed response' do
        response = client.generate_text(prompt)
        
        expect(response[:text]).to eq("Hello! How can I help you today?")
        expect(response[:finish_reason]).to eq("success")
        expect(response[:usage_metadata]).to include("provider" => "codex")
      end
    end

    context 'when codex command fails' do
      let(:mock_stdout) { "" }
      let(:mock_stderr) { "Authentication failed" }
      let(:mock_status) { double(success?: false) }

      before do
        allow(Open3).to receive(:capture3).and_return([mock_stdout, mock_stderr, mock_status])
      end

      it 'raises an error' do
        expect { client.generate_text(prompt) }.to raise_error(
          CodingAgentTools::Error, /Codex CLI failed: Authentication failed/
        )
      end
    end

    context 'when timeout occurs' do
      before do
        allow(Open3).to receive(:capture3).and_raise(Timeout::Error)
      end

      it 'raises timeout error' do
        expect { client.generate_text(prompt) }.to raise_error(
          CodingAgentTools::Error, /Codex CLI execution timed out/
        )
      end
    end
  end

  describe '#validate_codex_availability!' do
    context 'when codex is not available' do
      before do
        allow(client).to receive(:codex_available?).and_return(false)
      end

      it 'raises availability error' do
        expect { client.send(:validate_codex_availability!) }.to raise_error(
          CodingAgentTools::Error, /Codex CLI not found/
        )
      end
    end

    context 'when codex is available but not authenticated' do
      before do
        allow(client).to receive(:codex_available?).and_return(true)
        allow(client).to receive(:codex_authenticated?).and_return(false)
      end

      it 'raises authentication error' do
        expect { client.send(:validate_codex_availability!) }.to raise_error(
          CodingAgentTools::Error, /Codex authentication required/
        )
      end
    end

    context 'when codex is available and authenticated' do
      before do
        allow(client).to receive(:codex_available?).and_return(true)
        allow(client).to receive(:codex_authenticated?).and_return(true)
      end

      it 'does not raise error' do
        expect { client.send(:validate_codex_availability!) }.not_to raise_error
      end
    end
  end

  describe '#codex_available?' do
    it 'checks for codex command availability' do
      expect(client).to receive(:system).with("which codex > /dev/null 2>&1")
      client.send(:codex_available?)
    end
  end

  describe '#codex_authenticated?' do
    context 'when version command succeeds' do
      before do
        allow(Open3).to receive(:capture3)
          .with("codex", "--version")
          .and_return(["codex version 1.0.0", "", double(success?: true)])
      end

      it 'returns true' do
        expect(client.send(:codex_authenticated?)).to be true
      end
    end

    context 'when version command fails but help succeeds' do
      before do
        allow(Open3).to receive(:capture3)
          .with("codex", "--version")
          .and_raise(StandardError)
        allow(Open3).to receive(:capture3)
          .with("codex", "--help")
          .and_return(["", "", double(success?: true)])
      end

      it 'returns true' do
        expect(client.send(:codex_authenticated?)).to be true
      end
    end

    context 'when both commands fail' do
      before do
        allow(Open3).to receive(:capture3).and_raise(StandardError)
      end

      it 'returns false' do
        expect(client.send(:codex_authenticated?)).to be false
      end
    end
  end

  describe '#build_codex_command' do
    let(:prompt) { "Test prompt" }
    let(:options) { {} }

    it 'builds basic command' do
      cmd = client.send(:build_codex_command, prompt, options)
      expect(cmd).to eq(["codex", "-s", "danger-full-access", "Test prompt"])
    end

    it 'includes model selection for non-default model' do
      cmd = model_client.send(:build_codex_command, prompt, options)
      expect(cmd).to include("-m", "o3")
    end

    it 'includes system prompt when provided' do
      options[:system] = "You are a helpful assistant"
      cmd = client.send(:build_codex_command, prompt, options)
      expect(cmd).to include("--system", "You are a helpful assistant")
    end

    it 'includes temperature when provided' do
      options[:temperature] = 0.7
      cmd = client.send(:build_codex_command, prompt, options)
      expect(cmd).to include("--temperature", "0.7")
    end

    it 'includes max_tokens when provided' do
      options[:max_tokens] = 1000
      cmd = client.send(:build_codex_command, prompt, options)
      expect(cmd).to include("--max-tokens", "1000")
    end
  end

  describe '#normalize_model_name' do
    it 'maps known aliases' do
      expect(client.send(:normalize_model_name, "o3")).to eq("o3")
      expect(client.send(:normalize_model_name, "o3-mini")).to eq("o3-mini")
    end

    it 'passes through unknown models' do
      expect(client.send(:normalize_model_name, "custom-model")).to eq("custom-model")
    end
  end

  describe '#build_synthetic_metadata' do
    let(:response_text) { "This is a response" }
    let(:prompt) { "This is a prompt" }

    it 'creates synthetic usage metadata' do
      metadata = client.send(:build_synthetic_metadata, response_text, prompt)
      
      expect(metadata).to include(
        "provider" => "codex",
        "input_tokens" => 4,  # "This is a prompt".length / 4
        "output_tokens" => 4, # "This is a response".length / 4
        "total_tokens" => 8
      )
    end
  end
end