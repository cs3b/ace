# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "coding_agent_tools/organisms/code/prompt_builder"

RSpec.describe CodingAgentTools::Organisms::Code::PromptBuilder do
  let(:prompt_builder) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir("prompt_builder_test") }
  let(:session_dir) { File.join(temp_dir, "session") }

  before do
    FileUtils.mkdir_p(session_dir)

    # Mock molecules and atoms
    @mock_prompt_combiner = instance_double(CodingAgentTools::Molecules::Code::PromptCombiner)
    @mock_file_reader = instance_double(CodingAgentTools::Atoms::Code::FileContentReader)

    allow(CodingAgentTools::Molecules::Code::PromptCombiner).to receive(:new).and_return(@mock_prompt_combiner)
    allow(CodingAgentTools::Atoms::Code::FileContentReader).to receive(:new).and_return(@mock_file_reader)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#initialize" do
    it "initializes with prompt combiner and file reader" do
      expect(prompt_builder.instance_variable_get(:@prompt_combiner)).to eq(@mock_prompt_combiner)
      expect(prompt_builder.instance_variable_get(:@file_reader)).to eq(@mock_file_reader)
    end
  end

  describe "#build_review_prompt" do
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

    let(:target) do
      CodingAgentTools::Models::Code::ReviewTarget.new(
        type: "file_pattern",
        target_spec: "src/*.rb",
        resolved_paths: ["src/app.rb", "src/config.rb"],
        content_type: "xml",
        size_info: {files: 2, lines: 100}
      )
    end

    let(:context) do
      CodingAgentTools::Models::Code::ReviewContext.new(
        mode: "auto",
        documents: [
          {type: "blueprint", path: "README.md", content: "# Project Blueprint"},
          {type: "vision", path: "docs/vision.md", content: "# Vision"},
          {type: "architecture", path: "docs/architecture.md", content: "# Architecture"}
        ],
        loaded_at: Time.now
      )
    end

    let(:mock_prompt) do
      CodingAgentTools::Models::Code::ReviewPrompt.new(
        session_id: "test-session",
        focus_areas: ["Architecture compliance (see docs/architecture.md)"],
        system_prompt_path: "prompts/architecture.md",
        combined_content: "Combined prompt content",
        metadata: {generated_at: Time.now.iso8601}
      )
    end

    before do
      # Create target content file
      File.write(File.join(session_dir, "input.xml"), "<files><file>content</file></files>")

      # Mock file reader
      allow(@mock_file_reader).to receive(:read).with(File.join(session_dir, "input.xml")).and_return({
        success: true,
        content: "<files><file>content</file></files>"
      })

      # Mock prompt combiner
      allow(@mock_prompt_combiner).to receive(:build_prompt).and_return(mock_prompt)
      allow(@mock_prompt_combiner).to receive(:save_prompt).and_return({success: true, error: nil})
    end

    it "builds complete review prompt by orchestrating molecules" do
      result = prompt_builder.build_review_prompt(session, target, context)

      expect(@mock_prompt_combiner).to have_received(:build_prompt).with(
        session,
        "<files><file>content</file></files>",
        context,
        "architecture",
        nil
      )

      expect(@mock_prompt_combiner).to have_received(:save_prompt).with(mock_prompt, session_dir)
      expect(result).to eq(mock_prompt)
    end

    it "handles custom system prompt override" do
      custom_prompt_path = "/custom/prompt.md"

      prompt_builder.build_review_prompt(session, target, context, custom_prompt_path)

      expect(@mock_prompt_combiner).to have_received(:build_prompt).with(
        session,
        "<files><file>content</file></files>",
        context,
        "architecture",
        custom_prompt_path
      )
    end

    context "when target uses diff content" do
      let(:diff_target) do
        CodingAgentTools::Models::Code::ReviewTarget.new(
          type: "git_diff",
          target_spec: "HEAD~1..HEAD",
          resolved_paths: [],
          content_type: "diff",
          size_info: {lines: 50}
        )
      end

      before do
        File.write(File.join(session_dir, "input.diff"), "diff content here")

        allow(@mock_file_reader).to receive(:read).with(File.join(session_dir, "input.diff")).and_return({
          success: true,
          content: "diff content here"
        })
      end

      it "loads diff content correctly" do
        prompt_builder.build_review_prompt(session, diff_target, context)

        expect(@mock_prompt_combiner).to have_received(:build_prompt).with(
          session,
          "diff content here",
          context,
          "architecture",
          nil
        )
      end
    end

    context "when file reading fails" do
      before do
        allow(@mock_file_reader).to receive(:read).and_return({
          success: false,
          error: "File not found"
        })
      end

      it "raises error when content cannot be loaded" do
        expect {
          prompt_builder.build_review_prompt(session, target, context)
        }.to raise_error("Failed to read target content: File not found")
      end
    end

    context "when prompt saving fails" do
      before do
        allow(@mock_prompt_combiner).to receive(:save_prompt).and_return({
          success: false,
          error: "Save failed"
        })
      end

      it "raises error when prompt cannot be saved" do
        expect {
          prompt_builder.build_review_prompt(session, target, context)
        }.to raise_error("Failed to save prompt: Save failed")
      end
    end

    context "with unknown content type" do
      let(:unknown_target) do
        CodingAgentTools::Models::Code::ReviewTarget.new(
          type: "unknown",
          target_spec: "unknown",
          resolved_paths: [],
          content_type: "unknown",
          size_info: {}
        )
      end

      it "raises error for unknown content type" do
        expect {
          prompt_builder.build_review_prompt(session, unknown_target, context)
        }.to raise_error("Unknown content type: unknown")
      end
    end
  end

  describe "#select_system_prompt" do
    it "delegates to prompt combiner" do
      expected_path = "prompts/architecture.md"

      expect(@mock_prompt_combiner).to receive(:select_system_prompt).with("architecture", nil).and_return(expected_path)

      result = prompt_builder.select_system_prompt("architecture")
      expect(result).to eq(expected_path)
    end

    it "handles custom system prompt override" do
      custom_path = "/custom/prompt.md"

      expect(@mock_prompt_combiner).to receive(:select_system_prompt).with("security", custom_path).and_return(custom_path)

      result = prompt_builder.select_system_prompt("security", custom_path)
      expect(result).to eq(custom_path)
    end
  end

  describe "#build_immediate_prompt" do
    let(:context) do
      CodingAgentTools::Models::Code::ReviewContext.new(
        mode: "auto",
        documents: [
          {type: "blueprint", path: "README.md", content: "# Project Blueprint"}
        ],
        loaded_at: Time.now
      )
    end

    let(:mock_immediate_prompt) do
      CodingAgentTools::Models::Code::ReviewPrompt.new(
        session_id: "temp-123",
        focus_areas: ["Code quality, architecture, security, performance"],
        system_prompt_path: "prompts/security.md",
        combined_content: "Immediate prompt content",
        metadata: {generated_at: Time.now.iso8601}
      )
    end

    before do
      allow(@mock_prompt_combiner).to receive(:build_prompt).and_return(mock_immediate_prompt)
      allow(Dir).to receive(:tmpdir).and_return("/tmp")
    end

    it "builds prompt for immediate use without saving" do
      target_content = "function test() { return true; }"

      result = prompt_builder.build_immediate_prompt("security", target_content, context)

      expect(@mock_prompt_combiner).to have_received(:build_prompt) do |session, content, ctx, focus|
        expect(session.session_id).to start_with("temp-")
        expect(session.session_name).to eq("temp")
        expect(session.directory_path).to eq("/tmp")
        expect(session.focus).to eq("security")
        expect(session.target).to eq("immediate")
        expect(content).to eq(target_content)
        expect(ctx).to eq(context)
        expect(focus).to eq("security")
      end

      expect(result).to eq("Immediate prompt content")
    end
  end

  describe "#get_prompt_stats" do
    let(:mock_prompt) do
      CodingAgentTools::Models::Code::ReviewPrompt.new(
        session_id: "test-session",
        focus_areas: ["Architecture compliance (see docs/architecture.md)", "Code quality, architecture, security, performance"],
        system_prompt_path: "prompts/architecture.md",
        combined_content: "---\nfocus: architecture security\ncustom: value\n---\nContent with some words here",
        metadata: {generated_at: Time.now.iso8601}
      )
    end

    # No mocking needed - multi_focus? is a real method

    it "returns comprehensive prompt statistics" do
      stats = prompt_builder.get_prompt_stats(mock_prompt)

      expect(stats).to eq({
        size_bytes: mock_prompt.content_size,
        word_count: mock_prompt.word_count,
        multi_focus: true,
        primary_focus: "Architecture compliance (see docs/architecture.md)",
        focus_count: 2,
        has_frontmatter: true,
        session_id: "test-session"
      })
    end

    context "with simple prompt" do
      let(:simple_prompt) do
        CodingAgentTools::Models::Code::ReviewPrompt.new(
          session_id: "simple-session",
          focus_areas: ["Code quality, architecture, security, performance"],
          system_prompt_path: "prompts/performance.md",
          combined_content: "Simple content",
          metadata: {}
        )
      end

      # No mocking needed - multi_focus? is a real method

      it "returns stats for simple prompt" do
        stats = prompt_builder.get_prompt_stats(simple_prompt)

        expect(stats[:multi_focus]).to be false
        expect(stats[:focus_count]).to eq(1)
        expect(stats[:has_frontmatter]).to be false
      end
    end
  end
end
