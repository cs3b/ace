# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe CodingAgentTools::Atoms::YamlReader do
  describe ".read_file" do
    context "when file exists and contains valid YAML" do
      it "returns parsed YAML content" do
        Tempfile.create(["test", ".yml"]) do |file|
          file.write("key: value\narray:\n  - item1\n  - item2")
          file.flush

          result = described_class.read_file(file.path)

          expect(result).to eq({
            "key" => "value",
            "array" => ["item1", "item2"]
          })
        end
      end
    end

    context "when file does not exist" do
      it "raises an error" do
        expect {
          described_class.read_file("/nonexistent/file.yml")
        }.to raise_error(CodingAgentTools::Error, /YAML file not found/)
      end
    end

    context "when file contains invalid YAML syntax" do
      it "raises an error with syntax information" do
        Tempfile.create(["invalid", ".yml"]) do |file|
          file.write("invalid: yaml:\n  - missing: value\n  - - - invalid structure")
          file.flush

          expect {
            described_class.read_file(file.path)
          }.to raise_error(CodingAgentTools::Error, /Invalid YAML syntax/)
        end
      end
    end

    context "when file is unreadable" do
      it "raises an error" do
        # This test is platform dependent, but covers general IO errors
        allow(File).to receive(:exist?).and_return(true)
        allow(YAML).to receive(:load_file).and_raise(IOError, "Permission denied")

        expect {
          described_class.read_file("/some/file.yml")
        }.to raise_error(CodingAgentTools::Error, /Failed to read YAML file/)
      end
    end
  end

  describe ".parse_content" do
    context "when content is valid YAML" do
      it "returns parsed YAML object" do
        yaml_content = "name: test\nvalues:\n  - one\n  - two"

        result = described_class.parse_content(yaml_content)

        expect(result).to eq({
          "name" => "test",
          "values" => ["one", "two"]
        })
      end
    end

    context "when content is invalid YAML" do
      it "raises an error with syntax information" do
        invalid_yaml = "invalid: yaml:\n  - missing: value\n  - - - invalid"

        expect {
          described_class.parse_content(invalid_yaml)
        }.to raise_error(CodingAgentTools::Error, /Invalid YAML syntax/)
      end
    end

    context "when YAML parsing fails for other reasons" do
      it "raises a general error" do
        allow(YAML).to receive(:safe_load).and_raise(StandardError, "Unknown error")

        expect {
          described_class.parse_content("key: value")
        }.to raise_error(CodingAgentTools::Error, /Failed to parse YAML content/)
      end
    end
  end
end