# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "coding_agent_tools/organisms/code/review_manager"

RSpec.describe CodingAgentTools::Organisms::Code::ReviewManager do
  let(:review_manager) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir("review_manager_test") }
  let(:session_dir) { File.join(temp_dir, "session") }

  # Mock organisms
  let(:mock_session_manager) { instance_double(CodingAgentTools::Organisms::Code::SessionManager) }
  let(:mock_content_extractor) { instance_double(CodingAgentTools::Organisms::Code::ContentExtractor) }
  let(:mock_context_loader) { instance_double(CodingAgentTools::Organisms::Code::ContextLoader) }
  let(:mock_prompt_builder) { instance_double(CodingAgentTools::Organisms::Code::PromptBuilder) }

  # Mock model objects
  let(:mock_session) do
    double("ReviewSession",
      session_id: "20240101-120000",
      session_name: "review-20240101-120000",
      timestamp: "2024-01-01T12:00:00Z",
      directory_path: session_dir,
      focus: "code",
      target: "HEAD~1..HEAD",
      context_mode_with_default: "auto")
  end

  let(:mock_target) do
    double("ReviewTarget",
      type: "git_diff",
      content_type: "diff",
      file_count: 3,
      line_count: 150,
      size_info: {files: 3, lines: 150})
  end

  let(:mock_context) do
    double("ReviewContext",
      mode: "auto",
      document_count: 2)
  end

  let(:mock_prompt) do
    double("ReviewPrompt",
      word_count: 500,
      focus_areas: ["code"],
      system_prompt_path: "review/code-review.md")
  end

  before do
    # Mock organism instantiation
    allow(CodingAgentTools::Organisms::Code::SessionManager).to receive(:new).and_return(mock_session_manager)
    allow(CodingAgentTools::Organisms::Code::ContentExtractor).to receive(:new).and_return(mock_content_extractor)
    allow(CodingAgentTools::Organisms::Code::ContextLoader).to receive(:new).and_return(mock_context_loader)
    allow(CodingAgentTools::Organisms::Code::PromptBuilder).to receive(:new).and_return(mock_prompt_builder)

    # Create session directory for file operations
    FileUtils.mkdir_p(session_dir)
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#initialize" do
    it "initializes all required organisms" do
      expect(review_manager.session_manager).to eq(mock_session_manager)
      expect(review_manager.content_extractor).to eq(mock_content_extractor)
      expect(review_manager.context_loader).to eq(mock_context_loader)
      expect(review_manager.prompt_builder).to eq(mock_prompt_builder)
    end
  end

  describe "#create_review_session" do
    let(:focus) { "code" }
    let(:target) { "HEAD~1..HEAD" }
    let(:context) { "auto" }
    let(:base_path) { nil }
    let(:system_prompt_override) { nil }

    context "when all operations succeed" do
      before do
        # Setup successful organism responses
        allow(mock_session_manager).to receive(:create_session).and_return(mock_session)
        allow(mock_content_extractor).to receive(:extract_and_save).and_return(mock_target)
        allow(mock_context_loader).to receive(:load_context).and_return(mock_context)
        allow(mock_context_loader).to receive(:save_context)
        allow(mock_context_loader).to receive(:get_context_summary).and_return("Context summary")
        allow(mock_prompt_builder).to receive(:build_review_prompt).and_return(mock_prompt)

        # Mock File.write for session summary
        allow(File).to receive(:write)
      end

      it "creates a review session successfully" do
        result = review_manager.create_review_session(focus, target, context, base_path, system_prompt_override)

        expect(result[:success]).to be true
        expect(result[:error]).to be nil
        expect(result[:session]).to eq(mock_session)
        expect(result[:target]).to eq(mock_target)
        expect(result[:context]).to eq(mock_context)
        expect(result[:prompt]).to eq(mock_prompt)
      end

      it "calls session manager with correct parameters" do
        review_manager.create_review_session(focus, target, context, base_path, system_prompt_override)

        expect(mock_session_manager).to have_received(:create_session).with(
          focus: focus,
          target: target,
          context_mode: context,
          base_path: base_path
        )
      end

      it "extracts and saves content" do
        review_manager.create_review_session(focus, target, context, base_path, system_prompt_override)

        expect(mock_content_extractor).to have_received(:extract_and_save).with(target, session_dir)
      end

      it "loads and saves context" do
        review_manager.create_review_session(focus, target, context, base_path, system_prompt_override)

        expect(mock_context_loader).to have_received(:load_context).with(context, mock_session)
        expect(mock_context_loader).to have_received(:save_context).with(mock_context, session_dir)
      end

      it "builds review prompt" do
        review_manager.create_review_session(focus, target, context, base_path, system_prompt_override)

        expect(mock_prompt_builder).to have_received(:build_review_prompt).with(
          mock_session, mock_target, mock_context, system_prompt_override
        )
      end

      it "writes session summary" do
        expected_summary = include("# Code Review Session Summary")

        review_manager.create_review_session(focus, target, context, base_path, system_prompt_override)

        expect(File).to have_received(:write).with(
          File.join(session_dir, "session-summary.md"),
          expected_summary
        )
      end
    end

    context "when content extraction fails" do
      let(:error_target) do
        CodingAgentTools::Models::Code::ReviewTarget.new(
          type: "error",
          target_spec: "HEAD~1..HEAD",
          resolved_paths: [],
          content_type: "none",
          size_info: {error: "Git command failed"}
        )
      end

      before do
        allow(mock_session_manager).to receive(:create_session).and_return(mock_session)
        allow(mock_content_extractor).to receive(:extract_and_save).and_return(error_target)
      end

      it "returns error result for failed content extraction" do
        result = review_manager.create_review_session(focus, target, context, base_path, system_prompt_override)

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Failed to extract target content: Git command failed")
        expect(result[:session]).to be nil
      end
    end

    context "when an exception occurs" do
      before do
        allow(mock_session_manager).to receive(:create_session).and_raise(StandardError, "Unexpected error")
      end

      it "returns error result" do
        result = review_manager.create_review_session(focus, target, context, base_path, system_prompt_override)

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Unexpected error")
        expect(result[:session]).to be nil
      end
    end

    context "with custom system prompt" do
      let(:system_prompt_override) { "/path/to/custom-prompt.md" }

      before do
        allow(mock_session_manager).to receive(:create_session).and_return(mock_session)
        allow(mock_content_extractor).to receive(:extract_and_save).and_return(mock_target)
        allow(mock_context_loader).to receive(:load_context).and_return(mock_context)
        allow(mock_context_loader).to receive(:save_context)
        allow(mock_context_loader).to receive(:get_context_summary).and_return("Context summary")
        allow(mock_prompt_builder).to receive(:build_review_prompt).and_return(mock_prompt)
        allow(File).to receive(:write)
      end

      it "passes system prompt override to prompt builder" do
        review_manager.create_review_session(focus, target, context, base_path, system_prompt_override)

        expect(mock_prompt_builder).to have_received(:build_review_prompt).with(
          mock_session, mock_target, mock_context, system_prompt_override
        )
      end
    end
  end

  describe "#execute_review" do
    it "returns placeholder implementation response" do
      result = review_manager.execute_review(mock_session)

      expect(result[:success]).to be false
      expect(result[:error]).to eq("LLM integration not yet implemented")
      expect(result[:reports]).to eq([])
    end
  end

  describe "#finalize_session" do
    let(:reports) do
      [
        {name: "review-1", file: "review-1.md", model: "google:gemini-2.5-pro", status: "completed"},
        {name: "review-2", file: "review-2.md", model: "anthropic:claude-3-5-sonnet", status: "completed"}
      ]
    end

    before do
      # Mock file operations
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:read).and_return("")
      allow(File).to receive(:write)
      allow(Dir).to receive(:glob).and_return(["session.meta", "input.xml", "prompt.md"])
    end

    context "when finalization succeeds" do
      it "returns success" do
        result = review_manager.finalize_session(mock_session, reports)

        expect(result[:success]).to be true
        expect(result[:error]).to be nil
      end

      it "updates session index with reports" do
        include("## Review Reports")
        include("- [`review-1`](./review-1.md) - google:gemini-2.5-pro")
        expected_content = include("- [`review-2`](./review-2.md) - anthropic:claude-3-5-sonnet")

        review_manager.finalize_session(mock_session, reports)

        expect(File).to have_received(:write).with(
          File.join(session_dir, "README.md"),
          expected_content
        )
      end

      it "writes execution summary" do
        include("Session: review-20240101-120000")
        include("Target: HEAD~1..HEAD")
        include("Focus: code")
        include("- google:gemini-2.5-pro: completed")
        expected_summary = include("- anthropic:claude-3-5-sonnet: completed")

        review_manager.finalize_session(mock_session, reports)

        expect(File).to have_received(:write).with(
          File.join(session_dir, "execution.summary"),
          expected_summary
        )
      end
    end

    context "when an exception occurs" do
      before do
        allow(File).to receive(:write).and_raise(StandardError, "Write failed")
      end

      it "returns error result" do
        result = review_manager.finalize_session(mock_session, reports)

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Write failed")
      end
    end

    context "with existing README content" do
      let(:existing_readme) do
        <<~README
          # Existing Session
          
          Some existing content.
          
          ## Review Reports
          
          - Old report
          
          ## Other Section
          
          Other content.
        README
      end

      before do
        allow(File).to receive(:exist?).with(File.join(session_dir, "README.md")).and_return(true)
        allow(File).to receive(:read).with(File.join(session_dir, "README.md")).and_return(existing_readme)
      end

      it "replaces existing reports section" do
        include("## Review Reports")
        include("- [`review-1`](./review-1.md) - google:gemini-2.5-pro")
        include("## Other Section")
        expected_content = include("Other content.")

        review_manager.finalize_session(mock_session, reports)

        expect(File).to have_received(:write).with(
          File.join(session_dir, "README.md"),
          expected_content
        )
      end
    end
  end

  describe "#prepare_review" do
    let(:focus) { "code tests" }
    let(:target) { "HEAD~1..HEAD" }
    let(:context) { "auto" }
    let(:system_prompt_override) { "/custom/prompt.md" }

    let(:target_info) { {type: "git_diff", format: "diff"} }
    let(:context_info) do
      {
        available: true,
        found: [
          {type: "README", path: "README.md"},
          {type: "Architecture", path: "docs/architecture.md"}
        ]
      }
    end
    let(:system_prompt) { "review/code-review.md" }
    let(:focus_areas) { ["code review", "test analysis"] }

    before do
      # Mock diff extractor for analyze_target method
      mock_diff_extractor = instance_double(CodingAgentTools::Molecules::Code::GitDiffExtractor)
      allow(mock_content_extractor).to receive(:instance_variable_get).with(:@diff_extractor).and_return(mock_diff_extractor)
      allow(mock_diff_extractor).to receive(:git_diff_target?).with(target).and_return(true)

      allow(mock_context_loader).to receive(:check_availability).and_return(context_info)
      allow(mock_prompt_builder).to receive(:select_system_prompt).and_return(system_prompt)
      allow(CodingAgentTools::Models::Code::ReviewPrompt).to receive(:get_focus_descriptions).with("code").and_return(["code review"])
      allow(CodingAgentTools::Models::Code::ReviewPrompt).to receive(:get_focus_descriptions).with("tests").and_return(["test analysis"])
    end

    it "returns preparation results" do
      result = review_manager.prepare_review(focus, target, context, system_prompt_override)

      expect(result[:target_info]).to eq(target_info)
      expect(result[:context_info]).to eq(context_info)
      expect(result[:system_prompt]).to eq(system_prompt)
      expect(result[:focus_areas]).to eq(focus_areas)
    end

    it "checks context availability" do
      review_manager.prepare_review(focus, target, context, system_prompt_override)

      expect(mock_context_loader).to have_received(:check_availability)
    end

    it "selects system prompt" do
      review_manager.prepare_review(focus, target, context, system_prompt_override)

      expect(mock_prompt_builder).to have_received(:select_system_prompt).with(focus, system_prompt_override)
    end

    it "analyzes target" do
      # Mock the diff extractor access
      mock_diff_extractor = instance_double(CodingAgentTools::Molecules::Code::GitDiffExtractor)
      allow(mock_content_extractor).to receive(:instance_variable_get).with(:@diff_extractor).and_return(mock_diff_extractor)
      allow(mock_diff_extractor).to receive(:git_diff_target?).with(target).and_return(true)

      result = review_manager.prepare_review(focus, target, context, system_prompt_override)

      expect(result[:target_info]).to eq({type: "git_diff", format: "diff"})
    end
  end

  describe "private methods" do
    describe "#analyze_target" do
      context "when target is a git diff" do
        let(:target) { "HEAD~1..HEAD" }

        before do
          mock_diff_extractor = instance_double(CodingAgentTools::Molecules::Code::GitDiffExtractor)
          allow(mock_content_extractor).to receive(:instance_variable_get).with(:@diff_extractor).and_return(mock_diff_extractor)
          allow(mock_diff_extractor).to receive(:git_diff_target?).with(target).and_return(true)
        end

        it "returns git_diff type" do
          result = review_manager.send(:analyze_target, target)

          expect(result[:type]).to eq("git_diff")
          expect(result[:format]).to eq("diff")
        end
      end

      context "when target is a single file" do
        let(:target) { "/path/to/file.rb" }

        before do
          mock_diff_extractor = instance_double(CodingAgentTools::Molecules::Code::GitDiffExtractor)
          allow(mock_content_extractor).to receive(:instance_variable_get).with(:@diff_extractor).and_return(mock_diff_extractor)
          allow(mock_diff_extractor).to receive(:git_diff_target?).with(target).and_return(false)
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(target).and_return(true)
          allow(File).to receive(:directory?).with(target).and_return(false)
        end

        it "returns single_file type" do
          result = review_manager.send(:analyze_target, target)

          expect(result[:type]).to eq("single_file")
          expect(result[:format]).to eq("xml")
          expect(result[:path]).to eq(target)
        end
      end

      context "when target is a file pattern" do
        let(:target) { "*.rb" }

        before do
          mock_diff_extractor = instance_double(CodingAgentTools::Molecules::Code::GitDiffExtractor)
          allow(mock_content_extractor).to receive(:instance_variable_get).with(:@diff_extractor).and_return(mock_diff_extractor)
          allow(mock_diff_extractor).to receive(:git_diff_target?).with(target).and_return(false)
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(target).and_return(false)
        end

        it "returns file_pattern type" do
          result = review_manager.send(:analyze_target, target)

          expect(result[:type]).to eq("file_pattern")
          expect(result[:format]).to eq("xml")
          expect(result[:pattern]).to eq(target)
        end
      end
    end

    describe "#write_session_summary" do
      before do
        allow(File).to receive(:write)
        allow(mock_context_loader).to receive(:get_context_summary).and_return("Context summary text")
      end

      it "writes comprehensive session summary" do
        review_manager.send(:write_session_summary, mock_session, mock_target, mock_context, mock_prompt)

        expected_path = File.join(session_dir, "session-summary.md")
        include("# Code Review Session Summary")
        include("**ID**: 20240101-120000")
        include("**Name**: review-20240101-120000")
        include("**Focus**: code")
        include("**Target**: HEAD~1..HEAD")
        include("**Type**: git_diff")
        include("**Files**: 3")
        include("**Lines**: 150")
        include("**Size**: 500 words")
        expected_content = include("Context summary text")

        expect(File).to have_received(:write).with(expected_path, expected_content)
      end
    end

    describe "#update_session_index" do
      let(:reports) do
        [
          {name: "review-1", file: "review-1.md", model: "google:gemini-2.5-pro"},
          {name: "review-2", file: "review-2.md", model: "anthropic:claude-3-5-sonnet"}
        ]
      end

      before do
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:read).and_return("")
        allow(File).to receive(:write)
      end

      it "creates new index with reports section" do
        review_manager.send(:update_session_index, mock_session, reports)

        expected_path = File.join(session_dir, "README.md")
        include("## Review Reports")
        include("- [`review-1`](./review-1.md) - google:gemini-2.5-pro")
        expected_content = include("- [`review-2`](./review-2.md) - anthropic:claude-3-5-sonnet")

        expect(File).to have_received(:write).with(expected_path, expected_content)
      end
    end

    describe "#write_execution_summary" do
      let(:reports) do
        [
          {model: "google:gemini-2.5-pro", status: "completed"},
          {model: "anthropic:claude-3-5-sonnet", status: "failed"}
        ]
      end

      before do
        allow(File).to receive(:write)
        allow(Dir).to receive(:glob).and_return(["session.meta", "input.xml", "prompt.md"])
        allow(Time).to receive(:now).and_return(Time.parse("2024-01-01T15:30:00Z"))
      end

      it "writes execution summary with results" do
        review_manager.send(:write_execution_summary, mock_session, reports)

        expected_path = File.join(session_dir, "execution.summary")
        include("Session: review-20240101-120000")
        include("Target: HEAD~1..HEAD")
        include("Focus: code")
        include("- google:gemini-2.5-pro: completed")
        include("- anthropic:claude-3-5-sonnet: failed")
        include("session.meta")
        include("input.xml")
        expected_content = include("prompt.md")

        expect(File).to have_received(:write).with(expected_path, expected_content)
      end
    end
  end
end
