# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "coding_agent_tools/organisms/code/context_loader"

RSpec.describe CodingAgentTools::Organisms::Code::ContextLoader do
  let(:context_loader) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir("context_loader_test") }
  let(:session_dir) { File.join(temp_dir, "session") }

  before do
    FileUtils.mkdir_p(session_dir)

    # Mock molecules
    @mock_context_loader = instance_double(CodingAgentTools::Molecules::Code::ProjectContextLoader)
    @mock_file_handler = instance_double(CodingAgentTools::Molecules::FileIoHandler)

    allow(CodingAgentTools::Molecules::Code::ProjectContextLoader).to receive(:new).and_return(@mock_context_loader)
    allow(CodingAgentTools::Molecules::FileIoHandler).to receive(:new).and_return(@mock_file_handler)
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#initialize" do
    it "initializes with project context loader and file handler" do
      expect(context_loader.instance_variable_get(:@context_loader)).to eq(@mock_context_loader)
      expect(context_loader.instance_variable_get(:@file_handler)).to eq(@mock_file_handler)
    end
  end

  describe "#load_context" do
    let(:session) do
      CodingAgentTools::Models::Code::ReviewSession.new(
        session_id: "test-session",
        session_name: "test",
        timestamp: Time.now.iso8601,
        directory_path: session_dir,
        focus: "architecture",
        target: "src/",
        context_mode: "auto",
        metadata: {}
      )
    end

    let(:mock_context) do
      CodingAgentTools::Models::Code::ReviewContext.new(
        mode: "auto",
        documents: [
          {type: "blueprint", path: "README.md", content: "# Project README\nThis is a test project."},
          {type: "vision", path: "docs/vision.md", content: "# Vision\nProject vision."},
          {type: "architecture", path: "docs/architecture.md", content: "# Architecture\nSystem design."}
        ],
        loaded_at: Time.now
      )
    end

    before do
      allow(@mock_context_loader).to receive(:load_context).and_return(mock_context)
    end

    context "with auto mode" do
      it "loads context and logs to session" do
        expect(@mock_context_loader).to receive(:load_context).with("auto", nil)

        result = context_loader.load_context("auto", session)

        expect(result).to eq(mock_context)

        # Check that log file was created
        log_file = File.join(session_dir, "session.log")
        expect(File.exist?(log_file)).to be true

        log_content = File.read(log_file)
        expect(log_content).to include("Context Loading")
        expect(log_content).to include("Mode: auto")
        expect(log_content).to include("Documents: 3")
      end
    end

    context "with custom context file path" do
      let(:custom_context_path) { File.join(temp_dir, "custom_context.md") }

      before do
        File.write(custom_context_path, "# Custom Context\nCustom content.")
      end

      it "detects file path and loads as custom mode" do
        expect(@mock_context_loader).to receive(:load_context).with("custom", custom_context_path)

        context_loader.load_context(custom_context_path, session)
      end
    end

    context "with none mode" do
      it "loads empty context" do
        expect(@mock_context_loader).to receive(:load_context).with("none", nil)

        context_loader.load_context("none", session)
      end
    end

    context "when logging fails" do
      before do
        # Make session directory non-writable to simulate logging failure
        allow(File).to receive(:open).with(File.join(session_dir, "session.log"), "a").and_raise("Permission denied")
      end

      it "continues execution without failing" do
        expect { context_loader.load_context("auto", session) }.not_to raise_error
      end
    end
  end

  describe "#save_context" do
    let(:loaded_context) do
      CodingAgentTools::Models::Code::ReviewContext.new(
        mode: "auto",
        documents: [
          {type: "blueprint", path: "README.md", content: "# Project README\nThis is a test project."},
          {type: "vision", path: "docs/vision.md", content: "# Vision\nProject vision."},
          {type: "architecture", path: "docs/architecture.md", content: "# Architecture\nSystem design."}
        ],
        loaded_at: Time.parse("2024-01-15T10:30:00Z")
      )
    end

    let(:empty_context) do
      CodingAgentTools::Models::Code::ReviewContext.new(
        mode: "none",
        documents: [],
        loaded_at: nil
      )
    end

    context "with loaded context" do
      it "saves context metadata and documents" do
        result = context_loader.save_context(loaded_context, session_dir)

        expect(result[:success]).to be true
        expect(result[:error]).to be nil

        # Check context metadata file
        context_file = File.join(session_dir, "context.yaml")
        expect(File.exist?(context_file)).to be true

        context_data = YAML.load_file(context_file)
        expect(context_data["mode"]).to eq("auto")
        expect(context_data["document_count"]).to eq(3)
        expect(context_data["loaded_at"]).to eq("2024-01-15T10:30:00Z")

        # Check individual document files
        blueprint_file = File.join(session_dir, "context-blueprint.txt")
        expect(File.exist?(blueprint_file)).to be true
        expect(File.read(blueprint_file)).to eq("# Project README\nThis is a test project.")

        vision_file = File.join(session_dir, "context-vision.txt")
        expect(File.exist?(vision_file)).to be true
        expect(File.read(vision_file)).to eq("# Vision\nProject vision.")

        arch_file = File.join(session_dir, "context-architecture.txt")
        expect(File.exist?(arch_file)).to be true
        expect(File.read(arch_file)).to eq("# Architecture\nSystem design.")
      end
    end

    context "with empty context" do
      it "returns success without creating files" do
        result = context_loader.save_context(empty_context, session_dir)

        expect(result[:success]).to be true
        expect(result[:error]).to be nil

        # No files should be created
        context_file = File.join(session_dir, "context.yaml")
        expect(File.exist?(context_file)).to be false
      end
    end

    context "when file operations fail" do
      before do
        # Simulate file write failure
        allow(File).to receive(:write).and_raise("Disk full")
      end

      it "returns error result" do
        result = context_loader.save_context(loaded_context, session_dir)

        expect(result[:success]).to be false
        expect(result[:error]).to include("Failed to save context: Disk full")
      end
    end
  end

  describe "#check_availability" do
    let(:availability_info) do
      {
        auto_available: true,
        available_docs: ["README.md", "docs/architecture.md"],
        project_root: "/project/root"
      }
    end

    it "delegates to context loader molecule" do
      expect(@mock_context_loader).to receive(:check_auto_availability).and_return(availability_info)

      result = context_loader.check_availability
      expect(result).to eq(availability_info)
    end
  end

  describe "#get_context_summary" do
    context "with loaded context" do
      let(:loaded_context) do
        CodingAgentTools::Models::Code::ReviewContext.new(
          mode: "auto",
          documents: [
            {type: "blueprint", path: "README.md", content: "# Project README\nThis is a test project."},
            {type: "vision", path: "docs/vision.md", content: "# Vision\nProject vision."},
            {type: "architecture", path: "docs/architecture.md", content: "# Architecture\nSystem design."}
          ],
          loaded_at: Time.now
        )
      end

      it "returns formatted context summary" do
        summary = context_loader.get_context_summary(loaded_context)

        expect(summary).to include("Project Context (mode: auto)")
        expect(summary).to include("Using standard project documents")
        expect(summary).to include("Documents loaded: 3")
        expect(summary).to include("blueprint: README.md")
        expect(summary).to include("architecture: docs/architecture.md")
      end
    end

    context "with custom context" do
      let(:custom_context) do
        CodingAgentTools::Models::Code::ReviewContext.new(
          mode: "custom",
          documents: [
            {type: "custom", path: "custom.md", content: "Custom content here."}
          ],
          loaded_at: Time.now
        )
      end

      it "shows custom mode in summary" do
        summary = context_loader.get_context_summary(custom_context)

        expect(summary).to include("Project Context (mode: custom)")
        expect(summary).to include("Using custom context file")
        expect(summary).to include("Documents loaded: 1")
      end
    end

    context "with no context" do
      let(:empty_context) do
        CodingAgentTools::Models::Code::ReviewContext.new(
          mode: "none",
          documents: [],
          loaded_at: nil
        )
      end

      it "returns no context message" do
        summary = context_loader.get_context_summary(empty_context)
        expect(summary).to eq("No context loaded (mode: none)")
      end
    end
  end

  describe "private methods" do
    describe "#format_size" do
      it "formats bytes correctly" do
        expect(context_loader.send(:format_size, 500)).to eq("500 bytes")
        expect(context_loader.send(:format_size, 1536)).to eq("1.5 KB")
        expect(context_loader.send(:format_size, 2_097_152)).to eq("2.0 MB")
      end
    end
  end
end
