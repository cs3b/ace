# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/lms/query"

RSpec.describe CodingAgentTools::Cli::Commands::LMS::Query do
  let(:command) { described_class.new }
  let(:mock_lm_studio_client) { instance_double(CodingAgentTools::Organisms::LMStudioClient) }
  let(:mock_prompt_processor) { instance_double(CodingAgentTools::Organisms::PromptProcessor) }

  before do
    allow(CodingAgentTools::Organisms::LMStudioClient).to receive(:new).and_return(mock_lm_studio_client)
    allow(CodingAgentTools::Organisms::PromptProcessor).to receive(:new).and_return(mock_prompt_processor)
    allow(command).to receive(:exit) # Prevent actual exit calls during tests

    # Default stubs to handle parameter variations
    allow(mock_prompt_processor).to receive(:process).and_return("default response")
    allow(mock_lm_studio_client).to receive(:generate_text).and_return({
      text: "Default response",
      finish_reason: "stop",
      usage_metadata: { prompt_tokens: 5, completion_tokens: 10 }
    })
  end

  describe "#call" do
    let(:prompt) { "What is Ruby?" }
    let(:successful_response) do
      {
        text: "Ruby is a programming language",
        finish_reason: "stop",
        usage_metadata: { prompt_tokens: 10, completion_tokens: 20 }
      }
    end

    context "with basic prompt" do
      it "processes prompt and generates response" do
        allow(mock_prompt_processor).to receive(:process)
          .with(prompt, from_file: false)
          .and_return(prompt)

        allow(mock_lm_studio_client).to receive(:generate_text)
          .with(prompt)
          .and_return(successful_response)

        expect { command.call(prompt: prompt) }
          .to output("Ruby is a programming language\n").to_stdout
      end
    end

    context "with file input" do
      let(:file_content) { "Explain quantum computing" }

      it "processes file and generates response" do
        allow(mock_prompt_processor).to receive(:process)
          .with(prompt, from_file: true)
          .and_return(file_content)

        allow(mock_lm_studio_client).to receive(:generate_text)
          .with(file_content)
          .and_return(successful_response)

        expect { command.call(prompt: prompt, file: true) }
          .to output("Ruby is a programming language\n").to_stdout
      end
    end

    context "with custom model" do
      it "uses specified model" do
        allow(mock_prompt_processor).to receive(:process)
          .with(prompt, from_file: false)
          .and_return(prompt)
        expect(CodingAgentTools::Organisms::LMStudioClient).to receive(:new)
          .with(model: "custom-model")
          .and_return(mock_lm_studio_client)

        allow(mock_lm_studio_client).to receive(:generate_text)
          .with(prompt)
          .and_return(successful_response)

        expect { command.call(prompt: prompt, model: "custom-model") }
          .to output("Ruby is a programming language\n").to_stdout
      end
    end

    context "with system instruction" do
      it "includes system instruction in generation options" do
        system_instruction = "You are a helpful assistant"
        allow(mock_prompt_processor).to receive(:process)
          .with(prompt, from_file: false)
          .and_return(prompt)
        allow(mock_lm_studio_client).to receive(:generate_text)
          .with(prompt, system_instruction: system_instruction)
          .and_return(successful_response)

        expect { command.call(prompt: prompt, system: system_instruction) }
          .to output("Ruby is a programming language\n").to_stdout
      end
    end

    context "with generation config options" do
      it "includes temperature and max_tokens in generation config" do
        allow(mock_prompt_processor).to receive(:process)
          .with(prompt, from_file: false)
          .and_return(prompt)
        allow(mock_lm_studio_client).to receive(:generate_text)
          .with(prompt, generation_config: {
            temperature: 0.9,
            max_tokens: 1000
          })
          .and_return(successful_response)

        expect { command.call(prompt: prompt, temperature: 0.9, max_tokens: 1000) }
          .to output("Ruby is a programming language\n").to_stdout
      end
    end

    context "with JSON output format" do
      it "outputs JSON format" do
        allow(mock_prompt_processor).to receive(:process)
          .with(prompt, from_file: false)
          .and_return(prompt)
        allow(mock_lm_studio_client).to receive(:generate_text)
          .with(prompt)
          .and_return(successful_response)

        expected_json = {
          text: "Ruby is a programming language",
          metadata: {
            finish_reason: "stop",
            usage: { prompt_tokens: 10, completion_tokens: 20 }
          }
        }

        expect { command.call(prompt: prompt, format: "json") }
          .to output(/#{Regexp.escape(expected_json[:text])}/).to_stdout
      end
    end

    context "with empty prompt" do
      it "exits with error" do
        expect(command).to receive(:error_output).with("Error: Prompt is required")
        expect(command).to receive(:exit).with(1).and_raise(SystemExit)

        expect { command.call(prompt: "") }.to raise_error(SystemExit)
      end

      it "exits with error for nil prompt" do
        expect(command).to receive(:error_output).with("Error: Prompt is required")
        expect(command).to receive(:exit).with(1).and_raise(SystemExit)

        expect { command.call(prompt: nil) }.to raise_error(SystemExit)
      end
    end

    context "when prompt processing fails" do
      it "handles CodingAgentTools::Error" do
        error = CodingAgentTools::Error.new("File not found")
        allow(mock_prompt_processor).to receive(:process)
          .with(prompt, from_file: false)
          .and_raise(error)

        expect(command).to receive(:error_output).with("Error: File not found")
        expect(command).to receive(:error_output).with("Use --debug flag for more information")
        expect(command).to receive(:exit).with(1).and_raise(SystemExit)

        expect { command.call(prompt: prompt) }.to raise_error(SystemExit)
      end

      it "wraps other errors" do
        error = StandardError.new("Unexpected error")
        allow(mock_prompt_processor).to receive(:process)
          .with(prompt, from_file: false)
          .and_raise(error)

        expect(command).to receive(:error_output).with("Error: Failed to process prompt: Unexpected error")
        expect(command).to receive(:error_output).with("Use --debug flag for more information")
        expect(command).to receive(:exit).with(1).and_raise(SystemExit)

        expect { command.call(prompt: prompt) }.to raise_error(SystemExit)
      end
    end

    context "when LM Studio query fails" do
      it "wraps errors" do
        allow(mock_prompt_processor).to receive(:process)
          .with(prompt, from_file: false)
          .and_return(prompt)
        error = StandardError.new("Server unavailable")
        allow(mock_lm_studio_client).to receive(:generate_text)
          .with(prompt)
          .and_raise(error)

        expect(command).to receive(:error_output).with("Error: Failed to query LM Studio: Server unavailable")
        expect(command).to receive(:error_output).with("Use --debug flag for more information")
        expect(command).to receive(:exit).with(1).and_raise(SystemExit)

        expect { command.call(prompt: prompt) }.to raise_error(SystemExit)
      end
    end

    context "with debug flag" do
      it "shows detailed error information" do
        error = StandardError.new("Test error")
        error.set_backtrace(["line1", "line2"])
        allow(mock_prompt_processor).to receive(:process)
          .with(prompt, from_file: false)
          .and_raise(error)

        expect(command).to receive(:error_output).with("Error: CodingAgentTools::Error: Failed to process prompt: Test error")
        expect(command).to receive(:error_output).with("\nBacktrace:")
        expect(command).to receive(:error_output).with("  line1")
        expect(command).to receive(:error_output).with("  line2")
        expect(command).to receive(:exit).with(1).and_raise(SystemExit)

        expect { command.call(prompt: prompt, debug: true) }.to raise_error(SystemExit)
      end
    end
  end

  describe "private methods" do
    describe "#build_lm_studio_client" do
      it "builds client with default options" do
        expect(CodingAgentTools::Organisms::LMStudioClient).to receive(:new)

        command.send(:build_lm_studio_client, {})
      end

      it "builds client with model option" do
        expect(CodingAgentTools::Organisms::LMStudioClient).to receive(:new)
          .with(model: "custom-model")

        command.send(:build_lm_studio_client, { model: "custom-model" })
      end
    end

    describe "#build_generation_options" do
      it "builds empty options by default" do
        options = command.send(:build_generation_options, {})
        expect(options).to eq({})
      end

      it "includes system instruction" do
        options = command.send(:build_generation_options, { system: "Be helpful" })
        expect(options[:system_instruction]).to eq("Be helpful")
      end

      it "includes generation config" do
        options = command.send(:build_generation_options, {
          temperature: 0.9,
          max_tokens: 1000
        })

        expect(options[:generation_config]).to eq({
          temperature: 0.9,
          max_tokens: 1000
        })
      end

      it "excludes empty generation config" do
        options = command.send(:build_generation_options, {})
        expect(options).not_to have_key(:generation_config)
      end
    end

    describe "#output_text_response" do
      it "outputs text to stdout" do
        response = { text: "Hello world" }

        expect { command.send(:output_text_response, response) }
          .to output("Hello world\n").to_stdout
      end

      it "returns the response" do
        response = { text: "Hello world" }
        result = nil
        expect { result = command.send(:output_text_response, response) }
          .to output("Hello world\n").to_stdout
        expect(result).to eq(response)
      end
    end

    describe "#output_json_response" do
      it "outputs formatted JSON" do
        response = {
          text: "Hello world",
          finish_reason: "stop",
          usage_metadata: { tokens: 10 }
        }

        allow(CodingAgentTools::Atoms::JSONFormatter).to receive(:pretty_format)
          .and_return('{"formatted": "json"}')

        expect { command.send(:output_json_response, response) }
          .to output(%{{"formatted": "json"}\n}).to_stdout
      end

      it "returns the response" do
        response = { text: "Hello world" }
        allow(CodingAgentTools::Atoms::JSONFormatter).to receive(:pretty_format)
          .and_return("{}")

        result = nil
        expect { result = command.send(:output_json_response, response) }
          .to output("{}\n").to_stdout
        expect(result).to eq(response)
      end
    end

    describe "#error_output" do
      it "outputs to stderr" do
        expect { command.send(:error_output, "Error message") }
          .to output("Error message\n").to_stderr
      end
    end
  end
end
