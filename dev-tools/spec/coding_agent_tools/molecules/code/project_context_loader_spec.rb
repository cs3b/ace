# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::Code::ProjectContextLoader do
  let(:loader) { described_class.new }
  let(:file_reader_mock) { instance_double(CodingAgentTools::Atoms::Code::FileContentReader) }
  let(:yaml_reader_mock) { instance_double(CodingAgentTools::Atoms::YamlReader) }

  before do
    # Mock the atoms dependencies
    allow(CodingAgentTools::Atoms::Code::FileContentReader).to receive(:new).and_return(file_reader_mock)
    allow(CodingAgentTools::Atoms::YamlReader).to receive(:new).and_return(yaml_reader_mock)

    # Set up the instance variable mocks
    loader.instance_variable_set(:@file_reader, file_reader_mock)
    loader.instance_variable_set(:@yaml_reader, yaml_reader_mock)
  end

  describe "#load_context" do
    context "when mode is 'auto'" do
      before do
        # Mock file existence checks
        allow(File).to receive(:exist?).with("docs/blueprint.md").and_return(true)
        allow(File).to receive(:exist?).with("docs/what-do-we-build.md").and_return(true)
        allow(File).to receive(:exist?).with("docs/architecture.md").and_return(true)

        # Mock file reading
        allow(file_reader_mock).to receive(:read).with("docs/blueprint.md").and_return(
          success: true,
          content: "# Project Blueprint\nThis is the blueprint."
        )
        allow(file_reader_mock).to receive(:read).with("docs/what-do-we-build.md").and_return(
          success: true,
          content: "# What We Build\nProject vision content."
        )
        allow(file_reader_mock).to receive(:read).with("docs/architecture.md").and_return(
          success: true,
          content: "# Architecture\nSystem architecture details."
        )
      end

      it "loads standard project documents" do
        context = loader.load_context("auto")

        expect(context).to be_a(CodingAgentTools::Models::Code::ReviewContext)
        expect(context.mode).to eq("auto")
        expect(context.documents.length).to eq(3)
        expect(context.documents.map { |d| d[:type] }).to include("blueprint", "vision", "architecture")
      end

      it "includes document content in context" do
        context = loader.load_context("auto")

        blueprint_doc = context.documents.find { |doc| doc[:type] == "blueprint" }
        expect(blueprint_doc[:content]).to include("Project Blueprint")

        vision_doc = context.documents.find { |doc| doc[:type] == "vision" }
        expect(vision_doc[:content]).to include("Project vision content")
      end

      it "handles missing documents gracefully" do
        allow(file_reader_mock).to receive(:read).with("docs/blueprint.md").and_return(
          success: false,
          error: "File not found"
        )

        context = loader.load_context("auto")

        expect(context.documents.length).to eq(2)
        expect(context.documents.map { |d| d[:type] }).not_to include("blueprint")
        expect(context.documents.map { |d| d[:type] }).to include("vision", "architecture")
      end

      it "handles file read errors" do
        allow(file_reader_mock).to receive(:read).with("docs/blueprint.md").and_return(
          success: false,
          error: "Permission denied"
        )

        context = loader.load_context("auto")

        # Should still load other documents
        expect(context.documents.length).to eq(2)
        expect(context.documents.map { |d| d[:type] }).to include("vision", "architecture")
      end
    end

    context "when mode is 'none'" do
      it "returns empty context" do
        context = loader.load_context("none")

        expect(context).to be_a(CodingAgentTools::Models::Code::ReviewContext)
        expect(context.mode).to eq("none")
        expect(context.documents).to be_empty
      end
    end

    context "when mode is 'custom'" do
      let(:custom_path) { "custom/context.md" }

      before do
        allow(File).to receive(:exist?).with(custom_path).and_return(true)
        allow(file_reader_mock).to receive(:read).with(custom_path).and_return(
          success: true,
          content: "# Custom Context\nCustom project context."
        )
      end

      it "loads custom context file" do
        context = loader.load_context("custom", custom_path)

        expect(context.mode).to eq("custom")
        expect(context.documents.length).to eq(1)
        expect(context.documents.first[:content]).to include("Custom Context")
      end

      it "handles missing custom file" do
        allow(file_reader_mock).to receive(:read).with(custom_path).and_return(
          success: false,
          error: "File not found"
        )

        context = loader.load_context("custom", custom_path)

        expect(context.mode).to eq("custom")
        expect(context.documents).to be_empty
      end
    end

    context "when mode is a file path" do
      let(:file_path) { "/path/to/context.md" }

      before do
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(file_reader_mock).to receive(:read).with(file_path).and_return(
          success: true,
          content: "# Direct File Context\nDirect file content."
        )
      end

      it "treats mode as custom path when it's an existing file" do
        context = loader.load_context(file_path)

        expect(context.mode).to eq("custom")
        expect(context.documents.length).to eq(1)
        expect(context.documents.first[:content]).to include("Direct File Context")
      end
    end

    context "when mode is unrecognized" do
      it "returns context with empty documents" do
        context = loader.load_context("unknown-mode")

        expect(context.mode).to eq("unknown-mode")
        expect(context.documents).to be_empty
        expect(context.loaded_at).to be_a(Time)
      end
    end
  end

  describe "private methods" do
    describe "#load_auto_context" do
      before do
        described_class::AUTO_DOCUMENTS.each do |name, path|
          allow(file_reader_mock).to receive(:read).with(path).and_return(
            success: true,
            content: "Content for #{name}"
          )
        end
      end

      it "loads all standard documents" do
        context = loader.send(:load_auto_context)

        expect(context.mode).to eq("auto")
        expect(context.documents.length).to eq(3)
        expect(context.documents.map { |d| d[:type] }).to match_array(["blueprint", "vision", "architecture"])
      end
    end

    describe "#load_custom_context" do
      let(:custom_path) { "custom.md" }

      before do
        allow(File).to receive(:exist?).with(custom_path).and_return(true)
        allow(file_reader_mock).to receive(:read).with(custom_path).and_return(
          success: true,
          content: "Custom content"
        )
      end

      it "loads single custom document" do
        context = loader.send(:load_custom_context, custom_path)

        expect(context.mode).to eq("custom")
        expect(context.documents.length).to eq(1)
        expect(context.documents.first[:content]).to eq("Custom content")
      end
    end
  end
end
