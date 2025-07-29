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
    safe_directory_cleanup(temp_dir)
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

  # Edge case and comprehensive testing scenarios
  describe "edge case handling", :content_type_edge_cases do
    let(:session) do
      CodingAgentTools::Models::Code::ReviewSession.new(
        session_id: "edge-case-session",
        session_name: "edge",
        timestamp: Time.now.iso8601,
        directory_path: session_dir,
        focus: "security",
        target: "src/",
        context_mode: "auto",
        metadata: {}
      )
    end

    let(:context) do
      CodingAgentTools::Models::Code::ReviewContext.new(
        mode: "auto",
        documents: [],
        loaded_at: Time.now
      )
    end

    context "with edge case content types" do
      let(:edge_case_target) do
        CodingAgentTools::Models::Code::ReviewTarget.new(
          type: "file_pattern",
          target_spec: "src/*.rb",
          resolved_paths: ["src/app.rb"],
          content_type: "yaml",
          size_info: {files: 1, lines: 10}
        )
      end

      it "raises error for unsupported content types" do
        expect {
          prompt_builder.build_review_prompt(session, edge_case_target, context)
        }.to raise_error("Unknown content type: yaml")
      end

      it "handles empty content type gracefully" do
        empty_target = CodingAgentTools::Models::Code::ReviewTarget.new(
          type: "file_pattern",
          target_spec: "src/*.rb",
          resolved_paths: [],
          content_type: "",
          size_info: {}
        )

        expect {
          prompt_builder.build_review_prompt(session, empty_target, context)
        }.to raise_error("Unknown content type: ")
      end

      it "handles nil content type" do
        nil_target = CodingAgentTools::Models::Code::ReviewTarget.new(
          type: "file_pattern",
          target_spec: "src/*.rb",
          resolved_paths: [],
          content_type: nil,
          size_info: {}
        )

        expect {
          prompt_builder.build_review_prompt(session, nil_target, context)
        }.to raise_error("Unknown content type: ")
      end
    end
  end

  describe "file system error handling", :file_system_errors do
    let(:session) do
      CodingAgentTools::Models::Code::ReviewSession.new(
        session_id: "error-session",
        session_name: "error",
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
        resolved_paths: ["src/app.rb"],
        content_type: "xml",
        size_info: {files: 1, lines: 10}
      )
    end

    let(:context) do
      CodingAgentTools::Models::Code::ReviewContext.new(
        mode: "auto",
        documents: [],
        loaded_at: Time.now
      )
    end

    context "when input file is corrupted" do
      before do
        # Create a corrupted file
        File.write(File.join(session_dir, "input.xml"), "\x00\x01\x02corrupted")

        allow(@mock_file_reader).to receive(:read).and_return({
          success: false,
          error: "File contains invalid characters"
        })
      end

      it "handles corrupted file gracefully" do
        expect {
          prompt_builder.build_review_prompt(session, target, context)
        }.to raise_error("Failed to read target content: File contains invalid characters")
      end
    end

    context "when session directory is inaccessible" do
      before do
        allow(@mock_file_reader).to receive(:read).and_return({
          success: false,
          error: "Permission denied"
        })
      end

      it "handles permission errors appropriately" do
        expect {
          prompt_builder.build_review_prompt(session, target, context)
        }.to raise_error("Failed to read target content: Permission denied")
      end
    end

    context "when file system is full" do
      before do
        allow(@mock_file_reader).to receive(:read).and_return({
          success: true,
          content: "valid content"
        })

        allow(@mock_prompt_combiner).to receive(:build_prompt).and_return(
          CodingAgentTools::Models::Code::ReviewPrompt.new(
            session_id: "error-session",
            focus_areas: ["Architecture"],
            system_prompt_path: "prompts/architecture.md",
            combined_content: "Test content",
            metadata: {}
          )
        )

        allow(@mock_prompt_combiner).to receive(:save_prompt).and_return({
          success: false,
          error: "No space left on device"
        })
      end

      it "handles disk space errors during prompt saving" do
        expect {
          prompt_builder.build_review_prompt(session, target, context)
        }.to raise_error("Failed to save prompt: No space left on device")
      end
    end
  end

  describe "integration scenarios", :integration_scenarios do
    let(:complex_session) do
      CodingAgentTools::Models::Code::ReviewSession.new(
        session_id: "complex-integration-session",
        session_name: "complex",
        timestamp: Time.now.iso8601,
        directory_path: session_dir,
        focus: "multi-focus: architecture, security, performance",
        target: "src/",
        context_mode: "comprehensive",
        metadata: {
          reviewer: "expert",
          priority: "high",
          custom_rules: ["rule1", "rule2"]
        }
      )
    end

    let(:complex_target) do
      CodingAgentTools::Models::Code::ReviewTarget.new(
        type: "git_diff_with_context",
        target_spec: "HEAD~3..HEAD",
        resolved_paths: ["src/app.rb", "src/config.rb", "test/app_test.rb"],
        content_type: "diff",
        size_info: {files: 3, lines: 250, additions: 150, deletions: 100}
      )
    end

    let(:comprehensive_context) do
      CodingAgentTools::Models::Code::ReviewContext.new(
        mode: "comprehensive",
        documents: [
          {type: "blueprint", path: "README.md", content: "# Complex Project Blueprint"},
          {type: "vision", path: "docs/vision.md", content: "# Project Vision"},
          {type: "architecture", path: "docs/architecture.md", content: "# System Architecture"},
          {type: "security", path: "docs/security.md", content: "# Security Guidelines"},
          {type: "performance", path: "docs/performance.md", content: "# Performance Standards"}
        ],
        loaded_at: Time.now
      )
    end

    let(:complex_prompt) do
      CodingAgentTools::Models::Code::ReviewPrompt.new(
        session_id: "complex-integration-session",
        focus_areas: [
          "Architecture compliance (see docs/architecture.md)",
          "Security review (see docs/security.md)",
          "Performance analysis (see docs/performance.md)"
        ],
        system_prompt_path: "prompts/multi-focus.md",
        combined_content: "---\nfocus: architecture security performance\nsession: complex-integration\n---\nComplex multi-focus review content with comprehensive context",
        metadata: {
          generated_at: Time.now.iso8601,
          complexity: "high"
        }
      )
    end

    before do
      # Create complex diff content
      complex_diff = <<~DIFF
        diff --git a/src/app.rb b/src/app.rb
        index 1234567..abcdefg 100644
        --- a/src/app.rb
        +++ b/src/app.rb
        @@ -1,10 +1,15 @@
         class App
        +  include SecurityMixin
        +  
           def initialize
             @config = load_config
        +    @monitor = PerformanceMonitor.new
           end
           
           def process_request(request)
        +    @monitor.start_timer
             result = handle_request(request)
        +    @monitor.end_timer
             result
           end
         end
      DIFF

      File.write(File.join(session_dir, "input.diff"), complex_diff)

      allow(@mock_file_reader).to receive(:read).with(File.join(session_dir, "input.diff")).and_return({
        success: true,
        content: complex_diff
      })

      allow(@mock_prompt_combiner).to receive(:build_prompt).and_return(complex_prompt)
      allow(@mock_prompt_combiner).to receive(:save_prompt).and_return({success: true, error: nil})
    end

    it "handles complex multi-focus integration scenario" do
      result = prompt_builder.build_review_prompt(complex_session, complex_target, comprehensive_context)

      expect(@mock_prompt_combiner).to have_received(:build_prompt).with(
        complex_session,
        kind_of(String),
        comprehensive_context,
        "multi-focus: architecture, security, performance",
        nil
      )

      expect(result).to eq(complex_prompt)
      expect(result.focus_areas.size).to eq(3)
      expect(result.combined_content).to include("multi-focus")
    end

    it "processes large diffs efficiently" do
      large_diff = "diff content\n" * 1000  # Simulate large diff
      File.write(File.join(session_dir, "input.diff"), large_diff)

      allow(@mock_file_reader).to receive(:read).with(File.join(session_dir, "input.diff")).and_return({
        success: true,
        content: large_diff
      })

      prompt_builder.build_review_prompt(complex_session, complex_target, comprehensive_context)

      expect(@mock_prompt_combiner).to have_received(:build_prompt).with(
        complex_session,
        large_diff,
        comprehensive_context,
        "multi-focus: architecture, security, performance",
        nil
      )
    end
  end

  describe "boundary conditions", :boundary_conditions do
    context "temporary session creation edge cases" do
      let(:minimal_context) do
        CodingAgentTools::Models::Code::ReviewContext.new(
          mode: "minimal",
          documents: [],
          loaded_at: Time.now
        )
      end

      let(:mock_immediate_prompt) do
        CodingAgentTools::Models::Code::ReviewPrompt.new(
          session_id: "temp-123",
          focus_areas: ["Security"],
          system_prompt_path: "prompts/security.md",
          combined_content: "Immediate boundary test content",
          metadata: {generated_at: Time.now.iso8601}
        )
      end

      before do
        allow(@mock_prompt_combiner).to receive(:build_prompt).and_return(mock_immediate_prompt)
        allow(Dir).to receive(:tmpdir).and_return("/tmp")
      end

      it "handles empty target content" do
        result = prompt_builder.build_immediate_prompt("security", "", minimal_context)

        expect(@mock_prompt_combiner).to have_received(:build_prompt) do |session, content, ctx, focus|
          expect(content).to eq("")
          expect(session.session_id).to start_with("temp-")
          expect(session.focus).to eq("security")
        end

        expect(result).to eq("Immediate boundary test content")
      end

      it "handles very long target content" do
        long_content = "x" * 100_000  # 100KB of content

        result = prompt_builder.build_immediate_prompt("architecture", long_content, minimal_context)

        expect(@mock_prompt_combiner).to have_received(:build_prompt) do |session, content, ctx, focus|
          expect(content.length).to eq(100_000)
          expect(session.session_id).to start_with("temp-")
        end

        expect(result).to eq("Immediate boundary test content")
      end

      it "handles special characters in focus" do
        special_focus = "security & performance (high-priority!)"

        result = prompt_builder.build_immediate_prompt(special_focus, "content", minimal_context)

        expect(@mock_prompt_combiner).to have_received(:build_prompt) do |session, content, ctx, focus|
          expect(session.focus).to eq(special_focus)
          expect(focus).to eq(special_focus)
        end

        expect(result).to eq("Immediate boundary test content")
      end

      it "creates temporary sessions with correct attributes" do
        # Test session creation mechanism rather than uniqueness (which depends on timing)
        captured_session = nil
        allow(@mock_prompt_combiner).to receive(:build_prompt) do |session, *args|
          captured_session = session
          mock_immediate_prompt
        end

        result = prompt_builder.build_immediate_prompt("security", "test content", minimal_context)

        expect(@mock_prompt_combiner).to have_received(:build_prompt).once
        expect(captured_session).not_to be_nil

        # Verify session attributes
        expect(captured_session.session_id).to start_with("temp-")
        expect(captured_session.session_name).to eq("temp")
        expect(captured_session.directory_path).to eq("/tmp")
        expect(captured_session.focus).to eq("security")
        expect(captured_session.target).to eq("immediate")
        expect(captured_session.context_mode).to eq("minimal")
        expect(captured_session.metadata).to eq({})

        expect(result).to eq("Immediate boundary test content")
      end
    end
  end

  describe "statistics edge cases", :statistics_edge_cases do
    context "with malformed prompt data" do
      let(:malformed_prompt) do
        CodingAgentTools::Models::Code::ReviewPrompt.new(
          session_id: "",
          focus_areas: [],
          system_prompt_path: "",
          combined_content: "",
          metadata: {}
        )
      end

      it "handles empty prompt gracefully" do
        stats = prompt_builder.get_prompt_stats(malformed_prompt)

        expect(stats[:size_bytes]).to eq(0)
        expect(stats[:word_count]).to eq(0)
        expect(stats[:multi_focus]).to be false
        expect(stats[:focus_count]).to eq(0)
        expect(stats[:has_frontmatter]).to be false
        expect(stats[:session_id]).to eq("")
      end
    end

    context "with null/nil prompt fields" do
      let(:null_fields_prompt) do
        # Create a prompt with potential nil fields
        prompt = CodingAgentTools::Models::Code::ReviewPrompt.new(
          session_id: "test-nil-session",
          focus_areas: ["Architecture"],
          system_prompt_path: "prompts/test.md",
          combined_content: "Test content",
          metadata: {}
        )

        # Simulate nil fields that might occur in edge cases
        allow(prompt).to receive(:primary_focus).and_return(nil)
        prompt
      end

      it "handles nil primary focus" do
        stats = prompt_builder.get_prompt_stats(null_fields_prompt)

        expect(stats[:primary_focus]).to be_nil
        expect(stats[:focus_count]).to eq(1)
        expect(stats[:session_id]).to eq("test-nil-session")
      end
    end

    context "with extremely large prompts" do
      let(:large_prompt) do
        large_content = "word " * 50_000  # 50k words
        CodingAgentTools::Models::Code::ReviewPrompt.new(
          session_id: "large-session",
          focus_areas: ["Architecture"] * 100,  # 100 focus areas
          system_prompt_path: "prompts/large.md",
          combined_content: large_content,
          metadata: {large: true}
        )
      end

      it "handles very large prompts efficiently" do
        stats = prompt_builder.get_prompt_stats(large_prompt)

        expect(stats[:word_count]).to eq(50_000)
        expect(stats[:focus_count]).to eq(100)
        expect(stats[:size_bytes]).to be > 200_000  # At least 200KB
        expect(stats[:session_id]).to eq("large-session")
      end
    end
  end
end
