# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/llm/unified_query"
require "coding_agent_tools/cli/commands/google/query"
require "coding_agent_tools/cli/commands/anthropic/query"
require "coding_agent_tools/cli/commands/openai/query"
require "coding_agent_tools/cli/commands/mistral/query"
require "coding_agent_tools/cli/commands/together_ai/query"
require "coding_agent_tools/cli/commands/lms/query"

RSpec.describe CodingAgentTools::Cli::Commands::LLM::UnifiedQuery do
  let(:command) { described_class.new }
  let(:mock_google_command) { instance_double(CodingAgentTools::Cli::Commands::Google::Query) }
  let(:mock_anthropic_command) { instance_double(CodingAgentTools::Cli::Commands::Anthropic::Query) }
  let(:mock_openai_command) { instance_double(CodingAgentTools::Cli::Commands::OpenAI::Query) }
  let(:mock_mistral_command) { instance_double(CodingAgentTools::Cli::Commands::Mistral::Query) }
  let(:mock_together_ai_command) { instance_double(CodingAgentTools::Cli::Commands::TogetherAI::Query) }
  let(:mock_lms_command) { instance_double(CodingAgentTools::Cli::Commands::LMS::Query) }

  before do
    # Mock the provider command classes
    allow(CodingAgentTools::Cli::Commands::Google::Query).to receive(:new).and_return(mock_google_command)
    allow(CodingAgentTools::Cli::Commands::Anthropic::Query).to receive(:new).and_return(mock_anthropic_command)
    allow(CodingAgentTools::Cli::Commands::OpenAI::Query).to receive(:new).and_return(mock_openai_command)
    allow(CodingAgentTools::Cli::Commands::Mistral::Query).to receive(:new).and_return(mock_mistral_command)
    allow(CodingAgentTools::Cli::Commands::TogetherAI::Query).to receive(:new).and_return(mock_together_ai_command)
    allow(CodingAgentTools::Cli::Commands::LMS::Query).to receive(:new).and_return(mock_lms_command)

    # Mock the call methods to avoid actual API calls
    allow(mock_google_command).to receive(:call)
    allow(mock_anthropic_command).to receive(:call)
    allow(mock_openai_command).to receive(:call)
    allow(mock_mistral_command).to receive(:call)
    allow(mock_together_ai_command).to receive(:call)
    allow(mock_lms_command).to receive(:call)

    # Suppress error output during tests
    allow(command).to receive(:error_output)
  end

  describe "#call" do
    context "with valid provider:model syntax" do
      it "routes google provider correctly" do
        expect(mock_google_command).to receive(:call).with(
          prompt: "test prompt",
          model: "gemini-2.5-flash"
        )

        expect { command.call(provider_model: "google:gemini-2.5-flash", prompt: "test prompt") }
          .not_to raise_error
      end

      it "routes anthropic provider correctly" do
        expect(mock_anthropic_command).to receive(:call).with(
          prompt: "test prompt",
          model: "claude-4-0-sonnet-latest"
        )

        expect { command.call(provider_model: "anthropic:claude-4-0-sonnet-latest", prompt: "test prompt") }
          .not_to raise_error
      end

      it "routes openai provider correctly" do
        expect(mock_openai_command).to receive(:call).with(
          prompt: "test prompt",
          model: "gpt-4o"
        )

        expect { command.call(provider_model: "openai:gpt-4o", prompt: "test prompt") }
          .not_to raise_error
      end

      it "routes mistral provider correctly" do
        expect(mock_mistral_command).to receive(:call).with(
          prompt: "test prompt",
          model: "mistral-large-latest"
        )

        expect { command.call(provider_model: "mistral:mistral-large-latest", prompt: "test prompt") }
          .not_to raise_error
      end

      it "routes together_ai provider correctly" do
        expect(mock_together_ai_command).to receive(:call).with(
          prompt: "test prompt",
          model: "meta-llama/Llama-2-7b-chat-hf"
        )

        expect { command.call(provider_model: "together_ai:meta-llama/Llama-2-7b-chat-hf", prompt: "test prompt") }
          .not_to raise_error
      end

      it "routes lmstudio provider correctly" do
        expect(mock_lms_command).to receive(:call).with(
          prompt: "test prompt",
          model: "local-model"
        )

        expect { command.call(provider_model: "lmstudio:local-model", prompt: "test prompt") }
          .not_to raise_error
      end

      it "passes through additional options" do
        expect(mock_google_command).to receive(:call).with(
          prompt: "test prompt",
          model: "gemini-2.5-flash",
          temperature: 0.7,
          max_tokens: 1000,
          format: "json",
          output: "output.json",
          system: "system prompt",
          timeout: 30,
          debug: true
        )

        command.call(
          provider_model: "google:gemini-2.5-flash",
          prompt: "test prompt",
          temperature: 0.7,
          max_tokens: 1000,
          format: "json",
          output: "output.json",
          system: "system prompt",
          timeout: 30,
          debug: true
        )
      end
    end

    context "with dynamic aliases" do
      it "resolves gflash alias" do
        expect(mock_google_command).to receive(:call).with(
          prompt: "test prompt",
          model: "gemini-2.5-flash"
        )

        command.call(provider_model: "gflash", prompt: "test prompt")
      end

      it "resolves gpro alias" do
        expect(mock_google_command).to receive(:call).with(
          prompt: "test prompt",
          model: "gemini-2.5-pro"
        )

        command.call(provider_model: "gpro", prompt: "test prompt")
      end

      it "resolves csonet alias" do
        expect(mock_anthropic_command).to receive(:call).with(
          prompt: "test prompt",
          model: "claude-4-0-sonnet-latest"
        )

        command.call(provider_model: "csonet", prompt: "test prompt")
      end

      it "resolves copus alias" do
        expect(mock_anthropic_command).to receive(:call).with(
          prompt: "test prompt",
          model: "claude-4-0-opus-latest"
        )

        command.call(provider_model: "copus", prompt: "test prompt")
      end

      it "resolves o4mini alias" do
        expect(mock_openai_command).to receive(:call).with(
          prompt: "test prompt",
          model: "gpt-4o-mini"
        )

        command.call(provider_model: "o4mini", prompt: "test prompt")
      end

      it "resolves o3 alias" do
        expect(mock_openai_command).to receive(:call).with(
          prompt: "test prompt",
          model: "o3"
        )

        command.call(provider_model: "o3", prompt: "test prompt")
      end
    end

    context "with invalid input" do
      it "exits with error for invalid provider:model syntax" do
        expect { command.call(provider_model: "invalid-format", prompt: "test prompt") }
          .to raise_error(SystemExit)

        expect(command).to have_received(:error_output).with("Error: Invalid format. Expected 'provider:model' or alias")
      end

      it "exits with error for unknown provider" do
        expect { command.call(provider_model: "unknown:model", prompt: "test prompt") }
          .to raise_error(SystemExit)

        expect(command).to have_received(:error_output).with(/Error: Unknown provider: unknown/)
      end

      it "exits with error for empty prompt" do
        expect { command.call(provider_model: "google:gemini-2.5-flash", prompt: "") }
          .to raise_error(SystemExit)

        expect(command).to have_received(:error_output).with("Error: Prompt is required")
      end

      it "exits with error for nil prompt" do
        expect { command.call(provider_model: "google:gemini-2.5-flash", prompt: nil) }
          .to raise_error(SystemExit)

        expect(command).to have_received(:error_output).with("Error: Prompt is required")
      end

      it "exits with error for whitespace-only prompt" do
        expect { command.call(provider_model: "google:gemini-2.5-flash", prompt: "   ") }
          .to raise_error(SystemExit)

        expect(command).to have_received(:error_output).with("Error: Prompt is required")
      end

      it "shows supported providers and aliases on error" do
        expect { command.call(provider_model: "unknown:model", prompt: "test prompt") }
          .to raise_error(SystemExit)

        expect(command).to have_received(:error_output).with(/Supported providers:/).at_least(:once)
        expect(command).to have_received(:error_output).with(/Available aliases:/).at_least(:once)
      end
    end

    context "error handling" do
      it "handles exceptions from provider commands without debug" do
        allow(mock_google_command).to receive(:call).and_raise(StandardError.new("API error"))

        expect { command.call(provider_model: "google:gemini-2.5-flash", prompt: "test prompt") }
          .to raise_error(SystemExit)

        expect(command).to have_received(:error_output).with("Error: API error")
        expect(command).to have_received(:error_output).with("Use --debug flag for more information")
      end

      it "handles exceptions from provider commands with debug" do
        allow(mock_google_command).to receive(:call).and_raise(StandardError.new("API error"))

        expect { command.call(provider_model: "google:gemini-2.5-flash", prompt: "test prompt", debug: true) }
          .to raise_error(SystemExit)

        expect(command).to have_received(:error_output).with("Error: StandardError: API error")
        expect(command).to have_received(:error_output).with("\nBacktrace:")
      end
    end
  end

  describe "command metadata" do
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

    it "has examples" do
      examples = described_class.examples
      expect(examples).not_to be_empty
      expect(examples).to include(match(/google:gemini-2.5-flash/))
      expect(examples).to include(match(/gflash/))
      expect(examples).to include(match(/csonet/))
    end
  end
end
