# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe CodingAgentTools::Molecules::Code::ContextIntegrator do
  let(:integrator) { described_class.new }
  let(:mock_executor) { instance_double(CodingAgentTools::Organisms::System::CommandExecutor) }
  let(:mock_result) { double("result", success?: true, stderr: nil) }

  before do
    allow(integrator).to receive(:executor).and_return(mock_executor)
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return("/fake/project")
  end

  describe "#generate_context" do
    context "with multi-preset configuration" do
      it "handles multiple presets correctly" do
        config = {"presets" => ["project", "dev-tools", "dev-handbook"]}
        expected_preset_string = "project,dev-tools,dev-handbook"
        expected_output = "Combined preset content"

        # Mock file operations for preset execution
        expect(integrator).to receive(:execute_context_command)
          .with("--preset", expected_preset_string)
          .and_return(expected_output)

        result = integrator.generate_context(config)
        expect(result).to eq(expected_output)
      end

      it "handles mixed presets and additional files" do
        config = {
          "presets" => ["project", "dev-tools"],
          "files" => ["docs/custom.md"]
        }

        preset_content = "Preset content"
        additional_content = "Additional content"
        expected_output = "Preset content\n\nAdditional content"

        # Mock preset execution
        expect(integrator).to receive(:execute_context_command)
          .with("--preset", "project,dev-tools")
          .and_return(preset_content)

        # Mock additional content execution
        expect(integrator).to receive(:execute_context_command_with_yaml)
          .with("---\nfiles:\n- docs/custom.md\n")
          .and_return(additional_content)

        result = integrator.generate_context(config)
        expect(result).to eq(expected_output)
      end

      it "handles symbol keys for presets" do
        config = {presets: ["project"]}
        expected_output = "Symbol preset content"

        expect(integrator).to receive(:execute_context_command)
          .with("--preset", "project")
          .and_return(expected_output)

        result = integrator.generate_context(config)
        expect(result).to eq(expected_output)
      end

      it "validates preset names" do
        config = {"presets" => ["valid-preset", "invalid preset!"]}

        expect {
          integrator.generate_context(config)
        }.to raise_error(ArgumentError, "Invalid preset name: invalid preset!")
      end

      it "handles single preset in array" do
        config = {"presets" => ["project"]}
        expected_output = "Single preset content"

        expect(integrator).to receive(:execute_context_command)
          .with("--preset", "project")
          .and_return(expected_output)

        result = integrator.generate_context(config)
        expect(result).to eq(expected_output)
      end

      it "handles string value for presets" do
        config = {"presets" => "project"}
        expected_output = "String preset content"

        expect(integrator).to receive(:execute_context_command)
          .with("--preset", "project")
          .and_return(expected_output)

        result = integrator.generate_context(config)
        expect(result).to eq(expected_output)
      end
    end

    context "with existing string configuration" do
      it "passes preset name directly" do
        config = "project"
        expected_output = "Direct preset content"

        expect(integrator).to receive(:execute_context_command)
          .with("--preset", "project")
          .and_return(expected_output)

        result = integrator.generate_context(config)
        expect(result).to eq(expected_output)
      end
    end

    context "with hash configuration without presets" do
      it "uses YAML processing" do
        config = {"files" => ["docs/test.md"]}
        expected_output = "YAML processed content"

        expect(integrator).to receive(:execute_context_command_with_yaml)
          .with("---\nfiles:\n- docs/test.md\n")
          .and_return(expected_output)

        result = integrator.generate_context(config)
        expect(result).to eq(expected_output)
      end
    end

    context "with nil or 'none' configuration" do
      it "returns empty string for nil" do
        result = integrator.generate_context(nil)
        expect(result).to eq("")
      end

      it "returns empty string for 'none'" do
        result = integrator.generate_context("none")
        expect(result).to eq("")
      end
    end
  end

  describe "#validate_preset_names" do
    it "accepts valid preset names" do
      valid_names = ["project", "dev-tools", "dev_handbook", "preset123", "UPPER-case"]

      expect {
        integrator.send(:validate_preset_names, valid_names)
      }.not_to raise_error
    end

    it "rejects invalid preset names" do
      invalid_names = ["invalid name", "preset!", "preset@domain", "preset/path"]

      invalid_names.each do |invalid_name|
        expect {
          integrator.send(:validate_preset_names, [invalid_name])
        }.to raise_error(ArgumentError, "Invalid preset name: #{invalid_name}")
      end
    end

    it "handles non-string values" do
      expect {
        integrator.send(:validate_preset_names, [123])
      }.to raise_error(ArgumentError, "Invalid preset name: 123")
    end

    it "handles single preset" do
      expect {
        integrator.send(:validate_preset_names, "valid-preset")
      }.not_to raise_error
    end
  end
end
