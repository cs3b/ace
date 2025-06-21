# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/format_handlers"

RSpec.describe CodingAgentTools::Molecules::FormatHandlers do
  let(:response) do
    {
      text: "This is a test response from the AI model.",
      metadata: {
        finish_reason: "stop",
        input_tokens: 10,
        output_tokens: 20,
        total_tokens: 30,
        took: 1.234,
        provider: "gemini",
        model: "gemini-2.0-flash-lite",
        timestamp: "2024-01-01T12:00:00Z"
      }
    }
  end

  describe ".get_handler" do
    it "returns JSON handler for json format" do
      handler = described_class.get_handler("json")
      expect(handler).to be_a(described_class::JSON)
    end

    it "returns Markdown handler for markdown format" do
      handler = described_class.get_handler("markdown")
      expect(handler).to be_a(described_class::Markdown)
    end

    it "returns Markdown handler for md format" do
      handler = described_class.get_handler("md")
      expect(handler).to be_a(described_class::Markdown)
    end

    it "returns Text handler for text format" do
      handler = described_class.get_handler("text")
      expect(handler).to be_a(described_class::Text)
    end

    it "returns Text handler for txt format" do
      handler = described_class.get_handler("txt")
      expect(handler).to be_a(described_class::Text)
    end

    it "raises error for unsupported format" do
      expect {
        described_class.get_handler("xml")
      }.to raise_error(CodingAgentTools::Error, "Unsupported format: xml")
    end

    it "handles case-insensitive format names" do
      expect(described_class.get_handler("JSON")).to be_a(described_class::JSON)
      expect(described_class.get_handler("MARKDOWN")).to be_a(described_class::Markdown)
    end
  end

  describe ".supported_formats" do
    it "returns array of supported formats" do
      formats = described_class.supported_formats
      expect(formats).to eq(%w[json markdown text])
    end
  end

  describe "Base handler" do
    let(:base_handler) { described_class::Base.new }

    describe "#format" do
      it "raises NotImplementedError" do
        expect {
          base_handler.format(response)
        }.to raise_error(NotImplementedError, "Subclasses must implement #format")
      end
    end

    describe "#generate_summary" do
      let(:file_path) { "/path/to/output.txt" }

      it "generates comprehensive summary with all metadata" do
        summary = base_handler.generate_summary(response, file_path)

        expect(summary).to include("Response saved to: #{file_path}")
        expect(summary).to include("Provider: gemini (gemini-2.0-flash-lite)")
        expect(summary).to include("Execution time: 1.234s")
        expect(summary).to include("Tokens: 10 input, 20 output")
      end

      it "handles missing metadata gracefully" do
        minimal_response = {text: "Test", metadata: {}}
        summary = base_handler.generate_summary(minimal_response, file_path)

        expect(summary).to include("Response saved to: #{file_path}")
        expect(summary).not_to include("Provider:")
        expect(summary).not_to include("Execution time:")
        expect(summary).not_to include("Tokens:")
      end

      it "handles partial metadata" do
        partial_response = {
          text: "Test",
          metadata: {
            provider: "lmstudio",
            took: 2.5
          }
        }
        summary = base_handler.generate_summary(partial_response, file_path)

        expect(summary).to include("Response saved to: #{file_path}")
        expect(summary).to include("Provider: lmstudio")
        expect(summary).to include("Execution time: 2.5s")
        expect(summary).not_to include("Tokens:")
      end
    end

    describe "#validate_response" do
      it "passes validation for valid response" do
        expect {
          base_handler.send(:validate_response, response)
        }.not_to raise_error
      end

      it "raises error for response without text" do
        invalid_response = {metadata: {}}
        expect {
          base_handler.send(:validate_response, invalid_response)
        }.to raise_error(CodingAgentTools::Error, "Invalid response format: missing :text field")
      end

      it "raises error for non-hash response" do
        expect {
          base_handler.send(:validate_response, "invalid")
        }.to raise_error(CodingAgentTools::Error, "Invalid response format: missing :text field")
      end

      it "raises error for nil response" do
        expect {
          base_handler.send(:validate_response, nil)
        }.to raise_error(CodingAgentTools::Error, "Invalid response format: missing :text field")
      end
    end
  end

  describe "JSON handler" do
    let(:json_handler) { described_class::JSON.new }

    describe "#format" do
      it "formats response as pretty JSON" do
        result = json_handler.format(response)

        expect(result).to be_a(String)
        expect { JSON.parse(result) }.not_to raise_error

        parsed = JSON.parse(result)
        expect(parsed["text"]).to eq(response[:text])
        expect(parsed["metadata"]).to eq(response[:metadata].transform_keys(&:to_s))
      end

      it "handles response without metadata" do
        minimal_response = {text: "Test response"}
        result = json_handler.format(minimal_response)

        parsed = JSON.parse(result)
        expect(parsed["text"]).to eq("Test response")
        expect(parsed["metadata"]).to eq({})
      end

      it "validates response before formatting" do
        expect {
          json_handler.format({})
        }.to raise_error(CodingAgentTools::Error, "Invalid response format: missing :text field")
      end
    end
  end

  describe "Markdown handler" do
    let(:markdown_handler) { described_class::Markdown.new }

    describe "#format" do
      it "formats response as Markdown with YAML front matter" do
        result = markdown_handler.format(response)

        expect(result).to start_with("---\n")
        expect(result).to include("finish_reason: stop")
        expect(result).to include("input_tokens: 10")
        expect(result).to include("provider: gemini")
        expect(result).to include("---\n\n#{response[:text]}")
      end

      it "handles response without metadata" do
        minimal_response = {text: "Test response"}
        result = markdown_handler.format(minimal_response)

        expect(result).to eq("Test response")
        expect(result).not_to include("---")
      end

      it "handles empty metadata" do
        response_with_empty_metadata = {
          text: "Test response",
          metadata: {}
        }
        result = markdown_handler.format(response_with_empty_metadata)

        expect(result).to eq("Test response")
        expect(result).not_to include("---")
      end

      it "validates response before formatting" do
        expect {
          markdown_handler.format({})
        }.to raise_error(CodingAgentTools::Error, "Invalid response format: missing :text field")
      end

      it "produces valid YAML front matter" do
        result = markdown_handler.format(response)
        lines = result.split("\n")

        # Find YAML front matter boundaries
        start_index = lines.index("---")
        end_index = lines[start_index + 1..-1].index("---")
        end_index = start_index + 1 + end_index if end_index

        expect(start_index).not_to be_nil
        expect(end_index).not_to be_nil

        yaml_content = lines[(start_index + 1)...end_index].join("\n")
        expect { YAML.safe_load(yaml_content) }.not_to raise_error
      end
    end
  end

  describe "Text handler" do
    let(:text_handler) { described_class::Text.new }

    describe "#format" do
      it "formats response as plain text" do
        result = text_handler.format(response)
        expect(result).to eq(response[:text])
      end

      it "ignores metadata" do
        result = text_handler.format(response)
        expect(result).not_to include("metadata")
        expect(result).not_to include("tokens")
        expect(result).not_to include("provider")
      end

      it "validates response before formatting" do
        expect {
          text_handler.format({})
        }.to raise_error(CodingAgentTools::Error, "Invalid response format: missing :text field")
      end

      it "handles response without metadata" do
        minimal_response = {text: "Test response"}
        result = text_handler.format(minimal_response)
        expect(result).to eq("Test response")
      end
    end
  end

  describe "integration scenarios" do
    let(:complex_response) do
      {
        text: "Complex response with special characters: äöü, 中文, emoji 🚀",
        metadata: {
          finish_reason: "stop",
          input_tokens: 50,
          output_tokens: 100,
          total_tokens: 150,
          took: 3.567,
          provider: "lmstudio",
          model: "mistralai/devstral-small-2505",
          timestamp: "2024-01-01T15:30:45Z",
          custom_field: "custom_value"
        }
      }
    end

    it "handles complex response in JSON format" do
      handler = described_class.get_handler("json")
      result = handler.format(complex_response)

      parsed = JSON.parse(result)
      expect(parsed["text"]).to eq(complex_response[:text])
      expect(parsed["metadata"]["custom_field"]).to eq("custom_value")
    end

    it "handles complex response in Markdown format" do
      handler = described_class.get_handler("markdown")
      result = handler.format(complex_response)

      expect(result).to include(complex_response[:text])
      expect(result).to include("custom_field: custom_value")
    end

    it "handles complex response in Text format" do
      handler = described_class.get_handler("text")
      result = handler.format(complex_response)

      expect(result).to eq(complex_response[:text])
    end
  end
end
