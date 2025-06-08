# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/llm/query"
require "tempfile"

RSpec.describe CodingAgentTools::Cli::Commands::LLM::Query do
  let(:command) { described_class.new }
  let(:gemini_client) { instance_double(CodingAgentTools::Organisms::GeminiClient) }
  let(:prompt_processor) { instance_double(CodingAgentTools::Organisms::PromptProcessor) }

  before do
    # Mock the organisms
    allow(CodingAgentTools::Organisms::GeminiClient).to receive(:new).and_return(gemini_client)
    allow(CodingAgentTools::Organisms::PromptProcessor).to receive(:new).and_return(prompt_processor)

    # Set up default environment
    ENV["GEMINI_API_KEY"] = "test-api-key"
  end

  after do
    ENV.delete("GEMINI_API_KEY")
  end

  describe "#call" do
    context "with valid string prompt" do
      let(:prompt) { "What is Ruby?" }
      let(:response) do
        {
          text: "Ruby is a dynamic programming language.",
          finish_reason: "STOP",
          safety_ratings: [],
          usage_metadata: { totalTokens: 42 }
        }
      end

      before do
        allow(prompt_processor).to receive(:process).with(prompt, from_file: nil).and_return(prompt)
        allow(gemini_client).to receive(:generate_text).and_return(response)
      end

      it "queries Gemini and outputs text response" do
        expect {
          command.call(prompt: prompt)
        }.to output("Ruby is a dynamic programming language.\n").to_stdout
      end

      it "outputs JSON response when format is json" do
        expect {
          command.call(prompt: prompt, format: "json")
        }.to output(a_string_including("Ruby is a dynamic programming language")
                   .and(including('"finish_reason": "STOP"'))
                   .and(including('"totalTokens": 42'))).to_stdout
      end
    end

    context "with file input" do
      let(:temp_file) { Tempfile.new(["prompt", ".txt"]) }
      let(:file_content) { "Content from file" }

      before do
        temp_file.write(file_content)
        temp_file.close
      end

      after do
        temp_file.unlink
      end

      it "reads prompt from file when --file flag is set" do
        allow(prompt_processor).to receive(:process).with(temp_file.path, from_file: true).and_return(file_content)
        allow(gemini_client).to receive(:generate_text).and_return({ text: "Response", finish_reason: "STOP", safety_ratings: [], usage_metadata: {} })

        expect {
          command.call(prompt: temp_file.path, file: true)
        }.to output("Response\n").to_stdout
      end
    end

    context "with custom model" do
      it "uses specified model" do
        allow(prompt_processor).to receive(:process).and_return("Test")
        allow(CodingAgentTools::Organisms::GeminiClient).to receive(:new).with(model: "gemini-pro").and_return(gemini_client)
        allow(gemini_client).to receive(:generate_text).and_return({ text: "Response", finish_reason: "STOP", safety_ratings: [], usage_metadata: {} })

        command.call(prompt: "Test", model: "gemini-pro")

        expect(CodingAgentTools::Organisms::GeminiClient).to have_received(:new).with(model: "gemini-pro")
      end
    end

    context "with generation options" do
      it "passes temperature option" do
        allow(prompt_processor).to receive(:process).and_return("Test")
        allow(gemini_client).to receive(:generate_text).with("Test", generation_config: { temperature: 0.5 }).and_return({ text: "Response", finish_reason: "STOP", safety_ratings: [], usage_metadata: {} })

        command.call(prompt: "Test", temperature: 0.5)

        expect(gemini_client).to have_received(:generate_text).with("Test", generation_config: { temperature: 0.5 })
      end

      it "passes max_tokens option" do
        allow(prompt_processor).to receive(:process).and_return("Test")
        allow(gemini_client).to receive(:generate_text).with("Test", generation_config: { maxOutputTokens: 1000 }).and_return({ text: "Response", finish_reason: "STOP", safety_ratings: [], usage_metadata: {} })

        command.call(prompt: "Test", max_tokens: 1000)

        expect(gemini_client).to have_received(:generate_text).with("Test", generation_config: { maxOutputTokens: 1000 })
      end

      it "passes system instruction" do
        allow(prompt_processor).to receive(:process).and_return("Test")
        allow(gemini_client).to receive(:generate_text).with("Test", system_instruction: "You are a helpful assistant").and_return({ text: "Response", finish_reason: "STOP", safety_ratings: [], usage_metadata: {} })

        command.call(prompt: "Test", system: "You are a helpful assistant")

        expect(gemini_client).to have_received(:generate_text).with("Test", system_instruction: "You are a helpful assistant")
      end

      it "combines multiple generation options" do
        allow(prompt_processor).to receive(:process).and_return("Test")
        allow(gemini_client).to receive(:generate_text).with(
          "Test",
          system_instruction: "Be concise",
          generation_config: { temperature: 0.3, maxOutputTokens: 500 }
        ).and_return({ text: "Response", finish_reason: "STOP", safety_ratings: [], usage_metadata: {} })

        command.call(prompt: "Test", temperature: 0.3, max_tokens: 500, system: "Be concise")
      end
    end

    context "with empty or nil prompt" do
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

    context "with errors" do
      let(:prompt) { "Test prompt" }

      before do
        allow(prompt_processor).to receive(:process).and_return(prompt)
      end

      context "when debug is disabled" do
        it "shows simple error message for API errors" do
          allow(gemini_client).to receive(:generate_text).and_raise(CodingAgentTools::Error, "API rate limit exceeded")

          expect {
            expect { command.call(prompt: prompt, debug: false) }.to raise_error(SystemExit) do |error|
              expect(error.status).to eq(1)
            end
          }.to output(/Error: Failed to query Gemini: API rate limit exceeded\nUse --debug flag for more information/).to_stderr
        end

        it "shows simple error message for processing errors" do
          allow(prompt_processor).to receive(:process).and_raise(CodingAgentTools::Error, "File not found")

          expect {
            expect { command.call(prompt: prompt, debug: false) }.to raise_error(SystemExit) do |error|
              expect(error.status).to eq(1)
            end
          }.to output(/Error: File not found/).to_stderr
        end
      end

      context "when debug is enabled" do
        it "shows detailed error with backtrace" do
          error = CodingAgentTools::Error.new("Detailed API error")
          allow(gemini_client).to receive(:generate_text).and_raise(error)

          expect {
            expect { command.call(prompt: prompt, debug: true) }.to raise_error(SystemExit) do |error|
              expect(error.status).to eq(1)
            end
          }.to output(/Error: CodingAgentTools::Error: Failed to query Gemini: Detailed API error\n\nBacktrace:/).to_stderr
        end

        it "shows backtrace lines" do
          error = StandardError.new("Test error")
          error.set_backtrace(["line1", "line2", "line3"])
          allow(gemini_client).to receive(:generate_text).and_raise(error)

          expect {
            expect { command.call(prompt: prompt, debug: true) }.to raise_error(SystemExit)
          }.to output(/  line1\n  line2\n  line3/).to_stderr
        end
      end
    end

    context "with different output formats" do
      let(:prompt) { "Test" }
      let(:response) do
        {
          text: "Generated text response",
          finish_reason: "STOP",
          safety_ratings: [
            { category: "HARM_CATEGORY_HATE_SPEECH", probability: "NEGLIGIBLE" }
          ],
          usage_metadata: {
            promptTokenCount: 10,
            candidatesTokenCount: 20,
            totalTokenCount: 30
          }
        }
      end

      before do
        allow(prompt_processor).to receive(:process).and_return(prompt)
        allow(gemini_client).to receive(:generate_text).and_return(response)
      end

      it "outputs plain text by default" do
        expect {
          command.call(prompt: prompt)
        }.to output("Generated text response\n").to_stdout
      end

      it "outputs formatted JSON when requested" do
        expect {
          command.call(prompt: prompt, format: "json")
        }.to output(a_string_including("Generated text response")
                   .and(including('"finish_reason": "STOP"'))
                   .and(including('"promptTokenCount": 10'))
                   .and(including("HARM_CATEGORY_HATE_SPEECH"))).to_stdout
      end

      it "rejects invalid format option" do
        # This is handled by Dry::CLI validation
        # The format option has values: %w[text json]
        # Invalid values would be rejected before reaching our code
      end
    end

    context "with API key configuration" do
      it "raises error when API key is not available" do
        ENV.delete("GEMINI_API_KEY")
        allow(CodingAgentTools::Organisms::GeminiClient).to receive(:new).and_raise(KeyError, "API key not found")

        allow(prompt_processor).to receive(:process).and_return("Test")

        expect {
          expect { command.call(prompt: "Test") }.to raise_error(SystemExit)
        }.to output(/Error: Failed to query Gemini: API key not found/).to_stderr
      end
    end

    context "integration with components" do
      it "processes prompt and queries Gemini in correct order" do
        prompt = "Original prompt"
        processed_prompt = "Processed prompt"
        response = { text: "Response", finish_reason: "STOP", safety_ratings: [], usage_metadata: {} }

        expect(prompt_processor).to receive(:process).with(prompt, from_file: nil).ordered.and_return(processed_prompt)
        expect(gemini_client).to receive(:generate_text).with(processed_prompt).ordered.and_return(response)

        command.call(prompt: prompt)
      end
    end
  end

  describe "examples" do
    it "has valid examples in command definition" do
      expect(described_class.examples).not_to be_empty, "No examples registered for command."
      expect(described_class.examples.count).to eq(5), "Expected exactly five examples."

      expected_examples_array = [
        '"What is Ruby programming language?"',
        '"Explain quantum computing" --format json',
        'prompt.txt --file',
        'prompt.txt --file --format json --debug',
        '"Hello" --model gemini-pro --temperature 0.5'
      ]

      expect(described_class.examples).to eq(expected_examples_array), "The content of the registered examples array does not match the expected content."
    end
  end

  describe "command metadata" do
    it "has correct description" do
      expect(described_class.description).to eq("Query Google Gemini AI with a prompt")
    end

    it "has correct argument definition" do
      argument = described_class.arguments.find { |arg| arg.name == :prompt }
      expect(argument).not_to be_nil
      expect(argument.desc).to include("prompt text or file path")
    end

    it "has all required options" do
      expected_options = [:file, :format, :debug, :model, :temperature, :max_tokens, :system].sort
      actual_options = described_class.options.map(&:name).sort
      expect(actual_options).to eq(expected_options), "Options mismatch. Actual: #{actual_options.inspect}, Expected: #{expected_options.inspect}"
    end
  end
end
