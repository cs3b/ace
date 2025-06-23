# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/google/query"

RSpec.describe CodingAgentTools::Cli::Commands::Google::Query do
  let(:command) { described_class.new }
  let(:prompt) { "What is Ruby programming language?" }
  let(:output) { StringIO.new }

  # Shared mock objects
  let(:mock_response) do
    {
      text: "Ruby is a dynamic programming language...",
      finish_reason: "STOP",
      usage_metadata: {
        promptTokenCount: 10,
        candidatesTokenCount: 20,
        totalTokenCount: 30
      }
    }
  end

  let(:mock_client) { instance_double(CodingAgentTools::Organisms::GoogleClient) }

  before do
    allow($stdout).to receive(:puts) { |msg| output.puts(msg) }
    allow($stderr).to receive(:puts) { |msg| output.puts(msg) }
  end

  describe "#call" do
    context "with valid prompt" do

      before do
        allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:generate_text).and_return(mock_response)
        allow_any_instance_of(CodingAgentTools::Molecules::FileIoHandler)
          .to receive(:read_content).and_return(prompt)
      end

      it "queries Google API successfully" do
        expect { command.call(prompt: prompt) }.not_to raise_error
      end

      it "creates GoogleClient with default options" do
        expect(CodingAgentTools::Organisms::GoogleClient).to receive(:new).with(no_args)
        command.call(prompt: prompt)
      end

      it "creates GoogleClient with custom model" do
        expect(CodingAgentTools::Organisms::GoogleClient).to receive(:new).with(model: "gemini-pro")
        command.call(prompt: prompt, model: "gemini-pro")
      end

      it "creates GoogleClient with timeout option" do
        expect(CodingAgentTools::Organisms::GoogleClient).to receive(:new).with(timeout: 30)
        command.call(prompt: prompt, timeout: 30)
      end

      it "calls generate_text with prompt" do
        expect(mock_client).to receive(:generate_text).with(prompt)
        command.call(prompt: prompt)
      end

      it "includes system instruction when provided" do
        system_text = "You are a helpful assistant"
        allow_any_instance_of(CodingAgentTools::Molecules::FileIoHandler)
          .to receive(:read_content).with(system_text, auto_detect: true).and_return(system_text)

        expect(mock_client).to receive(:generate_text)
          .with(prompt, system_instruction: system_text)

        command.call(prompt: prompt, system: system_text)
      end

      it "includes generation config when temperature provided" do
        expect(mock_client).to receive(:generate_text)
          .with(prompt, generation_config: { temperature: 0.8 })

        command.call(prompt: prompt, temperature: 0.8)
      end

      it "includes generation config when max_tokens provided" do
        expect(mock_client).to receive(:generate_text)
          .with(prompt, generation_config: { maxOutputTokens: 100 })

        command.call(prompt: prompt, max_tokens: 100)
      end

      it "combines generation config options" do
        expect(mock_client).to receive(:generate_text)
          .with(prompt, generation_config: { temperature: 0.8, maxOutputTokens: 100 })

        command.call(prompt: prompt, temperature: 0.8, max_tokens: 100)
      end
    end

    context "with empty prompt" do
      before do
        # Suppress error output for tests that only check SystemExit
        allow_any_instance_of(described_class).to receive(:error_output)
      end

      it "raises error for empty prompt" do
        expect { command.call(prompt: "") }.to raise_error(SystemExit)
      end

      it "raises error for nil prompt" do
        expect { command.call(prompt: nil) }.to raise_error(SystemExit)
      end

      it "raises error for whitespace-only prompt" do
        expect { command.call(prompt: "   ") }.to raise_error(SystemExit)
      end
    end

    context "with file input" do
      let(:file_path) { "test_prompt.txt" }
      let(:file_content) { "What is machine learning?" }

      before do
        allow_any_instance_of(CodingAgentTools::Molecules::FileIoHandler)
          .to receive(:read_content).with(file_path, auto_detect: true).and_return(file_content)
        allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:generate_text).and_return(mock_response)
      end

      it "reads content from file" do
        expect_any_instance_of(CodingAgentTools::Molecules::FileIoHandler)
          .to receive(:read_content).with(file_path, auto_detect: true)

        command.call(prompt: file_path)
      end

      it "uses file content as prompt" do
        expect(mock_client).to receive(:generate_text).with(file_content)
        command.call(prompt: file_path)
      end
    end

    context "with output formats" do

      before do
        allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:generate_text).and_return(mock_response)
        allow_any_instance_of(CodingAgentTools::Molecules::FileIoHandler)
          .to receive(:read_content).and_return(prompt)

        # Mock the format handlers
        allow(CodingAgentTools::Molecules::FormatHandlers).to receive(:get_handler).and_return(
          double("handler", format: "formatted output", generate_summary: "summary")
        )
      end

      it "outputs text format by default" do
        expect(CodingAgentTools::Molecules::FormatHandlers).to receive(:get_handler).with("text")
        command.call(prompt: prompt)
      end

      it "outputs JSON format when specified" do
        expect(CodingAgentTools::Molecules::FormatHandlers).to receive(:get_handler).with("json")
        command.call(prompt: prompt, format: "json")
      end

      it "outputs markdown format when specified" do
        expect(CodingAgentTools::Molecules::FormatHandlers).to receive(:get_handler).with("markdown")
        command.call(prompt: prompt, format: "markdown")
      end
    end

    context "with file output" do
      let(:output_file) { "response.json" }
      let(:mock_file_handler) { instance_double(CodingAgentTools::Molecules::FileIoHandler) }

      before do
        allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:generate_text).and_return(mock_response)
        allow(CodingAgentTools::Molecules::FileIoHandler).to receive(:new).and_return(mock_file_handler)
        allow(mock_file_handler).to receive(:read_content).and_return(prompt)
        allow(mock_file_handler).to receive(:write_content)
        allow(mock_file_handler).to receive(:infer_format_from_path).and_return("json")
      end

      it "writes output to file" do
        expect(mock_file_handler).to receive(:write_content)
          .with(anything, output_file, format: "json")

        command.call(prompt: prompt, output: output_file)
      end

      it "infers format from file extension" do
        expect(mock_file_handler).to receive(:infer_format_from_path).with(output_file)
        command.call(prompt: prompt, output: output_file)
      end
    end

    context "error handling" do
      before do
        allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
        allow_any_instance_of(CodingAgentTools::Molecules::FileIoHandler)
          .to receive(:read_content).and_return(prompt)
        # Suppress error output for tests that only check SystemExit
        allow_any_instance_of(described_class).to receive(:error_output)
      end

      it "handles Google API errors" do
        allow(mock_client).to receive(:generate_text)
          .and_raise(CodingAgentTools::Error.new("API Error"))

        expect { command.call(prompt: prompt) }.to raise_error(SystemExit)
      end

      it "includes debug information when debug enabled" do
        allow(mock_client).to receive(:generate_text)
          .and_raise(StandardError.new("Test error"))

        expect { command.call(prompt: prompt, debug: true) }.to raise_error(SystemExit)
      end

      it "handles file reading errors" do
        allow_any_instance_of(CodingAgentTools::Molecules::FileIoHandler)
          .to receive(:read_content).and_raise(StandardError.new("File error"))

        expect { command.call(prompt: "nonexistent.txt") }.to raise_error(SystemExit)
      end
    end

    context "metadata normalization" do

      before do
        allow(CodingAgentTools::Organisms::GoogleClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:generate_text).and_return(mock_response)
        allow_any_instance_of(CodingAgentTools::Molecules::FileIoHandler)
          .to receive(:read_content).and_return(prompt)

        # Mock the metadata normalizer
        allow(CodingAgentTools::Molecules::MetadataNormalizer).to receive(:normalize).and_return(
          {
            provider: "google",
            model: "gemini-2.0-flash-lite",
            finish_reason: "stop",
            took: 1.23
          }
        )

        # Mock the format handlers
        allow(CodingAgentTools::Molecules::FormatHandlers).to receive(:get_handler).and_return(
          double("handler", format: "formatted output")
        )
      end

      it "normalizes metadata with google provider" do
        expect(CodingAgentTools::Molecules::MetadataNormalizer).to receive(:normalize)
          .with(mock_response, provider: "google", model: "gemini-2.0-flash-lite", execution_time: anything)

        command.call(prompt: prompt)
      end

      it "normalizes metadata with custom model" do
        expect(CodingAgentTools::Molecules::MetadataNormalizer).to receive(:normalize)
          .with(mock_response, provider: "google", model: "gemini-pro", execution_time: anything)

        command.call(prompt: prompt, model: "gemini-pro")
      end
    end
  end
end
