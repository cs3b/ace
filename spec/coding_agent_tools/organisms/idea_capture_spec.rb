# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/organisms/idea_capture"
require "tempfile"
require "fileutils"

RSpec.describe CodingAgentTools::Organisms::IdeaCapture do
  let(:temp_dir) { Dir.mktmpdir("idea_capture_test") }
  let(:debug) { false }
  let(:big_user_input_allowed) { false }
  let(:model) { "gflash" }
  let(:commit_after_capture) { false }

  # Mock molecule dependencies
  let(:mock_context_loader) { instance_double(CodingAgentTools::Molecules::ContextLoader) }
  let(:mock_idea_enhancer) { instance_double(CodingAgentTools::Molecules::IdeaEnhancer) }
  let(:mock_path_resolver) { instance_double(CodingAgentTools::Molecules::PathResolver) }
  let(:mock_llm_client) { instance_double(CodingAgentTools::Molecules::LLMClient) }

  subject do
    described_class.new(
      model: model,
      debug: debug,
      big_user_input_allowed: big_user_input_allowed,
      commit_after_capture: commit_after_capture
    )
  end

  before do
    # Mock molecule initialization
    allow(CodingAgentTools::Molecules::ContextLoader).to receive(:new).and_return(mock_context_loader)
    allow(CodingAgentTools::Molecules::IdeaEnhancer).to receive(:new).and_return(mock_idea_enhancer)
    allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(mock_path_resolver)
    allow(CodingAgentTools::Molecules::LLMClient).to receive(:new).and_return(mock_llm_client)

    # Add default stubs for File operations to handle unexpected calls
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:write).and_call_original
    allow(FileUtils).to receive(:mkdir_p).and_call_original

    # Add default stubs for molecule methods
    allow(mock_context_loader).to receive(:load_docs_context).and_return({success: true, context: ""})
    allow(mock_path_resolver).to receive(:generate_capture_idea_paths).and_return({
      success: true,
      input_path: File.join(temp_dir, "idea-input.md"),
      system_path: File.join(temp_dir, "system.prompt.md"),
      output_path: File.join(temp_dir, "enhanced-idea.md")
    })
    allow(mock_llm_client).to receive(:enhance_idea).and_return(double(success?: true, error: nil))
    allow(mock_idea_enhancer).to receive(:validate_idea_content).and_return({valid: true})
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#initialize" do
    context "with default parameters" do
      subject { described_class.new }

      it "initializes with default model" do
        expect(subject.instance_variable_get(:@model)).to eq("google:gemini-2.5-flash-lite")
      end

      it "initializes with debug disabled" do
        expect(subject.instance_variable_get(:@debug)).to be false
      end

      it "initializes with big input disabled by default" do
        expect(subject.instance_variable_get(:@big_user_input_allowed)).to be false
      end

      it "sets max input size to BIG_INPUT_THRESHOLD when big input is disabled" do
        expect(subject.instance_variable_get(:@max_input_size)).to eq(described_class::BIG_INPUT_THRESHOLD)
      end
    end

    context "with custom parameters" do
      let(:model) { "claude" }
      let(:debug) { true }
      let(:big_user_input_allowed) { true }

      it "initializes with custom model" do
        expect(subject.instance_variable_get(:@model)).to eq("claude")
      end

      it "initializes with debug enabled" do
        expect(subject.instance_variable_get(:@debug)).to be true
      end

      it "initializes with big input allowed" do
        expect(subject.instance_variable_get(:@big_user_input_allowed)).to be true
      end

      it "sets max input size to infinity when big input is allowed" do
        expect(subject.instance_variable_get(:@max_input_size)).to eq(Float::INFINITY)
      end
    end

    it "initializes molecule dependencies correctly" do
      # Create an instance to trigger the constructor calls
      described_class.new

      expect(CodingAgentTools::Molecules::ContextLoader).to have_received(:new)
      expect(CodingAgentTools::Molecules::IdeaEnhancer).to have_received(:new)
      expect(CodingAgentTools::Molecules::PathResolver).to have_received(:new)
      expect(CodingAgentTools::Molecules::LLMClient).to have_received(:new).with(model: "google:gemini-2.5-flash-lite", debug: false)
    end
  end

  describe "#capture_idea" do
    let(:idea_text) { "This is a great idea for improving the workflow" }
    let(:input_path) { File.join(temp_dir, "idea-input.md") }
    let(:system_path) { File.join(temp_dir, "system-prompt.md") }
    let(:output_path) { File.join(temp_dir, "enhanced-idea.md") }

    let(:path_generation_result) do
      {
        success: true,
        input_path: input_path,
        system_path: system_path,
        output_path: output_path
      }
    end

    let(:context_result) do
      {
        success: true,
        context: "Project context information",
        files_loaded: 3,
        files_failed: 0
      }
    end

    let(:llm_result) do
      instance_double(CodingAgentTools::Molecules::LLMClient::LLMResult, success?: true, error_message: nil)
    end

    before do
      # Create temp directories
      FileUtils.mkdir_p(temp_dir)
      FileUtils.mkdir_p(File.dirname(input_path))
      FileUtils.mkdir_p(File.dirname(output_path))

      # Mock successful path generation
      allow(mock_path_resolver).to receive(:generate_capture_idea_paths)
        .with(idea_text)
        .and_return(path_generation_result)

      # Mock successful context loading
      allow(mock_context_loader).to receive(:load_docs_context)
        .and_return(context_result)

      # Mock successful system prompt template loading
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(anything).and_return(true)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(anything).and_return("System prompt template")
      allow(File).to receive(:write).and_call_original

      # Mock successful LLM enhancement
      allow(mock_llm_client).to receive(:enhance_idea)
        .with(input_path: input_path, system_path: system_path, output_path: output_path)
        .and_return(llm_result)
    end

    context "with valid input" do
      it "returns successful result" do
        result = subject.capture_idea(idea_text)

        expect(result).to be_a(described_class::CaptureResult)
        expect(result.success?).to be true
        expect(result.output_path).to eq(output_path)
        expect(result.error_message).to be_nil
      end

      it "generates paths using path resolver" do
        subject.capture_idea(idea_text)

        expect(mock_path_resolver).to have_received(:generate_capture_idea_paths).with(idea_text)
      end

      it "saves raw idea to input file" do
        expect(File).to receive(:write).with(input_path, idea_text.strip)

        subject.capture_idea(idea_text)
      end

      it "loads project context" do
        subject.capture_idea(idea_text)

        expect(mock_context_loader).to have_received(:load_docs_context)
      end

      it "enhances idea using LLM client" do
        subject.capture_idea(idea_text)

        expect(mock_llm_client).to have_received(:enhance_idea).with(
          input_path: input_path,
          system_path: system_path,
          output_path: output_path
        )
      end

      context "with debug enabled" do
        let(:debug) { true }

        it "includes debug information in result" do
          result = subject.capture_idea(idea_text)

          expect(result.debug_info).to eq("Enhancement completed")
        end

        it "outputs debug messages" do
          expect(subject).to receive(:puts).with("Debug: Starting idea capture process")
          expect(subject).to receive(:puts).with(/Debug: Generated paths:/)
          expect(subject).to receive(:puts).with(/Debug: Saved raw idea to:/)
          expect(subject).to receive(:puts).with(/Debug: Context loading result:/)
          expect(subject).to receive(:puts).with(/Debug: Generated system prompt:/)
          expect(subject).to receive(:puts).with("Debug: Idea enhancement completed successfully")

          subject.capture_idea(idea_text)
        end
      end
    end

    context "input validation" do
      context "with nil input" do
        it "returns failure result" do
          result = subject.capture_idea(nil)

          expect(result.success?).to be false
          expect(result.error_message).to eq("Idea text cannot be nil")
        end
      end

      context "with empty input" do
        it "returns failure result" do
          result = subject.capture_idea("   ")

          expect(result.success?).to be false
          expect(result.error_message).to eq("Idea text cannot be empty")
        end
      end

      context "with input too short" do
        it "returns failure result" do
          result = subject.capture_idea("Hi")

          expect(result.success?).to be false
          expect(result.error_message).to eq("Idea text must be at least 5 characters")
        end
      end

      context "with input too large" do
        let(:large_input) { "a" * (described_class::BIG_INPUT_THRESHOLD + 1000) }

        context "when big input is not allowed" do
          it "returns failure result with size information" do
            result = subject.capture_idea(large_input)

            expect(result.success?).to be false
            expect(result.error_message).to include("Input too large:")
            expect(result.error_message).to include("KB")
            expect(result.error_message).to include("words")
            expect(result.error_message).to include("Use --big-user-input-allowed to proceed")
          end
        end

        context "when big input is allowed" do
          let(:big_user_input_allowed) { true }

          it "accepts large input" do
            # Mock the path resolver to handle large input specifically
            allow(mock_path_resolver).to receive(:generate_capture_idea_paths).with(large_input).and_return({
              success: true,
              input_path: File.join(temp_dir, "idea-input.md"),
              system_path: File.join(temp_dir, "system.prompt.md"),
              output_path: File.join(temp_dir, "enhanced-idea.md")
            })

            result = subject.capture_idea(large_input)

            expect(result.success?).to be true
          end
        end
      end
    end

    context "path generation failures" do
      before do
        allow(mock_path_resolver).to receive(:generate_capture_idea_paths)
          .and_return(success: false, error: "Path generation failed")
      end

      it "returns failure result" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be false
        expect(result.error_message).to eq("Path generation failed: Path generation failed")
      end
    end

    context "file save failures" do
      before do
        allow(File).to receive(:write).with(input_path, anything).and_raise(Errno::EACCES, "Permission denied")
      end

      it "returns failure result" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be false
        expect(result.error_message).to include("Failed to save raw idea:")
      end
    end

    context "context loading failures" do
      before do
        allow(mock_context_loader).to receive(:load_docs_context)
          .and_return(success: false, error: "Context loading failed")
      end

      it "continues with system prompt generation" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be true
      end
    end

    context "system prompt generation failures" do
      before do
        allow(File).to receive(:exist?).with(anything).and_return(false)
      end

      it "returns failure result" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be false
        expect(result.error_message).to include("System prompt template not found:")
      end
    end

    context "LLM enhancement failures" do
      let(:failed_llm_result) do
        instance_double(
          CodingAgentTools::Molecules::LLMClient::LLMResult,
          success?: false,
          error_message: "LLM service unavailable"
        )
      end

      before do
        allow(mock_llm_client).to receive(:enhance_idea)
          .and_return(failed_llm_result)
      end

      it "saves fallback idea with error information" do
        expected_content = "# Raw Idea (Enhanced Version Failed)\n\n"
        expected_content += "**Enhancement Error:** LLM service unavailable\n\n"
        expected_content += "## Original Idea\n\n#{idea_text.strip}"

        expect(File).to receive(:write).with(output_path, expected_content)

        result = subject.capture_idea(idea_text)

        expect(result.success?).to be true
        expect(result.output_path).to eq(output_path)
        expect(result.debug_info).to eq("Saved raw idea due to enhancement failure")
      end

      context "when fallback save also fails" do
        before do
          allow(File).to receive(:write).with(output_path, anything).and_raise(Errno::ENOSPC, "No space left")
        end

        it "returns failure result" do
          result = subject.capture_idea(idea_text)

          expect(result.success?).to be false
          expect(result.error_message).to include("Failed to save fallback idea:")
        end
      end
    end

    context "unexpected errors during capture" do
      before do
        allow(mock_path_resolver).to receive(:generate_capture_idea_paths)
          .and_raise(StandardError, "Unexpected system error")
      end

      it "returns failure result with error details" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be false
        expect(result.error_message).to include("Unexpected error during idea capture: Unexpected system error")
      end

      context "with debug enabled" do
        let(:debug) { true }

        it "includes backtrace in debug details" do
          result = subject.capture_idea(idea_text)

          expect(result.debug_info).to be_a(String)
          expect(result.debug_info).to include("spec/coding_agent_tools/organisms/idea_capture_spec.rb")
        end
      end
    end
  end

  describe "system prompt generation" do
    let(:project_root) { File.expand_path("../../../../../", __FILE__) }
    let(:template_path) { File.join(project_root, "dev-handbook/templates/idea-manager/system.prompt.md") }
    let(:idea_template_path) { File.join(project_root, "dev-handbook/templates/idea-manager/idea.template.md") }
    let(:system_path) { File.join(temp_dir, "system.md") }

    let(:context_result) do
      {
        success: true,
        context: "Project context information"
      }
    end

    let(:system_template) { "System prompt template content" }
    let(:idea_template) { "Idea template content" }

    before do
      FileUtils.mkdir_p(temp_dir)
    end

    context "with successful template loading" do
      before do
        allow(File).to receive(:exist?).with(template_path).and_return(true)
        allow(File).to receive(:exist?).with(idea_template_path).and_return(true)
        allow(File).to receive(:read).with(template_path).and_return(system_template)
        allow(File).to receive(:read).with(idea_template_path).and_return(idea_template)
        allow(File).to receive(:write).and_call_original
      end

      it "generates system prompt with project context" do
        expected_content = system_template
        expected_content += "\n\n## Project Context\n\n"
        expected_content += context_result[:context]
        expected_content += "\n\n## Template Format\n\nUse this exact template format:\n\n```markdown\n"
        expected_content += idea_template
        expected_content += "\n```"

        expect(File).to receive(:write).with(system_path, expected_content)

        result = subject.send(:generate_system_prompt, context_result, system_path)
        expect(result.success?).to be true
      end

      context "without project context" do
        let(:context_result) { {success: false, error: "No context"} }

        it "generates system prompt without context section" do
          expected_content = system_template
          expected_content += "\n\n## Template Format\n\nUse this exact template format:\n\n```markdown\n"
          expected_content += idea_template
          expected_content += "\n```"

          expect(File).to receive(:write).with(system_path, expected_content)

          result = subject.send(:generate_system_prompt, context_result, system_path)
          expect(result.success?).to be true
        end
      end

      context "without idea template" do
        before do
          allow(File).to receive(:exist?).with(idea_template_path).and_return(false)
        end

        it "generates system prompt without template format section" do
          expected_content = system_template
          expected_content += "\n\n## Project Context\n\n"
          expected_content += context_result[:context]

          expect(File).to receive(:write).with(system_path, expected_content)

          result = subject.send(:generate_system_prompt, context_result, system_path)
          expect(result.success?).to be true
        end
      end
    end

    context "with missing system template" do
      before do
        allow(File).to receive(:exist?).with(template_path).and_return(false)
      end

      it "returns failure result" do
        result = subject.send(:generate_system_prompt, context_result, system_path)

        expect(result.success?).to be false
        expect(result.error_message).to include("System prompt template not found:")
      end
    end

    context "with file write error" do
      before do
        allow(File).to receive(:exist?).with(template_path).and_return(true)
        allow(File).to receive(:read).with(template_path).and_return(system_template)
        allow(File).to receive(:write).with(system_path, anything).and_raise(Errno::EACCES, "Permission denied")
      end

      it "returns failure result" do
        result = subject.send(:generate_system_prompt, context_result, system_path)

        expect(result.success?).to be false
        expect(result.error_message).to include("Failed to generate system prompt:")
      end
    end
  end

  describe "minimum guarantee functionality" do
    let(:idea_text) { "Important idea that must be saved" }
    let(:output_path) { File.join(temp_dir, "saved-idea.md") }

    before do
      FileUtils.mkdir_p(temp_dir)
    end

    context "when all enhancement steps fail" do
      before do
        # Mock path generation to succeed but everything else to fail
        allow(mock_path_resolver).to receive(:generate_capture_idea_paths)
          .and_return(
            success: true,
            input_path: File.join(temp_dir, "input.md"),
            system_path: File.join(temp_dir, "system.md"),
            output_path: output_path
          )

        # Mock raw idea save to succeed
        allow(File).to receive(:write).and_call_original

        # Mock system prompt generation to fail
        allow(File).to receive(:exist?).and_return(false)
      end

      it "still tries to capture the core idea" do
        result = subject.capture_idea(idea_text)

        # Should fail due to system prompt template not found, but raw idea should be saved
        expect(result.success?).to be false
        expect(File).to have_received(:write).with(anything, idea_text.strip)
      end
    end

    context "when LLM enhancement fails but fallback save succeeds" do
      let(:input_path) { File.join(temp_dir, "input.md") }
      let(:system_path) { File.join(temp_dir, "system.md") }

      before do
        # Mock all steps to succeed except LLM enhancement
        allow(mock_path_resolver).to receive(:generate_capture_idea_paths)
          .and_return(
            success: true,
            input_path: input_path,
            system_path: system_path,
            output_path: output_path
          )

        allow(mock_context_loader).to receive(:load_docs_context)
          .and_return(success: true, context: "Context")

        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).and_return("template")
        allow(File).to receive(:write).and_call_original

        # Mock LLM to fail
        failed_llm_result = instance_double(
          CodingAgentTools::Molecules::LLMClient::LLMResult,
          success?: false,
          error_message: "Service unavailable"
        )
        allow(mock_llm_client).to receive(:enhance_idea).and_return(failed_llm_result)
      end

      it "saves raw idea as fallback ensuring minimum guarantee" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be true
        expect(result.output_path).to eq(output_path)

        # Verify fallback content structure
        expect(File).to have_received(:write).with(
          output_path,
          "# Raw Idea (Enhanced Version Failed)\n\n**Enhancement Error:** Service unavailable\n\n## Original Idea\n\n#{idea_text.strip}"
        )
      end
    end
  end

  describe "CaptureResult struct" do
    it "has success? predicate method" do
      success_result = described_class::CaptureResult.new(true, "/path", nil, nil)
      failure_result = described_class::CaptureResult.new(false, nil, "error", nil)

      expect(success_result.success?).to be true
      expect(failure_result.success?).to be false
    end

    it "provides access to all result fields" do
      result = described_class::CaptureResult.new(
        true,
        "/output/path",
        nil,
        "debug info"
      )

      expect(result.success).to be true
      expect(result.output_path).to eq("/output/path")
      expect(result.error_message).to be_nil
      expect(result.debug_info).to eq("debug info")
    end
  end

  describe "constants" do
    it "defines expected constants" do
      expect(described_class::DEFAULT_MAX_INPUT_SIZE).to eq(7000)
      expect(described_class::BIG_INPUT_THRESHOLD).to eq(7000)
    end
  end

  describe "orchestration behavior" do
    let(:idea_text) { "Test orchestration of all components" }

    context "with successful complete workflow" do
      before do
        # Setup complete successful mock chain
        allow(mock_path_resolver).to receive(:generate_capture_idea_paths)
          .and_return(
            success: true,
            input_path: File.join(temp_dir, "input.md"),
            system_path: File.join(temp_dir, "system.md"),
            output_path: File.join(temp_dir, "output.md")
          )

        allow(mock_context_loader).to receive(:load_docs_context)
          .and_return(success: true, context: "Context")

        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).and_return("template")
        allow(File).to receive(:write).and_call_original

        success_llm_result = instance_double(
          CodingAgentTools::Molecules::LLMClient::LLMResult,
          success?: true
        )
        allow(mock_llm_client).to receive(:enhance_idea).and_return(success_llm_result)

        FileUtils.mkdir_p(temp_dir)
      end

      it "orchestrates all molecules in correct sequence" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be true

        # Verify orchestration sequence
        expect(mock_path_resolver).to have_received(:generate_capture_idea_paths).ordered
        expect(mock_context_loader).to have_received(:load_docs_context).ordered
        expect(mock_llm_client).to have_received(:enhance_idea).ordered
      end
    end

    context "with degraded functionality" do
      before do
        # Setup partial failure scenario
        allow(mock_path_resolver).to receive(:generate_capture_idea_paths)
          .and_return(
            success: true,
            input_path: File.join(temp_dir, "input.md"),
            system_path: File.join(temp_dir, "system.md"),
            output_path: File.join(temp_dir, "output.md")
          )

        # Context loading fails, but system prompt generation succeeds
        allow(mock_context_loader).to receive(:load_docs_context)
          .and_return(success: false, error: "Context unavailable")

        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).and_return("template")
        allow(File).to receive(:write).and_call_original

        success_llm_result = instance_double(
          CodingAgentTools::Molecules::LLMClient::LLMResult,
          success?: true
        )
        allow(mock_llm_client).to receive(:enhance_idea).and_return(success_llm_result)

        FileUtils.mkdir_p(temp_dir)
      end

      it "continues processing with degraded functionality" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be true
        expect(mock_context_loader).to have_received(:load_docs_context)
        expect(mock_llm_client).to have_received(:enhance_idea)
      end
    end
  end

  describe "commit_after_capture functionality" do
    let(:idea_text) { "Test idea for commit functionality" }
    let(:output_path) { File.join(temp_dir, "enhanced-idea.md") }

    before do
      # Setup successful idea capture
      success_llm_result = instance_double(
        CodingAgentTools::Molecules::LLMClient::LLMResult,
        success?: true
      )
      allow(mock_llm_client).to receive(:enhance_idea).and_return(success_llm_result)

      FileUtils.mkdir_p(temp_dir)
    end

    context "when commit_after_capture is true" do
      let(:commit_after_capture) { true }

      it "executes git-commit after successful idea creation" do
        allow(subject).to receive(:test_environment?).and_return(false)
        allow(subject).to receive(:execute_git_commit).and_return(true)

        result = subject.capture_idea(idea_text)

        expect(result.success?).to be true
        expect(subject).to have_received(:execute_git_commit).with(output_path)
      end

      it "handles git-commit execution errors gracefully" do
        allow(subject).to receive(:test_environment?).and_return(false)
        allow(subject).to receive(:execute_git_commit).and_raise(StandardError.new("git failed"))

        result = subject.capture_idea(idea_text)

        expect(result.success?).to be true  # Idea creation still succeeds
        expect(result.error_message).to include("git failed")
      end

      context "in test environment" do
        it "skips git-commit execution when CI environment is detected" do
          with_env("CI" => "true") do
            allow(subject).to receive(:execute_git_commit)

            result = subject.capture_idea(idea_text)

            expect(result.success?).to be true
            expect(subject).not_to have_received(:execute_git_commit)
          end
        end

        it "skips git-commit execution when TEST environment is detected" do
          with_env("TEST" => "1") do
            allow(subject).to receive(:execute_git_commit)

            result = subject.capture_idea(idea_text)

            expect(result.success?).to be true
            expect(subject).not_to have_received(:execute_git_commit)
          end
        end
      end
    end

    context "when commit_after_capture is false" do
      let(:commit_after_capture) { false }

      it "does not execute git-commit after idea creation" do
        allow(subject).to receive(:execute_git_commit)

        result = subject.capture_idea(idea_text)

        expect(result.success?).to be true
        expect(subject).not_to have_received(:execute_git_commit)
      end
    end

    context "when idea creation fails" do
      let(:commit_after_capture) { true }

      before do
        # Make LLM enhancement fail
        failed_llm_result = instance_double(
          CodingAgentTools::Molecules::LLMClient::LLMResult,
          success?: false,
          error_message: "LLM enhancement failed"
        )
        allow(mock_llm_client).to receive(:enhance_idea).and_return(failed_llm_result)
      end

      it "does not attempt git-commit" do
        allow(subject).to receive(:execute_git_commit)

        result = subject.capture_idea(idea_text)

        # Should still succeed due to fallback
        expect(result.success?).to be true
        expect(subject).not_to have_received(:execute_git_commit)
      end
    end
  end

  describe "#execute_git_commit" do
    let(:file_path) { "/test/path/idea.md" }
    let(:git_commit_path) { File.expand_path("../../../../exe/git-commit", __FILE__) }

    before do
      allow(File).to receive(:exist?).with(git_commit_path).and_return(true)
    end

    it "calls git-commit executable with correct file path and intention" do
      allow(subject).to receive(:system).and_return(true)

      subject.send(:execute_git_commit, file_path)

      expect(subject).to have_received(:system).with(
        git_commit_path,
        file_path,
        "--intention", "capture idea"
      )
    end

    it "raises error when git-commit executable is not found" do
      allow(File).to receive(:exist?).with(git_commit_path).and_return(false)

      expect {
        subject.send(:execute_git_commit, file_path)
      }.to raise_error(StandardError, /git-commit executable not found/)
    end

    it "raises error when git-commit fails" do
      # Mock system call to return false (failure)
      allow(subject).to receive(:system).and_return(false)

      # Mock the exit status method instead of the global variable
      allow(subject).to receive(:last_command_exit_status).and_return(1)

      expect {
        subject.send(:execute_git_commit, file_path)
      }.to raise_error(StandardError, /git-commit failed with exit status 1/)
    end
  end

  describe "#append_source_section" do
    let(:content) { "# Enhanced Idea\n\nThis is the enhanced content." }
    let(:raw_input) { "This is the raw user input" }

    it "appends SOURCE section to content" do
      result = subject.send(:append_source_section, content, raw_input)
      
      expect(result).to include(content)
      expect(result).to include("> SOURCE")
      expect(result).to include("```text")
      expect(result).to include(raw_input)
      expect(result).to include("```")
    end

    it "properly formats the SOURCE section" do
      result = subject.send(:append_source_section, content, raw_input)
      
      # Check proper formatting
      lines = result.split("\n")
      source_index = lines.index("> SOURCE")
      
      expect(source_index).not_to be_nil
      expect(lines[source_index - 1]).to eq("") # Empty line before SOURCE
      expect(lines[source_index + 1]).to eq("") # Empty line after SOURCE
      expect(lines[source_index + 2]).to eq("```text") # Code block start
      expect(lines[source_index + 3]).to eq(raw_input) # Raw input
      expect(lines[source_index + 4]).to eq("```") # Code block end
    end

    context "with markdown code blocks in raw input" do
      let(:raw_input) { "Here is code:\n```ruby\nputs 'hello'\n```\nEnd of code" }

      it "escapes code blocks properly" do
        result = subject.send(:append_source_section, content, raw_input)
        
        # Should use quad backticks to escape triple backticks in input
        expect(result).to include("````text")
        expect(result).to include("````")
        expect(result).to include(raw_input)
      end
    end

    context "with nested code blocks in raw input" do
      let(:raw_input) { "Code:\n````ruby\n```inner\ncode\n```\n````" }

      it "uses enough backticks to escape all levels" do
        result = subject.send(:append_source_section, content, raw_input)
        
        # Should use 5 backticks to escape quad backticks in input
        expect(result).to include("`````text")
        expect(result).to include("`````")
      end
    end

    context "with large input" do
      let(:large_input) { "a" * (described_class::BIG_INPUT_THRESHOLD + 1000) }
      
      context "when big input is not allowed" do
        let(:big_user_input_allowed) { false }
        
        it "truncates the input and adds truncation notice" do
          result = subject.send(:append_source_section, content, large_input)
          
          expect(result).to include("[truncated at #{described_class::BIG_INPUT_THRESHOLD} characters]")
          # Check that truncated content is correct length
          expect(result).to include("a" * described_class::BIG_INPUT_THRESHOLD)
          expect(result).not_to include("a" * (described_class::BIG_INPUT_THRESHOLD + 1))
        end
      end
      
      context "when big input is allowed" do
        let(:big_user_input_allowed) { true }
        
        it "includes full input without truncation" do
          result = subject.send(:append_source_section, content, large_input)
          
          expect(result).not_to include("[truncated")
          expect(result).to include(large_input)
        end
      end
    end

    it "strips trailing whitespace from content before appending" do
      content_with_trailing = content + "\n\n\n"
      result = subject.send(:append_source_section, content_with_trailing, raw_input)
      
      # Should have exactly 2 newlines between content and SOURCE
      expect(result).to match(/#{Regexp.escape(content.rstrip)}\n\n> SOURCE/)
    end

    it "strips whitespace from raw input" do
      raw_with_whitespace = "  \n" + raw_input + "\n\n  "
      result = subject.send(:append_source_section, content, raw_with_whitespace)
      
      expect(result).to include(raw_input)
      expect(result).not_to match(/```text\n\s+#{Regexp.escape(raw_input)}/)
    end
  end

  describe "SOURCE section integration" do
    let(:idea_text) { "This is my idea for a new feature" }
    let(:enhanced_content) { "# Enhanced Idea\n\n## Intention\n\nTo create a new feature\n\n## Details\n\nThis is the enhanced version" }
    let(:input_path) { File.join(temp_dir, "idea-input.md") }
    let(:system_path) { File.join(temp_dir, "system.prompt.md") }
    let(:output_path) { File.join(temp_dir, "enhanced-idea.md") }

    before do
      FileUtils.mkdir_p(temp_dir)
      
      # Setup successful path generation
      allow(mock_path_resolver).to receive(:generate_capture_idea_paths).and_return({
        success: true,
        input_path: input_path,
        system_path: system_path,
        output_path: output_path
      })

      # Mock successful context loading
      allow(mock_context_loader).to receive(:load_docs_context).and_return({
        success: true,
        context: "Project context"
      })

      # Mock template files
      project_root = File.expand_path("../../../../../", __FILE__)
      template_path = File.join(project_root, "dev-handbook/templates/idea-manager/system.prompt.md")
      idea_template_path = File.join(project_root, "dev-handbook/templates/idea-manager/idea.template.md")
      
      allow(File).to receive(:exist?).with(template_path).and_return(true)
      allow(File).to receive(:exist?).with(idea_template_path).and_return(true)
      allow(File).to receive(:read).with(template_path).and_return("System template")
      allow(File).to receive(:read).with(idea_template_path).and_return("Idea template")
    end

    context "when enhancement succeeds" do
      before do
        # Mock successful LLM enhancement
        allow(mock_llm_client).to receive(:enhance_idea).and_return(
          CodingAgentTools::Molecules::LLMClient::LLMResult.new(true, output_path, nil, 0)
        )

        # Mock the enhanced content being written by LLM
        allow(File).to receive(:read).with(output_path).and_return(enhanced_content)
      end

      it "appends SOURCE section to enhanced idea" do
        # Expect the file to be written with SOURCE section
        expect(File).to receive(:write).with(output_path, anything) do |path, content|
          expect(content).to include(enhanced_content)
          expect(content).to include("> SOURCE")
          expect(content).to include("```text")
          expect(content).to include(idea_text)
          expect(content).to include("```")
        end

        result = subject.capture_idea(idea_text)
        expect(result.success?).to be true
      end
    end

    context "when enhancement fails and fallback is used" do
      before do
        # Mock failed LLM enhancement
        allow(mock_llm_client).to receive(:enhance_idea).and_return(
          CodingAgentTools::Molecules::LLMClient::LLMResult.new(false, nil, "LLM error", 3)
        )
      end

      it "includes SOURCE section in fallback idea" do
        # Expect the fallback file to be written with SOURCE section
        expect(File).to receive(:write).with(output_path, anything) do |path, content|
          expect(content).to include("# Raw Idea (Enhanced Version Failed)")
          expect(content).to include("## Original Idea")
          expect(content).to include(idea_text)
          expect(content).to include("> SOURCE")
          expect(content).to include("```text")
        end

        result = subject.capture_idea(idea_text)
        expect(result.success?).to be true
      end
    end

    context "when file already exists with enhanced content" do
      let(:existing_enhanced) { "# Previously Enhanced\n\nSome existing enhanced content that is longer than the raw input" }

      before do
        # Mock failed LLM enhancement
        allow(mock_llm_client).to receive(:enhance_idea).and_return(
          CodingAgentTools::Molecules::LLMClient::LLMResult.new(false, nil, "Security error", 0)
        )

        # Mock existing file with enhanced content
        allow(File).to receive(:exist?).with(output_path).and_return(true)
        allow(File).to receive(:read).with(output_path).and_return(existing_enhanced)
      end

      it "preserves existing content and adds SOURCE section" do
        expect(File).to receive(:write).with(output_path, anything) do |path, content|
          expect(content).to include(existing_enhanced)
          expect(content).to include("> SOURCE")
          expect(content).to include(idea_text)
          expect(content).not_to include("# Raw Idea (Enhanced Version Failed)")
        end

        result = subject.capture_idea(idea_text)
        expect(result.success?).to be true
        expect(result.debug_info).to include("Enhanced content preserved with SOURCE")
      end
    end
  end

  describe "#test_environment?" do
    it "returns true when CI environment variable is set" do
      with_env("CI" => "true") do
        expect(subject.send(:test_environment?)).to be true
      end
    end

    it "returns true when TEST environment variable is set" do
      with_env("TEST" => "1") do
        expect(subject.send(:test_environment?)).to be true
      end
    end

    it "returns true when RSPEC_RUN environment variable is set" do
      with_env("RSPEC_RUN" => "true") do
        expect(subject.send(:test_environment?)).to be true
      end
    end

    it "returns true when RSpec is defined" do
      # RSpec is already defined in test environment
      expect(subject.send(:test_environment?)).to be true
    end

    it "detects test environment even when env vars are nil" do
      # In test environment, RSpec is always defined, so method should return true
      with_env("CI" => nil, "TEST" => nil, "RSPEC_RUN" => nil) do
        expect(subject.send(:test_environment?)).to be true # Still true because RSpec constant exists
      end
    end
  end

  private

  def with_env(new_env)
    old_env = ENV.to_h
    new_env.each { |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    }
    yield
  ensure
    ENV.replace(old_env)
  end
end
