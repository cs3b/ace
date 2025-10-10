# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/llm/query"

RSpec.describe CodingAgentTools::Cli::Commands::LLM::Query do
  let(:command) { described_class.new }
  let(:mock_file_handler) { instance_double(CodingAgentTools::Molecules::FileIoHandler) }
  let(:mock_google_client) { instance_double(CodingAgentTools::Organisms::GoogleClient) }
  let(:mock_anthropic_client) { instance_double(CodingAgentTools::Organisms::AnthropicClient) }
  let(:mock_openai_client) { instance_double(CodingAgentTools::Organisms::OpenaiClient) }
  let(:mock_mistral_client) { instance_double(CodingAgentTools::Organisms::MistralClient) }
  let(:mock_together_ai_client) { instance_double(CodingAgentTools::Organisms::TogetheraiClient) }
  let(:mock_lmstudio_client) { instance_double(CodingAgentTools::Organisms::LmstudioClient) }
  let(:mock_format_handler) { instance_double(CodingAgentTools::Molecules::FormatHandlers::Text) }
  let(:mock_response) { {text: "Mock response", metadata: {}} }
  let(:mock_normalized_response) { {text: "Mock response", metadata: {provider: "google", model: "gemini-2.0-flash-lite"}} }

  before do
    # Mock file handler
    allow(CodingAgentTools::Molecules::FileIoHandler).to receive(:new).and_return(mock_file_handler)
    allow(mock_file_handler).to receive(:read_content).and_return("test prompt")

    # Mock clients
    allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_google_client)
    allow(CodingAgentTools::Organisms::AnthropicClient).to receive(:new).and_return(mock_anthropic_client)
    allow(CodingAgentTools::Organisms::OpenaiClient).to receive(:new).and_return(mock_openai_client)
    allow(CodingAgentTools::Organisms::MistralClient).to receive(:new).and_return(mock_mistral_client)
    allow(CodingAgentTools::Organisms::TogetheraiClient).to receive(:new).and_return(mock_together_ai_client)
    allow(CodingAgentTools::Organisms::LmstudioClient).to receive(:new).and_return(mock_lmstudio_client)

    # Mock client generate_text methods
    [mock_google_client, mock_anthropic_client, mock_openai_client,
      mock_mistral_client, mock_together_ai_client, mock_lmstudio_client].each do |client|
      allow(client).to receive(:generate_text).and_return(mock_response)
    end

    # Mock metadata normalizer and cost tracker
    allow(CodingAgentTools::CostTracker).to receive(:new).and_return(double("CostTracker"))
    mock_usage_metadata = double("UsageMetadata",
      to_h: mock_normalized_response[:metadata],
      input_tokens: 100,
      output_tokens: 50,
      cached?: false,
      cached_tokens: 0,
      has_cost_info?: false,
      cost_summary: "Cost info unavailable")
    allow(CodingAgentTools::Molecules::MetadataNormalizer).to receive(:normalize_with_cost).and_return(mock_usage_metadata)

    # Mock format handlers
    allow(CodingAgentTools::Molecules::FormatHandlers).to receive(:get_handler).and_return(mock_format_handler)
    allow(mock_format_handler).to receive(:format).and_return("formatted response")
    allow(mock_format_handler).to receive(:generate_summary).and_return("summary")

    # Mock stdout
    allow($stdout).to receive(:puts)

    # Suppress error output during tests
    allow(command).to receive(:error_output)
  end

  describe "#call" do
    context "with valid provider:model syntax" do
      it "queries google provider correctly" do
        expect(CodingAgentTools::Organisms::GoogleClient).to receive(:new).with(model: "gemini-2.5-flash")
        expect(mock_google_client).to receive(:generate_text).with("test prompt")

        result = command.call(provider_model: "google:gemini-2.5-flash", prompt: "test prompt")
        expect(result).to eq(0)
      end

      it "queries anthropic provider correctly" do
        expect(CodingAgentTools::Organisms::AnthropicClient).to receive(:new).with(model: "claude-sonnet-4-20250514")
        expect(mock_anthropic_client).to receive(:generate_text).with("test prompt")

        command.call(provider_model: "anthropic:claude-sonnet-4-20250514", prompt: "test prompt")
      end

      it "queries openai provider correctly" do
        expect(CodingAgentTools::Organisms::OpenaiClient).to receive(:new).with(model: "gpt-4o")
        expect(mock_openai_client).to receive(:generate_text).with("test prompt")

        command.call(provider_model: "openai:gpt-4o", prompt: "test prompt")
      end

      it "queries mistral provider correctly" do
        expect(CodingAgentTools::Organisms::MistralClient).to receive(:new).with(model: "mistral-large")
        expect(mock_mistral_client).to receive(:generate_text).with("test prompt")

        command.call(provider_model: "mistral:mistral-large", prompt: "test prompt")
      end

      it "queries together_ai provider correctly" do
        expect(CodingAgentTools::Organisms::TogetheraiClient).to receive(:new).with(model: "meta-llama/Llama-2-7b-chat-hf")
        expect(mock_together_ai_client).to receive(:generate_text).with("test prompt")

        command.call(provider_model: "together_ai:meta-llama/Llama-2-7b-chat-hf", prompt: "test prompt")
      end

      it "queries lmstudio provider correctly" do
        expect(CodingAgentTools::Organisms::LmstudioClient).to receive(:new).with(model: "local-model")
        expect(mock_lmstudio_client).to receive(:generate_text).with("test prompt")

        command.call(provider_model: "lmstudio:local-model", prompt: "test prompt")
      end

      it "passes timeout option to client" do
        expect(CodingAgentTools::Organisms::GoogleClient).to receive(:new).with(model: "gemini-2.5-flash", timeout: 30)

        command.call(provider_model: "google:gemini-2.5-flash", prompt: "test prompt", timeout: 30)
      end
    end

    context "with provider-only syntax (using default models)" do
      it "uses default model for google" do
        expect(CodingAgentTools::Organisms::GoogleClient).to receive(:new).with(model: "gemini-2.0-flash-lite")

        result = command.call(provider_model: "google", prompt: "test prompt")
        expect(result).to eq(0)
      end

      it "uses default model for anthropic" do
        expect(CodingAgentTools::Organisms::AnthropicClient).to receive(:new).with(model: "claude-3-5-haiku-20241022")

        command.call(provider_model: "anthropic", prompt: "test prompt")
      end

      it "uses default model for openai" do
        expect(CodingAgentTools::Organisms::OpenaiClient).to receive(:new).with(model: "gpt-4o-mini")

        command.call(provider_model: "openai", prompt: "test prompt")
      end

      it "uses default model for mistral" do
        expect(CodingAgentTools::Organisms::MistralClient).to receive(:new).with(model: "open-mistral-nemo")

        command.call(provider_model: "mistral", prompt: "test prompt")
      end

      it "uses default model for together_ai" do
        expect(CodingAgentTools::Organisms::TogetheraiClient).to receive(:new).with(model: "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo")

        command.call(provider_model: "together_ai", prompt: "test prompt")
      end

      it "uses default model for lmstudio" do
        expect(CodingAgentTools::Organisms::LmstudioClient).to receive(:new).with(model: "mistralai/devstral-small-2505")

        command.call(provider_model: "lmstudio", prompt: "test prompt")
      end
    end

    context "with dynamic aliases" do
      it "resolves gflash alias to google:gemini-2.5-flash" do
        expect(CodingAgentTools::Organisms::GoogleClient).to receive(:new).with(model: "gemini-2.5-flash")

        command.call(provider_model: "gflash", prompt: "test prompt")
      end

      it "resolves gpro alias to google:gemini-2.5-pro" do
        expect(CodingAgentTools::Organisms::GoogleClient).to receive(:new).with(model: "gemini-2.5-pro")

        command.call(provider_model: "gpro", prompt: "test prompt")
      end

      it "resolves csonet alias to anthropic:claude-sonnet-4-20250514" do
        expect(CodingAgentTools::Organisms::AnthropicClient).to receive(:new).with(model: "claude-sonnet-4-20250514")

        command.call(provider_model: "csonet", prompt: "test prompt")
      end

      it "resolves copus alias to anthropic:claude-4-0-opus-latest" do
        expect(CodingAgentTools::Organisms::AnthropicClient).to receive(:new).with(model: "claude-4-0-opus-latest")

        command.call(provider_model: "copus", prompt: "test prompt")
      end

      it "resolves o4mini alias to openai:gpt-4o-mini" do
        expect(CodingAgentTools::Organisms::OpenaiClient).to receive(:new).with(model: "gpt-4o-mini")

        command.call(provider_model: "o4mini", prompt: "test prompt")
      end

      it "resolves o3 alias to openai:o3" do
        expect(CodingAgentTools::Organisms::OpenaiClient).to receive(:new).with(model: "o3")

        command.call(provider_model: "o3", prompt: "test prompt")
      end
    end

    context "with generation options" do
      it "passes temperature option with provider-specific conversion for anthropic" do
        expect(mock_anthropic_client).to receive(:generate_text).with(
          "test prompt",
          generation_config: {temperature: 0.7}
        )

        command.call(provider_model: "anthropic:claude-sonnet-4-20250514", prompt: "test prompt", temperature: 0.7)
      end

      it "passes temperature option with provider-specific conversion for openai" do
        expect(mock_openai_client).to receive(:generate_text).with(
          "test prompt",
          generation_config: {temperature: 0.7}
        )

        command.call(provider_model: "openai:gpt-4o", prompt: "test prompt", temperature: 0.7)
      end

      it "passes temperature option for google" do
        expect(mock_google_client).to receive(:generate_text).with(
          "test prompt",
          generation_config: {temperature: 0.7}
        )

        command.call(provider_model: "google:gemini-2.5-flash", prompt: "test prompt", temperature: 0.7)
      end

      it "passes max_tokens with provider-specific naming for google" do
        expect(mock_google_client).to receive(:generate_text).with(
          "test prompt",
          generation_config: {maxOutputTokens: 1000}
        )

        command.call(provider_model: "google:gemini-2.5-flash", prompt: "test prompt", max_tokens: 1000)
      end

      it "passes max_tokens for other providers" do
        expect(mock_openai_client).to receive(:generate_text).with(
          "test prompt",
          generation_config: {max_tokens: 1000}
        )

        command.call(provider_model: "openai:gpt-4o", prompt: "test prompt", max_tokens: 1000)
      end

      it "passes system instruction" do
        allow(mock_file_handler).to receive(:read_content).with("system prompt", auto_detect: true).and_return("processed system")

        expect(mock_google_client).to receive(:generate_text).with(
          "test prompt",
          system_instruction: "processed system"
        )

        command.call(provider_model: "google:gemini-2.5-flash", prompt: "test prompt", system: "system prompt")
      end
    end

    context "with output options" do
      it "outputs to stdout with text format by default" do
        expect($stdout).to receive(:puts).with("formatted response")

        result = command.call(provider_model: "google:gemini-2.5-flash", prompt: "test prompt")
        expect(result).to eq(0)
      end

      it "outputs to file when specified" do
        allow(mock_file_handler).to receive(:validate_write_path).and_return("output.json")
        allow(mock_file_handler).to receive(:write_content)
        allow(mock_file_handler).to receive(:infer_format_from_path).and_return("json")
        expect($stdout).to receive(:puts).with("summary")

        command.call(provider_model: "google:gemini-2.5-flash", prompt: "test prompt", output: "output.json")
      end

      it "respects format option" do
        expect(CodingAgentTools::Molecules::FormatHandlers).to receive(:get_handler).with("json")

        command.call(provider_model: "google:gemini-2.5-flash", prompt: "test prompt", format: "json")
      end
    end

    context "with invalid input" do
      it "returns error status for unknown provider" do
        result = command.call(provider_model: "unknown:model", prompt: "test prompt")
        expect(result).to eq(1)

        expect(command).to have_received(:error_output).with(/Error: Unknown provider: unknown/)
      end

      it "returns error status for empty prompt" do
        result = command.call(provider_model: "google:gemini-2.5-flash", prompt: "")
        expect(result).to eq(1)

        expect(command).to have_received(:error_output).with("Error: Prompt is required")
      end

      it "returns error status for nil prompt" do
        result = command.call(provider_model: "google:gemini-2.5-flash", prompt: nil)
        expect(result).to eq(1)

        expect(command).to have_received(:error_output).with("Error: Prompt is required")
      end

      it "returns error status for whitespace-only prompt" do
        result = command.call(provider_model: "google:gemini-2.5-flash", prompt: "   ")
        expect(result).to eq(1)

        expect(command).to have_received(:error_output).with("Error: Prompt is required")
      end

      it "shows helpful error information" do
        result = command.call(provider_model: "unknown:model", prompt: "test prompt")
        expect(result).to eq(1)

        expect(command).to have_received(:error_output).with(/Supported providers:/).at_least(:once)
        expect(command).to have_received(:error_output).with(/Available aliases:/).at_least(:once)
        expect(command).to have_received(:error_output).with(/Examples:/).at_least(:once)
      end
    end

    context "error handling" do
      it "handles client errors without debug" do
        allow(mock_google_client).to receive(:generate_text).and_raise(StandardError.new("API error"))

        result = command.call(provider_model: "google:gemini-2.5-flash", prompt: "test prompt")
        expect(result).to eq(1)

        expect(command).to have_received(:error_output).with(/Error: Failed to query google: API error/)
        expect(command).to have_received(:error_output).with("Use --debug flag for more information")
      end

      it "handles client errors with debug" do
        allow(mock_google_client).to receive(:generate_text).and_raise(StandardError.new("API error"))

        result = command.call(provider_model: "google:gemini-2.5-flash", prompt: "test prompt", debug: true)
        expect(result).to eq(1)

        expect(command).to have_received(:error_output).with(/Error: CodingAgentTools::Error: Failed to query google: API error/)
        expect(command).to have_received(:error_output).with("\nBacktrace:")
      end

      it "handles file processing errors" do
        allow(mock_file_handler).to receive(:read_content).and_raise(CodingAgentTools::Error.new("File not found"))

        result = command.call(provider_model: "google:gemini-2.5-flash", prompt: "nonexistent.txt")
        expect(result).to eq(1)

        expect(command).to have_received(:error_output).with(/Error: File not found/)
      end
    end
  end

  describe "command metadata" do
    it "has correct description" do
      expect(described_class.description).to eq("Query any LLM provider")
    end

    it "has correct arguments" do
      arguments = described_class.arguments
      argument_names = arguments.map(&:name)
      expect(argument_names).to include(:provider_model)
      expect(argument_names).to include(:prompt)

      provider_model_arg = arguments.find { |arg| arg.name == :provider_model }
      prompt_arg = arguments.find { |arg| arg.name == :prompt }
      expect(provider_model_arg.options[:required]).to be true
      expect(prompt_arg.options[:required]).to be true
    end

    it "has correct options" do
      options = described_class.options
      option_names = options.map(&:name)
      expect(option_names).to include(:output)
      expect(option_names).to include(:format)
      expect(option_names).to include(:debug)
      expect(option_names).to include(:temperature)
      expect(option_names).to include(:max_tokens)
      expect(option_names).to include(:system)
      expect(option_names).to include(:timeout)
    end

    it "has comprehensive examples" do
      examples = described_class.examples
      expect(examples).not_to be_empty
      expect(examples).to include(match(/google:gemini-2.5-flash/))
      expect(examples).to include(match(/google.*uses default model/))
      expect(examples).to include(match(/gflash.*alias/))
      expect(examples).to include(match(/csonet.*alias/))
      expect(examples).to include(match(/o4mini.*alias/))
      expect(examples).to include(match(/lmstudio/))
      expect(examples).to include(match(/mistral/))
    end
  end
end
