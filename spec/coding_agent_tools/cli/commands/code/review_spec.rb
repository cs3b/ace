# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Cli::Commands::Code::Review do
  let(:command) { described_class.new }
  let(:mock_review_manager) { instance_double("CodingAgentTools::Organisms::Code::ReviewManager") }
  let(:mock_project_root_detector) { class_double("CodingAgentTools::Atoms::ProjectRootDetector") }
  let(:temp_dir) { Dir.mktmpdir }

  before do
    allow(CodingAgentTools::Organisms::Code::ReviewManager).to receive(:new).and_return(mock_review_manager)
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return("/project/root")

    # Capture output
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:write)
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#call" do
    context "with valid focus and target" do
      let(:session_result) do
        {
          success: true,
          session: double("session",
            session_name: "review-20240101-120000",
            session_id: "20240101-120000",
            directory_path: "/sessions/review-20240101-120000",
            focus: "code"),
          target: double("target", type: "git_range", file_count: 10, line_count: 500),
          context: double("context", mode: "auto", document_count: 3)
        }
      end

      before do
        allow(mock_review_manager).to receive(:create_review_session).and_return(session_result)
      end

      it "executes successfully with valid focus" do
        result = command.call(focus: "code", target: "HEAD~1..HEAD")

        expect(result).to eq(0)
        expect(mock_review_manager).to have_received(:create_review_session).with(
          "code", "HEAD~1..HEAD", "auto", nil, nil
        )
      end

      it "handles multiple focus areas" do
        result = command.call(focus: "code tests", target: "HEAD~1..HEAD")

        expect(result).to eq(0)
        expect(mock_review_manager).to have_received(:create_review_session).with(
          "code tests", "HEAD~1..HEAD", "auto", nil, nil
        )
      end

      it "passes custom context" do
        result = command.call(focus: "code", target: "HEAD~1..HEAD", context: "docs/overview.md")

        expect(result).to eq(0)
        expect(mock_review_manager).to have_received(:create_review_session).with(
          "code", "HEAD~1..HEAD", "docs/overview.md", nil, nil
        )
      end

      it "passes base_path option" do
        result = command.call(focus: "code", target: "HEAD~1..HEAD", base_path: "/custom/path")

        expect(result).to eq(0)
        expect(mock_review_manager).to have_received(:create_review_session).with(
          "code", "HEAD~1..HEAD", "auto", "/custom/path", nil
        )
      end

      it "displays success messages" do
        command.call(focus: "code", target: "HEAD~1..HEAD")

        expect($stdout).to have_received(:puts).with("✅ Created review session: review-20240101-120000")
        expect($stdout).to have_received(:puts).with("📁 Session directory: /sessions/review-20240101-120000")
      end

      it "shows session summary" do
        command.call(focus: "code", target: "HEAD~1..HEAD")

        expect($stdout).to have_received(:puts).with("\n📊 Session Summary:")
        expect($stdout).to have_received(:puts).with("  Focus: code")
        expect($stdout).to have_received(:puts).with("  Target: git_range (10 files, 500 lines)")
        expect($stdout).to have_received(:puts).with("  Context: auto (3 documents)")
      end

      it "shows next step information when no model specified" do
        command.call(focus: "code", target: "HEAD~1..HEAD")

        expect($stdout).to have_received(:puts).with(
          "\n🔄 Next step: Execute review with llm-query or code-review --session 20240101-120000"
        )
      end
    end

    context "with invalid focus" do
      it "rejects empty focus" do
        result = command.call(focus: "", target: "HEAD~1..HEAD")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Invalid focus. Must be one or more of: code, tests, docs\n")
      end

      it "rejects invalid focus option" do
        result = command.call(focus: "invalid", target: "HEAD~1..HEAD")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Invalid focus. Must be one or more of: code, tests, docs\n")
      end

      it "rejects mixed valid and invalid focus" do
        result = command.call(focus: "code invalid tests", target: "HEAD~1..HEAD")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Invalid focus. Must be one or more of: code, tests, docs\n")
      end

      it "accepts all valid focus options" do
        ["code", "tests", "docs"].each do |focus|
          allow(mock_review_manager).to receive(:create_review_session).and_return({
            success: true,
            session: double("session", session_name: "test", session_id: "test", directory_path: "/test", focus: focus),
            target: double("target", type: "test", file_count: 1, line_count: 1),
            context: double("context", mode: "test", document_count: 1)
          })

          result = command.call(focus: focus, target: "HEAD~1..HEAD")
          expect(result).to eq(0)
        end
      end
    end

    context "with custom system prompt" do
      let(:system_prompt_file) { File.join(temp_dir, "custom-prompt.md") }

      before do
        File.write(system_prompt_file, "Custom system prompt content")
        allow(mock_review_manager).to receive(:create_review_session).and_return({
          success: true,
          session: double("session", session_name: "test", session_id: "test", directory_path: "/test", focus: "code"),
          target: double("target", type: "test", file_count: 1, line_count: 1),
          context: double("context", mode: "test", document_count: 1)
        })
      end

      it "validates system prompt file exists" do
        result = command.call(focus: "code", target: "HEAD~1..HEAD", system_prompt: "/nonexistent.md")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Custom system prompt file not found: /nonexistent.md\n")
      end

      it "validates system prompt file is readable" do
        File.chmod(0o000, system_prompt_file)
        result = command.call(focus: "code", target: "HEAD~1..HEAD", system_prompt: system_prompt_file)

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Custom system prompt file not readable: #{system_prompt_file}\n")
      ensure
        File.chmod(0o644, system_prompt_file) if File.exist?(system_prompt_file)
      end

      it "accepts valid system prompt file" do
        result = command.call(focus: "code", target: "HEAD~1..HEAD", system_prompt: system_prompt_file)

        expect(result).to eq(0)
        expect(mock_review_manager).to have_received(:create_review_session).with(
          "code", "HEAD~1..HEAD", "auto", nil, system_prompt_file
        )
      end
    end

    context "with session resume" do
      it "calls resume_session when session option provided" do
        allow(command).to receive(:resume_session).and_return(0)

        result = command.call(focus: "code", target: "HEAD~1..HEAD", session: "existing-session-id")

        expect(result).to eq(0)
        expect(command).to have_received(:resume_session).with("existing-session-id", hash_including(session: "existing-session-id"))
      end

      it "returns error for unimplemented session resume" do
        result = command.call(focus: "code", target: "HEAD~1..HEAD", session: "existing-session-id")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Session resume not yet implemented\n")
      end
    end

    context "with dry run" do
      let(:prep_result) do
        {
          target_info: {type: "git_range", format: "commit_range"},
          context_info: {
            available: true,
            found: [
              {type: "README", path: "README.md"},
              {type: "Architecture", path: "docs/architecture.md"}
            ]
          },
          system_prompt: "review/code-review.md",
          focus_areas: ["code"]
        }
      end

      before do
        allow(mock_review_manager).to receive(:prepare_review).and_return(prep_result)
        allow(mock_review_manager).to receive(:create_review_session)
      end

      it "executes dry run without creating session" do
        result = command.call(focus: "code", target: "HEAD~1..HEAD", dry_run: true)

        expect(result).to eq(0)
        expect(mock_review_manager).to have_received(:prepare_review).with("code", "HEAD~1..HEAD", "auto", nil)
        expect(mock_review_manager).not_to have_received(:create_review_session)
      end

      it "shows dry run analysis output" do
        command.call(focus: "code", target: "HEAD~1..HEAD", dry_run: true)

        expect($stdout).to have_received(:puts).with("🔍 Dry run - Analyzing review configuration:")
        expect($stdout).to have_received(:puts).with("\nTarget Analysis:")
        expect($stdout).to have_received(:puts).with("  Type: git_range")
        expect($stdout).to have_received(:puts).with("  Format: commit_range")
      end

      it "shows context availability" do
        command.call(focus: "code", target: "HEAD~1..HEAD", dry_run: true)

        expect($stdout).to have_received(:puts).with("\nContext Availability:")
        expect($stdout).to have_received(:puts).with("  ✅ Project context available")
        expect($stdout).to have_received(:puts).with("    - README: README.md")
        expect($stdout).to have_received(:puts).with("    - Architecture: docs/architecture.md")
      end

      it "shows no context when unavailable" do
        prep_result[:context_info][:available] = false
        command.call(focus: "code", target: "HEAD~1..HEAD", dry_run: true)

        expect($stdout).to have_received(:puts).with("  ❌ No project context found")
      end

      it "shows custom system prompt" do
        custom_prompt_file = File.join(temp_dir, "custom.md")
        File.write(custom_prompt_file, "Custom prompt content")

        command.call(focus: "code", target: "HEAD~1..HEAD", dry_run: true, system_prompt: custom_prompt_file)

        expect($stdout).to have_received(:puts).with("\nSystem Prompt: review/code-review.md (custom)")
      end
    end

    context "with model execution" do
      let(:session_result) do
        {
          success: true,
          session: double("session",
            session_name: "review-20240101-120000",
            session_id: "20240101-120000",
            directory_path: "/sessions/review-20240101-120000",
            focus: "code"),
          target: double("target", type: "git_range", file_count: 10, line_count: 500),
          context: double("context", mode: "auto", document_count: 3)
        }
      end

      before do
        allow(mock_review_manager).to receive(:create_review_session).and_return(session_result)
        allow(mock_review_manager).to receive(:execute_review).and_return({success: true})
      end

      it "executes review with specified model" do
        result = command.call(focus: "code", target: "HEAD~1..HEAD", model: "google:gemini-2.5-pro")

        expect(result).to eq(0)
        expect($stdout).to have_received(:puts).with("\n🚀 Executing review with model: google:gemini-2.5-pro")
        expect(mock_review_manager).to have_received(:execute_review).with(session_result[:session])
      end

      it "shows success message on successful execution" do
        command.call(focus: "code", target: "HEAD~1..HEAD", model: "google:gemini-2.5-pro")

        expect($stdout).to have_received(:puts).with("✅ Review completed successfully")
      end

      it "saves output to file when specified" do
        command.call(focus: "code", target: "HEAD~1..HEAD", model: "test", output: "report.md")

        expect($stdout).to have_received(:puts).with("📄 Report saved to: report.md")
      end

      it "handles execution failure" do
        allow(mock_review_manager).to receive(:execute_review).and_return({success: false, error: "Model failed"})

        command.call(focus: "code", target: "HEAD~1..HEAD", model: "test")

        expect($stderr).to have_received(:write).with("❌ Review failed: Model failed\n")
      end
    end

    context "with session creation failure" do
      before do
        allow(mock_review_manager).to receive(:create_review_session).and_return({
          success: false,
          error: "Target validation failed"
        })
      end

      it "returns error code and shows error message" do
        result = command.call(focus: "code", target: "invalid-target")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Target validation failed\n")
      end
    end

    context "with exceptions" do
      before do
        allow(mock_review_manager).to receive(:create_review_session).and_raise(StandardError, "Unexpected error")
      end

      it "handles exceptions gracefully" do
        result = command.call(focus: "code", target: "HEAD~1..HEAD")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Unexpected error\n")
      end

      it "shows backtrace in debug mode" do
        ENV["DEBUG"] = "true"

        result = command.call(focus: "code", target: "HEAD~1..HEAD")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with(match(/Error: Unexpected error/))
      ensure
        ENV.delete("DEBUG")
      end
    end
  end

  describe "private methods" do
    describe "#validate_focus" do
      it "accepts single valid focus" do
        expect(command.send(:validate_focus, "code")).to be true
        expect(command.send(:validate_focus, "tests")).to be true
        expect(command.send(:validate_focus, "docs")).to be true
      end

      it "accepts multiple valid focus areas" do
        expect(command.send(:validate_focus, "code tests")).to be true
        expect(command.send(:validate_focus, "code tests docs")).to be true
        expect(command.send(:validate_focus, "tests docs")).to be true
      end

      it "rejects invalid focus" do
        expect(command.send(:validate_focus, "invalid")).to be false
        expect(command.send(:validate_focus, "code invalid")).to be false
        expect(command.send(:validate_focus, "")).to be false
      end

      it "rejects empty focus" do
        expect(command.send(:validate_focus, "")).to be false
      end
    end
  end

  describe "command configuration" do
    it "has correct description" do
      expect(described_class.description).to eq("Execute code review on specified target with configurable focus")
    end

    it "defines required arguments" do
      # Test that required arguments are enforced by attempting calls without them
      expect { command.call }.to raise_error(ArgumentError)
      expect { command.call(focus: "code") }.to raise_error(ArgumentError)
    end

    it "has usage examples defined" do
      # This tests that examples are provided for the command
      expect(described_class).to respond_to(:example)
    end
  end
end
